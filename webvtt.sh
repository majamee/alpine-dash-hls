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
extension="${filename##*.}"
filename="${filename%.*}"
frames=$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 "${input_file}")

# Video Preview thumbnails (1/${thumbnail_timewindow} seconds)
thumbnail_timewindow=7

shopt -s nullglob;

# Create Video Preview thumbnails (1/${thumbnail_timewindow} seconds)
echo -e "\nCreating video preview thumbnails (1/${thumbnail_timewindow} seconds)";
# Creating target directory
mkdir -p "output/${filename}/thumbnails";
# Renaming input file for automated thumbnail preview generating
mv "${filename}.${extension}" "thumbnails.${extension}";
# Let `mt` do the thumbnail & webvtt file generation https://github.com/mutschler/mt
mt -i ${thumbnail_timewindow} -w 120 -p 0 -d --header=false --webvtt=true "thumbnails.${extension}";
mv "thumbnails.vtt" "output/${filename}/thumbnails/thumbnails.vtt" && mv "thumbnails.jpg" "output/${filename}/thumbnails/thumbnails.jpg";
# Revert renaming
mv "thumbnails.${extension}" "${filename}.${extension}";
