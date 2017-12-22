[![](https://images.microbadger.com/badges/version/majamee/alpine-dash-hls.svg)](https://microbadger.com/images/majamee/alpine-dash-hls) [![](https://images.microbadger.com/badges/image/majamee/alpine-dash-hls.svg)](https://microbadger.com/images/majamee/alpine-dash-hls) [![Docker Automated build](https://img.shields.io/docker/automated/majamee/alpine-dash-hls.svg)]() [![Docker Build Status](https://img.shields.io/docker/build/majamee/alpine-dash-hls.svg)]() | [![Docker Stars](https://img.shields.io/docker/stars/majamee/alpine-dash-hls.svg?style=social)]() [![Docker Pulls](https://img.shields.io/docker/pulls/majamee/alpine-dash-hls.svg?style=social)]()

# alpine-dash-hls
A ready-prepared video transcoding pipeline to create DASH/ HLS compatible video files &amp; playlists.

Recommended usage via Docker [Kitematic](https://kitematic.com/) & [Docker Hub](https://hub.docker.com/r/majamee/alpine-dash-hls/).

# Simplified usage (run in shell/ terminal/ cmd)
Prerequisite: [Docker](https://www.docker.com/) needs to be installed and running.
```sh
docker pull majamee/alpine-dash-hls
docker run -v /absolute/path/to/video/:/video majamee/alpine-dash-hls name_of_my_video_file.ext
```
Please just replace in the command above the absolute path to your video file folder and the full file name of your video file to be converted.

## Examplary toolchain usage
(Based on work of [squidpickles](https://github.com/squidpickles))

Just use Kitematic to open the shared folder, place your video file in there, replace `"input.mkv"` in the commands below by your input video file (without `""`) and execute the shell commands subsequent into the Docker container.
```sh
# 1080p@CRF22
ffmpeg -y -threads 4 -i "input.mkv" -an -c:v libx264 -x264opts 'keyint=24:min-keyint=24:no-scenecut' -profile:v high -level 4.0 -vf "scale=min'(1920,iw)':-4" -crf 22 -movflags faststart -write_tmcd 0 intermed_1080p.mp4
# 720p@CRF22
ffmpeg -y -threads 4 -i "input.mkv" -an -c:v libx264 -x264opts 'keyint=24:min-keyint=24:no-scenecut' -profile:v high -level 4.0 -vf "scale=min'(1280,iw)':-4" -crf 22 -movflags faststart -write_tmcd 0 intermed_720p.mp4
# 480p@CRF22
ffmpeg -y -threads 4 -i "input.mkv" -an -c:v libx264 -x264opts 'keyint=24:min-keyint=24:no-scenecut' -profile:v high -level 4.0 -vf "scale=min'(720,iw)':-4" -crf 22 -movflags faststart -write_tmcd 0 intermed_480p.mp4
# 128k AAC audio only
ffmpeg -y -threads 4 -i "input.mkv" -vn -c:a aac -b:a 128k audio_128k.m4a

# Create MPEG-DASH files (segments & mpd-playlist)
MP4Box -dash 2000 -rap -frag-rap -url-template -dash-profile onDemand -segment-name 'segment_$RepresentationID$' -out playlist.mpd intermed_1080p.mp4 intermed_720p.mp4 intermed_480p.mp4 audio_128k.m4a

# Create HLS playlists for each quality level
ffmpeg -i intermed_1080p.mp4 -i audio_128k.m4a -map 0:v:0 -map 1:a:0 -shortest -acodec copy -vcodec copy -hls_time 2 -hls_list_size 0 -hls_flags single_file segment_1.m3u8
ffmpeg -i intermed_720p.mp4 -i audio_128k.m4a -map 0:v:0 -map 1:a:0 -shortest -acodec copy -vcodec copy -hls_time 2 -hls_list_size 0 -hls_flags single_file segment_2.m3u8
ffmpeg -i intermed_480p.mp4 -i audio_128k.m4a -map 0:v:0 -map 1:a:0 -shortest -acodec copy -vcodec copy -hls_time 2 -hls_list_size 0 -hls_flags single_file segment_3.m3u8
ffmpeg -i audio_128k.m4a -acodec copy -vcodec copy -hls_time 2 -hls_list_size 0 -hls_flags single_file segment_4.m3u8

# Transform MPD-Master-Playlist to M3U8-Master-Playlist
xsltproc --stringparam run_id "segment" /app/mpd-to-m3u8/mpd_to_hls.xsl playlist.mpd > playlist.m3u8
```

I am glad to receive any improvement ideas about this "any video to DASH/ HLS" pipeline. 
Especially if someone has any input on integrating better [Apple's support of fragemented mp4 (fmp4) files](https://gpac.wp.imt.fr/tag/hls-fmp4/) in this pipeline.

Suggestions welcome. :)

## General hints for hosting the files (to test streaming)
* Video and playlist files should be hosted best via HTTPS
* DASH requires the .mpd playlist to be set as `Content-Type: application/dash+xml`
* No specific streaming server is required, but your hosting should have progressive downloading enabled
* If using a different domain name for the video files compared to the page where the player is hosted CORS headers need to be set

## Tools to test the generated files for streaming
* HLS (e.g. Safari on Mac OS X): https://videojs.github.io/videojs-contrib-hls/ (use the .m3u8 master-playlist)
* DASH (e.g. Firefox/ Chrome): http://reference.dashif.org/dash.js/ (use the latest released version & the .mpd playlist)

# Features
* Creates DASH (VOD) compatible files (including Safari on Mac)
* Creates HLS files for compatibility with Safari on iOS
* Optimizes video files for web playback (`moov` atom)
* Compresses videos using H.264@CRF22 (for best compatibility)
* Compresses audio using AAC@128k (for DASH as separate track to save data)
* Creates automatically 3 quality levels (Full HD/ HD/ DVD quality)
* Fragments video files in 2 second windows to allow dynamic quality switching based on available bandwidth
* Creates master MPD-Playlist which connects everything (MPEG-DASH)
* Creates master M3U8-Playlist for HLS
* Creates all output files neatly stored in a sub-folder matching the video file name in the folder `output` next to the transcoded video file
* Adds also HTML and `.htaccess` file including code ready for inclusion into the own website for playback next to all other created files
* Included fallback player (`plyr.html`) is based on the great work of the guys at [Plyr](https://plyr.io/) 
* Included player (`index.html`) is based on the great work of the guys at [Video.js](http://videojs.com/) 
