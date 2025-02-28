import numpy as np
import cv2
import librosa
import colorsys
from tqdm import tqdm
import os
import pygame
import msvcrt
import time
from pathlib import Path

class AudioPlayer:
    def __init__(self):
        pygame.mixer.init()
        self.currently_playing = None

    def play(self, file_path):
        if self.currently_playing:
            pygame.mixer.music.stop()
        pygame.mixer.music.load(file_path)
        pygame.mixer.music.play()
        self.currently_playing = file_path

    def stop(self):
        if self.currently_playing:
            pygame.mixer.music.stop()
            self.currently_playing = None

class MandelbrotWormhole:
    def __init__(self, width=1920, height=1080, max_iter=100):
        self.width = width
        self.height = height
        self.max_iter = max_iter
        self.center_x = -0.5
        self.center_y = 0
        self.zoom_start = 2.0
        self.zoom_factor = 0.97

    def mandelbrot(self, h, w, zoom, rotation):
        y, x = np.ogrid[
            self.center_y - zoom:self.center_y + zoom:h*1j,
            self.center_x - zoom:self.center_x + zoom:w*1j
        ]
        
        rot_x = (x - self.center_x) * np.cos(rotation) - (y - self.center_y) * np.sin(rotation) + self.center_x
        rot_y = (x - self.center_x) * np.sin(rotation) + (y - self.center_y) * np.cos(rotation) + self.center_y
        
        c = rot_x + rot_y*1j
        z = c
        divtime = self.max_iter + np.zeros(z.shape, dtype=int)

        for i in range(self.max_iter):
            z = z**2 + c
            diverge = z*np.conj(z) > 2**2
            div_now = diverge & (divtime == self.max_iter)
            divtime[div_now] = i
            z[diverge] = 2

        return divtime

    def create_frame(self, zoom, rotation, audio_intensity):
        mandel = self.mandelbrot(self.height, self.width, zoom, rotation)
        normalized = mandel / self.max_iter
        
        hue_offset = (audio_intensity * 0.5) % 1.0
        saturation = min(1.0, 0.5 + audio_intensity * 0.5)
        value = min(1.0, 0.7 + audio_intensity * 0.3)
        
        frame = np.zeros((self.height, self.width, 3))
        
        for i in range(self.height):
            for j in range(self.width):
                if normalized[i, j] < 1:
                    hue = (normalized[i, j] + hue_offset) % 1.0
                    rgb = colorsys.hsv_to_rgb(hue, saturation, value)
                    frame[i, j] = [x * 255 for x in rgb]
                
        return frame.astype(np.uint8)

def process_audio(audio_file, fps=30):
    y, sr = librosa.load(audio_file)
    tempo, beats = librosa.beat.beat_track(y=y, sr=sr)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    
    times = librosa.times_like(onset_env)
    onset_samples = np.interp(
        np.linspace(0, times[-1], int(times[-1] * fps)),
        times,
        onset_env
    )
    
    onset_samples = (onset_samples - onset_samples.min()) / (onset_samples.max() - onset_samples.min())
    return onset_samples

def create_video(audio_file, output_file, duration=None):
    fps = 30
    wormhole = MandelbrotWormhole()
    
    audio_intensities = process_audio(audio_file, fps)
    
    if duration is None:
        n_frames = len(audio_intensities)
    else:
        n_frames = int(duration * fps)
        audio_intensities = audio_intensities[:n_frames]
    
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_file, fourcc, fps, (wormhole.width, wormhole.height))
    
    zoom = wormhole.zoom_start
    rotation = 0
    
    for i in tqdm(range(n_frames), desc="Generating frames"):
        intensity = audio_intensities[i]
        zoom *= wormhole.zoom_factor
        rotation += intensity * 0.1
        
        frame = wormhole.create_frame(zoom, rotation, intensity)
        out.write(frame)
    
    out.release()

def select_audio_file():
    # Default directory
    music_dir = Path(r"C:\Users\Owner\Downloads\Music")
    
    # Get all MP3 files
    mp3_files = list(music_dir.glob("*.mp3"))
    if not mp3_files:
        print("No MP3 files found in the directory!")
        return None

    # Initialize audio player
    player = AudioPlayer()
    
    current_selection = 0
    
    def print_menu():
        os.system('cls' if os.name == 'nt' else 'clear')
        print("\nSelect an MP3 file (Use Up/Down arrows, Enter to select, Space to preview, Esc to exit):\n")
        for i, file in enumerate(mp3_files):
            if i == current_selection:
                print(f"➤ {file.name}")
            else:
                print(f"  {file.name}")

    print_menu()
    
    while True:
        if msvcrt.kbhit():
            key = msvcrt.getch()
            
            # Arrow keys generate two bytes
            if key == b'\xe0':
                key = msvcrt.getch()
                if key == b'H':  # Up arrow
                    current_selection = (current_selection - 1) % len(mp3_files)
                    player.stop()
                elif key == b'P':  # Down arrow
                    current_selection = (current_selection + 1) % len(mp3_files)
                    player.stop()
                print_menu()
            
            elif key == b'\r':  # Enter
                player.stop()
                return str(mp3_files[current_selection])
            
            elif key == b' ':  # Space
                # Toggle preview
                if player.currently_playing == str(mp3_files[current_selection]):
                    player.stop()
                else:
                    player.play(str(mp3_files[current_selection]))
            
            elif key == b'\x1b':  # Esc
                player.stop()
                return None

if __name__ == "__main__":
    print("Welcome to Mandelbrot Wormhole Visualizer!")
    
    # Select audio file
    selected_file = select_audio_file()
    
    if selected_file:
        print(f"\nSelected: {selected_file}")
        output_file = Path(selected_file).with_suffix('.mp4')
        print(f"Output will be saved as: {output_file}")
        
        proceed = input("\nPress Enter to start rendering, or 'n' to cancel: ")
        if proceed.lower() != 'n':
            create_video(selected_file, str(output_file))
            print(f"\nVideo has been saved to: {output_file}")
    else:
        print("\nNo file selected. Exiting.")