import numpy as np
import librosa
import os
from tqdm import tqdm
from datetime import datetime
import ffmpeg


# Efficient mathematical function for generative visuals
def render_frame(time, width, height, audio_features):
    # Create a blank canvas
    image = np.zeros((height, width, 3), dtype=np.float32)

    # Map time to audio features
    amplitude, frequency = audio_features
    scale = 1.5 + amplitude * 0.5  # Dynamic scale factor
    rotation = time * 0.5  # Rotate based on time

    # Render procedural visuals (inspired by demoscene)
    for y in range(height):
        for x in range(width):
            # Map pixel coordinates to normalized space [-1, 1]
            nx = (x / width - 0.5) * scale
            ny = (y / height - 0.5) * scale

            # Apply rotation
            nx_rot = nx * np.cos(rotation) - ny * np.sin(rotation)
            ny_rot = nx * np.sin(rotation) + ny * np.cos(rotation)

            # Procedural math for visuals
            r = np.sin(10 * nx_rot + time) * np.cos(10 * ny_rot - time)
            g = np.sin(8 * nx_rot - time) * np.sin(8 * ny_rot + time)
            b = np.cos(6 * nx_rot + time) * np.sin(6 * ny_rot - time)

            # Modulate with audio frequency
            r, g, b = r * frequency, g * frequency, b * frequency

            # Set pixel color
            image[y, x] = [r, g, b]

    # Normalize the image
    image = np.clip(image, 0, 1)
    return (image * 255).astype(np.uint8)


# Render all frames
def render_frames(mp3_file, width=1920, height=1080, fps=12):
    # Load audio and extract features
    y, sr = librosa.load(mp3_file)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    spectral_centroid = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
    duration = len(y) / sr

    # Generate frames
    print("Rendering frames...")
    times = np.linspace(0, duration, int(duration * fps))
    frames = []

    for time in tqdm(times):
        # Map time to audio features
        amplitude = onset_env[min(int(time * sr), len(onset_env) - 1)] / np.max(onset_env)
        frequency = spectral_centroid[min(int(time * sr), len(spectral_centroid) - 1)] / np.max(spectral_centroid)

        # Render frame
        frame = render_frame(time, width, height, (amplitude, frequency))
        frames.append(frame)

    return frames


# Stream frames directly to FFmpeg
def create_video(frames, mp3_file, output_file, fps=12):
    print("Encoding video...")
    process = (
        ffmpeg
        .input('pipe:', format='rawvideo', pix_fmt='rgb24', s=f"{frames[0].shape[1]}x{frames[0].shape[0]}", framerate=fps)
        .input(mp3_file)
        .output(output_file, vcodec='libx264', pix_fmt='yuv420p', crf=15, preset='slow', acodec='aac')
        .overwrite_output()
        .run_async(pipe_stdin=True)
    )

    for frame in frames:
        process.stdin.write(frame.tobytes())

    process.stdin.close()
    process.wait()


# Main function
if __name__ == "__main__":
    print("Press 'Enter' to create a demoscene-inspired generative masterpiece.")
    input()

    # File paths
    mp3_file = "input.mp3"
    output_file = f"output_{datetime.now().strftime('%Y%m%d_%H%M%S')}.mp4"

    try:
        # Render frames
        frames = render_frames(mp3_file)

        # Create video
        create_video(frames, mp3_file, output_file)

        print(f"Generative masterpiece created: {output_file}")
    except Exception as e:
        print(f"An error occurred: {e}")
