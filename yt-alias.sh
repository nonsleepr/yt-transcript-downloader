__yt() {
  if [ -z "$1" ]; then
    echo "Usage: yt [--ts] <youtube_url>"
    return 1
  fi

  local ts=false
  local youtube_url=""

  if [ "$1" = "--ts" ]; then
    ts=true
    youtube_url="$2"
  else
    youtube_url="$1"
  fi

  local video_id=$(echo "$youtube_url" | grep -oP '(?<=v=|youtu\.be/)[\w-]{11}')

  local transcript="/tmp/transcript_$video_id.en.vtt"

  if [ ! -f "$transcript" ]; then
    yt-dlp --quiet --no-warnings \
          --skip-download \
          --write-subs --write-auto-subs \
          --sub-lang en --sub-format ttml \
          --convert-subs vtt \
          --output "/tmp/transcript_%(id)s" \
          "$youtube_url" >&2
  fi
  if [ "$ts" = true ]; then
    tail -n +2 "$transcript"
  else
    rg -Nv -e '^$' -e '\-->' "$transcript" | tail -n +2
  fi
};
__yt
