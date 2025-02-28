import numpy as np
import cv2
import librosa
import os
from tqdm import tqdm
from moviepy.editor import VideoClip, AudioFileClip


# Advanced fractal generation with dynamic layers
def generate_fractal(iterations, width, height, scale, params, time, depth=5, brightness=1.5):
    image = np.zeros((height, width, 3), dtype=np.float32)
    x, y = 0.0, 0.0

    for _ in range(iterations):
        # Randomly select a transformation
        a, b, c, d, e, f, color = params[np.random.randint(len(params))]
        x_new = np.sin(a * x + b * y + e + np.cos(time))
        y_new = np.cos(c * x + d * y + f + np.sin(time))
        x, y = x_new, y_new

        # Map coordinates to pixel space
        px = int((x + scale) / (2 * scale) * width)
        py = int((y + scale) / (2 * scale) * height)

        # Add layered depth and color
        if 0 <= px < width and 0 <= py < height:
            layer = (np.sin(depth * x) + 1) * 0.5  # Add depth effect
            image[py, px] += np.array(color) * layer

    # Normalize and enhance brightness
    image = np.clip(image / np.max(image) * brightness, 0, 1)
    return image


# Dynamic fractal parameters that evolve over time
def get_dynamic_params(amplitude, frequency, time, layers=3):
    scale = 1.5 / (1.0 + amplitude)  # Adjust fractal density based on amplitude
    colors = [
        (np.sin(time * 0.1), 0.3, 0.7),
        (0.2, np.cos(time * 0.2), 0.5),
        (0.6, 0.2, np.sin(time * 0.3)),
    ]
    params = []
    for i in range(layers):
        color = colors[i % len(colors)]
        params.append((
            0.5 + 0.2 * np.sin(time * 0.5),
            0.1 + 0.3 * np.cos(time * 0.3),
            -0.4 + 0.2 * np.sin(time * 0.4),
            0.7 + 0.1 * np.cos(time * 0.2),
            0.0,
            1.2 * np.sin(time * 0.1),
            color,
        ))
    return params


# Render frames with dynamic evolution and depth
def render_frames(mp3_file, output_dir, width=1920, height=1080, iterations=300000):
    os.makedirs(output_dir, exist_ok=True)
    y, sr = librosa.load(mp3_file)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
    spectral_centroid = librosa.feature.spectral_centroid(y=y, sr=sr)[0]

    for i, t in tqdm(enumerate(np.linspace(0, len(onset_env) / sr, int(tempo))), total=int(tempo), desc="Rendering Frames"):
        amplitude = onset_env[min(int(t * sr), len(onset_env) - 1)]
        frequency = spectral_centroid[min(int(t * sr), len(spectral_centroid) - 1)]

        # Get evolving fractal parameters
        params = get_dynamic_params(amplitude, frequency, t)

        # Generate fractal with depth
        fractal = generate_fractal(iterations, width, height, scale=1.5, params=params, time=t, depth=8, brightness=2.0)
        fractal = (fractal * 255).astype(np.uint8)

        # Save frame
        cv2.imwrite(f"{output_dir}/frame_{i:04d}.png", cv2.cvtColor(fractal, cv2.COLOR_RGB2BGR))


# Create high-quality video from frames
def create_video(output_dir, mp3_file, output_file):
    os.system(f"ffmpeg -r 30 -i {output_dir}/frame_%04d.png -i {mp3_file} -c:v libx264 -crf 15 -preset slow -pix_fmt yuv420p -c:a aac {output_file}")


# Main function to produce art
if __name__ == "__main__":
    print("Press 'Enter' to create a generative masterpiece.")
    input()

    # File paths
    mp3_file = "input.mp3"
    output_dir = "frames"
    output_file = "output.mp4"

    # Generate frames and create video
    render_frames(mp3_file, output_dir)
    create_video(output_dir, mp3_file, output_file)

    print(f"Generative masterpiece created: {output_file}")
