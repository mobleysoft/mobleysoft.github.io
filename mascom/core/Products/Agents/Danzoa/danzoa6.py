import os
import numpy as np
import librosa
import scipy.signal
from pydub import AudioSegment
import random
import logging
from tqdm import tqdm

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class FrissionPeakMixer:
    def __init__(self, input_dir, output_dir, target_duration_minutes=20):
        self.input_dir = input_dir
        self.output_dir = output_dir
        self.target_duration_ms = target_duration_minutes * 60 * 1000
        os.makedirs(output_dir, exist_ok=True)

    def detect_frission_peaks(self, y, sr):
        """
        Advanced peak detection algorithm to identify transcendent musical moments
        """
        # Multiple feature extraction for comprehensive analysis
        features = []
        
        # 1. Spectral contrast (timbral richness)
        spectral_contrast = librosa.feature.spectral_contrast(y=y, sr=sr)[0]
        features.append(spectral_contrast)
        
        # 2. Onset strength (rhythmic intensity)
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        features.append(onset_env)
        
        # 3. Root Mean Square Energy (overall intensity)
        rms = librosa.feature.rms(y=y)[0]
        features.append(rms)
        
        # 4. Pitch salience (melodic prominence)
        pitch_salience = librosa.piptrack(y=y, sr=sr)[0]
        features.append(np.mean(pitch_salience, axis=0))
        
        # Combine features
        combined_features = np.mean(features, axis=0)
        
        # Find local maxima that represent potential frission points
        peak_indices = scipy.signal.find_peaks(
            combined_features, 
            height=np.percentile(combined_features, 90),  # Top 10% intensity
            distance=int(sr * 1)  # Minimum 1 second between peaks
        )[0]
        
        # Convert to times
        peak_times = librosa.frames_to_time(peak_indices, sr=sr)
        
        return peak_times

    def analyze_tracks(self):
        """
        Analyze all tracks to find their most transcendent moments
        """
        track_peaks = {}
        
        audio_files = [
            f for f in os.listdir(self.input_dir) 
            if f.lower().endswith('.mp3')
        ]
        
        for track_file in tqdm(audio_files, desc="Analyzing Tracks"):
            try:
                # Full path to track
                full_path = os.path.join(self.input_dir, track_file)
                
                # Load audio
                y, sr = librosa.load(full_path, sr=22050, mono=True)
                
                # Detect frission peaks
                peaks = self.detect_frission_peaks(y, sr)
                
                # Store track information
                track_peaks[track_file] = {
                    'path': full_path,
                    'peaks': peaks,
                    'total_duration': librosa.get_duration(y=y, sr=sr)
                }
            except Exception as e:
                logger.error(f"Error analyzing {track_file}: {e}")
        
        return track_peaks

    def create_peak_mix(self):
        """
        Create a mixed composition from peak moments
        """
        # Analyze tracks to find peaks
        track_peaks = self.analyze_tracks()
        
        # Prepare final mix
        final_mix = AudioSegment.empty()
        current_duration_ms = 0
        
        # Randomize track order to create unique experience each time
        track_files = list(track_peaks.keys())
        random.shuffle(track_files)
        
        while current_duration_ms < self.target_duration_ms and track_files:
            # Select next track
            current_track_file = track_files.pop(0)
            track_info = track_peaks[current_track_file]
            
            # Load full track
            full_track = AudioSegment.from_file(track_info['path'])
            
            # Select peak moment
            if track_info['peaks'].size > 0:
                # Choose a random peak moment
                peak_time = random.choice(track_info['peaks'])
                peak_start_ms = int(peak_time * 1000)
                
                # Extract segment around peak (2-3 seconds)
                segment_duration = 2500  # 2.5 seconds
                segment_start = max(0, peak_start_ms - 500)
                segment_end = min(len(full_track), segment_start + segment_duration)
                
                peak_segment = full_track[segment_start:segment_end]
            else:
                # Fallback to random segment
                segment_duration = 2500
                start_ms = random.randint(0, max(0, len(full_track) - segment_duration))
                peak_segment = full_track[start_ms:start_ms + segment_duration]
            
            # Add to mix with intelligent transition
            if current_duration_ms > 0:
                # Crossfade or creative transition
                crossfade_duration = min(1000, len(peak_segment) // 2)
                final_mix = final_mix.append(peak_segment, crossfade=crossfade_duration)
            else:
                final_mix += peak_segment
            
            current_duration_ms += len(peak_segment)
            
            # If we've run out of tracks, reshuffle
            if not track_files:
                track_files = list(track_peaks.keys())
                random.shuffle(track_files)
        
        # Export final mix
        output_path = os.path.join(self.output_dir, "frission_peak_mix.mp3")
        final_mix.export(output_path, format="mp3")
        
        logger.info(f"Peak Mix created: {output_path}")
        logger.info(f"Final duration: {len(final_mix)/1000/60:.2f} minutes")

def main():
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    INPUT_DIR = os.path.join(BASE_DIR, "AllAtOnce")
    OUTPUT_DIR = os.path.join(BASE_DIR, "output")
    
    mixer = FrissionPeakMixer(INPUT_DIR, OUTPUT_DIR)
    mixer.create_peak_mix()

if __name__ == "__main__":
    main()