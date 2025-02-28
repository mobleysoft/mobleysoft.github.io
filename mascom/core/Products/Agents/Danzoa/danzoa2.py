import os
import sys
import librosa
import numpy as np
import logging
import random
from pydub import AudioSegment
from dj_mixing_techniques import DJMixingTechniques

logging.basicConfig(
    level=logging.DEBUG, 
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("danzoa_mixer.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class RecursiveSegmentMixer:
    def __init__(self, upload_dir, output_dir):
        self.upload_dir = upload_dir
        self.output_dir = output_dir
        self.seed = random.randint(0, 2**32 - 1)
        random.seed(self.seed)
        os.makedirs(output_dir, exist_ok=True)
        self.segment_types = ['intro', 'verse', 'chorus', 'bridge']

    def analyze_track_segments(self, track_path):
        try:
            y, sr = librosa.load(track_path, sr=22050, mono=True)
            
            if len(y) < sr * 10:
                logger.warning(f"Track too short: {track_path}")
                return None
            
            # Use onset strength for more reliable segmentation
            onset_env = librosa.onset.onset_strength(y=y, sr=sr)
            tempo, beat_frames = librosa.beat.beat_track(onset_envelope=onset_env, sr=sr)
            
            if len(beat_frames) < 4:
                logger.warning(f"Not enough beats detected in: {track_path}")
                return None
            
            duration = librosa.get_duration(y=y, sr=sr)
            segments = {
                'intro': (0, beat_frames[len(beat_frames)//4] / sr),
                'verse': (beat_frames[len(beat_frames)//4] / sr, 
                          beat_frames[len(beat_frames)//2] / sr),
                'chorus': (beat_frames[len(beat_frames)//2] / sr, 
                           beat_frames[3*len(beat_frames)//4] / sr),
                'bridge': (beat_frames[3*len(beat_frames)//4] / sr, 
                           duration)
            }
            
            return {
                'path': track_path,
                'segments': segments,
                'duration': duration
            }
        except Exception as e:
            logger.error(f"Segment analysis error for {track_path}: {e}")
            return None

    def extract_segment(self, track_info, segment_type):
        try:
            audio = AudioSegment.from_file(track_info['path'])
            
            segments = track_info['segments']
            start_ms = int(segments[segment_type][0] * 1000)
            end_ms = int(segments[segment_type][1] * 1000)
            
            segment = audio[start_ms:end_ms]
            if len(segment) < 1000:
                logger.warning(f"Segment too short: {track_info['path']} - {segment_type}")
                return None
            
            return segment
        except Exception as e:
            logger.error(f"Segment extraction error: {e}")
            return None

    def recursive_mix(self, track_segments, current_mix=None, used_tracks=None, 
                      max_duration=90*60*1000, current_duration=0, attempt=0):
        used_tracks = used_tracks or set()
        
        if current_duration >= max_duration or attempt > len(track_segments) * len(self.segment_types):
            return current_mix
        
        available_tracks = [
            track for track in track_segments 
            if track['path'] not in used_tracks
        ]
        
        if not available_tracks:
            used_tracks.clear()
            available_tracks = track_segments
        
        if not available_tracks:
            return current_mix
        
        next_track = random.choice(available_tracks)
        next_segment_type = random.choice(self.segment_types)
        
        next_segment = self.extract_segment(next_track, next_segment_type)
        
        if next_segment is None:
            return self.recursive_mix(
                track_segments, 
                current_mix, 
                used_tracks, 
                max_duration, 
                current_duration, 
                attempt + 1
            )
        
        if current_mix is None:
            current_mix = next_segment
            current_duration = len(current_mix)
            used_tracks.add(next_track['path'])
            
            return self.recursive_mix(
                track_segments, 
                current_mix, 
                used_tracks, 
                max_duration, 
                current_duration
            )
        
        try:
            transition_techniques = DJMixingTechniques.get_all_techniques()
            mixed_segment = random.choice(transition_techniques)(current_mix, next_segment)
            
            if mixed_segment is None:
                return current_mix
            
            current_mix = mixed_segment
            current_duration += len(mixed_segment)
            used_tracks.add(next_track['path'])
            
            return self.recursive_mix(
                track_segments, 
                current_mix, 
                used_tracks, 
                max_duration, 
                current_duration
            )
        except Exception as e:
            logger.error(f"Mixing error: {e}")
            return current_mix

    def generate_mix(self):
        audio_files = [
            f for f in os.listdir(self.upload_dir) 
            if f.lower().endswith(('.mp3', '.wav'))
        ]
        
        logger.info(f"Found {len(audio_files)} audio files")
        
        track_segments = []
        for audio_file in audio_files:
            full_path = os.path.join(self.upload_dir, audio_file)
            track_info = self.analyze_track_segments(full_path)
            if track_info:
                track_segments.append(track_info)
        
        logger.info(f"Processed {len(track_segments)} valid track segments")
        
        final_mix = self.recursive_mix(track_segments)
        
        if final_mix:
            output_path = os.path.join(
                self.output_dir, 
                f"ultimate_mix_{self.seed}.mp3"
            )
            final_mix.export(output_path, format="mp3")
            logger.info(
                f"Mix created: {output_path} "
                f"(Duration: {len(final_mix)/1000/60:.2f} minutes)"
            )
        
        return final_mix

def main():
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    UPLOAD_DIR = os.path.join(BASE_DIR, "AllAtOnce")
    OUTPUT_DIR = os.path.join(BASE_DIR, "output")
    
    try:
        mixer = RecursiveSegmentMixer(UPLOAD_DIR, OUTPUT_DIR)
        mixer.generate_mix()
    except Exception as e:
        logger.error(f"Mixing process failed: {e}")

if __name__ == "__main__":
    main()