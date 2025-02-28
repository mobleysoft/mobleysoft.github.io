import os
import json
import numpy as np
import librosa
import scipy.signal
from pydub import AudioSegment
import random
import logging
from tqdm import tqdm

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class PeakAnalysisMixer:
    def __init__(self, input_dir, output_dir):
        self.input_dir = input_dir
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)

    def extract_song_components(self, y, sr):
        """
        Intelligently segment the track into different components
        """
        # Onset detection
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        tempo, beat_frames = librosa.beat.beat_track(onset_envelope=onset_env, sr=sr)
        
        # Divide track into components
        total_frames = len(y)
        components = {
            'intro': (0, beat_frames[len(beat_frames)//4]),
            'verse': (beat_frames[len(beat_frames)//4], beat_frames[len(beat_frames)//2]),
            'chorus': (beat_frames[len(beat_frames)//2], beat_frames[3*len(beat_frames)//4]),
            'bridge': (beat_frames[3*len(beat_frames)//4], total_frames)
        }
        
        return components

    def detect_frission_peaks(self, y, sr, components):
        """
        Advanced peak detection for each track component
        """
        peaks_data = {}
        
        # Multiple feature extraction
        features = {
            'spectral_contrast': librosa.feature.spectral_contrast(y=y, sr=sr)[0],
            'onset_strength': librosa.onset.onset_strength(y=y, sr=sr),
            'rms': librosa.feature.rms(y=y)[0],
            'pitch_salience': np.mean(librosa.piptrack(y=y, sr=sr)[0], axis=0)
        }
        
        # Combine features for each component
        for component_name, (start_frame, end_frame) in components.items():
            component_y = y[start_frame:end_frame]
            
            # Combine features for this component
            combined_features = np.mean([
                features['spectral_contrast'][start_frame:end_frame],
                features['onset_strength'][start_frame:end_frame],
                features['rms'][start_frame:end_frame],
                features['pitch_salience'][start_frame:end_frame]
            ], axis=0)
            
            # Find peaks
            peak_indices = scipy.signal.find_peaks(
                combined_features, 
                height=np.percentile(combined_features, 90),
                distance=int(sr * 0.5)  # Minimum 0.5 second between peaks
            )[0]
            
            # Convert to absolute frame indices and then to times
            absolute_peak_indices = peak_indices + start_frame
            peak_times = librosa.frames_to_time(absolute_peak_indices, sr=sr)
            
            peaks_data[component_name] = {
                'peak_times': peak_times.tolist(),
                'peak_frames': absolute_peak_indices.tolist()
            }
        
        return peaks_data

    def analyze_tracks(self):
        """
        Comprehensive analysis of all tracks
        """
        track_analyses = {}
        
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
                
                # Extract song components
                components = self.extract_song_components(y, sr)
                
                # Detect peaks
                peaks = self.detect_frission_peaks(y, sr, components)
                
                # Store track information
                track_analyses[track_file] = {
                    'path': full_path,
                    'components': {
                        comp: {
                            'start_time': librosa.frames_to_time(start, sr=sr),
                            'end_time': librosa.frames_to_time(end, sr=sr)
                        } for comp, (start, end) in components.items()
                    },
                    'peaks': peaks
                }
            except Exception as e:
                logger.error(f"Error analyzing {track_file}: {e}")
        
        return track_analyses

    def create_ranked_peak_mix(self):
        """
        Create a mix that showcases the best peaks across all tracks
        """
        # Analyze tracks
        track_analyses = self.analyze_tracks()
        
        # Save detailed analysis
        analysis_output_path = os.path.join(self.output_dir, "track_peak_analysis.json")
        with open(analysis_output_path, 'w') as f:
            json.dump(track_analyses, f, indent=2)
        logger.info(f"Detailed peak analysis saved to {analysis_output_path}")
        
        # Prepare final mix
        final_mix = AudioSegment.empty()
        
        # Group peaks by component across all tracks
        component_peaks = {
            'intro': [],
            'verse': [],
            'chorus': [],
            'bridge': []
        }
        
        # Collect peaks for each component
        for track, analysis in track_analyses.items():
            for component, peak_data in analysis['peaks'].items():
                for peak_time, peak_frame in zip(peak_data['peak_times'], peak_data['peak_frames']):
                    component_peaks[component].append({
                        'track': track,
                        'peak_time': peak_time,
                        'peak_frame': peak_frame
                    })
        
        # Sort peaks within each component by their combined feature strength
        for component in component_peaks:
            component_peaks[component].sort(
                key=lambda x: track_analyses[x['track']]['peaks'][component]['peak_frames'].index(x['peak_frame']),
                reverse=True
            )
        
        # Extract and mix top peaks
        for component in ['intro', 'verse', 'chorus', 'bridge']:
            # Take top 4 peaks
            top_peaks = component_peaks[component][:4]
            
            for peak_info in top_peaks:
                track = peak_info['track']
                full_track = AudioSegment.from_file(track_analyses[track]['path'])
                
                # Extract segment around peak
                peak_time = peak_info['peak_time']
                segment_start_ms = max(0, int((peak_time - 1) * 1000))  # 1 second before peak
                segment_end_ms = min(len(full_track), int((peak_time + 1.5) * 1000))  # 1.5 seconds after peak
                
                peak_segment = full_track[segment_start_ms:segment_end_ms]
                
                # Add to mix with crossfade
                if len(final_mix) > 0:
                    final_mix = final_mix.append(peak_segment, crossfade=min(1000, len(peak_segment)//2))
                else:
                    final_mix += peak_segment
        
        # Export final mix
        output_path = os.path.join(self.output_dir, "ranked_peak_mix.mp3")
        final_mix.export(output_path, format="mp3")
        
        logger.info(f"Ranked Peak Mix created: {output_path}")
        logger.info(f"Final duration: {len(final_mix)/1000/60:.2f} minutes")

def main():
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    INPUT_DIR = os.path.join(BASE_DIR, "AllAtOnce")
    OUTPUT_DIR = os.path.join(BASE_DIR, "output")
    
    mixer = PeakAnalysisMixer(INPUT_DIR, OUTPUT_DIR)
    mixer.create_ranked_peak_mix()

if __name__ == "__main__":
    main()