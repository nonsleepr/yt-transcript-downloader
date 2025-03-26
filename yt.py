#!/usr/bin/env python3

import os
import sys
import re
import subprocess
import json
import xml.etree.ElementTree as ET
import html
from urllib import request
from urllib.parse import urlparse, parse_qs

def extract_video_id(url):
    """Extract the video ID from YouTube URL or youtu.be shortlink using regex."""
    match = re.search(r'(?:v=|youtu\.be/)([\w-]{11})', url)
    return match.group(1) if match else None

def fetch_transcript(video_url):
    # Extract video ID
    video_id = extract_video_id(video_url)
    if not video_id:
        print("Invalid YouTube URL.")
        return

    cache_file = f"/tmp/transcript_{video_id}"

    # Check if cache file exists
    if os.path.isfile(cache_file):
        with open(cache_file, 'r') as file:
            print(file.read())
        return

    # Fetch video metadata using yt-dlp
    result = subprocess.run(['yt-dlp', '--dump-json', video_url], stdout=subprocess.PIPE, text=True)
    metadata = json.loads(result.stdout)  # Safely parse JSON

    # Extract relevant information
    title = metadata.get('title', 'Unknown Title')
    description = metadata.get('description', 'No description available.')
    chapters = metadata.get('chapters') or []

    # Fetch TTML transcript URL
    automatic_captions = metadata.get('automatic_captions', {})
    captions = automatic_captions.get('en-orig') or automatic_captions.get('en', [])
    transcript_url = next((item['url'] for item in captions if item['ext'] == 'ttml'), None)

    if not transcript_url:
        print("No TTML captions found.")
        return

    # Download the TTML transcript
    response = request.urlopen(transcript_url)
    ttml_data = response.read().decode('utf-8')

    # Parse the TTML and extract captions
    root = ET.fromstring(ttml_data)
    namespace = {'ttml': 'http://www.w3.org/ns/ttml'}

    captions_list = []
    for p in root.findall('.//ttml:p', namespace):
        begin = p.attrib.get('begin', '')
        end = p.attrib.get('end', '')
        text = "".join(p.itertext())  # Extract the text from the <p> tag and its children
        text = html.unescape(text)    # Decode HTML/XML entities
        captions_list.append((begin, end, text.strip()))

    # Process chapters
    chapter_data = [(chapter['start_time'], chapter['title']) for chapter in chapters]

    # Format transcript with chapters
    transcript = []
    chapter_index = 0
    if chapter_data:
        transcript.append(f"### 1. {chapter_data[0][1]}")

    for begin, _, text in captions_list:
        begin_seconds = sum(float(x) * 60 ** i for i, x in enumerate(reversed(begin.split(':'))))
        while chapter_index + 1 < len(chapter_data) and begin_seconds >= chapter_data[chapter_index + 1][0]:
            chapter_index += 1
            transcript.append(f"\n### {chapter_index + 1}. {chapter_data[chapter_index][1]}")

        transcript.append(text)

    # Generate output in Markdown format
    output = f"# {title}\n\n- [Video URL]({video_url})\n\n## Description\n\n> {description}\n\n## Transcript\n\n" + "\n".join(transcript)

    # Write to cache file
    with open(cache_file, 'w') as file:
        file.write(output)

    # Print the transcript
    print(output)

# Main script
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: yt <youtube_url>")
        sys.exit(1)

    video_url = sys.argv[1]
    fetch_transcript(video_url)

