import requests
from bs4 import BeautifulSoup
import json

# Load cookies from a file
def load_cookies(cookie_file):
    with open(cookie_file, 'r') as f:
        cookies = json.load(f)
    return cookies

# Add cookies to the session
def add_cookies_to_session(session, cookies):
    for cookie in cookies:
        session.cookies.set(cookie['name'], cookie['value'])

def get_library(session, base_url):
    """Navigate to the user's library."""
    library_url = f"{base_url}/library"
    response = session.get(library_url)
    if response.status_code == 200:
        print("Library accessed successfully.")
        return response.text
    else:
        print("Failed to access library.")
        return None

def parse_library(html):
    """Parse library HTML and retrieve track links."""
    soup = BeautifulSoup(html, 'html.parser')
    tracks = soup.find_all('a', class_='track-link')  # Adjust class name as needed
    print(f"Found {len(tracks)} tracks in the library.")
    return [track['href'] for track in tracks]

def download_track(session, track_url, filename):
    """Download a single track."""
    response = session.get(track_url, stream=True)
    if response.status_code == 200:
        with open(filename, 'wb') as f:
            for chunk in response.iter_content(1024):
                f.write(chunk)
        print(f"Downloaded {filename}.")
    else:
        print(f"Failed to download {filename}.")

# Main script
if __name__ == "__main__":
    # Path to the cookie file exported from the browser
    cookie_file = "cookies.json"
    base_url = "https://suno.com"

    # Initialize session
    session = requests.Session()

    # Load and set cookies
    cookies = load_cookies(cookie_file)
    add_cookies_to_session(session, cookies)

    # Access library
    library_html = get_library(session, base_url)
    if library_html:
        track_links = parse_library(library_html)
        if track_links:
            first_track_url = f"{base_url}{track_links[0]}"
            download_track(session, first_track_url, "track1.mp3")
