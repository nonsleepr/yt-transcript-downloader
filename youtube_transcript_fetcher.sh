#!/usr/bin/env bash

fetch_transcript() {
    local video_url="$1"
    local video_id=$(echo "$video_url" | grep -oP '(?<=v=|youtu\.be/)[\w-]{11}')
    local cache_file="/tmp/transcript_${video_id}"

    if [ -f "$cache_file" ]; then
        cat "$cache_file"
        return
    fi

    # Fetch video metadata
    local metadata=$(yt-dlp --dump-json "$video_url")

    # Extract relevant information
    local title=$(echo "$metadata" | jq -r '.title')
    local description=$(echo "$metadata" | jq -r '.description')
    local chapters=$(echo "$metadata" | jq -r '.chapters')

    # Fetch transcript
    local transcript_url=$(echo "$metadata" | jq -r '.automatic_captions."en-orig"[] | select(.ext=="vtt") | .url')
    local transcript=$(curl -s "$transcript_url")

    # Process transcript
    local processed_transcript=$(echo "$transcript" | awk '
        BEGIN {in_caption=0; prev_time=""}
        /^[0-9]/ {
            if (in_caption) {
                in_caption=0
                print ""
            }
            split($1, start_time, ":")
            start_seconds = start_time[1] * 3600 + start_time[2] * 60 + start_time[3]
            if (start_seconds - prev_time >= 300) {
                chapter_count++
                print "### Chapter " chapter_count
            }
            prev_time = start_seconds
            next
        }
        !/^WEBVTT|^Kind:|^Language:/ && !/<[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}>/ {
            if (!in_caption) {
                in_caption=1
                printf "%s ", $0
            }
        }
    ')

    # Generate output in Markdown format
    cat << EOF > "$cache_file"
# $title

- [Video URL]($video_url)

## Description

> $description

## Transcript

$processed_transcript
EOF

    cat "$cache_file"
}

# Main script
if [ $# -eq 0 ]; then
    echo "Usage: $0 <youtube_url>"
    exit 1
fi

fetch_transcript "$1"
