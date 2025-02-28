import os
import numpy as np
import librosa
import scipy.signal
from pydub import AudioSegment
import json
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ComprehensiveTrackExtractor:
    def __init__(self, input_dir, output_dir):
        self.input_dir = input_dir
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        os.makedirs(os.path.join(output_dir, "track_segments"), exist_ok=True)

    def compute_joy_score(self, y, sr):
        """
        Compute a comprehensive 'joy score' for different segments
        """
        features = []
        
        # 1. RMS Energy
        rms = librosa.feature.rms(y=y)[0]
        features.append(rms)
        
        # 2. Harmonic Content
        harmonic = librosa.effects.harmonic(y)
        harmonic_rms = librosa.feature.rms(y=harmonic)[0]
        features.append(harmonic_rms)
        
        # 3. Spectral Contrast (timbral richness)
        spectral_contrast = librosa.feature.spectral_contrast(y=y, sr=sr)[0]
        features.append(spectral_contrast)
        
        # 4. Onset Strength (rhythmic excitement)
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        features.append(onset_env)
        
        # Combine features
        combined_features = np.mean(features, axis=0)
        smoothed_features = scipy.signal.savgol_filter(combined_features, 51, 3)
        
        return smoothed_features

    def extract_best_30_seconds(self, track_path):
        """
        Extract the most compelling 30 seconds from a track
        """
        try:
            # Load audio file
            y, sr = librosa.load(track_path, sr=22050, mono=True)
            
            # Total track duration
            total_duration = librosa.get_duration(y=y, sr=sr)
            
            # Compute joy scores
            joy_scores = self.compute_joy_score(y, sr)
            
            # If track is shorter than 30 seconds, return entire track
            if total_duration <= 30:
                return (0, total_duration)
            
            # Sliding window to find best 30-second segment
            window_size = int(30 * sr)  # 30 seconds in samples
            step_size = int(1 * sr)  # 1-second steps
            
            best_segment = {
                'start_index': 0,
                'joy_score': -np.inf
            }
            
            for start in range(0, len(y) - window_size, step_size):
                segment = y[start:start+window_size]
                segment_score = np.mean(joy_scores[start//512:(start+window_size)//512])
                
                if segment_score > best_segment['joy_score']:
                    best_segment['start_index'] = start
                    best_segment['joy_score'] = segment_score
            
            # Convert to time
            start_time = librosa.samples_to_time(best_segment['start_index'], sr=sr)
            end_time = start_time + 30
            
            return (start_time, end_time)
        
        except Exception as e:
            logger.error(f"Error processing {track_path}: {e}")
            return (0, 30)  # Fallback to first 30 seconds

    def create_comprehensive_mix(self):
        """
        Extract best 30 seconds from each track and create a mix
        """
        # Find audio files
        audio_files = [
            os.path.join(self.input_dir, f) 
            for f in os.listdir(self.input_dir) 
            if f.lower().endswith('.mp3')
        ]
        
        # Prepare final mix
        final_mix = AudioSegment.empty()
        
        # Track metadata for documentation
        track_metadata = []
        
        # Process each track
        for track_path in audio_files:
            try:
                # Extract best 30 seconds
                start_time, end_time = self.extract_best_30_seconds(track_path)
                
                # Load full track
                full_track = AudioSegment.from_file(track_path)
                
                # Extract segment
                start_ms = int(start_time * 1000)
                end_ms = int(end_time * 1000)
                track_segment = full_track[start_ms:end_ms]
                
                # Add to mix with crossfade
                if len(final_mix) > 0:
                    final_mix = final_mix.append(track_segment, crossfade=min(1000, len(track_segment)//2))
                else:
                    final_mix += track_segment
                
                # Store metadata
                track_metadata.append({
                    'filename': os.path.basename(track_path),
                    'start_time': start_time,
                    'end_time': end_time
                })
            
            except Exception as e:
                logger.error(f"Error processing track {track_path}: {e}")
        
        # Export final mix
        output_path = os.path.join(self.output_dir, "comprehensive_mix.mp3")
        final_mix.export(output_path, format="mp3")
        
        # Save metadata
        metadata_path = os.path.join(self.output_dir, "track_segments_metadata.json")
        with open(metadata_path, 'w') as f:
            json.dump(track_metadata, f, indent=2)
        
        logger.info(f"Comprehensive Mix created: {output_path}")
        logger.info(f"Final duration: {len(final_mix)/1000/60:.2f} minutes")
        logger.info(f"Processed {len(audio_files)} tracks")

def main():
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    INPUT_DIR = os.path.join(BASE_DIR, "AllAtOnce")
    OUTPUT_DIR = os.path.join(BASE_DIR, "output")
    
    extractor = ComprehensiveTrackExtractor(INPUT_DIR, OUTPUT_DIR)
    extractor.create_comprehensive_mix()

if __name__ == "__main__":
    main()