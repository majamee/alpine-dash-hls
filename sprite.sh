#!/bin/bash
# Credits go to: https://github.com/shoys89/vtt-preview-generator
fname_static="thumbnails";

if [ $# -eq 0 ]
  then
    echo "No arguments supplied / video file is not being provided"
  else
  	fullfilename=$1
    filename=$(basename "$fullfilename")
    fname="${filename%.*}"
    interval=5

    # if [ ! -d "$fname" ]
    # then
    #     mkdir -p "$fname";
    # fi

    # Create Video Preview thumbnails (1/${thumbnail_timewindow} seconds)
    mkdir -p "output/${fname}/thumbnails";
    echo -e "\nCreating video preview thumbnails (1/${interval} seconds)";
    rm -rf "output/${fname}/thumbnails/"*;

    ##ffmpeg -i $fullfilename -vf fps=1/10 -s 160x90 $fname/thumb-%d.png

    ffmpeg -i "$fullfilename" -vf select="isnan(prev_selected_t)+gte(t-prev_selected_t\,$interval)",scale=160:90,tile -frames:v 1 "$fname_static".png

    ##get some values for VTT creator
    eval $(ffprobe -v quiet -show_format -of flat=s=_ -show_entries stream=height,width,nb_frames,duration,codec_name "$fullfilename")
    duration=${format_duration};

    ##parse this to Integer in order to validate
    VTT_OUTPUT="${fname_static}".vtt
    duration=${duration%.*}
    echo "Video duration is:" $duration

    ##check if vtt file exist
    if [ -f "$VTT_OUTPUT" ]; then
        rm "$VTT_OUTPUT"
    fi

    counter=1;
    width=160;
    height=90;
    x=0;
  for ((a=interval; a<=duration; a=a+interval))
  do
    eval $(ffprobe -v quiet -sexagesimal -show_format -of flat=s=_ -read_intervals ${a}%+1 -skip_frame nokey -select_streams v:0 -show_entries frame=pkt_pts_time "$fullfilename")
    timestamp=${frames_frame_0_pkt_pts_time:2:10};

  if [ 960 -le ${x} ]
    then
     ((x=0))
     ((y=y+height))
    fi

    if [ ${counter} -le 1 ]
                then
                    start='00:00.0000'
                    printf "WEBVTT FILE\n">>"$VTT_OUTPUT";
                    printf "\n%10s --> %10s" "$start" "$timestamp" >>"$VTT_OUTPUT";
                else
                    printf "\n%10s --> %10s" "$current" "$timestamp" >>"$VTT_OUTPUT";
                fi
                    printf "\n%s.png#xywh=%d,%d,128,72\n" "$fname_static" "$x" "$y" >>"$VTT_OUTPUT";
                    current=$timestamp;
                    ((counter++))
                    ((x=x+width))
done

mv "${fname_static}."* "output/${fname}/thumbnails";

fi
