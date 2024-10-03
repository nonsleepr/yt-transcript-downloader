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
    local chapters=$(echo "$metadata" | jq -r '.chapters | map("\(.start_time)|\(.title)") | join("\n")')

    # Fetch TTML transcript
    local transcript_url=$(echo "$metadata" | jq -r '.automatic_captions."en-orig"[] | select(.ext=="ttml") | .url')
    local transcript=$(curl -s "$transcript_url")

    # Process TTML transcript and add chapters
    local processed_transcript=$(echo "$transcript" | awk -v chapters="$chapters" '
        BEGIN {
            split(chapters, chapter_array, "\n")
            chapter_count = length(chapter_array)
            for (i = 1; i <= chapter_count; i++) {
                split(chapter_array[i], chapter_data, "|")
                chapter_times[i] = chapter_data[1]
                chapter_titles[i] = chapter_data[2]
            }
            chapter_index = 1
            if (chapter_count > 0) {
                print "### 1. " chapter_titles[1]
            }
        }
        /<p begin=/ {
            match($0, /begin="([0-9:.]+)" end="([0-9:.]+)"/, time)
            gsub(/<\/?[^>]+(>|$)/, "", $0)  # Remove XML tags
            start_time = time[1]
            split(start_time, time_parts, ":")
            start_seconds = time_parts[1] * 3600 + time_parts[2] * 60 + time_parts[3]

            while (chapter_index < chapter_count && start_seconds >= chapter_times[chapter_index + 1]) {
                chapter_index++
                print "\n### " chapter_index ". " chapter_titles[chapter_index]
            }

            gsub(/^[[:space:]]+|[[:space:]]+$/, "")
            if ($0 != "") {
                if (caption != "") {
                    print caption
                    caption = ""
                }
                caption = caption " " $0
            }
        }
        END {
            if (caption != "") print caption
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

