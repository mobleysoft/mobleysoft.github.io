import os, random, logging
from pydub import AudioSegment
from typing import List

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SimpleMixer:
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

    def bag_concat_mix(self) -> None:
        # Get all audio files
        audio_files = self.get_audio_files()
        
        if not audio_files:
            logger.error("No audio files found")
            return

        # Create our "bag" of files - we'll remove each one as we use it
        remaining_files = audio_files.copy()
        final_mix = AudioSegment.empty()
        track_order = []

        # Keep picking files until the bag is empty
        while remaining_files:
            # Pick a random file from the remaining ones
            current_track = random.choice(remaining_files)
            # Remove it from the bag
            remaining_files.remove(current_track)
            
            # Add the track to our mix
            final_mix += AudioSegment.from_file(current_track)
            
            # Log which track we're adding
            track_name = os.path.basename(current_track)
            track_order.append(track_name)
            logger.info(f"Added track: {track_name}")

        # Export the final mix
        output_path = os.path.join(self.output_dir, "final_mix_bag.mp3")
        final_mix.export(output_path, format="mp3")
        
        # Log completion info
        logger.info(f"Mix created: {output_path}")
        logger.info(f"Duration: {len(final_mix)/1000/60:.2f} minutes")
        logger.info("Track order:")
        for i, track in enumerate(track_order, 1):
            logger.info(f"{i}. {track}")

def main():
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    INPUT_DIR = os.path.join(BASE_DIR, "AllAtOnce")
    OUTPUT_DIR = os.path.join(BASE_DIR, "output")
    
    mixer = SimpleMixer(INPUT_DIR, OUTPUT_DIR)
    mixer.bag_concat_mix()

if __name__ == "__main__":
    main()