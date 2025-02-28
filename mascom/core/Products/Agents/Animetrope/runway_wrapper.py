import os
import sys
import requests

# Function to call RunwayML API
def generate_video(api_key, image_uri, prompt):
    api_endpoint = 'https://api.runwayml.com/v1/generate_video'
    headers = {'Authorization': f'Bearer {api_key}'}
    payload = {
        'assets': [{'url': image_uri, 'content_type': 'image/jpg'}],
        'script': prompt
    }
    response = requests.post(api_endpoint, headers=headers, json=payload)
    return response.json()

if __name__ == "__main__":
    api_key = os.getenv('RUNWAYML_API_SECRET')
    image_uri = sys.argv[1]
    prompt = sys.argv[2]
    result = generate_video(api_key, image_uri, prompt)
    print(result)
