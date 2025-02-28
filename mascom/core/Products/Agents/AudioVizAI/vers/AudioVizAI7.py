import numpy as np
import librosa
import os
from tqdm import tqdm
from datetime import datetime
import ffmpeg


# Vectorized procedural frame rendering
def render_frame(time, width, height, audio_features):
    # Map time to audio features
    amplitude, frequency = audio_features
    scale = 1.5 + amplitude * 0.5  # Dynamic scale factor
    rotation = time * 0.5  # Rotate based on time

    # Create normalized grid for pixel coordinates
    x = np.linspace(-0.5, 0.5, width) * scale
    y = np.linspace(-0.5, 0.5, height) * scale
    xx, yy = np.meshgrid(x, y)

    # Apply rotation to the grid
    nx_rot = xx * np.cos(rotation) - yy * np.sin(rotation)
    ny_rot = xx * np.sin(rotation) + yy * np.cos(rotation)

    # Procedural math for visuals (vectorized)
    r = np.sin(10 * nx_rot + time) * np.cos(10 * ny_rot - time)
    g = np.sin(8 * nx_rot - time) * np.sin(8 * ny_rot + time)
    b = np.cos(6 * nx_rot + time) * np.sin(6 * ny_rot - time)

    # Modulate colors with frequency
    r, g, b = r * frequency, g * frequency, b * frequency

    # Stack RGB channels
    image = np.stack([r, g, b], axis=-1)

    # Normalize and clip values to [0, 1]
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
