import os
import sys
import json
import librosa

def extract_metadata(input_folder, output_file):
    metadata = []
    for filename in os.listdir(input_folder):
        if filename.endswith(".mp3") or filename.endswith(".wav"):
            file_path = os.path.join(input_folder, filename)
            try:
                # Load the audio file
                y, sr = librosa.load(file_path, sr=None)
                
                # Extract metadata
                duration = librosa.get_duration(y=y, sr=sr)
                tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
                key = librosa.feature.chroma_cqt(y=y, sr=sr).mean(axis=1).argmax()

                # Map numeric key to musical notes
                keys = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
                key_name = keys[key % 12]

                metadata.append({
                    "FileName": filename,
                    "FullPath": file_path,
                    "Duration": round(duration, 2),
                    "BPM": round(tempo),
                    "Key": key_name
                })
            except Exception as e:
                print(f"Error processing {file_path}: {e}")

    # Save metadata to JSON
    with open(output_file, "w") as f:
        json.dump(metadata, f, indent=4)
    print(f"Metadata extracted and saved to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python extract_metadata.py <input_folder> <output_file>")
        sys.exit(1)

    input_folder = sys.argv[1]
    output_file = sys.argv[2]
    extract_metadata(input_folder, output_file)
