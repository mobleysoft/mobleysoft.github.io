import librosa
import librosa.display
import numpy as np
import matplotlib.pyplot as plt
from moviepy.editor import VideoClip, AudioFileClip
import os

# Define the main function
def create_music_video(mp3_file, output_file):
    # Step 1: Load and Analyze Audio
    y, sr = librosa.load(mp3_file)
    tempo, beats = librosa.beat.beat_track(y=y, sr=sr)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    times = librosa.times_like(onset_env, sr=sr)
    chroma = librosa.feature.chroma_stft(y=y, sr=sr)
    
    # Step 2: Generate Visuals Synced to Audio
    def make_frame(t):
        frame_idx = int(t * sr / 512)
        # Beat Pulses
        pulse = onset_env[min(frame_idx, len(onset_env) - 1)] * 255
        
        # Create Image (Simple Animation)
        fig, ax = plt.subplots(figsize=(8, 8))
        ax.axis('off')
        ax.set_facecolor((0, 0, 0))
        
        # Draw Shapes Based on Chroma
        chroma_idx = int(t * sr / 512)
        chroma_vals = chroma[:, min(chroma_idx, chroma.shape[1] - 1)]
        
        for i, val in enumerate(chroma_vals):
            color = plt.cm.hsv(i / 12.0)
            circle = plt.Circle((0.5, 0.5), radius=val / 10, color=color, alpha=0.7)
            ax.add_artist(circle)
        
        # Save frame to image
        fig.canvas.draw()
        image = np.frombuffer(fig.canvas.tostring_rgb(), dtype='uint8')
        image = image.reshape(fig.canvas.get_width_height()[::-1] + (3,))
        plt.close(fig)
        return image / 255  # Normalize to [0, 1] for MoviePy
    
    # Step 3: Create and Render Video
    audio_clip = AudioFileClip(mp3_file)
    duration = audio_clip.duration
    video_clip = VideoClip(make_frame, duration=duration)
    video_clip = video_clip.set_audio(audio_clip)
    video_clip.write_videofile(output_file, fps=24, codec="libx264", audio_codec="aac")

# Run the script
if __name__ == "__main__":
    # Input MP3 and Output Video Paths
    mp3_file = os.path.join(os.path.dirname(__file__), "input.mp3")  # Path to input.mp3
    output_file = os.path.join(os.path.dirname(__file__), "output.mp4")  # Output video path
    
    # Ensure output directory exists, if specified
    output_dir = os.path.dirname(output_file)
    if output_dir and not os.path.exists(output_dir):  # Check if directory exists
        os.makedirs(output_dir, exist_ok=True)
    
    create_music_video(mp3_file, output_file)
