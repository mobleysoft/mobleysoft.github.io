import numpy as np
import cv2
import librosa
import os
from moviepy.editor import VideoClip, AudioFileClip


# Recursive fractal generation
def generate_fractal(iterations, width, height, scale, params):
    image = np.zeros((height, width, 3), dtype=np.float32)
    x, y = 0.0, 0.0  # Start with a random point

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

    # Normalize the image
    image = np.clip(image / np.max(image), 0, 1)
    return image


# Audio-reactive parameters
def get_audio_reactive_params(audio_features):
    scale = 2.0 / (1.0 + audio_features['amplitude'])
    color = audio_features['frequency'] * 10
    return [
        (0.85, 0.04, -0.04, 0.85, 0.0, 1.6, (color, 0.3, 0.1)),
        (0.2, -0.26, 0.23, 0.22, 0.0, 1.0, (0.2, color, 0.2)),
        (-0.15, 0.28, 0.26, 0.24, 0.0, 0.44, (0.1, 0.2, color)),
    ]


# Generate frames
def render_frames(mp3_file, output_dir, width=800, height=800, iterations=100000):
    os.makedirs(output_dir, exist_ok=True)
    y, sr = librosa.load(mp3_file)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)

    for i, t in enumerate(np.linspace(0, len(onset_env) / sr, int(tempo))):
        amplitude = onset_env[min(int(t * sr), len(onset_env) - 1)]
        frequency = librosa.feature.spectral_centroid(y=y, sr=sr)[0][min(int(t * sr), len(onset_env) - 1)]
        params = get_audio_reactive_params({'amplitude': amplitude, 'frequency': frequency})
        fractal = generate_fractal(iterations, width, height, scale=2.0, params=params)
        fractal = (fractal * 255).astype(np.uint8)
        cv2.imwrite(f"{output_dir}/frame_{i:04d}.png", cv2.cvtColor(fractal, cv2.COLOR_RGB2BGR))


# Combine frames into video
def create_video(output_dir, mp3_file, output_file):
    os.system(f"ffmpeg -r 24 -i {output_dir}/frame_%04d.png -i {mp3_file} -c:v libx264 -pix_fmt yuv420p -c:a aac {output_file}")


# Self-testing functionality
def run_tests():
    try:
        print("Running tests...")

        # Test 1: Fractal Generation
        fractal = generate_fractal(iterations=1000, width=100, height=100, scale=2.0,
                                   params=[(0.5, 0, 0, 0.5, 0, 0, (1, 1, 1))])
        assert fractal.shape == (100, 100, 3), "Fractal dimensions are incorrect"
        assert np.max(fractal) > 0, "Fractal contains no data"
        assert np.min(fractal) >= 0, "Fractal has invalid negative values"

        # Test 2: Audio Feature Extraction
        y, sr = librosa.load("input.mp3")
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        assert len(onset_env) > 0, "Onset envelope should not be empty"
        assert np.max(onset_env) > 0, "Onset envelope should contain valid amplitudes"

        # Test 3: Frame Rendering
        render_frames("input.mp3", "test_frames", width=100, height=100, iterations=1000)
        frame_files = os.listdir("test_frames")
        assert len(frame_files) > 0, "No frames were generated"
        assert frame_files[0].endswith(".png"), "Generated frames are not PNGs"

        # Test 4: Video Creation
        create_video("test_frames", "input.mp3", "test_output.mp4")
        assert os.path.exists("test_output.mp4"), "Video file was not created"
        assert os.path.getsize("test_output.mp4") > 0, "Video file is empty"

        print("All tests passed!")
        return True
    except Exception as e:
        print(f"Test failed: {e}")
        return False


# Main execution
if __name__ == "__main__":
    print("Press 'Enter' to run the system, or 'T'/'R' to run tests.")
    choice = input().strip().lower()

    if choice in ['t', 'r']:
        if run_tests():
            print("Tests passed. Running the system...")
            render_frames("input.mp3", "frames")
            create_video("frames", "input.mp3", "output.mp4")
        else:
            print("Tests failed. Fix issues and try again.")
    else:
        print("Running the system...")
        render_frames("input.mp3", "frames")
        create_video("frames", "input.mp3", "output.mp4")
