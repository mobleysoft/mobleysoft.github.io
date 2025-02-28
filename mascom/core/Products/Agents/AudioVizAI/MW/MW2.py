import numpy as np
import cv2
import librosa
import pygame
import os
from pathlib import Path
import threading
from numba import jit
import time
import colorsys

@jit(nopython=True)
def calculate_mandelbrot(width, height, max_iter, center_x, center_y, zoom, rotation):
    """Optimized Mandelbrot calculation"""
    result = np.zeros((height, width), dtype=np.uint8)
    
    for i in range(height):
        for j in range(width):
            x = (j - width/2) / (width/4) / zoom + center_x
            y = (i - height/2) / (height/4) / zoom + center_y
            
            c = complex(x, y)
            z = 0j
            
            for n in range(max_iter):
                if abs(z) > 2:
                    result[i, j] = n
                    break
                z = z*z + c
                
    return result

class VisualizerSettings:
    def __init__(self):
        # Core parameters
        self.zoom_speed = 0.97
        self.rotation_speed = 0.1
        self.color_speed = 0.01
        
        # Available color schemes
        self.color_schemes = ["Psychedelic", "Ocean", "Fire", "Matrix", "Rainbow"]
        self.current_scheme = 0
    
    def get_color_tables(self):
        """Generate color lookup tables based on current scheme"""
        tables = np.zeros((3, 256), dtype=np.uint8)
        
        if self.current_scheme == 0:  # Psychedelic
            for i in range(256):
                tables[0, i] = int(255 * (0.5 + 0.5 * np.sin(i * 0.1)))
                tables[1, i] = int(255 * (0.5 + 0.5 * np.sin(i * 0.1 + 2.094)))
                tables[2, i] = int(255 * (0.5 + 0.5 * np.sin(i * 0.1 + 4.189)))
        elif self.current_scheme == 1:  # Ocean
            for i in range(256):
                tables[0, i] = int(i * 0.2)
                tables[1, i] = int(i * 0.8)
                tables[2, i] = i
        elif self.current_scheme == 2:  # Fire
            for i in range(256):
                tables[0, i] = i
                tables[1, i] = int(i * 0.5)
                tables[2, i] = int(i * 0.2)
        elif self.current_scheme == 3:  # Matrix
            for i in range(256):
                tables[0, i] = int(i * 0.2)
                tables[1, i] = i
                tables[2, i] = int(i * 0.2)
        else:  # Rainbow
            for i in range(256):
                rgb = colorsys.hsv_to_rgb(i/255.0, 1.0, 1.0)
                tables[0, i] = int(rgb[0] * 255)
                tables[1, i] = int(rgb[1] * 255)
                tables[2, i] = int(rgb[2] * 255)
        
        return tables

class Visualizer:
    def __init__(self, preview_mode=False):
        # Resolution settings
        if preview_mode:
            self.width = 160
            self.height = 90
            self.max_iter = 10
        else:
            self.width = 640
            self.height = 360
            self.max_iter = 20
        
        # Core parameters
        self.settings = VisualizerSettings()
        self.center_x = -0.7453
        self.center_y = 0.1127
        self.zoom_start = 1.8
        
        # Initialize color tables
        self.color_tables = self.settings.get_color_tables()
    
    def create_frame(self, zoom, rotation, audio_intensity, frame_number):
        """Generate a single frame of the visualization"""
        # Calculate Mandelbrot set
        mandel = calculate_mandelbrot(
            self.width, self.height, self.max_iter,
            self.center_x, self.center_y, zoom, rotation
        )
        
        # Apply color mapping
        color_idx = (mandel + frame_number) % 256
        frame = np.zeros((self.height, self.width, 3), dtype=np.uint8)
        
        for i in range(3):  # RGB channels
            frame[:, :, i] = self.color_tables[i, color_idx] * audio_intensity
        
        return frame

def process_audio(audio_file, fps=30):
    """Process audio file to extract intensity data"""
    y, sr = librosa.load(audio_file, sr=22050)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=512)
    
    # Resample to match video fps
    times = librosa.times_like(onset_env)
    onset_samples = np.interp(
        np.linspace(0, times[-1], int(times[-1] * fps)),
        times,
        onset_env
    )
    
    # Normalize
    return onset_samples / onset_samples.max()

class GUI:
    def __init__(self):
        pygame.init()
        pygame.mixer.init()
        
        # Basic setup
        self.screen_width = 1000
        self.screen_height = 600
        self.screen = pygame.display.set_mode((self.screen_width, self.screen_height))
        pygame.display.set_caption("Music Visualizer")
        
        # Colors
        self.BLACK = (0, 0, 0)
        self.WHITE = (255, 255, 255)
        self.BLUE = (0, 120, 255)
        
        # Font
        self.font = pygame.font.SysFont(None, 24)
        
        # File handling
        self.music_dir = Path(r"C:\Users\Owner\Downloads\Music")
        self.mp3_files = list(self.music_dir.glob("*.mp3"))
        self.selected_index = 0
        self.scroll_position = 0
        self.visible_items = 15
        
        # Preview setup
        self.visualizer = Visualizer(preview_mode=True)
        self.preview_surface = pygame.Surface((self.visualizer.width, self.visualizer.height))
        self.preview_rect = pygame.Rect(800, 60, 160, 90)
        
        # State
        self.is_playing = False
        self.is_generating = False
        self.is_previewing = False
        self.preview_data = None
        self.preview_frame = 0
        self.preview_zoom = 1.8
        self.preview_rotation = 0
        
        # Buttons
        self.setup_buttons()
    
    def setup_buttons(self):
        """Initialize button positions and labels"""
        self.buttons = {
            'preview': (pygame.Rect(50, 520, 100, 30), "Preview"),
            'stop': (pygame.Rect(160, 520, 100, 30), "Stop"),
            'generate': (pygame.Rect(270, 520, 100, 30), "Generate"),
            'color': (pygame.Rect(800, 200, 160, 30), "Change Color")
        }
    
    def draw(self):
        """Draw the interface"""
        self.screen.fill(self.BLACK)
        
        # Draw file list
        for i in range(self.visible_items):
            idx = self.scroll_position + i
            if idx < len(self.mp3_files):
                y_pos = 60 + i * 28
                color = self.BLUE if idx == self.selected_index else self.WHITE
                text = self.font.render(self.mp3_files[idx].name, True, color)
                self.screen.blit(text, (50, y_pos))
        
        # Draw preview if active
        if self.is_previewing:
            self.update_preview()
            scaled_preview = pygame.transform.scale(self.preview_surface, 
                                                 (self.preview_rect.width, 
                                                  self.preview_rect.height))
            self.screen.blit(scaled_preview, self.preview_rect)
        
        # Draw buttons
        for (rect, label) in self.buttons.values():
            pygame.draw.rect(self.screen, self.BLUE, rect)
            text = self.font.render(label, True, self.BLACK)
            text_rect = text.get_rect(center=rect.center)
            self.screen.blit(text, text_rect)
        
        pygame.display.flip()
    
    def update_preview(self):
        """Update the preview animation"""
        if self.preview_data is not None:
            self.preview_frame = (self.preview_frame + 1) % len(self.preview_data)
            intensity = self.preview_data[self.preview_frame]
            
            self.preview_zoom *= self.visualizer.settings.zoom_speed
            self.preview_rotation += intensity * self.visualizer.settings.rotation_speed
            
            frame = self.visualizer.create_frame(
                self.preview_zoom,
                self.preview_rotation,
                intensity,
                self.preview_frame
            )
            
            pygame.surfarray.blit_array(self.preview_surface, frame)
    
    def handle_event(self, event):
        """Handle pygame events"""
        if event.type == pygame.MOUSEBUTTONDOWN:
            # Handle button clicks
            mouse_pos = event.pos
            for button, (rect, _) in self.buttons.items():
                if rect.collidepoint(mouse_pos):
                    self.handle_button(button)
            
            # Handle file selection
            if 50 <= mouse_pos[0] <= 750 and 60 <= mouse_pos[1] <= 480:
                clicked_index = self.scroll_position + (mouse_pos[1] - 60) // 28
                if 0 <= clicked_index < len(self.mp3_files):
                    self.selected_index = clicked_index
        
        elif event.type == pygame.MOUSEWHEEL:
            self.scroll_position = max(0, min(self.scroll_position - event.y,
                                            len(self.mp3_files) - self.visible_items))
    
    def handle_button(self, button):
        """Handle button clicks"""
        if button == 'preview':
            self.start_preview()
        elif button == 'stop':
            self.stop_preview()
        elif button == 'generate':
            self.start_generation()
        elif button == 'color':
            self.visualizer.settings.current_scheme = \
                (self.visualizer.settings.current_scheme + 1) % len(self.visualizer.settings.color_schemes)
            self.visualizer.color_tables = self.visualizer.settings.get_color_tables()
    
    def start_preview(self):
        """Start audio and visualization preview"""
        if not self.is_playing and self.selected_index < len(self.mp3_files):
            try:
                selected_file = str(self.mp3_files[self.selected_index])
                pygame.mixer.music.load(selected_file)
                pygame.mixer.music.play()
                self.is_playing = True
                
                self.preview_data = process_audio(selected_file)
                self.preview_zoom = self.visualizer.zoom_start
                self.preview_rotation = 0
                self.preview_frame = 0
                self.is_previewing = True
            except Exception as e:
                print(f"Error starting preview: {e}")
    
    def stop_preview(self):
        """Stop audio and visualization preview"""
        pygame.mixer.music.stop()
        self.is_playing = False
        self.is_previewing = False
        self.preview_data = None
    
    def start_generation(self):
        """Start generating the final video"""
        if not self.is_generating and self.selected_index < len(self.mp3_files):
            self.is_generating = True
            selected_file = str(self.mp3_files[self.selected_index])
            output_dir = Path(r"C:\Users\Owner\Downloads\Music\MusicVideos")
            output_dir.mkdir(exist_ok=True)
            output_file = output_dir / Path(selected_file).with_suffix('.mp4').name
            
            self.stop_preview()
            
            thread = threading.Thread(target=self.generate_video,
                                   args=(selected_file, str(output_file)))
            thread.daemon = True
            thread.start()
    
    def generate_video(self, input_file, output_file):
        """Generate the final video file"""
        try:
            visualizer = Visualizer(preview_mode=False)
            fps = 30
            
            print("\nProcessing audio...")
            audio_data = process_audio(input_file, fps)
            
            print("\nGenerating video...")
            fourcc = cv2.VideoWriter_fourcc(*'mp4v')
            out = cv2.VideoWriter(output_file, fourcc, fps,
                                (visualizer.width, visualizer.height))
            
            zoom = visualizer.zoom_start
            rotation = 0
            
            for i in range(0, len(audio_data)):
                intensity = audio_data[i]
                zoom *= visualizer.settings.zoom_speed
                rotation += intensity * visualizer.settings.rotation_speed
                
                frame = visualizer.create_frame(zoom, rotation, intensity, i)
                out.write(frame)
            
            out.release()
            print(f"\nVideo saved to: {output_file}")
            
        except Exception as e:
            print(f"Error generating video: {e}")
        
        finally:
            self.is_generating = False

def main():
    gui = GUI()
    clock = pygame.time.Clock()
    
    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                return
            
            gui.handle_event(event)
        
        gui.draw()
        clock.tick(30)

if __name__ == "__main__":
    main()