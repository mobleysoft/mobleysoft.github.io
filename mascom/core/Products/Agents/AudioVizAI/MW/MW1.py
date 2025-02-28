import numpy as np
import cv2
import librosa
import pygame
from pathlib import Path
import threading
from numba import jit
import time
import colorsys

# Ensure pygame is initialized only once
if not pygame.get_init():
    pygame.init()
if not pygame.mixer.get_init():
    pygame.mixer.init()

# Set a default logging level (optional, for debugging)
import logging
logging.basicConfig(level=logging.INFO)
