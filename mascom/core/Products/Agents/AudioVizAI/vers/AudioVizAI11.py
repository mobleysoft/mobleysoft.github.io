import numpy as np
import cv2
import os
import librosa
from datetime import datetime
import subprocess

# Procedural pattern generator with enhanced visuals
def generate_pattern(scaled_frame_number, width, height):
    image = np.zeros((height, width, 3), dtype=np.uint8)

    for y in range(height):
        for x in range(width):
            r = (x ^ y ^ scaled_frame_number) % 256
            g = ((x & y) ^ scaled_frame_number) % 256
            b = (r * g) % 256
            image[y, x] = (b, g, r)

    return image

# Animation renderer
def generate_video(audio_file, output_file, width=320, height=240, upscale_factor=4, fps=30):
    try:
        subprocess.run(["ffmpeg", "-version"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError:
        raise EnvironmentError("FFmpeg is not installed or not in the system's PATH.")

    print(f"Loading audio file: {audio_file}")
    y, sr = librosa.load(audio_file, sr=None)
    music_duration = librosa.get_duration(y=y, sr=sr)
    print(f"Music duration: {music_duration:.2f} seconds.")

    frame_count = 60  # Fixed number of unique frames
    print(f"Generating {frame_count} unique frames...")

    frames_dir = "frames"
    if os.path.exists(frames_dir):
        for file in os.listdir(frames_dir):
            os.remove(os.path.join(frames_dir, file))
    else:
        os.makedirs(frames_dir)

    for frame_number in range(frame_count):
        scaled_frame_number = frame_number * 10
        pattern = generate_pattern(scaled_frame_number, width, height)

        upscaled = cv2.resize(pattern, (width * upscale_factor, height * upscale_factor), interpolation=cv2.INTER_CUBIC)
        colored = cv2.applyColorMap(upscaled, cv2.COLORMAP_PLASMA)

        cv2.imwrite(f"{frames_dir}/frame_{frame_number:04d}.png", colored)

    print("Frames generated. Compiling into video...")

    frame_pattern = f"{frames_dir}/frame_%04d.png"

    subprocess.run(
        [
            "ffmpeg",
            "-stream_loop", "-1",  # Loop frames to match audio duration
            "-i", frame_pattern,
            "-i", audio_file,
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac",
            "-b:a", "192k",
            "-shortest",
            output_file,
            "-y"
        ],
        check=True
    )

    for frame_file in os.listdir(frames_dir):
        os.remove(os.path.join(frames_dir, frame_file))
    os.rmdir(frames_dir)

    print(f"Music video saved as {output_file}")

if __name__ == "__main__":
    input_dir = "inputs"
    output_dir = "outputs"
    used_dir = "used"

    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(used_dir, exist_ok=True)

    for audio_file in os.listdir(input_dir):
        if audio_file.endswith(".mp3"):
            input_path = os.path.join(input_dir, audio_file)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_path = os.path.join(output_dir, f"output_{timestamp}.mp4")

            try:
                generate_video(input_path, output_path)

                used_path = os.path.join(used_dir, audio_file)
                os.rename(input_path, used_path)
                print(f"Processed and moved {audio_file} to {used_dir}")
            except Exception as e:
                print(f"Error processing {audio_file}: {e}")
