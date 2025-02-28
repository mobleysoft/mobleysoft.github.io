import numpy as np
import cv2
import os
import librosa
from datetime import datetime
import subprocess
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Tuple
import json
import time

class AudioFeatures:
    def __init__(self, y: np.ndarray, sr: int):
        self.waveform = y
        self.sr = sr
        self._cached_features = {}
        
    def get_spectrum(self, start_idx: int, end_idx: int) -> np.ndarray:
        """Get frequency spectrum for a specific segment"""
        if start_idx >= len(self.waveform):
            return np.zeros(1024)
        segment = self.waveform[start_idx:end_idx]
        return np.abs(np.fft.rfft(segment))
    
    def get_beat_strength(self, start_idx: int, end_idx: int) -> float:
        """Get beat strength for a segment"""
        key = f'beat_{start_idx}_{end_idx}'
        if key not in self._cached_features:
            if start_idx >= len(self.waveform):
                return 0.0
            segment = self.waveform[start_idx:end_idx]
            onset_env = librosa.onset.onset_strength(y=segment, sr=self.sr)
            self._cached_features[key] = onset_env.mean()
        return self._cached_features[key]

class BaseVisualizer(ABC):
    def __init__(self, width: int, height: int):
        self.width = width
        self.height = height
        self.metadata = {
            "name": self.__class__.__name__,
            "version": "1.0",
            "author": "AudioVizAI",
            "tier": "development",
            "tags": [],
            "best_for": []
        }
        
    @abstractmethod
    def generate_frame(self, frame_number: int, audio_features: Optional[AudioFeatures] = None) -> np.ndarray:
        pass
    
    def get_metadata(self) -> Dict:
        return self.metadata

class ProfessionalBeatVisualizer(BaseVisualizer):
    """Pro-grade beat-reactive visualization"""
    def __init__(self, width: int, height: int):
        super().__init__(width, height)
        self.metadata.update({
            "tier": "premium",
            "tags": ["professional", "beat-reactive", "clubs"],
            "best_for": ["edm", "live", "clubs"]
        })
        self.particles = np.random.rand(100, 4)  # x, y, dx, dy
        self.particles[:, 0] *= width
        self.particles[:, 1] *= height
        
    def generate_frame(self, frame_number: int, audio_features: Optional[AudioFeatures] = None) -> np.ndarray:
        image = np.zeros((self.height, self.width), dtype=np.uint8)
        
        if audio_features:
            # Get beat strength
            chunk_size = len(audio_features.waveform) // frame_number if frame_number > 0 else len(audio_features.waveform)
            beat_strength = audio_features.get_beat_strength(
                frame_number * chunk_size,
                (frame_number + 1) * chunk_size
            )
            
            # Update particle velocities based on beat
            self.particles[:, 2:] *= 1 + beat_strength
            
            # Update positions
            self.particles[:, :2] += self.particles[:, 2:]
            
            # Bounce off walls with energy preservation
            bounce_x = (self.particles[:, 0] < 0) | (self.particles[:, 0] > self.width)
            bounce_y = (self.particles[:, 1] < 0) | (self.particles[:, 1] > self.height)
            self.particles[bounce_x, 2] *= -0.95
            self.particles[bounce_y, 3] *= -0.95
            
            # Draw particles with size based on beat
            particle_size = int(2 + beat_strength * 5)
            positions = self.particles[:, :2].astype(int)
            for x, y in positions:
                x = np.clip(x, 0, self.width-1)
                y = np.clip(y, 0, self.height-1)
                cv2.circle(image, (x, y), particle_size, 255, -1)
                
        return image

class SpectralFlowVisualizer(BaseVisualizer):
    """Professional frequency spectrum visualizer"""
    def __init__(self, width: int, height: int):
        super().__init__(width, height)
        self.metadata.update({
            "tier": "premium",
            "tags": ["frequency", "professional", "smooth"],
            "best_for": ["analysis", "studio", "broadcast"]
        })
        self.prev_spectrum = None
        
    def generate_frame(self, frame_number: int, audio_features: Optional[AudioFeatures] = None) -> np.ndarray:
        image = np.zeros((self.height, self.width), dtype=np.uint8)
        
        if audio_features:
            # Get current spectrum
            chunk_size = len(audio_features.waveform) // frame_number if frame_number > 0 else len(audio_features.waveform)
            spectrum = audio_features.get_spectrum(
                frame_number * chunk_size,
                (frame_number + 1) * chunk_size
            )
            
            # Smooth spectrum over time
            if self.prev_spectrum is None:
                self.prev_spectrum = spectrum
            else:
                spectrum = 0.7 * spectrum + 0.3 * self.prev_spectrum
                self.prev_spectrum = spectrum
            
            # Scale spectrum to fit screen
            scaled_spectrum = (spectrum / (spectrum.max() + 1e-10) * self.height).astype(int)
            
            # Draw smooth frequency bars
            bar_width = max(1, self.width // len(scaled_spectrum))
            for i, height in enumerate(scaled_spectrum):
                if i * bar_width < self.width:
                    cv2.rectangle(image,
                                (i * bar_width, self.height),
                                ((i + 1) * bar_width, self.height - height),
                                255, -1)
                    
        return image

class ArtisticFlowVisualizer(BaseVisualizer):
    """High-end artistic flow field visualization"""
    def __init__(self, width: int, height: int):
        super().__init__(width, height)
        self.metadata.update({
            "tier": "premium",
            "tags": ["artistic", "flowing", "ambient"],
            "best_for": ["ambient", "classical", "background"]
        })
        self.flow_field = np.random.rand(height//10, width//10, 2) * 2 * np.pi
        
    def generate_frame(self, frame_number: int, audio_features: Optional[AudioFeatures] = None) -> np.ndarray:
        image = np.zeros((self.height, self.width), dtype=np.uint8)
        
        # Update flow field
        noise = np.random.rand(self.flow_field.shape[0], self.flow_field.shape[1], 2) * 0.1
        self.flow_field += noise
        
        # Create grid of points
        y, x = np.mgrid[0:self.height:1, 0:self.width:1]
        
        # Sample flow field
        field_y = y // 10
        field_x = x // 10
        field_y = np.clip(field_y, 0, self.flow_field.shape[0]-1)
        field_x = np.clip(field_x, 0, self.flow_field.shape[1]-1)
        
        angles = self.flow_field[field_y, field_x, 0]
        strengths = self.flow_field[field_y, field_x, 1]
        
        # Calculate flow
        dx = np.cos(angles) * strengths
        dy = np.sin(angles) * strengths
        
        # Update points
        x = (x + dx).astype(int) % self.width
        y = (y + dy).astype(int) % self.height
        
        # Draw flow
        image[y, x] = 255
        return image

def generate_video(audio_file: str, 
                  output_file: str,
                  visualizer: BaseVisualizer,
                  width: int = 854,  # 480p landscape
                  height: int = 480,
                  fps: int = 30,
                  colormap: int = cv2.COLORMAP_VIRIDIS,
                  quality_preset: str = "medium") -> Dict:
    """
    Generate a professional-grade music visualization video
    Returns statistics about the generation process
    """
    stats = {
        "start_time": time.time(),
        "frames_generated": 0,
        "total_frames": 0,
        "avg_frame_time": 0,
        "visualization_type": visualizer.get_metadata()["name"],
        "quality_preset": quality_preset
    }
    
    # Verify FFmpeg
    try:
        subprocess.run(["ffmpeg", "-version"], check=True, capture_output=True)
    except subprocess.CalledProcessError:
        raise EnvironmentError("FFmpeg not found. Required for video generation.")
        
    # Load and analyze audio
    print(f"Loading audio: {audio_file}")
    y, sr = librosa.load(audio_file, sr=None)
    audio_features = AudioFeatures(y, sr)
    duration = librosa.get_duration(y=y, sr=sr)
    print(f"Audio duration: {duration:.2f} seconds")
    
    # Calculate frames
    frame_count = int(duration * fps)
    stats["total_frames"] = frame_count
    print(f"Generating {frame_count} frames...")
    
    # Setup output directory
    frames_dir = "frames"
    os.makedirs(frames_dir, exist_ok=True)
    
    # Quality presets
    quality_settings = {
        "low": {
            "compression": "ultrafast",
            "bitrate": "2M"
        },
        "medium": {
            "compression": "medium",
            "bitrate": "4M"
        },
        "high": {
            "compression": "slow",
            "bitrate": "8M"
        }
    }
    settings = quality_settings.get(quality_preset, quality_settings["medium"])
    
    # Generate frames
    frame_times = []
    for frame_number in range(frame_count):
        frame_start = time.time()
        
        if frame_number % 50 == 0:
            print(f"Processing frame {frame_number}/{frame_count}")
            
        # Generate frame
        frame = visualizer.generate_frame(frame_number, audio_features)
        
        # Apply color
        colored = cv2.applyColorMap(frame, colormap)
        
        # Save frame
        cv2.imwrite(
            f"{frames_dir}/frame_{frame_number:04d}.png",
            colored,
            [cv2.IMWRITE_PNG_COMPRESSION, 1]
        )
        
        # Track performance
        frame_time = time.time() - frame_start
        frame_times.append(frame_time)
        stats["frames_generated"] += 1
        
    stats["avg_frame_time"] = np.mean(frame_times)
    
    # Compile video
    print("Generating final video...")
    
    ffmpeg_cmd = [
        "ffmpeg",
        "-r", str(fps),
        "-i", f"{frames_dir}/frame_%04d.png",
        "-i", audio_file,
        "-c:v", "libx264",
        "-preset", settings["compression"],
        "-b:v", settings["bitrate"],
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        output_file,
        "-y"
    ]
    
    subprocess.run(ffmpeg_cmd, check=True)
    
    # Cleanup
    print("Cleaning up...")
    for file in os.listdir(frames_dir):
        os.remove(os.path.join(frames_dir, file))
    os.rmdir(frames_dir)
    
    stats["end_time"] = time.time()
    stats["total_time"] = stats["end_time"] - stats["start_time"]
    
    print(f"Video saved as {output_file}")
    return stats

if __name__ == "__main__":
    # Configuration
    width, height = 854, 480  # 480p landscape
    fps = 30
    
    # Get input file
    audio_file = input("Enter path to audio file: ").strip('"')
    
    # Select visualization style
    print("\nSelect visualization style:")
    print("1. Professional Beat Visualizer (Perfect for clubs/EDM)")
    print("2. Spectral Flow (Studio-grade frequency visualization)")
    print("3. Artistic Flow (High-end ambient visuals)")
    
    choice = int(input("Enter choice (1-3): "))
    
    # Select color scheme
    print("\nSelect color scheme:")
    print("1. Pro Night (Blue -> White, club-ready)")
    print("2. Studio (Green -> White, broadcast-ready)")
    print("3. Artistic (Purple -> Yellow, cinema-grade)")
    print("4. Neon (Multi-color, stage-ready)")
    
    color_choice = int(input("Enter choice (1-4): "))
    
    # Map choices to colormaps
    colormaps = [
        cv2.COLORMAP_OCEAN,   # Pro Night
        cv2.COLORMAP_BONE,    # Studio
        cv2.COLORMAP_MAGMA,   # Artistic
        cv2.COLORMAP_RAINBOW  # Neon
    ]
    
    # Select quality preset
    print("\nSelect quality preset:")
    print("1. Development (Fast, lower quality)")
    print("2. Preview (Balanced)")
    print("3. Production (High quality, slower)")
    
    quality_choice = int(input("Enter choice (1-3): "))
    quality_presets = ["low", "medium", "high"]
    
    # Create visualizer
    visualizers = {
        1: ProfessionalBeatVisualizer(width, height),
        2: SpectralFlowVisualizer(width, height),
        3: ArtisticFlowVisualizer(width, height)
    }
    
    visualizer = visualizers.get(choice)
    if not visualizer:
        print("Invalid choice. Using Professional Beat Visualizer.")
        visualizer = ProfessionalBeatVisualizer(width, height)
    
    # Generate output filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"output_{visualizer.metadata['name']}_{timestamp}.mp4"
    
    # Generate video and get stats
    stats = generate_video(
        audio_file=audio_file,
        output_file=output_file,
        visualizer=visualizer,
        width=width,
        height=height,
        fps=fps,
        colormap=colormaps[color_choice - 1],
        quality_preset=quality_presets[quality_choice - 1]
    )
    
    # Print professional stats report
    print("\n============ Generation Report ============")
    print(f"Visualization Type: {stats['visualization_type']}")
    print(f"Quality Preset: {stats['quality_preset'].upper()}")
    print(f"Resolution: {width}x{height} @ {fps}fps")
    print("\nPerformance Metrics:")
    print(f"Total Frames: {stats['frames_generated']}/{stats['total_frames']}")
    print(f"Average Frame Time: {stats['avg_frame_time']*1000:.1f}ms")
    print(f"Total Processing Time: {stats['total_time']:.1f}s")
    print(f"Effective FPS: {stats['frames_generated']/stats['total_time']:.1f}")
    
    # Save stats for analysis
    stats_file = f"render_stats_{timestamp}.json"
    with open(stats_file, 'w') as f:
        json.dump(stats, f, indent=2)
    print(f"\nDetailed statistics saved to: {stats_file}")
    print("===========================================")