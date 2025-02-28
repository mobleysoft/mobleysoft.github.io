import numpy as np
import cv2
import os
import librosa
from datetime import datetime
import subprocess
from typing import Callable
from abc import ABC, abstractmethod

class Visualizer(ABC):
    def __init__(self, width: int, height: int):
        self.width = width
        self.height = height
        
    @abstractmethod
    def generate_frame(self, frame_number: int, audio_data: np.ndarray = None) -> np.ndarray:
        pass

class BitPatternVisualizer(Visualizer):
    def generate_frame(self, frame_number: int, audio_data: np.ndarray = None) -> np.ndarray:
        x, y = np.meshgrid(np.arange(self.width), np.arange(self.height))
        scaled_frame = frame_number // 5
        val = (x ^ y ^ scaled_frame) & (x | y)
        val = (val * (x & y)) % 256
        return val.astype(np.uint8)

class CircularVisualizer(Visualizer):
    def generate_frame(self, frame_number: int, audio_data: np.ndarray = None) -> np.ndarray:
        x, y = np.meshgrid(
            np.linspace(-2, 2, self.width),
            np.linspace(-2, 2, self.height)
        )
        
        # Create spiral pattern
        r = np.sqrt(x**2 + y**2)
        theta = np.arctan2(y, x)
        
        pattern = np.sin(r * 5 - frame_number / 10) * np.cos(theta * 3 + frame_number / 20)
        pattern = ((pattern + 1) * 127.5).astype(np.uint8)
        return pattern

class WaveformVisualizer(Visualizer):
    def generate_frame(self, frame_number: int, audio_data: np.ndarray) -> np.ndarray:
        if audio_data is None:
            return np.zeros((self.height, self.width), dtype=np.uint8)
            
        # Get the audio segment for this frame
        samples_per_frame = len(audio_data) // frame_number if frame_number > 0 else len(audio_data)
        start_idx = frame_number * samples_per_frame
        end_idx = min(start_idx + samples_per_frame, len(audio_data))
        segment = audio_data[start_idx:end_idx]
        
        # Create visualization
        image = np.zeros((self.height, self.width), dtype=np.uint8)
        if len(segment) > 0:
            # Normalize and scale the waveform
            normalized = (segment - segment.min()) / (segment.max() - segment.min() + 1e-10)
            scaled = (normalized * (self.height - 20)).astype(int)
            
            # Draw the waveform
            points_per_pixel = len(scaled) // self.width
            for x in range(self.width):
                start = x * points_per_pixel
                end = start + points_per_pixel
                if start < len(scaled):
                    height = int(np.mean(scaled[start:end]))
                    cv2.line(image, 
                            (x, self.height//2 - height),
                            (x, self.height//2 + height),
                            255, 1)
        return image

# Fast Kaleidoscope pattern generator
class KaleidoscopeVisualizer(Visualizer):
    def generate_frame(self, frame_number: int, audio_data: np.ndarray = None) -> np.ndarray:
        # Create base coordinates
        x, y = np.meshgrid(np.linspace(-1, 1, self.width), np.linspace(-1, 1, self.height))
        r = np.sqrt(x**2 + y**2)
        theta = np.arctan2(y, x)
        
        # Create kaleidoscope effect with 8-fold symmetry
        k = 8
        theta = ((theta * k) % (2 * np.pi)) / k
        
        # Animate pattern
        pattern = np.sin(r * 10 + frame_number / 10) * np.cos(theta * 4 - frame_number / 15)
        return ((pattern + 1) * 127.5).astype(np.uint8)

# Fast matrix rain effect
class MatrixRainVisualizer(Visualizer):
    def __init__(self, width: int, height: int):
        super().__init__(width, height)
        self.drops = np.random.randint(0, height, width)
        self.speeds = np.random.randint(1, 4, width)
        
    def generate_frame(self, frame_number: int, audio_data: np.ndarray = None) -> np.ndarray:
        image = np.zeros((self.height, self.width), dtype=np.uint8)
        
        # Update and draw drops vectorized
        self.drops = (self.drops + self.speeds) % self.height
        x_coords = np.arange(self.width)
        y_coords = self.drops
        
        # Create fade effect
        for i in range(10):
            valid_y = y_coords - i >= 0
            image[y_coords[valid_y] - i, x_coords[valid_y]] = 255 - i * 25
            
        return image

# Fast frequency bars visualizer
class FrequencyBarsVisualizer(Visualizer):
    def generate_frame(self, frame_number: int, audio_data: np.ndarray = None) -> np.ndarray:
        image = np.zeros((self.height, self.width), dtype=np.uint8)
        if audio_data is None:
            return image
            
        # Get audio segment for this frame
        chunk_size = len(audio_data) // (frame_number + 1)
        start = frame_number * chunk_size
        end = start + chunk_size
        if start >= len(audio_data):
            return image
            
        # Calculate frequency spectrum
        spectrum = np.abs(np.fft.rfft(audio_data[start:end]))
        spectrum = spectrum[:self.width]  # Limit to width
        
        # Normalize and scale
        if len(spectrum) > 0:
            spectrum = (spectrum / spectrum.max() * self.height).astype(int)
            x_coords = np.arange(len(spectrum))
            
            # Draw bars vectorized
            for x, height in enumerate(spectrum):
                if x < self.width:
                    image[self.height-height:self.height, x] = 255
                    
        return image

# Fast voronoi pattern generator
class VoronoiVisualizer(Visualizer):
    def __init__(self, width: int, height: int, num_points: int = 12):
        super().__init__(width, height)
        self.num_points = num_points
        self.points = np.random.rand(num_points, 2)
        
    def generate_frame(self, frame_number: int, audio_data: np.ndarray = None) -> np.ndarray:
        # Animate points in circular motion
        t = frame_number * 0.05
        angles = np.linspace(0, 2*np.pi, self.num_points) + t
        r = 0.3 + 0.1 * np.sin(t * 0.5)
        
        self.points[:, 0] = 0.5 + r * np.cos(angles)
        self.points[:, 1] = 0.5 + r * np.sin(angles)
        
        # Generate grid points
        x, y = np.meshgrid(np.linspace(0, 1, self.width), np.linspace(0, 1, self.height))
        grid = np.dstack((x, y))
        
        # Calculate distances to all points
        distances = np.zeros((self.height, self.width, self.num_points))
        for i in range(self.num_points):
            distances[:,:,i] = np.sqrt(
                (grid[:,:,0] - self.points[i,0])**2 + 
                (grid[:,:,1] - self.points[i,1])**2
            )
        
        # Get closest point indices
        closest = np.argmin(distances, axis=2)
        
        # Create pattern based on closest points
        pattern = (closest * (255 // self.num_points)).astype(np.uint8)
        return pattern

# Hypnotic rings visualizer
class RingsVisualizer(Visualizer):
    def generate_frame(self, frame_number: int, audio_data: np.ndarray = None) -> np.ndarray:
        x, y = np.meshgrid(np.linspace(-1, 1, self.width), np.linspace(-1, 1, self.height))
        r = np.sqrt(x**2 + y**2)
        
        # Create multiple ring patterns with different frequencies
        pattern = np.sin(r * 20 - frame_number / 10) * np.cos(r * 15 + frame_number / 8)
        pattern += np.sin(r * 10 + frame_number / 12)
        
        return ((pattern + 2) * 64).astype(np.uint8)

class ParticleVisualizer(Visualizer):
    def __init__(self, width: int, height: int, num_particles: int = 100):
        super().__init__(width, height)
        self.num_particles = num_particles
        self.particles = np.random.rand(num_particles, 4)  # x, y, dx, dy
        self.particles[:, 0] *= width
        self.particles[:, 1] *= height
        self.particles[:, 2:] = (np.random.rand(num_particles, 2) - 0.5) * 5

    def generate_frame(self, frame_number: int, audio_data: np.ndarray = None) -> np.ndarray:
        image = np.zeros((self.height, self.width), dtype=np.uint8)
        
        # Update particle positions
        self.particles[:, 0] += self.particles[:, 2]
        self.particles[:, 1] += self.particles[:, 3]
        
        # Bounce off walls
        bounce_x = (self.particles[:, 0] < 0) | (self.particles[:, 0] > self.width)
        bounce_y = (self.particles[:, 1] < 0) | (self.particles[:, 1] > self.height)
        self.particles[bounce_x, 2] *= -1
        self.particles[bounce_y, 3] *= -1
        
        # Draw particles
        positions = self.particles[:, :2].astype(int)
        for x, y in positions:
            x = np.clip(x, 0, self.width-1)
            y = np.clip(y, 0, self.height-1)
            cv2.circle(image, (x, y), 2, 255, -1)
            
        return image

def generate_video(audio_file: str, output_file: str, visualizer: Visualizer, 
                  width: int = 426, height: int = 240, 
                  upscale_factor: int = 2, fps: int = 24,
                  colormap: int = cv2.COLORMAP_VIRIDIS):
    """
    Generate a music visualization video using the specified visualizer.
    """
    # Check FFmpeg
    try:
        subprocess.run(["ffmpeg", "-version"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError:
        raise EnvironmentError("FFmpeg is not installed or not in the system's PATH.")

    # Load audio
    print(f"Loading audio file: {audio_file}")
    y, sr = librosa.load(audio_file, sr=None)
    duration = librosa.get_duration(y=y, sr=sr)
    print(f"Duration: {duration:.2f} seconds")

    frame_count = int(duration * fps)
    print(f"Generating {frame_count} frames...")

    # Setup output directory
    frames_dir = "frames"
    os.makedirs(frames_dir, exist_ok=True)

    # Generate frames
    for frame_number in range(frame_count):
        if frame_number % 50 == 0:
            print(f"Processing frame {frame_number}/{frame_count}")

        # Generate base pattern
        pattern = visualizer.generate_frame(frame_number, y)

        # Upscale if needed
        if upscale_factor > 1:
            pattern = cv2.resize(pattern, 
                               (width * upscale_factor, height * upscale_factor),
                               interpolation=cv2.INTER_NEAREST)

        # Apply color
        colored = cv2.applyColorMap(pattern, colormap)

        # Save frame
        cv2.imwrite(f"{frames_dir}/frame_{frame_number:04d}.png", 
                    colored, [cv2.IMWRITE_PNG_COMPRESSION, 1])

    print("Compiling video with FFmpeg...")

    # Combine frames and audio
    subprocess.run([
        "ffmpeg",
        "-r", str(fps),
        "-i", f"{frames_dir}/frame_%04d.png",
        "-i", audio_file,
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        output_file,
        "-y"
    ], check=True)

    # Cleanup
    print("Cleaning up...")
    for file in os.listdir(frames_dir):
        os.remove(os.path.join(frames_dir, file))
    os.rmdir(frames_dir)

    print(f"Video saved as {output_file}")

if __name__ == "__main__":
    # Configuration
    width, height = 426, 240  # 240p base resolution
    upscale_factor = 2  # Final resolution will be 852x480 (480p)
    fps = 24
    
    # Get input file
    audio_file = input("Enter path to audio file: ")
    audio_file = audio_file.strip('"')  # Remove quotes if present
    
    # Select visualization style
    print("\nSelect visualization style:")
    print("1. Digital Patterns (fast geometric patterns)")
    print("2. Circular/Spiral (hypnotic spirals)")
    print("3. Audio Waveform (direct audio visualization)")
    print("4. Particle System (flowing particles)")
    print("5. Kaleidoscope (symmetrical patterns)")
    print("6. Matrix Rain (digital rain effect)")
    print("7. Frequency Bars (audio spectrum)")
    print("8. Voronoi (cellular patterns)")
    print("9. Hypnotic Rings (concentric patterns)")
    
    choice = int(input("Enter choice (1-9): "))
    
    # Select color scheme
    print("\nSelect color scheme:")
    print("1. Viridis (Purple -> Yellow)")
    print("2. Turbo (Blue -> Red)")
    print("3. Plasma (Purple -> Yellow, more vibrant)")
    print("4. Magma (Black -> Yellow)")
    print("5. Inferno (Black -> Yellow, intense)")
    print("6. Cividis (Blue -> Yellow, colorblind-friendly)")
    print("7. Rainbow (Full spectrum)")
    print("8. Ocean (Blue -> White)")
    print("9. Hot (Black -> Yellow -> Red)")
    print("10. HSV (Hue cycle)")
    print("11. Parula (Blue -> Yellow, MATLAB-style)")
    print("12. Twilight (Blue -> Red -> Blue)")
    print("13. Deep Green (Black -> Green)")
    print("14. Cool Warm (Blue -> Red, diverging)")
    print("15. Spectral (Red -> Yellow -> Blue)")
    
    color_choice = int(input("Enter choice (1-15): "))
    colormaps = [
        cv2.COLORMAP_VIRIDIS,
        cv2.COLORMAP_TURBO,
        cv2.COLORMAP_PLASMA,
        cv2.COLORMAP_MAGMA,
        cv2.COLORMAP_INFERNO,
        cv2.COLORMAP_CIVIDIS,
        cv2.COLORMAP_RAINBOW,
        cv2.COLORMAP_OCEAN,
        cv2.COLORMAP_HOT,
        cv2.COLORMAP_HSV,
        cv2.COLORMAP_PARULA,
        cv2.COLORMAP_TWILIGHT,
        cv2.COLORMAP_BONE,  # Using BONE for Deep Green (will be tinted)
        cv2.COLORMAP_JET,   # Using JET for Cool Warm
        cv2.COLORMAP_SPRING # Using SPRING for Spectral
    ]
    
    # Create visualizer based on choice
    visualizers = {
        1: BitPatternVisualizer(width, height),
        2: CircularVisualizer(width, height),
        3: WaveformVisualizer(width, height),
        4: ParticleVisualizer(width, height, num_particles=200),
        5: KaleidoscopeVisualizer(width, height),
        6: MatrixRainVisualizer(width, height),
        7: FrequencyBarsVisualizer(width, height),
        8: VoronoiVisualizer(width, height),
        9: RingsVisualizer(width, height)
    }
    
    visualizer = visualizers.get(choice)
    if not visualizer:
        print("Invalid choice. Using default BitPattern visualizer.")
        visualizer = BitPatternVisualizer(width, height)
    
    # Generate output filename with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"output_{timestamp}.mp4"
    
    # Generate the video
    generate_video(
        audio_file=audio_file,
        output_file=output_file,
        visualizer=visualizer,
        width=width,
        height=height,
        upscale_factor=upscale_factor,
        fps=fps,
        colormap=colormaps[color_choice - 1]
    )