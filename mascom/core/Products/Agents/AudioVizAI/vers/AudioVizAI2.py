import numpy as np
import cv2
import librosa
import os
from moviepy.editor import VideoClip, AudioFileClip

# Recursive fractal generation
def generate_fractal(iterations, width, height, scale, params):
    # Initialize an empty image
    image = np.zeros((height, width, 3), dtype=np.float32)
    
    # Start with a random point
    x, y = 0.0, 0.0
    
    for _ in range(iterations):
        # Randomly select a transformation
        a, b, c, d, e, f, color = params[np.random.randint(len(params))]
        
        # Apply affine transformation
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
    # Example: Beat drives scale, pitch drives color intensity
    scale = 2.0 / (1.0 + audio_features['amplitude'])  # Dynamic scale
    color = audio_features['frequency'] * 10  # Adjust colors based on frequency
    return [
        (0.85, 0.04, -0.04, 0.85, 0.0, 1.6, (color, 0.3, 0.1)),
        (0.2, -0.26, 0.23, 0.22, 0.0, 1.0, (0.2, color, 0.2)),
        (-0.15, 0.28, 0.26, 0.24, 0.0, 0.44, (0.1, 0.2, color)),
    ]

# Generate frames
def render_frames(mp3_file, output_dir, width=800, height=800, iterations=100000):
    os.makedirs(output_dir, exist_ok=True)
    
    # Load audio
    y, sr = librosa.load(mp3_file)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    tempo, beats = librosa.beat.beat_track(y=y, sr=sr)
    
    # Frame rendering loop
    for i, t in enumerate(np.linspace(0, len(onset_env) / sr, int(tempo))):
        # Get audio features
        amplitude = onset_env[min(int(t * sr), len(onset_env) - 1)]
        frequency = librosa.feature.spectral_centroid(y=y, sr=sr)[0][min(int(t * sr), len(onset_env) - 1)]
        
        # Generate audio-reactive fractal parameters
        params = get_audio_reactive_params({'amplitude': amplitude, 'frequency': frequency})
        
        # Render fractal image
        fractal = generate_fractal(iterations, width, height, scale=2.0, params=params)
        fractal = (fractal * 255).astype(np.uint8)
        
        # Save frame
        cv2.imwrite(f"{output_dir}/frame_{i:04d}.png", cv2.cvtColor(fractal, cv2.COLOR_RGB2BGR))

# Combine frames and audio into video
def create_video(output_dir, mp3_file, output_file):
    # Use FFmpeg to combine frames into a video
    os.system(f"ffmpeg -r 24 -i {output_dir}/frame_%04d.png -i {mp3_file} -c:v libx264 -pix_fmt yuv420p -c:a aac {output_file}")

# Main execution
if __name__ == "__main__":
    # File paths
    mp3_file = "input.mp3"  # Path to your audio file
    output_dir = "frames"   # Temporary directory for frames
    output_file = "output.mp4"  # Final video file
    
    # Render frames
    render_frames(mp3_file, output_dir)
    
    # Create video
    create_video(output_dir, mp3_file, output_file)
