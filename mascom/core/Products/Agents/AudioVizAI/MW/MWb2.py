import pygame
import numpy as np
from numba import jit
import time

@jit(nopython=True, fastmath=True)
def calculate_mandelbrot(width, height, max_iter, center_x, center_y, zoom, rotation):
    """Optimized Mandelbrot calculation with zoom and rotation support"""
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

class MandelbrotVisualizer:
    def __init__(self, width=640, height=360, preview_mode=False):
        self.width = width // (2 if preview_mode else 1)
        self.height = height // (2 if preview_mode else 1)
        self.max_iter = 20 if preview_mode else 50
        
        self.center_x = -0.7453
        self.center_y = 0.1127
        self.zoom_start = 1.8
        self.zoom_speed = 0.98
        self.rotation_speed = 0.1
        
        self._init_colors()
    
    def _init_colors(self):
        self.color_tables = np.zeros((3, 256), dtype=np.uint8)
        for i in range(256):
            self.color_tables[0, i] = int(255 * (0.5 + 0.5 * np.sin(i * 0.1)))
            self.color_tables[1, i] = int(255 * (0.5 + 0.5 * np.sin(i * 0.1 + 2.094)))
            self.color_tables[2, i] = int(255 * (0.5 + 0.5 * np.sin(i * 0.1 + 4.189)))
    
    def create_frame(self, zoom, rotation, frame_number):
        mandel = calculate_mandelbrot(
            self.width, self.height, self.max_iter,
            self.center_x, self.center_y, zoom, rotation
        )
        
        color_idx = (mandel + frame_number) % 256
        frame = np.zeros((self.height, self.width, 3), dtype=np.uint8)
        
        for i in range(3):
            frame[:, :, i] = self.color_tables[i, color_idx]
        
        return frame

def main():
    # Initialize pygame
    pygame.init()
    
    # Create display window
    width, height = 640, 360
    screen = pygame.display.set_mode((width, height))
    pygame.display.set_caption("Mandelbrot Wormhole Test")
    
    # Create visualizer
    visualizer = MandelbrotVisualizer(width, height)
    
    # Create surface for frame display
    surface = pygame.Surface((width, height))
    
    # Animation parameters
    zoom = visualizer.zoom_start
    rotation = 0
    frame_number = 0
    running = True
    clock = pygame.time.Clock()
    
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False
        
        # Create and display frame
        frame = visualizer.create_frame(zoom, rotation, frame_number)
        pygame.surfarray.blit_array(surface, frame)
        screen.blit(surface, (0, 0))
        pygame.display.flip()
        
        # Update parameters
        zoom *= visualizer.zoom_speed
        rotation += visualizer.rotation_speed
        frame_number += 1
        
        clock.tick(30)  # Limit to 30 FPS
    
    pygame.quit()

if __name__ == "__main__":
    main()