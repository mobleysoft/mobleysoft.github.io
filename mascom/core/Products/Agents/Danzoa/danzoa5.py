import os
import random
import logging
import numpy as np
import librosa
from pydub import AudioSegment
import scipy.signal
import time
from tqdm import tqdm

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class IntelligentMixer:
    def __init__(self, input_dir, output_dir):
        self.input_dir = input_dir
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)

    def analyze_track_segments(self, track_path):
        """
        Deeply analyze track to find most interesting segments
        """
        try:
            # Load audio
            y, sr = librosa.load(track_path, sr=22050, mono=True)
            
            # Compute various musical features
            onset_env = librosa.onset.onset_strength(y=y, sr=sr)
            tempo, beat_frames = librosa.beat.beat_track(onset_envelope=onset_env, sr=sr)
            
            # Spectral features
            spectral_centroids = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
            spectral_bandwidth = librosa.feature.spectral_bandwidth(y=y, sr=sr)[0]
            
            # Compute novelty curve
            novelty = scipy.signal.argrelextrema(onset_env, np.greater)[0]
            
            # Energy calculation
            rms = librosa.feature.rms(y=y)[0]
            
            # Combine features into an "interestingness" score
            interestingness = (
                scipy.signal.savgol_filter(rms, 11, 3) * 
                scipy.signal.savgol_filter(spectral_centroids, 11, 3) / 
                scipy.signal.savgol_filter(spectral_bandwidth, 11, 3)
            )
            
            # Find top interesting segments
            top_segments = sorted(
                range(len(interestingness)), 
                key=lambda i: interestingness[i], 
                reverse=True
            )
            
            # Convert frames to time
            interesting_times = [
                librosa.frames_to_time(frame, sr=sr) 
                for frame in top_segments[:10]  # Top 10 interesting moments
            ]
            
            return {
                'path': track_path,
                'interesting_moments': interesting_times,
                'total_duration': librosa.get_duration(y=y, sr=sr),
                'tempo': tempo
            }
        
        except Exception as e:
            logger.error(f"Error analyzing {track_path}: {e}")
            return None

    def create_intelligent_mix(self, target_duration_minutes=60):
        # Find and analyze tracks
        audio_files = [
            os.path.join(self.input_dir, f) 
            for f in os.listdir(self.input_dir) 
            if f.lower().endswith('.mp3')
        ]
        
        # Progress tracking for analysis
        print("Analyzing tracks...")
        track_analyses = []
        for track in tqdm(audio_files, desc="Track Analysis"):
            analysis = self.analyze_track_segments(track)
            if analysis:
                track_analyses.append(analysis)
        
        # Calculate proportional representation
        total_duration = sum(t['total_duration'] for t in track_analyses)
        target_duration_ms = target_duration_minutes * 60 * 1000
        
        # Create mix with progress tracking
        print("\nCreating mix...")
        final_mix = AudioSegment.empty()
        current_duration_ms = 0
        
        for track_info in tqdm(track_analyses, desc="Mix Creation"):
            # Calculate proportional segment length
            track_proportion = track_info['total_duration'] / total_duration
            segment_duration_ms = int(target_duration_ms * track_proportion)
            
            # Load full track
            full_track = AudioSegment.from_file(track_info['path'])
            
            # Select an interesting segment
            interesting_moments = track_info['interesting_moments']
            if interesting_moments:
                # Choose a random interesting moment
                start_time = random.choice(interesting_moments)
                
                # Convert to milliseconds
                start_ms = int(start_time * 1000)
                end_ms = min(start_ms + segment_duration_ms, len(full_track))
                
                # Extract segment
                track_segment = full_track[start_ms:end_ms]
            else:
                # Fallback to random segment
                start_ms = random.randint(0, max(0, len(full_track) - segment_duration_ms))
                track_segment = full_track[start_ms:start_ms + segment_duration_ms]
            
            # Add to mix with crossfade
            if current_duration_ms > 0:
                crossfade_duration = min(5000, len(track_segment) // 2)
                final_mix = final_mix.append(track_segment, crossfade=crossfade_duration)
            else:
                final_mix += track_segment
            
            current_duration_ms += len(track_segment)
            
            # Stop if we've reached target duration
            if current_duration_ms >= target_duration_ms:
                break
        
        # Export mix
        output_path = os.path.join(self.output_dir, "intelligent_mix.mp3")
        print("\nExporting mix...")
        final_mix.export(output_path, format="mp3")
        
        logger.info(f"Mix created: {output_path}")
        logger.info(f"Final duration: {len(final_mix)/1000/60:.2f} minutes")
        print(f"Mix duration: {len(final_mix)/1000/60:.2f} minutes")

def main():
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    INPUT_DIR = os.path.join(BASE_DIR, "AllAtOnce")
    OUTPUT_DIR = os.path.join(BASE_DIR, "output")
    
    start_time = time.time()
    mixer = IntelligentMixer(INPUT_DIR, OUTPUT_DIR)
    mixer.create_intelligent_mix()
    end_time = time.time()
    
    print(f"\nTotal processing time: {end_time - start_time:.2f} seconds")

if __name__ == "__main__":
    main()