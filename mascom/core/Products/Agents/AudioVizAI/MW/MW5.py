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
    
@jit(nopython=True, parallel=True, fastmath=True)
def create_enhanced_frame(width, height, max_iter, center_x, center_y, zoom, rotation, 
                         audio_features, frame_number, secondary_iter=5):
    """Enhanced frame generation with layered effects"""
    intensity, spectral, bass, harmonic = audio_features
    result = np.zeros((height, width, 3), dtype=np.uint8)
    
    # Primary Mandelbrot layer
    main_layer = calculate_mandelbrot(
        width, height, max_iter,
        center_x + np.sin(frame_number * 0.01) * (0.1 + bass * 0.1),
        center_y + np.cos(frame_number * 0.01) * (0.1 + bass * 0.1),
        zoom * (1 + bass * 0.2),
        rotation + spectral * 0.5
    )
    
    # Secondary "echo" layer with different parameters
    echo_layer = calculate_mandelbrot(
        width, height, secondary_iter,
        center_x - np.sin(frame_number * 0.005) * 0.2,
        center_y - np.cos(frame_number * 0.005) * 0.2,
        zoom * 1.5,
        -rotation * 0.5
    )
    
    # Dynamic color mapping with interference patterns
    for i in range(3):  # RGB channels
        phase = frame_number * (0.02 + harmonic * 0.01)
        main_color = np.sin(main_layer * 0.1 + phase + i * 2.094)
        echo_color = np.sin(echo_layer * 0.2 - phase + i * 2.094)
        
        # Combine layers with interference
        combined = (main_color * 0.7 + echo_color * 0.3 + 1) * 127
        result[:, :, i] = (combined * intensity).astype(np.uint8)
    
    # Add subtle energy tendrils based on spectral content
    high_energy = main_layer > (max_iter * 0.85)
    result[high_energy] = result[high_energy] * (1.3 + spectral * 0.7)
    
    return result

class EnhancedVisualizer(Visualizer):
    def __init__(self, preview_mode=False):
        super().__init__(preview_mode)
        self.secondary_iter = 5 if preview_mode else 10
        
        # Add orbital parameters
        self.orbital_speed = 0.01
        self.echo_speed = 0.005
        self.color_flow = 0.02
        
    def create_frame(self, zoom, rotation, audio_features, frame_number):
        return create_enhanced_frame(
            self.width, self.height, self.max_iter,
            self.center_x, self.center_y, zoom, rotation,
            audio_features, frame_number, self.secondary_iter
        )
        
        # Create psychedelic color mapping
        color_phase = frame_number * 0.02
        frame = np.zeros((self.height, self.width, 3), dtype=np.uint8)
        
        # Dynamic color mapping based on audio
        for i in range(3):  # RGB channels
            phase_offset = i * 2.094  # 120° offset between channels
            color_factor = np.sin(mandel * 0.1 + color_phase + phase_offset)
            frame[:, :, i] = ((color_factor + 1) * 127 * intensity).astype(np.uint8)
        
        # Add glow effect based on spectral content
        glow_mask = mandel > (self.max_iter * 0.8)
        frame[glow_mask] = frame[glow_mask] * (1 + spectral)
        
        return frame

    def process_audio_features(y, sr, hop_length=512):
        # Core features
        onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=hop_length)
        spectral = librosa.feature.spectral_centroid(y=y, sr=sr, hop_length=hop_length)[0]
        
        # Enhanced bass detection using multiple bands
        spec = np.abs(librosa.stft(y))
        bass = np.mean(spec[1:10, :], axis=0)  # Sub-bass
        lowmid = np.mean(spec[10:30, :], axis=0)  # Low-mids
        
        # Harmonic content analysis
        chroma = librosa.feature.chroma_stft(y=y, sr=sr, hop_length=hop_length)
        harmonic = np.sum(chroma, axis=0)
        
        # Rhythmic features for movement
        tempo, beats = librosa.beat.beat_track(y=y, sr=sr, hop_length=hop_length)
        beat_strength = np.zeros_like(onset_env)
        beat_frames = librosa.frames_to_samples(beats, hop_length=hop_length) // hop_length
        beat_strength[beat_frames] = 1
        
        # Smooth all features
        kernel_size = 5
        kernel = np.ones(kernel_size) / kernel_size
        features = {
            'onset': np.convolve(onset_env, kernel, mode='same'),
            'spectral': np.convolve(spectral, kernel, mode='same'),
            'bass': np.convolve(bass, kernel, mode='same'),
            'lowmid': np.convolve(lowmid, kernel, mode='same'),
            'harmonic': np.convolve(harmonic, kernel, mode='same'),
            'beat': np.convolve(beat_strength, kernel, mode='same')
        }
        
        # Normalize features
        for key in features:
            features[key] = features[key] / (np.max(features[key]) + 1e-6)
        
        return features

def generate_video(self, input_file, output_file):
    """Generate video with enhanced audio reactivity and layered visuals"""
    try:
        visualizer = EnhancedVisualizer(preview_mode=False)
        fps = 30
        loop_seconds = 15
        crossfade_frames = 45
        loop_frames = fps * loop_seconds
        
        print("\nExtracting enhanced audio features...")
        y, sr = librosa.load(input_file, sr=22050)
        features = self.process_audio_features(y, sr)
        
        # Resample all features to video fps
        times = librosa.times_like(features['onset'])
        target_times = np.linspace(0, times[-1], int(times[-1] * fps))
        
        audio_features = {}
        for key, value in features.items():
            audio_features[key] = np.interp(target_times, times, value)
        
        print("\nGenerating base sequence with layered effects...")
        base_frames = []
        zoom = visualizer.zoom_start
        rotation = 0
        
        for i in range(loop_frames):
            # Combine features for rich modulation
            combined_features = (
                audio_features['onset'][i],
                audio_features['spectral'][i],
                audio_features['bass'][i] * 0.7 + audio_features['lowmid'][i] * 0.3,
                audio_features['harmonic'][i]
            )
            
            # Dynamic movement based on audio
            zoom *= 0.98 + audio_features['bass'][i] * 0.01
            rotation += 0.1 + audio_features['beat'][i] * 0.2
            
            frame = visualizer.create_frame(zoom, rotation, combined_features, i)
            base_frames.append(frame)
        
        print("\nAssembling final video with fluid transitions...")
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(output_file, fourcc, fps,
                            (visualizer.width, visualizer.height))
        
        total_frames = len(audio_features['onset'])
        
        # Enhanced frame blending
        for i in range(total_frames):
            base_idx = i % loop_frames
            
            if base_idx >= loop_frames - crossfade_frames:
                # Smooth crossfade with easing
                fade_progress = (loop_frames - base_idx) / crossfade_frames
                fade_factor = 0.5 + 0.5 * np.cos(fade_progress * np.pi)
                next_idx = (base_idx + 1) % loop_frames
                
                # Blend frames with beat-reactive shift
                frame1 = base_frames[base_idx].astype(float)
                frame2 = base_frames[next_idx].astype(float)
                
                # Add subtle shift based on beat
                beat_shift = int(audio_features['beat'][i] * 3)
                frame2 = np.roll(frame2, beat_shift, axis=1)
                
                frame = (frame1 * fade_factor + frame2 * (1 - fade_factor))
            else:
                frame = base_frames[base_idx].astype(float)
            
            # Final modulation
            intensity = audio_features['onset'][i]
            spectral_mod = audio_features['spectral'][i]
            beat_mod = audio_features['beat'][i]
            
            # Apply layered modulation
            frame = frame * (0.7 + 0.3 * intensity)
            frame = np.roll(frame, int(spectral_mod * 5), axis=2)  # Color shift
            
            # Add beat-reactive pulse
            if beat_mod > 0.8:
                frame = frame * (1 + beat_mod * 0.2)
            
            out.write(frame.astype(np.uint8))
            
            if i % fps == 0:
                progress = (i + 1) / total_frames
                print(f"Progress: {progress*100:.1f}%", end='\r')
        
        out.release()
        print(f"\nVideo saved to: {output_file}")
        
    except Exception as e:
        print(f"Error generating video: {e}")
        raise e
    
    finally:
        self.is_generating = False
        try:
            visualizer = Visualizer(preview_mode=False)
            fps = 30
            loop_seconds = 15  # Longer base loop for more variation
            crossfade_frames = 45  # Longer crossfade
            loop_frames = fps * loop_seconds
            
            print("\nExtracting audio features...")
            y, sr = librosa.load(input_file, sr=22050)
            
            # Rich audio feature extraction
            onset = librosa.onset.onset_strength(y=y, sr=sr, hop_length=512)
            spectral = librosa.feature.spectral_centroid(y=y, sr=sr, hop_length=512)[0]
            
            # Bass content for extra dimension
            spec = np.abs(librosa.stft(y))
            bass = np.mean(spec[1:10, :], axis=0)  # Low frequency content
            
            # Chromagram for harmonic content
            chroma = librosa.feature.chroma_stft(y=y, sr=sr, hop_length=512)
            harmonic_complexity = np.sum(chroma, axis=0)
            
            # Normalize and resample all features
            times = librosa.times_like(onset)
            target_times = np.linspace(0, times[-1], int(times[-1] * fps))
            
            audio_features = {
                'intensity': np.interp(target_times, times, onset),
                'spectral': np.interp(target_times, times, spectral),
                'bass': np.interp(target_times, times, bass),
                'harmonic': np.interp(target_times, times, harmonic_complexity)
            }
            
            # Normalize features
            for key in audio_features:
                audio_features[key] = audio_features[key] / np.max(audio_features[key])
            
            print("\nGenerating enhanced base sequence...")
            base_frames = []
            zoom = visualizer.zoom_start
            rotation = 0
            
            # Generate base pattern with all effects
            for i in range(loop_frames):
                features = (
                    audio_features['intensity'][i],
                    audio_features['spectral'][i],
                    audio_features['bass'][i]
                )
                
                zoom *= 0.98 + audio_features['bass'][i] * 0.01  # Bass influences zoom speed
                rotation += 0.1 + audio_features['harmonic'][i] * 0.2  # Harmony affects rotation
                
                frame = visualizer.create_frame(zoom, rotation, features, i)
                base_frames.append(frame)
            
            print("\nAssembling final video with advanced transitions...")
            fourcc = cv2.VideoWriter_fourcc(*'mp4v')
            out = cv2.VideoWriter(output_file, fourcc, fps,
                                (visualizer.width, visualizer.height))
            
            total_frames = len(audio_features['intensity'])
            
            # Write final video with enhanced transitions
            for i in range(total_frames):
                base_idx = i % loop_frames
                
                # Smooth loop transition
                if base_idx >= loop_frames - crossfade_frames:
                    fade_factor = (loop_frames - base_idx) / crossfade_frames
                    fade_factor = 0.5 + 0.5 * np.cos(fade_factor * np.pi)  # Smooth cosine fade
                    next_idx = (base_idx + 1) % loop_frames
                    
                    frame = cv2.addWeighted(
                        base_frames[base_idx], fade_factor,
                        base_frames[next_idx], 1 - fade_factor,
                        0
                    )
                else:
                    frame = base_frames[base_idx].copy()
                
                # Add dynamic color modulation
                hue_shift = int(audio_features['harmonic'][i] * 10)
                frame = np.roll(frame, hue_shift, axis=2)
                
                # Apply intensity modulation
                frame = (frame * (0.7 + 0.3 * audio_features['intensity'][i])).astype(np.uint8)
                
                out.write(frame)
                
                if i % fps == 0:
                    progress = (i + 1) / total_frames
                    print(f"Progress: {progress*100:.1f}%", end='\r')
            
            out.release()
            print(f"\nVideo saved to: {output_file}")
            
        except Exception as e:
            print(f"Error generating video: {e}")
            raise e
        
        finally:
            self.is_generating = False
        try:
            visualizer = Visualizer(preview_mode=False)
            fps = 30
            loop_seconds = 12  # Increased for smoother patterns
            crossfade_frames = 30  # 1 second crossfade
            loop_frames = fps * loop_seconds
            
            print("\nProcessing audio...")
            # Process audio with multiple features
            y, sr = librosa.load(input_file, sr=22050)
            
            # Extract multiple audio features for modulation
            print("Extracting audio features...")
            full_onset = librosa.onset.onset_strength(y=y, sr=sr, hop_length=512)
            full_spectral = librosa.feature.spectral_centroid(y=y, sr=sr, hop_length=512)[0]
            full_rms = librosa.feature.rms(y=y, hop_length=512)[0]
            
            # Normalize and resample all features to video fps
            times = librosa.times_like(full_onset)
            target_times = np.linspace(0, times[-1], int(times[-1] * fps))
            
            audio_features = {
                'onset': np.interp(target_times, times, full_onset),
                'spectral': np.interp(target_times, times, full_spectral),
                'rms': np.interp(target_times, times, full_rms)
            }
            
            # Normalize all features
            for key in audio_features:
                audio_features[key] = audio_features[key] / np.max(audio_features[key])
            
            # Get base pattern length of audio data
            base_features = {k: v[:loop_frames] for k, v in audio_features.items()}
            
            print("\nGenerating base patterns...")
            base_frames = []
            zoom = visualizer.zoom_start
            rotation = 0
            
            # Generate base sequence with higher quality
            for i in range(loop_frames):
                # Combine audio features for richer modulation
                intensity = (base_features['onset'][i] * 0.5 + 
                           base_features['rms'][i] * 0.3 +
                           base_features['spectral'][i] * 0.2)
                
                zoom *= visualizer.settings.zoom_speed
                rotation += intensity * visualizer.settings.rotation_speed
                
                frame = visualizer.create_frame(zoom, rotation, intensity, i)
                base_frames.append(frame)
            
            print("\nAssembling final video with transitions...")
            fourcc = cv2.VideoWriter_fourcc(*'mp4v')
            out = cv2.VideoWriter(output_file, fourcc, fps,
                                (visualizer.width, visualizer.height))
            
            total_frames = len(audio_features['onset'])
            
            # Write the final video with crossfading and multi-parameter modulation
            for i in range(total_frames):
                base_idx = i % loop_frames
                intensity = (audio_features['onset'][i] * 0.5 + 
                           audio_features['rms'][i] * 0.3 +
                           audio_features['spectral'][i] * 0.2)
                
                # Calculate crossfade if near loop point
                if base_idx >= loop_frames - crossfade_frames:
                    fade_factor = (loop_frames - base_idx) / crossfade_frames
                    next_idx = (base_idx + 1) % loop_frames
                    
                    # Blend current and next frame
                    current_frame = base_frames[base_idx].astype(float)
                    next_frame = base_frames[next_idx].astype(float)
                    blended_frame = (current_frame * fade_factor + 
                                   next_frame * (1 - fade_factor))
                    
                    # Apply audio reactivity
                    frame = (blended_frame * intensity).astype(np.uint8)
                else:
                    # Regular frame with audio reactivity
                    frame = (base_frames[base_idx] * intensity).astype(np.uint8)
                
                # Add subtle color modulation based on spectral content
                color_shift = int(audio_features['spectral'][i] * 10)
                frame = np.roll(frame, color_shift, axis=2)
                
                out.write(frame)
                
                # Update progress
                if i % fps == 0:
                    progress = (i + 1) / total_frames
                    print(f"Progress: {progress*100:.1f}%", end='\r')
            
            out.release()
            print(f"\nVideo saved to: {output_file}")
            
        except Exception as e:
            print(f"Error generating video: {e}")
        
        finally:
            self.is_generating = False
        try:
            visualizer = Visualizer(preview_mode=False)
            fps = 30
            loop_seconds = 8  # Length of base pattern
            loop_frames = fps * loop_seconds
            
            print("\nProcessing audio...")
            # Get full audio data for intensity matching
            full_audio_data = process_audio(input_file, fps)
            # Get just enough audio data for base pattern
            base_audio_data = full_audio_data[:loop_frames]
            
            print("\nGenerating base pattern sequence...")
            # Create temporary file for base sequence
            temp_dir = Path(r"C:\Users\Owner\Downloads\Music\MusicVideos\temp")
            temp_dir.mkdir(exist_ok=True)
            temp_file = temp_dir / "base_sequence.mp4"
            
            # Generate base pattern
            fourcc = cv2.VideoWriter_fourcc(*'mp4v')
            out = cv2.VideoWriter(str(temp_file), fourcc, fps,
                                (visualizer.width, visualizer.height))
            
            zoom = visualizer.zoom_start
            rotation = 0
            
            # Generate base sequence
            for i in range(loop_frames):
                intensity = base_audio_data[i]
                zoom *= visualizer.settings.zoom_speed
                rotation += intensity * visualizer.settings.rotation_speed
                
                frame = visualizer.create_frame(zoom, rotation, intensity, i)
                out.write(frame)
            
            out.release()
            
            print("\nAssembling final video...")
            # Now create the final video by looping the base sequence
            # but modulating it with the full audio intensity
            cap = cv2.VideoCapture(str(temp_file))
            out = cv2.VideoWriter(output_file, fourcc, fps,
                                (visualizer.width, visualizer.height))
            
            base_frames = []
            while cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    break
                base_frames.append(frame)
            cap.release()
            
            # Write the final video with audio-reactive modulation
            for i in range(len(full_audio_data)):
                frame_idx = i % loop_frames
                intensity = full_audio_data[i]
                
                # Modulate base frame with current audio intensity
                modulated_frame = (base_frames[frame_idx] * intensity).astype(np.uint8)
                out.write(modulated_frame)
            
            out.release()
            
            # Cleanup
            temp_file.unlink()
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