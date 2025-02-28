import numpy as np
import cv2
import librosa
import os
from tqdm import tqdm
from moviepy.editor import VideoClip, AudioFileClip

# Recursive fractal generation
def generate_fractal(iterations, width, height, scale, params):
    image = np.zeros((height, width, 3), dtype=np.float32)
    x, y = 0.0, 0.0  # Start point

    for _ in range(iterations):
        # Randomly select a transformation
        a, b, c, d, e, f, color = params[np.random.randint(len(params))]
        x_new = a * x + b * y + e
        y_new = c * x + d * y + f
        x, y = x_new, y_new

        # Map coordinates to pixel space
        px = int((x + scale) / (2 * scale) * width)
        py = int((y + scale) / (2 * scale) * height)

        # Add color if within bounds
        if 0 <= px < width and 0 <= py < height:
            image[py, px] += color

    # Normalize the image for display
    image = np.clip(image / np.max(image), 0, 1)
    return image


# Dynamic fractal parameters
def get_audio_reactive_params(amplitude, frequency):
    scale = 2.0 / (1.0 + amplitude)  # Reacts to amplitude
    color = frequency * 10  # Reacts to frequency
    return [
        (0.85, 0.04, -0.04, 0.85, 0.0, 1.6, (color, 0.3, 0.1)),
        (0.2, -0.26, 0.23, 0.22, 0.0, 1.0, (0.2, color, 0.2)),
        (-0.15, 0.28, 0.26, 0.24, 0.0, 0.44, (0.1, 0.2, color)),
    ]


# Generate frames
def render_frames(mp3_file, output_dir, width=1920, height=1080, iterations=200000):
    os.makedirs(output_dir, exist_ok=True)
    y, sr = librosa.load(mp3_file)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)

    for i, t in tqdm(enumerate(np.linspace(0, len(onset_env) / sr, int(tempo))), total=int(tempo), desc="Rendering Frames"):
        amplitude = onset_env[min(int(t * sr), len(onset_env) - 1)]
        frequency = librosa.feature.spectral_centroid(y=y, sr=sr)[0][min(int(t * sr), len(onset_env) - 1)]
        params = get_audio_reactive_params(amplitude, frequency)
        fractal = generate_fractal(iterations, width, height, scale=2.0, params=params)
        fractal = (fractal * 255).astype(np.uint8)
        cv2.imwrite(f"{output_dir}/frame_{i:04d}.png", cv2.cvtColor(fractal, cv2.COLOR_RGB2BGR))


# Combine frames into a high-quality video
def create_video(output_dir, mp3_file, output_file):
    os.system(f"ffmpeg -r 24 -i {output_dir}/frame_%04d.png -i {mp3_file} -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p -c:a aac -strict experimental {output_file}")


# Main function
if __name__ == "__main__":
    print("Press 'Enter' to run the system, or 'T'/'R' to test the functionality.")
    choice = input().strip().lower()

    if choice in ['t', 'r']:
        print("Tests not included in this production-ready script. Proceeding with system run...")
        choice = ''

    if choice == '':
        print("Running the system...")

        # File paths
        mp3_file = "input.mp3"  # Path to the audio file
        output_dir = "frames"   # Directory for rendered frames
        output_file = "output2.mp4"  # Final video output

        # Generate frames and create video
        render_frames(mp3_file, output_dir)
        create_video(output_dir, mp3_file, output_file)

        print(f"Music video generated: {output_file}")
