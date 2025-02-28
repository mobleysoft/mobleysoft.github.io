import unittest
import os
import json
import numpy as np
from pydub import AudioSegment
import danzoa
import logging
import time
import shutil
import tempfile
import gc
import librosa
from unittest.mock import patch, MagicMock

class TestDanzoa(unittest.TestCase):
    def setUp(self):
        """Set up test environment before each test"""
        # Reset global state before each test
        danzoa.metadata = {}
        danzoa.cumulative_system_prompt = danzoa.initialization_string
        danzoa.cumulative_user_prompt = ""
        danzoa.remix = None
        
        # Ensure output directory exists
        os.makedirs(danzoa.OUTPUT_DIR, exist_ok=True)
        
        # Remove any existing output files
        for file in os.listdir(danzoa.OUTPUT_DIR):
            if file != '.gitkeep':
                try:
                    self.retry_remove(os.path.join(danzoa.OUTPUT_DIR, file))
                except Exception as e:
                    print(f"Warning: Could not remove {file}: {e}")

    def test_analyze_single_file(self):
        """Test metadata analysis on first available audio file"""
        files = [f for f in os.listdir(danzoa.UPLOAD_DIR) if f.endswith(('.mp3', '.wav'))]
        if not files:
            self.skipTest("No audio files found for testing")
        
        test_file = files[0]
        print(f"\nTesting metadata analysis with single file: {test_file}")
        
        with tempfile.TemporaryDirectory() as tmpdir:
            # Copy test file to temp directory
            src_path = os.path.join(danzoa.UPLOAD_DIR, test_file)
            tmp_path = os.path.join(tmpdir, test_file)
            shutil.copy2(src_path, tmp_path)
            
            # Analyze single file
            metadata = danzoa.analyze_metadata(tmpdir)
            
            # Verify metadata
            self.assertEqual(len(metadata), 1, "Should analyze exactly one file")
            self.assertIn(test_file, metadata, "Test file should be in metadata")
            
            data = metadata[test_file]
            print(f"\nMetadata for {test_file}:")
            print(f"BPM: {data['bpm']}")
            print(f"Duration: {data['duration']} seconds")
            print(f"Key: {data['key']}")
            print(f"Energy: {data['energy']}")
            
            # Validate metadata types and ranges
            self.assertIsInstance(data['bpm'], int, f"BPM should be integer, got {type(data['bpm'])}")
            self.assertTrue(20 <= data['bpm'] <= 200, f"BPM {data['bpm']} out of normal range (20-200)")
            self.assertIsInstance(data['duration'], float, f"Duration should be float, got {type(data['duration'])}")
            self.assertTrue(data['duration'] > 0, "Duration should be positive")
            self.assertIsInstance(data['key'], int, f"Key should be integer, got {type(data['key'])}")
            self.assertTrue(0 <= data['key'] <= 11, f"Key {data['key']} out of range (0-11)")
            self.assertIsInstance(data['energy'], float, f"Energy should be float, got {type(data['energy'])}")
            self.assertTrue(data['energy'] >= 0, "Energy should be positive")
            
            # Verify actual duration against metadata
            actual_duration = librosa.get_duration(path=tmp_path)
            self.assertAlmostEqual(data['duration'], actual_duration, delta=1.0,
                                 msg=f"Duration mismatch: metadata={data['duration']}, actual={actual_duration}")

    def test_error_handling(self):
        """Test error handling in various functions"""
        # Test invalid audio file
        with self.assertRaises(ValueError):
            danzoa.validate_audio_file("nonexistent.mp3")
            
        # Test invalid speed adjustment
        with self.assertRaises(ValueError):
            audio = AudioSegment.silent(duration=1000)
            danzoa.adjust_speed(audio, 3.0)  # Too fast
            
        # Test pattern validation with invalid patterns
        invalid_patterns = [
            [],  # Empty list
            [{}],  # Empty pattern
            [{"track": "test.mp3"}],  # Missing fields
            [{"track": "test.mp3", "transition": "invalid"}],  # Invalid transition
            [{"track": "test.mp3", "transition": "crossfade", "details": "not_dict"}]  # Invalid details
        ]
        for pattern in invalid_patterns:
            self.assertFalse(danzoa.validate_patterns(pattern))
            
        # Test OpenAI key validation
        if 'OPENAI_API_KEY' in os.environ:
            saved_key = os.environ['OPENAI_API_KEY']
            try:
                # Test with no key
                del os.environ['OPENAI_API_KEY']
                danzoa.metadata = {"test.mp3": {}}  # Add some metadata so the function continues
                self.assertEqual(danzoa.generate_patterns(), [], "Should return empty list when no API key")
            finally:
                # Always restore the key
                os.environ['OPENAI_API_KEY'] = saved_key

    def test_full_workflow(self):
        """Test the complete workflow with real files"""
        print("\nTesting full Danzoa workflow with real files...")
        
        # 1. Test analyze_metadata with real files
        print("\nAnalyzing metadata...")
        start_time = time.time()
        metadata = danzoa.analyze_metadata(danzoa.UPLOAD_DIR)
        analysis_time = time.time() - start_time
        
        # Verify metadata was generated
        self.assertTrue(len(metadata) > 0, "No metadata generated")
        print(f"\nAnalyzed {len(metadata)} files in {analysis_time:.2f} seconds")
        
        # Print and validate metadata for first few files
        for i, (file, data) in enumerate(list(metadata.items())[:3]):
            print(f"\nFile {i+1}: {file}")
            print(f"BPM: {data['bpm']}")
            print(f"Duration: {data['duration']} seconds")
            print(f"Key: {data['key']}")
            print(f"Energy: {data['energy']}")
            
            # Detailed metadata validation
            self.assertIsInstance(data['bpm'], int, f"BPM should be integer for {file}")
            self.assertTrue(20 <= data['bpm'] <= 200, f"BPM {data['bpm']} out of range for {file}")
            self.assertIsInstance(data['duration'], float, f"Duration should be float for {file}")
            self.assertTrue(data['duration'] > 0, f"Duration should be positive for {file}")
            self.assertIsInstance(data['key'], int, f"Key should be integer for {file}")
            self.assertTrue(0 <= data['key'] <= 11, f"Key {data['key']} out of range for {file}")
            self.assertIsInstance(data['energy'], float, f"Energy should be float for {file}")
            self.assertTrue(data['energy'] >= 0, f"Energy should be positive for {file}")
            
            # Additional duration verification
            if 'duration' in data:
                actual_duration = librosa.get_duration(path=os.path.join(danzoa.UPLOAD_DIR, file))
                self.assertAlmostEqual(data['duration'], actual_duration, delta=1.0,
                                     msg=f"Duration mismatch for {file}")

        if len(metadata) > 3:
            print(f"\n... and {len(metadata) - 3} more files")

        # Verify metadata file was saved
        metadata_file = os.path.join(danzoa.OUTPUT_DIR, "metadata.json")
        self.assertTrue(os.path.exists(metadata_file), "Metadata file not created")
        
        # Verify metadata file contents
        with open(metadata_file, 'r') as f:
            saved_metadata = json.load(f)
        self.assertEqual(metadata, saved_metadata, "Saved metadata doesn't match generated metadata")
        
        # Mock OpenAI for pattern generation
        with patch('openai.ChatCompletion.create') as mock_openai:
            mock_openai.return_value = {
                "choices": [{
                    "message": {
                        "content": json.dumps([{
                            "track": list(metadata.keys())[0],
                            "next_track": list(metadata.keys())[1] if len(metadata) > 1 else None,
                            "transition": "crossfade",
                            "details": {"fade_duration": 5}
                        }])
                    }
                }]
            }
            
            # 2. Test pattern generation
            print("\nGenerating mixing patterns...")
            patterns = danzoa.generate_patterns()
            self.assertTrue(patterns, "No patterns generated")
            
            # Print first few patterns
            for i, pattern in enumerate(patterns[:2]):
                print(f"\nPattern {i+1}:")
                print(f"Track: {pattern['track']}")
                print(f"Next Track: {pattern.get('next_track', 'None')}")
                print(f"Transition: {pattern['transition']}")
                print(f"Details: {pattern['details']}")
            
            if len(patterns) > 2:
                print(f"\n... and {len(patterns) - 2} more patterns")

            # 3. Test pattern validation
            print("\nValidating patterns...")
            valid = danzoa.validate_patterns(patterns)
            self.assertTrue(valid, "Pattern validation failed")

            # 4. Test mixing
            print("\nMixing tracks...")
            start_time = time.time()
            danzoa.mix_tracks(patterns)
            mixing_time = time.time() - start_time
            
            self.assertIsNotNone(danzoa.remix, "No remix was created")
            print(f"Mixing completed in {mixing_time:.2f} seconds")

            # 5. Test saving
            print("\nSaving final mix...")
            danzoa.save_remix()
            output_path = os.path.join(danzoa.OUTPUT_DIR, "final_mix.mp3")
            self.assertTrue(os.path.exists(output_path), "Final mix file not created")
            
            # Verify the output file
            output_audio = AudioSegment.from_file(output_path)
            duration_seconds = len(output_audio) / 1000
            self.assertTrue(duration_seconds > 0, "Output file is empty")
            print(f"Final mix saved: {output_path}")
            print(f"Mix duration: {duration_seconds:.2f} seconds")

    def retry_remove(self, file_path, max_attempts=3):
        """Retry file removal with timeout."""
        for attempt in range(max_attempts):
            try:
                os.remove(file_path)
                break
            except Exception as e:
                if attempt == max_attempts - 1:
                    raise
                time.sleep(0.1)

    def tearDown(self):
        """Clean up after each test"""
        try:
            # Clean up output directory
            for file in os.listdir(danzoa.OUTPUT_DIR):
                if file != '.gitkeep':
                    file_path = os.path.join(danzoa.OUTPUT_DIR, file)
                    self.retry_remove(file_path)
            
            # Force garbage collection
            gc.collect()
            
        except Exception as e:
            print(f"Error in tearDown: {e}")

if __name__ == "__main__":
    unittest.main(verbosity=2)