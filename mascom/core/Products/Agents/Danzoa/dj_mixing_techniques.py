import numpy as np
from pydub import AudioSegment
import librosa
import random
import logging
import io

logger = logging.getLogger(__name__)

class DJMixingTechniques:
    @staticmethod
    def safe_audio_conversion(samples, frame_rate, sample_width, channels):
        """
        Safely convert numpy array to AudioSegment
        """
        try:
            # Ensure samples are int16
            samples_int16 = np.clip(samples, -32768, 32767).astype(np.int16)
            
            # Ensure length is multiple of sample_width * channels
            remainder = len(samples_int16) % (sample_width * channels)
            if remainder:
                samples_int16 = samples_int16[:-(remainder)]
            
            return AudioSegment(
                samples_int16.tobytes(),
                frame_rate=frame_rate,
                sample_width=sample_width,
                channels=channels
            )
        except Exception as e:
            logger.error(f"Audio conversion error: {e}")
            return None

    @staticmethod
    def crossfade_transition(segment1, segment2):
        try:
            # Ensure both segments are valid
            if not segment1 or not segment2:
                logger.warning("Invalid segments for crossfade")
                return segment1 or segment2
            
            return segment1.append(
                segment2, 
                crossfade=min(len(segment1), len(segment2), 5000)
            )
        except Exception as e:
            logger.error(f"Crossfade transition error: {e}")
            return segment1 + segment2 if segment1 and segment2 else segment1 or segment2

    @staticmethod
    def spectral_blend(segment1, segment2):
        try:
            # Convert segments to numpy arrays
            samples1 = np.array(segment1.get_array_of_samples())
            samples2 = np.array(segment2.get_array_of_samples())
            
            # Ensure equal length by padding
            max_length = max(len(samples1), len(samples2))
            samples1 = np.pad(samples1, (0, max_length - len(samples1)), mode='constant')
            samples2 = np.pad(samples2, (0, max_length - len(samples2)), mode='constant')
            
            # Blend samples
            blend_factor = random.uniform(0.3, 0.7)
            blended_samples = (
                samples1 * (1 - blend_factor) + 
                samples2 * blend_factor
            )
            
            # Safe audio conversion
            blended_audio = DJMixingTechniques.safe_audio_conversion(
                blended_samples, 
                segment1.frame_rate, 
                segment1.sample_width, 
                segment1.channels
            )
            
            return blended_audio or (segment1 + segment2)
        except Exception as e:
            logger.error(f"Spectral blend error: {e}")
            return segment1 + segment2

    @staticmethod
    def rhythmic_morph(segment1, segment2):
        try:
            # Load audio files
            bytes_io1 = io.BytesIO()
            segment1.export(bytes_io1, format="wav")
            bytes_io1.seek(0)
            
            bytes_io2 = io.BytesIO()
            segment2.export(bytes_io2, format="wav")
            bytes_io2.seek(0)
            
            y1, sr1 = librosa.load(bytes_io1, sr=None, mono=True)
            y2, sr2 = librosa.load(bytes_io2, sr=None, mono=True)
            
            # Detect beats
            _, beat_frames1 = librosa.beat.beat_track(y=y1, sr=sr1)
            _, beat_frames2 = librosa.beat.beat_track(y=y2, sr=sr2)
            
            # Create morphed rhythm
            max_length = max(len(y1), len(y2))
            morphed_rhythm = np.zeros(max_length)
            
            for i in range(min(len(beat_frames1), len(beat_frames2))):
                if i < len(beat_frames1) and beat_frames1[i] < len(morphed_rhythm):
                    morphed_rhythm[int(beat_frames1[i])] += y1[int(beat_frames1[i])]
                if i < len(beat_frames2) and beat_frames2[i] < len(morphed_rhythm):
                    morphed_rhythm[int(beat_frames2[i])] += y2[int(beat_frames2[i])]
            
            # Normalize safely
            max_val = np.max(np.abs(morphed_rhythm))
            if max_val > 0:
                morphed_rhythm /= max_val
            
            # Safe audio conversion
            morphed_audio = DJMixingTechniques.safe_audio_conversion(
                morphed_rhythm * 32767, 
                sr1, 
                2,  # 16-bit 
                1   # mono
            )
            
            return morphed_audio or (segment1 + segment2)
        except Exception as e:
            logger.error(f"Rhythmic morph error: {e}")
            return segment1 + segment2

    @staticmethod
    def pitch_warp(segment1, segment2):
        try:
            # Convert to numpy arrays
            samples1 = np.array(segment1.get_array_of_samples())
            
            # Pitch shift factor
            pitch_factor = random.uniform(0.8, 1.2)
            
            # Interpolate samples
            warped_samples = np.interp(
                np.linspace(0, len(samples1), int(len(samples1) * pitch_factor)), 
                np.arange(len(samples1)), 
                samples1
            )
            
            # Safe audio conversion
            warped_audio = DJMixingTechniques.safe_audio_conversion(
                warped_samples, 
                int(segment1.frame_rate * pitch_factor), 
                segment1.sample_width, 
                segment1.channels
            )
            
            return (warped_audio or segment1) + segment2
        except Exception as e:
            logger.error(f"Pitch warp error: {e}")
            return segment1 + segment2

    @staticmethod
    def quantum_blend(segment1, segment2):
        try:
            # Convert to numpy arrays
            samples1 = np.array(segment1.get_array_of_samples())
            samples2 = np.array(segment2.get_array_of_samples())
            
            # Ensure equal length
            max_length = max(len(samples1), len(samples2))
            samples1 = np.pad(samples1, (0, max_length - len(samples1)), mode='constant')
            samples2 = np.pad(samples2, (0, max_length - len(samples2)), mode='constant')
            
            # Quantum-inspired blending
            quantum_wave = np.sin(np.linspace(0, np.pi, max_length))
            
            quantum_blend = (
                samples1 * (1 - quantum_wave) + 
                samples2 * quantum_wave
            )
            
            # Safe audio conversion
            blended_audio = DJMixingTechniques.safe_audio_conversion(
                quantum_blend, 
                segment1.frame_rate, 
                segment1.sample_width, 
                segment1.channels
            )
            
            return blended_audio or (segment1 + segment2)
        except Exception as e:
            logger.error(f"Quantum blend error: {e}")
            return segment1 + segment2

    @classmethod
    def get_all_techniques(cls):
        return [
            cls.crossfade_transition,
            cls.spectral_blend,
            cls.rhythmic_morph,
            cls.pitch_warp,
            cls.quantum_blend
        ]