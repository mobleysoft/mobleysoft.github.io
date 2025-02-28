import numpy as np
import cv2
import os
import librosa
from datetime import datetime
import subprocess


# Procedural pattern generator
def generate_pattern(scaled_frame_number, width, height):
    # Create a blank image
    image = np.zeros((height, width), dtype=np.uint8)

    # Loop through pixels and apply bitwise and mathematical operations
    for y in range(height):
        for x in range(width):
            # Combine x, y, and scaled_frame_number using bitwise logic
            val = (x ^ y ^ scaled_frame_number) & (x | y)
            val = (val * (x & y)) % 256  # Add a bit of modular chaos
            image[y, x] = val

    return image


# Animation renderer
def generate_video(audio_file, output_file, width=320, height=240, upscale_factor=4, fps=30):
    # Check if FFmpeg is available
    try:
        subprocess.run(["ffmpeg", "-version"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError:
        raise EnvironmentError("FFmpeg is not installed or not in the system's PATH.")

    # Load the audio file to determine its duration
    print(f"Loading audio file: {audio_file}")
    y, sr = librosa.load(audio_file, sr=None)
    music_duration = librosa.get_duration(y=y, sr=sr)
    print(f"Music duration: {music_duration:.2f} seconds.")

    # Calculate the total number of frames to match the music duration
    frame_count = int(music_duration * fps)
    print(f"Total frames to generate: {frame_count}")

    # Prepare the frames directory
    frames_dir = "frames"
    if os.path.exists(frames_dir):
        for file in os.listdir(frames_dir):
            os.remove(os.path.join(frames_dir, file))
    else:
        os.makedirs(frames_dir)

    # Generate frames
    print(f"Generating {frame_count} frames...")
    for frame_number in range(frame_count):
        # Slow down the animation by scaling the frame number
        scaled_frame_number = frame_number // 3  # Adjust this factor for slower animation

        # Generate the current pattern
        pattern = generate_pattern(scaled_frame_number, width, height)

        # Upscale the pattern for display or saving
        upscaled = cv2.resize(pattern, (width * upscale_factor, height * upscale_factor), interpolation=cv2.INTER_NEAREST)

        # Add color mapping for a visually interesting effect
        colored = cv2.applyColorMap(upscaled, cv2.COLORMAP_TURBO)

        # Save frame to disk
        cv2.imwrite(f"{frames_dir}/frame_{frame_number:04d}.png", colored)

    print("Frames generated. Compiling into video...")

    # Use ffmpeg to combine frames and audio into a music video
    subprocess.run(
        [
            "ffmpeg",
            "-r", str(fps),
            "-i", f"{frames_dir}/frame_%04d.png",
            "-i", audio_file,
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac",
            "-b:a", "192k",
            "-shortest",  # Ensure the video length matches the audio
            output_file,
            "-y"  # Overwrite the output file if it exists
        ],
        check=True
    )

    # Cleanup frames
    print("Cleaning up frame files...")
    for frame_file in os.listdir(frames_dir):
        os.remove(os.path.join(frames_dir, frame_file))
    os.rmdir(frames_dir)

    print(f"Music video saved as {output_file}")


if __name__ == "__main__":
    # Set parameters
    audio_file = "input.mp3"  # Input audio file
    width, height = 320, 240  # Resolution
    upscale_factor = 4  # Scale up for higher resolution output
    fps = 30  # Frames per second
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"output_{timestamp}.mp4"  # Output video file

    # Generate video
    generate_video(audio_file, output_file, width, height, upscale_factor, fps)
