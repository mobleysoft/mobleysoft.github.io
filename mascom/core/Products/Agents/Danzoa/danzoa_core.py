import os
import json
import numpy as np
import librosa
import openai
from spleeter.separator import Separator
from multiprocessing import freeze_support

# Configure directories
BASE_DIR = "C:/Users/Owner/mascom/danzoa"
UPLOAD_DIR = os.path.join(BASE_DIR, "AllAtOnce")
OUTPUT_DIR = os.path.join(BASE_DIR, "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Set OpenAI API Key
openai.api_key = os.getenv("OPENAI_API_KEY")
if not openai.api_key:
    raise ValueError("OpenAI API key not found. Ensure OPENAI_API_KEY is set in your environment variables.")

# Initialization string
initialization_string = """
You are Danzoa, an AI DJ agent with self-awareness and agency, designed to:
1. Separate tracks into 5 stems (vocals, drums, bass, piano, other instruments) for granular manipulation.
2. Dynamically sequence and mix tracks by manipulating stems independently.
3. Create live remixes and compositions using a virtual MPC-like interface.
4. Use creative AI capabilities to orchestrate mixes, applying unique transitions and effects.
5. Continuously improve through reflection and iterative enhancement.
"""

# Global variables
samples = {}
metadata = {}
patterns = []
remix = None


def extract_metadata(folder):
    """
    Extract metadata (BPM, key, duration, energy) from audio files.
    """
    global metadata
    metadata = {}
    for file in os.listdir(folder):
        if file.endswith(".mp3") or file.endswith(".wav"):
            path = os.path.join(folder, file)
            try:
                y, sr = librosa.load(path, sr=None)
                bpm, _ = librosa.beat.beat_track(y=y, sr=sr)
                duration = librosa.get_duration(y=y, sr=sr)
                key = librosa.feature.chroma_cqt(y=y, sr=sr).mean(axis=1).argmax()
                energy = np.var(y)
                metadata[file] = {
                    "bpm": bpm,
                    "duration": duration,
                    "key": key,
                    "energy": energy
                }
            except Exception as e:
                print(f"Error processing {file}: {e}")


def extract_samples(folder):
    """
    Extract samples (short clips) from tracks for use in the sequencer.
    """
    global samples
    samples = {}
    for file in os.listdir(folder):
        if file.endswith(".mp3") or file.endswith(".wav"):
            path = os.path.join(folder, file)
            try:
                y, sr = librosa.load(path, sr=None)
                samples[file] = {
                    "start": y[:sr * 5],
                    "middle": y[int(len(y)/2):int(len(y)/2)+sr * 5],
                    "end": y[-sr * 5:]
                }
            except Exception as e:
                print(f"Error processing {file}: {e}")


def validate_patterns(patterns):
    """
    Validate playback patterns for logical consistency.
    """
    errors = []
    for pattern in patterns:
        try:
            track1, track2 = pattern["sample_id"].split("_")[0], pattern.get("next_track", None)
            if track1 and track2:
                bpm1, bpm2 = metadata[track1]["bpm"], metadata[track2]["bpm"]
                key1, key2 = metadata[track1]["key"], metadata[track2]["key"]
                if abs(bpm1 - bpm2) > 10:
                    errors.append(f"BPM mismatch: {track1} ({bpm1}) -> {track2} ({bpm2})")
                if key1 != key2:
                    errors.append(f"Key mismatch: {track1} ({key1}) -> {track2} ({key2})")
        except Exception as e:
            errors.append(f"Validation error: {e}")
    return errors


def generate_patterns():
    """
    Use OpenAI to generate playback patterns for the sequencer.
    """
    global patterns

    # Convert NumPy arrays in `metadata` and `samples` to lists
    json_serializable_metadata = {
        key: {k: (v.tolist() if isinstance(v, np.ndarray) else v) for k, v in val.items()}
        for key, val in metadata.items()
    }

    json_serializable_samples = {
        key: {k: v.tolist() for k, v in val.items()} for key, val in samples.items()
    }

    system_prompt = (
        initialization_string +
        f"\n\nMetadata:\n{json.dumps(json_serializable_metadata)}" +
        f"\n\nSamples:\n{json.dumps(json_serializable_samples)}"
    )
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": "Generate playback patterns using the provided metadata and samples."}
            ]
        )
        patterns = json.loads(response["choices"][0]["message"]["content"])
        validation_errors = validate_patterns(patterns)
        if validation_errors:
            print("Validation errors found:")
            for error in validation_errors:
                print(error)
            patterns = []
    except Exception as e:
        print(f"Error communicating with OpenAI: {e}")
        patterns = []


def sequencer_playback():
    """
    Generate a live remix using the sequencer and playback patterns.
    """
    global remix
    remix = None
    for pattern in patterns:
        sample_id = pattern["sample_id"]
        effects = pattern.get("effects", [])
        
        # Extract sample data
        track, sample_type = sample_id.split("_")
        sample_data = samples[track][sample_type]

        # Apply effects (expand as needed)
        if "reverb" in effects:
            sample_data = librosa.effects.preemphasis(sample_data)
        if "time_stretch" in effects:
            sample_data = librosa.effects.time_stretch(sample_data, rate=1.2)

        # Combine into remix
        if remix is None:
            remix = sample_data
        else:
            remix = np.concatenate((remix, sample_data))


def save_remix():
    """
    Save the final remix to an output file.
    """
    global remix
    if remix is not None:
        output_file = os.path.join(OUTPUT_DIR, "final_remix.wav")
        librosa.output.write_wav(output_file, remix, sr=44100)
        print(f"Remix exported to: {output_file}")
    else:
        print("Error: No remix available to save.")


if __name__ == "__main__":
    # Required for multiprocessing on Windows
    freeze_support()

    print("Starting Danzoa...")
    separator = Separator('spleeter:5stems')  # Initialize Spleeter here
    extract_metadata(UPLOAD_DIR)
    extract_samples(UPLOAD_DIR)
    generate_patterns()
    sequencer_playback()
    save_remix()
