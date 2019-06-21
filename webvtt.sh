#!/bin/bash

# Text formatting details @https://misc.flogisoft.com/bash/tip_colors_and_formatting
# Reset
Color_Off='\e[0m'         # Text Reset

# Regular Colors
Black='\e[0;30m'          # Black
Red='\e[0;31m'            # Red
Green='\e[0;32m'          # Green
Yellow='\e[0;33m'         # Yellow
Blue='\e[0;34m'           # Blue
Purple='\e[0;35m'         # Purple
Cyan='\e[0;36m'           # Cyan
White='\e[0;37m'          # White

# Bold
Bold='\e[1m'               # Bold on
Bold_Off='\e[21m'          # Bold off

# Underline
Underline='\e[4m'          # Underline on
Underline_Off='\e[24m'     # Underline off

# Blinking
Blinking='\e[5m'          # Blinking on
Blinking_Off='\e[25m'     # Blinking off

# Reverse
Reverse='\e[7m'           # Reverse on
Reverse_Off='\e[27m'      # Reverse off

# Background
On_Black='\e[40m'         # Black
On_Red='\e[41m'           # Red
On_Green='\e[42m'         # Green
On_Yellow='\e[43m'        # Yellow
On_Light_Red='\e[101m'    # Light Red
On_Light_Blue='\e[104m'   # Light Blue

input_file="${1?Input file missing}"
filename=$(basename "${input_file}")
filename="${filename%.*}"
frames=$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 "${input_file}")

# Video Preview thumbnails (1/${thumbnail_timewindow} seconds)
thumbnail_timewindow=7

n=0
h1=0
m1=0
s1=0
h2=0
m2=0
s2=0
thumbnail_counter=0
thumbnail_width=120
thumbnail_height=68

shopt -s nullglob;

# Create Video Preview thumbnails (1/${thumbnail_timewindow} seconds)
mkdir -p "output/${filename}/thumbnails";
echo -e "\nCreating video preview thumbnails (1/${thumbnail_timewindow} seconds)";
rm -rf "output/${filename}/thumbnails/"*;
ffmpeg -y -v error -i "${input_file}" -r 1/${thumbnail_timewindow} -vf scale=-1:120 -vcodec png "output/${filename}/thumbnails/thumbnail%02d.png" && \
rm -f "output/${filename}/thumbnails/thumbnail01.png";

cd "output/${filename}/thumbnails";
# Write thumbnail image names into file
ls *.png > thumbnails.tmp;

image_stack="";
delete_tmp_files="";
x=0;
while read line
do
  image_stack="${image_stack} -i ${line}";
  delete_tmp_files="${delete_tmp_files} ${line}";
  if [[ $thumbnail_counter -eq 0 ]]; then
    thumbnail_width=$(( exiv2 ${line} | grep " x " | grep -o '[0-9]*' | head -1 ) 2>/dev/null);
    thumbnail_height=$(( exiv2 ${line} | grep " x " | grep -o '[0-9]*' | tail -n +2 ) 2>/dev/null);
    echo -e "Thumbnail Dimensions: ${thumbnail_width} x ${thumbnail_height}";
  fi
  thumbnail_counter=$((thumbnail_counter+1));
  echo "thumbnails.png#xywh=${x},0,${thumbnail_width},${thumbnail_height}" >> thumbnails.vtt;
  x=$((x+thumbnail_width));
done < thumbnails.tmp
if [[ $thumbnail_counter -gt 1 ]]; then
  ffmpeg -y -v error $image_stack -filter_complex hstack=inputs=$thumbnail_counter thumbnails.png;
fi
rm -f $delete_tmp_files;
echo -e "Thumbnail count: ${thumbnail_counter}";
mv thumbnails.vtt thumbnails.tmp;

# Insert matching WEBVTT timestamps for the preview images
while read line
do
  h1=$(( n / 3600 ));
  printf -v h1 "%02d" $h1;
  m1=$(( ( n / 60 ) % 60 ));
  printf -v m1 "%02d" $m1;
  s1=$(( n % 60 ));
  printf -v s1 "%02d" $s1;
  h2=$(( ( n + thumbnail_timewindow ) / 3600 ));
  printf -v h2 "%02d" $h2;
  m2=$(( ( ( n + thumbnail_timewindow ) / 60 ) % 60 ));
  printf -v m2 "%02d" $m2;
  s2=$(( ( n + thumbnail_timewindow ) % 60 ));
  printf -v s2 "%02d" $s2;
  echo $line|sed -e "/thumbnail/ { s/thumbnail/\n$h1:$m1:$s1.000 --> $h2:$m2:$s2.000\n&/ }" >> thumbnails.vtt;
  n=$((n+thumbnail_timewindow));
done < thumbnails.tmp

rm -f thumbnails.tmp;
# Insert new line "WEBVTT" at the start of thumbnails.vtt file
sed -i '1 i\WEBVTT' thumbnails.vtt;
# Append line-feed at the end of thumbnails.vtt file
echo >> thumbnails.vtt;
