# YouTube Transcript Fetcher

This tool uses `yt-dlp` to fetch the transcript of a video.
Apart from the transcript it also fetches the video title, description and chapters information.

Here are the paths to the fields of interest in the JQ notation obtained with `yt-dlp --dump-json <video url>`:
- `.title` - video title
- `.description` - video description
- `.chapters` - list of chapters, each one is a dictionary containing:
    - `start_time` - start time in seconds
    - `end_time` - end time in seconds
    - `title` - chapter title
- `.automatic_captions."en-orig"` - list of captions in various formats, each one is a dictionary containing:
    - `ext` - format of the caption (e.g., json3, srv3, ttml, vtt)
    - `url` - URL to the caption file
    - `name` - name of the caption (e.g., English (Original))

Transcript is fetched using `curl`.

## Transcript Format

The tool retrieves the transcript in a `vtt` format.

The VTT file has a header followed by timestamps and captions.
The timestamps are in the format `HH:MM:SS.MMM` (e.g., 12:47:06.000).

Each caption block stars with start and end timestamps separated by `-->`.
The second line of a caption block contains the already shown caption.
The next line(s) contain the caption about to be shown surrounded by tags. We are not interested in those.

Example of a VTT transcript file:
```vtt
WEBVTT
Kind: captions
Language: en

00:00:05.000 --> 00:00:08.430 align:start position:0%

hi<00:00:05.720><c> welcome</c><00:00:06.000><c> to</c><00:00:06.240><c> another</c><00:00:07.000><c> video</c><00:00:08.000><c> I've</c><00:00:08.160><c> already</c>

00:00:08.430 --> 00:00:08.440 align:start position:0%
hi welcome to another video I've already
 

00:00:08.440 --> 00:00:11.110 align:start position:0%
hi welcome to another video I've already
covered<00:00:08.800><c> some</c><00:00:09.000><c> cursor</c><00:00:09.440><c> Alternatives</c><00:00:10.160><c> like</c><00:00:10.759><c> z</c>

00:00:11.110 --> 00:00:11.120 align:start position:0%
covered some cursor Alternatives like z
 

00:00:11.120 --> 00:00:15.829 align:start position:0%
covered some cursor Alternatives like z
a<00:00:12.080><c> VSS</c><00:00:12.559><c> code</c><00:00:12.840><c> Claud</c><00:00:13.240><c> Dev</c><00:00:14.040><c> vs</c><00:00:14.480><c> code</c><00:00:14.759><c> AER</c><00:00:15.599><c> and</c><00:00:15.759><c> a</c>

```

## Output

The output is in a Markdown format with the following structure:
```markdown
# Video Title

- [Video URL](https://www.youtube.com/watch?v=VIDEO_ID)

## Description

> Video Description

## Transcript

> Text of a video transcript with sections/chapters denoted as 3-rd level headings.
```

## Caching

The output is cached in the files like `/tmp/transcript_<video_id>`. If the file exists, it will be used instead of generating new one.