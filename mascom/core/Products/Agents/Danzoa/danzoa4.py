import os, random, logging
from pydub import AudioSegment
from typing import List

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class CrossfadeMixer:
    def __init__(self, input_dir: str, output_dir: str):
        self.input_dir = input_dir
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)

    def get_audio_files(self) -> List[str]:
        return [
            os.path.join(self.input_dir, f) 
            for f in os.listdir(self.input_dir) 
            if f.lower().endswith('.mp3') and os.path.isfile(os.path.join(self.input_dir, f))
        ]

    def create_crossfade_mix(self) -> None:
        audio_files = self.get_audio_files()
        
        if not audio_files:
            logger.error("No audio files found")
            return
        
        track_bag = audio_files.copy()
        random.shuffle(track_bag)
        
        final_mix = AudioSegment.empty()
        
        while track_bag:
            current_track = track_bag.pop(random.randint(0, len(track_bag) - 1))
            current_audio = AudioSegment.from_file(current_track)
            
            final_mix += current_audio
            
            if track_bag:
                next_track = track_bag[0]
                next_audio = AudioSegment.from_file(next_track)
                crossfade_duration = min(len(current_audio), len(next_audio), 10000)
                final_mix = final_mix.append(next_audio, crossfade=crossfade_duration)
        
        output_path = os.path.join(self.output_dir, "final_mix_crossfade.mp3")
        final_mix.export(output_path, format="mp3")
        logger.info(f"Mix created: {output_path} (Duration: {len(final_mix)/1000/60:.2f} minutes)")

def main():
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    INPUT_DIR = os.path.join(BASE_DIR, "AllAtOnce")
    OUTPUT_DIR = os.path.join(BASE_DIR, "output")
    
    mixer = CrossfadeMixer(INPUT_DIR, OUTPUT_DIR)
    mixer.create_crossfade_mix()

if __name__ == "__main__":
    main()