import numpy as np
from numba import jit
import cv2
import librosa
import pygame
from pathlib import Path
import threading

@jit(nopython=True, fastmath=True)
def calculate_mandelbrot(width, height, max_iter, center_x, center_y, zoom, rotation):
    """Optimized Mandelbrot calculation with zoom and rotation support"""
    result = np.zeros((height, width), dtype=np.uint8)
    
    for i in range(height):
        for j in range(width):
            # Map pixel to complex plane with zoom and rotation
            x = (j - width/2) / (width/4) / zoom + center_x
            y = (i - height/2) / (height/4) / zoom + center_y
            
            # Initial conditions
            c = complex(x, y)
            z = 0j
            
            # Main iteration
            for n in range(max_iter):
                if abs(z) > 2:
                    result[i, j] = n  # Store iteration count for coloring
                    break
                z = z*z + c
    
    return result

class MandelbrotVisualizer:
    def __init__(self, width=640, height=360, preview_mode=False):
        # Core dimensions and quality settings
        self.width = width // (2 if preview_mode else 1)  # Half resolution for preview
        self.height = height // (2 if preview_mode else 1)
        self.max_iter = 20 if preview_mode else 50
        
        # Visualization parameters
        self.center_x = -0.7453  # Interesting Mandelbrot region
        self.center_y = 0.1127
        self.zoom_start = 1.8
        self.zoom_speed = 0.98
        self.rotation_speed = 0.1
        
        # Generate initial color lookup tables
        self._init_colors()
    
    def _init_colors(self):
        """Initialize psychedelic color mapping tables"""
        self.color_tables = np.zeros((3, 256), dtype=np.uint8)
        for i in range(256):
            # Create smooth, cyclical color transitions
            self.color_tables[0, i] = int(255 * (0.5 + 0.5 * np.sin(i * 0.1)))        # Red
            self.color_tables[1, i] = int(255 * (0.5 + 0.5 * np.sin(i * 0.1 + 2.094))) # Green
            self.color_tables[2, i] = int(255 * (0.5 + 0.5 * np.sin(i * 0.1 + 4.189))) # Blue
    
    def create_frame(self, zoom, rotation, frame_number):
        """Generate a single frame of the visualization"""
        # Calculate base Mandelbrot set
        mandel = calculate_mandelbrot(
            self.width, self.height, self.max_iter,
            self.center_x, self.center_y, zoom, rotation
        )
        
        # Create color mapping
        color_idx = (mandel + frame_number) % 256
        frame = np.zeros((self.height, self.width, 3), dtype=np.uint8)
        
        # Apply color tables
        for i in range(3):
            frame[:, :, i] = self.color_tables[i, color_idx]
        
        return frame