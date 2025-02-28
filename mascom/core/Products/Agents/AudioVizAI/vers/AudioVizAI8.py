import numpy as np
import cv2
import os
import time
from datetime import datetime
import subprocess


# Procedural pattern generator
def generate_pattern(frame_number, width, height):
    # Create a blank image
    image = np.zeros((height, width), dtype=np.uint8)

    # Loop through pixels and apply bitwise and mathematical operations
    for y in range(height):
        for x in range(width):
            # Combine x, y, and frame_number using bitwise logic
            val = (x ^ y ^ frame_number) & (x | y)
            val = (val * (x & y)) % 256  # Add a bit of modular chaos
            image[y, x] = val

    return image


# Animation renderer
def generate_video(output_file, width=320, height=240, upscale_factor=4, frame_count=300, fps=30):
    # Validate inputs
    if frame_count <= 0:
        raise ValueError("Frame count must be greater than zero.")
    if fps <= 0:
        raise ValueError("FPS must be greater than zero.")
    if upscale_factor > 8:
        raise ValueError("Upscale factor is too high and may cause memory issues. Reduce it to 8 or below.")

    # Check if FFmpeg is available
    try:
        subprocess.run(["ffmpeg", "-version"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError:
        raise EnvironmentError("FFmpeg is not installed or not in the system's PATH.")

    # Prepare the frames directory
    frames_dir = "frames"
    if os.path.exists(frames_dir):
        for file in os.listdir(frames_dir):
            try:
                os.remove(os.path.join(frames_dir, file))
            except Exception as e:
                print(f"Warning: Could not delete {file}: {e}")
    else:
        os.makedirs(frames_dir)

    print(f"Generating {frame_count} frames...")
    try:
        for frame_number in range(frame_count):
            # Generate the current pattern
            pattern = generate_pattern(frame_number, width, height)

            # Upscale the pattern for display or saving
            upscaled = cv2.resize(pattern, (width * upscale_factor, height * upscale_factor), interpolation=cv2.INTER_NEAREST)

            # Add color mapping for a visually interesting effect
            try:
                colored = cv2.applyColorMap(upscaled, cv2.COLORMAP_TURBO)
            except Exception as e:
                print(f"Error applying color map: {e}")
                colored = upscaled  # Fallback to grayscale

            # Save frame to disk
            cv2.imwrite(f"{frames_dir}/frame_{frame_number:04d}.png", colored)

        print("Frames generated. Compiling into video...")

        # Use ffmpeg to compile frames into a video
        subprocess.run(
            ["ffmpeg", "-r", str(fps), "-i", f"{frames_dir}/frame_%04d.png", "-c:v", "libx264", "-pix_fmt", "yuv420p", output_file, "-y"],
            check=True,
        )
    finally:
        # Cleanup frames
        print("Cleaning up frame files...")
        for frame_file in os.listdir(frames_dir):
            try:
                os.remove(os.path.join(frames_dir, frame_file))
            except Exception as e:
                print(f"Warning: Could not delete {frame_file}: {e}")
        try:
            os.rmdir(frames_dir)
        except Exception as e:
            print(f"Warning: Could not delete frames directory: {e}")

    print(f"Video saved as {output_file}")


if __name__ == "__main__":
    # Set parameters
    width, height = 320, 240  # Resolution
    upscale_factor = 4  # Scale up for higher resolution output
    frame_count = 300  # Total frames
    fps = 30  # Frames per second
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"output_{timestamp}.mp4"  # Output video file

    # Generate video
    start_time = time.time()
    generate_video(output_file, width, height, upscale_factor, frame_count, fps)
    elapsed_time = time.time() - start_time
    print(f"Video generation complete in {elapsed_time:.2f} seconds.")
