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

class MusicalPhraseMixer:
    def __init__(self, input_dir, output_dir):
        self.input_dir = input_dir
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)

    def extract_phrases(self, y, sr):
        """
        Extract meaningful musical phrases using beat and onset analysis
        """
        # Compute onset envelope and beat frames
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        tempo, beat_frames = librosa.beat.beat_track(onset_envelope=onset_env, sr=sr)
        
        # Estimate number of beats in a typical phrase (4 bars)
        beats_per_bar = tempo / 60 * 4  # 4 beats per bar assumption
        phrase_length = int(beats_per_bar * 4)  # 4 bars
        
        # Find potential phrase start points
        phrase_starts = []
        for i in range(0, len(beat_frames) - phrase_length, phrase_length):
            phrase_starts.append(beat_frames[i])
        
        # Analyze each phrase for musical interest
        phrases = []
        for start_frame in phrase_starts:
            # Extract phrase segment
            start_index = np.where(beat_frames == start_frame)[0][0]
            end_index = min(start_index + phrase_length, len(beat_frames) - 1)
            
            # Convert to audio sample indices
            start_sample = librosa.frames_to_samples(start_frame, hop_length=512)
            end_sample = librosa.frames_to_samples(beat_frames[end_index], hop_length=512)
            
            # Extract phrase audio
            phrase_y = y[start_sample:end_sample]
            
            # Compute phrase "interestingness"
            rms = librosa.feature.rms(y=phrase_y)[0]
            spectral_contrast = librosa.feature.spectral_contrast(y=phrase_y, sr=sr)[0]
            pitch_salience = np.mean(librosa.piptrack(y=phrase_y, sr=sr)[0], axis=0)
            
            # Combined interest score
            interest_score = np.mean(rms) * np.mean(spectral_contrast) * np.mean(pitch_salience)
            
            phrases.append({
                'start_sample': start_sample,
                'end_sample': end_sample,
                'start_time': librosa.samples_to_time(start_sample, sr=sr),
                'end_time': librosa.samples_to_time(end_sample, sr=sr),
                'interest_score': interest_score
            })
        
        # Sort phrases by interest score
        phrases.sort(key=lambda x: x['interest_score'], reverse=True)
        
        return phrases

    def create_phrase_mix(self):
        """
        Create a mix using the most interesting 4-bar phrases
        """
        # Find audio files
        audio_files = [
            f for f in os.listdir(self.input_dir) 
            if f.lower().endswith('.mp3')
        ]
        
        # Prepare final mix
        final_mix = AudioSegment.empty()
        
        # Track which files have been used
        used_files = set()
        
        # Collect phrases from all tracks
        all_phrases = []
        for track_file in tqdm(audio_files, desc="Analyzing Tracks"):
            try:
                # Full path to track
                full_path = os.path.join(self.input_dir, track_file)
                
                # Load audio
                y, sr = librosa.load(full_path, sr=22050, mono=True)
                
                # Extract phrases
                track_phrases = self.extract_phrases(y, sr)
                
                # Add track information to phrases
                for phrase in track_phrases:
                    phrase['track'] = full_path
                
                all_phrases.extend(track_phrases)
            
            except Exception as e:
                logger.error(f"Error analyzing {track_file}: {e}")
        
        # Sort all phrases by interest score
        all_phrases.sort(key=lambda x: x['interest_score'], reverse=True)
        
        # Select top phrases, ensuring variety
        selected_phrases = []
        used_tracks = set()
        
        for phrase in all_phrases:
            # Avoid using the same track multiple times in a row
            if phrase['track'] not in used_tracks:
                selected_phrases.append(phrase)
                used_tracks.add(phrase['track'])
            
            # Stop when we have enough phrases
            if len(selected_phrases) >= len(audio_files):
                break
        
        # Create mix from selected phrases
        for phrase in selected_phrases:
            # Load full track
            full_track = AudioSegment.from_file(phrase['track'])
            
            # Extract phrase segment
            phrase_segment = full_track[
                int(phrase['start_time'] * 1000):
                int(phrase['end_time'] * 1000)
            ]
            
            # Add to mix with crossfade
            if len(final_mix) > 0:
                final_mix = final_mix.append(phrase_segment, crossfade=min(1000, len(phrase_segment)//2))
            else:
                final_mix += phrase_segment
        
        # Export final mix
        output_path = os.path.join(self.output_dir, "musical_phrases_mix.mp3")
        final_mix.export(output_path, format="mp3")
        
        logger.info(f"Musical Phrases Mix created: {output_path}")
        logger.info(f"Final duration: {len(final_mix)/1000/60:.2f} minutes")

def main():
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    INPUT_DIR = os.path.join(BASE_DIR, "AllAtOnce")
    OUTPUT_DIR = os.path.join(BASE_DIR, "output")
    
    mixer = MusicalPhraseMixer(INPUT_DIR, OUTPUT_DIR)
    mixer.create_phrase_mix()

if __name__ == "__main__":
    main()