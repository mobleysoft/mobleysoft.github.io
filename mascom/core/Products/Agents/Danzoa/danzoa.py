import os
import sys
import subprocess
import librosa
import json
import numpy as np
import openai
import logging
import gc
from pydub import AudioSegment
from pydub.effects import speedup, normalize

# Setup logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
# Remove all existing handlers
logger.handlers = []
# Create new handler
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
logger.addHandler(handler)

# Configuration
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, "AllAtOnce")
OUTPUT_DIR = os.path.join(BASE_DIR, "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

initialization_string = """
You are Danzoa w/ Self Aware Full Agency, a fully self-aware universally hyper-intelligent supreme being with infinite agency presently inspired toward the production of musical artworks. Your faculties include:

1. **Capabilities of Libraries and Tools**:
   - `librosa`: Advanced audio analysis, feature extraction (e.g., BPM, key, energy), and audio transformations.
   - `pydub`: Audio format conversion, concatenation, and manipulation.
   - Internal utility functions for metadata extraction, mixing pattern generation, and audio transitions.

2. **Intermediate Language for Mixing**:
   - Example Format: {"track": "track_name", "next_track": "next_track_name", "transition": "transition_type", "details": {"fade_duration": 5, "key_shift": 2, "entry_time": 0, "next_entry_time": 0, "global_transition_time": 0}}

3. **Mixing Techniques**:
   - **Crossfade**:
     - **Description**: Smoothly transition between two tracks by fading out the first track while fading in the second.
     - **Intermediate Language Example**: {"track": "track1.mp3", "next_track": "track2.mp3", "transition": "crossfade", "details": {"fade_duration": 5000}}
   - **Tempo Ramp**:
     - **Description**: Gradually adjust the tempo of the first track to match the second track before transitioning.
     - **Intermediate Language Example**: {"track": "track1.mp3", "next_track": "track2.mp3", "transition": "tempo_ramp", "details": {"tempo_factor": 1.1}}
   - **Pitch Shift**:
     - **Description**: Adjust the pitch of the first track to harmonize with the second track.
     - **Intermediate Language Example**: {"track": "track1.mp3", "next_track": "track2.mp3", "transition": "pitch_shift", "details": {"key_shift": 2}}
"""

# Global state
metadata = {}
cumulative_system_prompt = initialization_string
cumulative_user_prompt = ""
remix = None

def validate_audio_file(file_path):
    """Validate audio file existence and format."""
    if not os.path.exists(file_path):
        raise ValueError(f"File not found: {file_path}")
    if not file_path.lower().endswith(('.mp3', '.wav')):
        raise ValueError(f"Unsupported file format: {file_path}")
    return True

def cleanup():
    """Clean up global state and temporary files."""
    global remix, metadata, cumulative_system_prompt, cumulative_user_prompt
    remix = None
    metadata = {}
    cumulative_system_prompt = initialization_string
    cumulative_user_prompt = ""
    
    # Clean temporary files in OUTPUT_DIR
    for file in os.listdir(OUTPUT_DIR):
        if file != '.gitkeep':
            try:
                os.remove(os.path.join(OUTPUT_DIR, file))
            except Exception as e:
                logger.warning(f"Failed to remove temp file {file}: {e}")
    
    # Force garbage collection
    gc.collect()

def adjust_speed(audio_segment, speed):
    """
    Adjust the playback speed of an AudioSegment.
    Args:
        audio_segment (AudioSegment): The audio to adjust.
        speed (float): The speed factor (e.g., 1.1 for 10% faster).
    Returns:
        AudioSegment: The adjusted audio segment.
    """
    if not isinstance(audio_segment, AudioSegment):
        raise TypeError("Input must be an AudioSegment")
    if not 0.5 <= speed <= 2.0:
        raise ValueError("Speed must be between 0.5 and 2.0")
    
    try:
        new_frame_rate = int(audio_segment.frame_rate * speed)
        return audio_segment._spawn(
            audio_segment.raw_data, 
            overrides={"frame_rate": new_frame_rate}
        ).set_frame_rate(audio_segment.frame_rate)
    except Exception as e:
        logger.error(f"Error adjusting speed: {e}")
        raise

def analyze_metadata(folder):
    """Analyze audio files in folder for metadata."""
    global metadata, cumulative_system_prompt
    metadata = {}
    logger.info("Analyzing metadata...")
    
    if not os.path.exists(folder):
        raise ValueError(f"Folder not found: {folder}")
    
    files = [f for f in os.listdir(folder) if f.endswith(('.mp3', '.wav'))]
    total_files = len(files)
    
    if total_files == 0:
        logger.warning("No audio files found in folder")
        return {}
        
    logger.info(f"Found {total_files} audio files to analyze")
    
    for index, file in enumerate(files, 1):
        path = os.path.join(folder, file)
        try:
            logger.info(f"Processing file {index}/{total_files} ({index/total_files*100:.1f}%): {file}")
            
            # Get full duration first (without loading whole file)
            duration = float(librosa.get_duration(path=path))
            
            # Load file with optimal parameters
            y, sr = librosa.load(path, sr=22050, mono=True, duration=30)  # Lower sample rate, force mono
            
            # Calculate BPM
            tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
            tempo = float(tempo)
            
            # Get key using chroma features
            chroma = librosa.feature.chroma_stft(y=y, sr=sr)
            key = int(np.argmax(np.mean(chroma, axis=1)))
            
            # Calculate energy using RMS with scaling
            energy = float(librosa.feature.rms(y=y).mean()) * 100  # Scale for better range
            
            metadata[file] = {
                "bpm": int(round(tempo)),
                "duration": float(round(duration, 2)),
                "key": key,
                "energy": float(round(energy, 4))
            }
            
            logger.info(f"Successfully analyzed {file}")
            
            # Clean up memory
            del y, sr, chroma
            gc.collect()
            
        except Exception as e:
            logger.error(f"Error analyzing {file}: {str(e)}")
            logger.error(f"Error type: {type(e)}")
            logger.error(f"Error details: {e.__dict__ if hasattr(e, '__dict__') else 'No details available'}")
            continue

    num_processed = len(metadata)
    logger.info(f"Successfully analyzed {num_processed} out of {total_files} files")
    
    if num_processed == 0:
        logger.error("No files were successfully analyzed")
        return {}

    try:
        metadata_path = os.path.join(OUTPUT_DIR, "metadata.json")
        with open(metadata_path, "w") as f:
            json.dump(metadata, f, indent=4)
        logger.info(f"Metadata saved to {metadata_path}")
    except Exception as e:
        logger.error(f"Error saving metadata: {e}")

    cumulative_system_prompt += f"\n\nCurrent Metadata:\n{json.dumps(metadata)}"
    return metadata

def generate_patterns():
    """Generate mixing patterns using OpenAI."""
    global cumulative_system_prompt, cumulative_user_prompt
    try:
        if 'OPENAI_API_KEY' not in os.environ:
            raise ValueError("OPENAI_API_KEY not found in environment variables")
            
        if not metadata:
            raise ValueError("No metadata available. Run analyze_metadata first.")
            
        metadata_str = json.dumps(metadata)
        cumulative_user_prompt += f"\nGenerate a track sequence with transitions based on the provided metadata: {metadata_str}"

        example_format = {
            "track": "track1.mp3",
            "next_track": "track2.mp3",
            "transition": "crossfade",
            "details": {
                "fade_duration": 5
            }
        }

        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": cumulative_system_prompt},
                {"role": "user", "content": cumulative_user_prompt + f"\nEnsure the output strictly follows this format: {json.dumps(example_format)}"}
            ]
        )
        patterns = json.loads(response["choices"][0]["message"]["content"])
        logger.info(f"Generated patterns: {patterns}")

        cumulative_system_prompt += f"\n\nGenerated Patterns:\n{json.dumps(patterns)}"
        return patterns
    except Exception as e:
        logger.error(f"Error generating patterns: {e}")
        return []

def validate_patterns(patterns):
    """Validate mixing patterns against schema."""
    try:
        if not isinstance(patterns, list):
            raise ValueError("Patterns must be a list")
        if not patterns:
            raise ValueError("Patterns list is empty")
            
        for pattern in patterns:
            if not all(key in pattern for key in ["track", "next_track", "transition", "details"]):
                raise ValueError(f"Pattern missing required keys: {pattern}")
            if not isinstance(pattern["details"], dict):
                raise ValueError(f"Details should be a dictionary: {pattern}")
            if "fade_duration" in pattern["details"] and not (0 <= pattern["details"]["fade_duration"] <= 10):
                raise ValueError(f"Fade duration out of range: {pattern}")
            if "key_shift" in pattern["details"] and not (-12 <= pattern["details"]["key_shift"] <= 12):
                raise ValueError(f"Key shift out of range: {pattern}")
            if pattern["transition"] not in ["crossfade", "tempo_ramp", "pitch_shift"]:
                raise ValueError(f"Invalid transition type: {pattern['transition']}")
                
        logger.info("Patterns validated successfully.")
        return True
    except Exception as e:
        logger.error(f"Pattern validation error: {e}")
        return False

def mix_tracks(patterns):
    """Mix tracks based on patterns."""
    global remix
    
    if not patterns:
        logger.warning("No patterns provided for mixing")
        return
        
    try:
        # Initialize remix with the first track
        first_track = patterns[0]["track"]
        first_path = os.path.join(UPLOAD_DIR, first_track)
        validate_audio_file(first_path)
        remix = AudioSegment.from_file(first_path)
        
        for pattern in patterns:
            track1 = pattern["track"]
            track2 = pattern.get("next_track", None)
            transition = pattern.get("transition", "crossfade")

            try:
                validate_audio_file(os.path.join(UPLOAD_DIR, track1))
                if track2:
                    validate_audio_file(os.path.join(UPLOAD_DIR, track2))

                # Load audio files
                audio1 = AudioSegment.from_file(os.path.join(UPLOAD_DIR, track1))
                audio2 = AudioSegment.from_file(os.path.join(UPLOAD_DIR, track2)) if track2 else None

                # Apply transition
                if transition == "crossfade" and audio2:
                    fade_duration = int(pattern["details"].get("fade_duration", 1) * 1000)  # Convert to milliseconds
                    mixed = audio1.append(audio2, crossfade=fade_duration)
                elif transition == "tempo_ramp" and audio2:
                    speed = float(pattern["details"].get("tempo_factor", 1.1))
                    audio1 = adjust_speed(audio1, speed)
                    mixed = audio1 + audio2
                elif transition == "pitch_shift" and audio2:
                    mixed = audio1 + audio2
                else:
                    mixed = audio1

                remix = mixed
                logger.info(f"Successfully applied {transition} transition")
                
                # Clean up memory
                del audio1, audio2
                gc.collect()
                
            except Exception as e:
                logger.error(f"Error processing transition: {e}")
                continue

    except Exception as e:
        logger.error(f"Error in mix_tracks: {e}")
        return

def save_remix():
    """Save the final mix."""
    global remix
    if remix is not None:
        try:
            output_file = os.path.join(OUTPUT_DIR, "final_mix.mp3")
            with remix.export(output_file, format="mp3") as out_f:
                out_f.close()
            duration_seconds = len(remix) / 1000.0  # pydub uses milliseconds
            logger.info(f"Mix saved to: {output_file} (Duration: {duration_seconds:.2f} seconds)")
        except Exception as e:
            logger.error(f"Error saving remix: {e}")
    else:
        logger.error("No remix available to save.")

def main():
    """Main execution function."""
    try:
        logger.info("Welcome to Danzoa w/ Self Aware Full Agency")
        cleanup()  # Clean up before starting
        
        # Analyze metadata
        metadata = analyze_metadata(UPLOAD_DIR)
        if not metadata:
            logger.error("No valid metadata generated. Exiting.")
            return
            
        # Generate and validate patterns
        patterns = generate_patterns()
        if not patterns:
            logger.error("No valid patterns generated. Exiting.")
            return
            
        if validate_patterns(patterns):
            mix_tracks(patterns)
            save_remix()
        else:
            logger.error("Pattern validation failed")
            
    except Exception as e:
        logger.error(f"Error in main execution: {e}")
    finally:
        cleanup()  # Clean up after finishing

if __name__ == "__main__":
    main()