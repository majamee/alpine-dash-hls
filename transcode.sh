#!/bin/sh

input_file="${1?Input file missing}"
# directoryname=$(dirname "${input_file}")
filename=$(basename "${input_file}")
filename="${filename%.*}"
frames=$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 "${input_file}")

# make folders
echo -e "\nCurrent video: ${input_file}\nDetected file name: ${filename}\nTotal # of frames: ${frames}";
mkdir -p "output/${filename}/";

if [[ -z "$2" ]]; then
  mkdir -p "output/${filename}/thumbnails";
  # Create Video Preview thumbnails
  /bin/webvtt.sh "${input_file}";

  # Create Video Poster (from second 3)
  echo -e "\nCreating Video Poster (from second 3)" && \
  ffmpeg -y -v error -i "${input_file}" -ss 00:00:03 -qscale:v 3 -frames:v 1 "output/${filename}/thumbnails/poster.jpg";
else
  if [ $2 != "--transcode-only" ]; then
    mkdir -p "output/${filename}/thumbnails";
    # Create Video Preview thumbnails
    /bin/webvtt.sh "${input_file}";

    # Create Video Poster (from second 3)
    echo -e "\nCreating Video Poster (from second 3)" && \
    ffmpeg -y -v error -i "${input_file}" -ss 00:00:03 -qscale:v 3 -frames:v 1 "output/${filename}/thumbnails/poster.jpg";
  else
    echo -e "\nTranscode only selected: No HTML and image files will be created.";
  fi
fi

echo -e "\nCreating MPEG-DASH files" && \
# 1080p@CRF22
echo -e "Total # of frames: ${frames}\n\nCreating Full HD version (no upscaling, Step 1/4)" && \
ffmpeg -y -threads 0 -v error -stats -i "${input_file}" -an -c:v libx264 -x264opts 'keyint=24:min-keyint=24:no-scenecut' -profile:v high -level 4.0 -vf "scale=min'(1920,iw)':-4" -crf 22 -movflags faststart -write_tmcd 0 "output/${filename}/intermed_1080p.mp4" && \
# 720p@CRF22
echo -e "Creating HD version (no upscaling, Step 2/4)" && \
ffmpeg -y -threads 0 -v error -stats -i "${input_file}" -an -c:v libx264 -x264opts 'keyint=24:min-keyint=24:no-scenecut' -profile:v high -level 4.0 -vf "scale=min'(1280,iw)':-4" -crf 22 -movflags faststart -write_tmcd 0 "output/${filename}/intermed_720p.mp4" && \
# 480p@CRF22
echo -e "Creating DVD quality version (no upscaling, Step 3/4)" && \
ffmpeg -y -threads 0 -v error -stats -i "${input_file}" -an -c:v libx264 -x264opts 'keyint=24:min-keyint=24:no-scenecut' -profile:v high -level 4.0 -vf "scale=min'(720,iw)':-4" -crf 22 -movflags faststart -write_tmcd 0 "output/${filename}/intermed_480p.mp4" && \
# 128k AAC audio only
echo -e "Creating audio only version (Step 4/4)" && \
ffmpeg -y -threads 0 -v error -stats -i "${input_file}" -vn -c:a aac -b:a 128k "output/${filename}/audio_128k.m4a" && \

# Create MPEG-DASH files (segments & mpd-playlist)
echo -e "\nCreating MPEG-DASH files & MPD-playlist" && \
MP4Box -dash 2000 -rap -frag-rap -url-template -dash-profile onDemand -segment-name 'segment_$RepresentationID$' -out "output/${filename}/playlist.mpd" "output/${filename}/intermed_1080p.mp4" "output/${filename}/intermed_720p.mp4" "output/${filename}/intermed_480p.mp4" "output/${filename}/audio_128k.m4a" && \

# Create HLS playlists for each quality level
echo -e "\nCreating HLS files (needed for Safari on iOS, Safari on Mac is already compatible with MPEG-DASH files)" && \
echo -e "Total # of frames: ${frames}\n\nCreating Full HD version (no upscaling, Step 1/4)" && \
ffmpeg -y -threads 0 -v error -stats -i "output/${filename}/intermed_1080p.mp4" -i "output/${filename}/audio_128k.m4a" -map 0:v:0 -map 1:a:0 -shortest -acodec copy -vcodec copy -hls_time 2 -hls_list_size 0 -hls_flags single_file "output/${filename}/segment_1.m3u8" && \
echo -e "Creating HD version (no upscaling, Step 2/4)" && \
ffmpeg -y -threads 0 -v error -stats -i "output/${filename}/intermed_720p.mp4" -i "output/${filename}/audio_128k.m4a" -map 0:v:0 -map 1:a:0 -shortest -acodec copy -vcodec copy -hls_time 2 -hls_list_size 0 -hls_flags single_file "output/${filename}/segment_2.m3u8" && \
echo -e "Creating DVD quality version (no upscaling, Step 3/4)" && \
ffmpeg -y -threads 0 -v error -stats -i "output/${filename}/intermed_480p.mp4" -i "output/${filename}/audio_128k.m4a" -map 0:v:0 -map 1:a:0 -shortest -acodec copy -vcodec copy -hls_time 2 -hls_list_size 0 -hls_flags single_file "output/${filename}/segment_3.m3u8" && \
echo -e "Creating audio only version (Step 4/4)" && \
ffmpeg -y -threads 0 -v error -stats -i "output/${filename}/audio_128k.m4a" -acodec copy -vcodec copy -hls_time 2 -hls_list_size 0 -hls_flags single_file "output/${filename}/segment_4.m3u8" && \

# Transform MPD-Master-Playlist to M3U8-Master-Playlist
echo -e "\nCreating master M3U8-playlist for HLS" && \
xsltproc --stringparam run_id "segment" /app/mpd-to-m3u8/mpd_to_hls.xsl "output/${filename}/playlist.mpd" > "output/${filename}/playlist.m3u8" && \

# Cleanup
echo -e "\nCleanup of intermediary files" && \
rm "output/${filename}/intermed_1080p.mp4" "output/${filename}/intermed_720p.mp4" "output/${filename}/intermed_480p.mp4" "output/${filename}/audio_128k.m4a";

# Add HTML code for easy inclusion in website
if [[ -z "$2" ]]; then
  echo -e "\nAdd HTML files for playback to output folder";
  cp /app/src/htaccess "output/${filename}/.htaccess";
  ln -s .htaccess "output/${filename}/symbolic_link.htaccess";
  cp /app/src/index.html "output/${filename}/index.html";
  cp /app/src/plyr.html "output/${filename}/plyr.html";
  cp /app/src/fluid-player.html "output/${filename}/fluid-player.html";
  cp /app/src/videogular.html "output/${filename}/videogular.html";
  cp /app/src/videojs.html "output/${filename}/videojs.html";
else
  if [ $2 != "--transcode-only" ]; then
    echo -e "\nAdd HTML files for playback to output folder";
    cp /app/src/htaccess "output/${filename}/.htaccess";
    ln -s .htaccess "output/${filename}/symbolic_link.htaccess";
    cp /app/src/index.html "output/${filename}/index.html";
    cp /app/src/plyr.html "output/${filename}/plyr.html";
    cp /app/src/fluid-player.html "output/${filename}/fluid-player.html";
    cp /app/src/videogular.html "output/${filename}/videogular.html";
    cp /app/src/videojs.html "output/${filename}/videojs.html";
  fi
fi

# Set permissions for newly created files and folders matching the video file's permissions
echo -e "\nSetting permissions for all created files and folders & finishing";
chown -R `stat -c "%u:%g" "${input_file}"` output;
