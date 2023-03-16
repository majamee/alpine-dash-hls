FROM                alpine:latest

COPY                ./transcode.sh /bin/transcode.sh
COPY                ./sprite.sh /bin/sprite.sh

RUN                 buildDeps="alsa-lib-dev \
                    build-base \
                    brotli-static \
                    bzip2-static \
                    coreutils \
                    expat-dev \
                    faad2-static \
                    ffmpeg-dev \
                    freetype-static \
                    freetype-dev \
                    git \
                    glu-dev \
                    jack-dev \
                    jpeg-dev \
                    lame-dev \
                    libass-dev \
                    libjpeg-turbo-dev \
                    libmad-dev \
                    libogg-dev \
                    libpng-dev \
                    libpng-static \
                    libpulse \
                    libtheora-dev \
                    libvorbis-dev \
                    libvpx-dev \
                    libwebp-dev \
                    libxv-dev \
                    mesa-dev \
                    mesa-utils \
                    musl-dev \
                    openjpeg-dev \
                    openssl-dev \
                    opus-dev \
                    sdl2-dev \
                    x264-dev \
                    x265-dev \
                    xvidcore-static \
                    yasm-dev \
                    zlib-static" && \
                    apk add --no-cache --update ${buildDeps} bash exiv2 ffmpeg libpng libxslt openssl && \
                    git clone https://github.com/squidpickles/mpd-to-m3u8.git /app/mpd-to-m3u8 && \
                    rm -rf !$/.git && \
                    git clone https://github.com/gpac/gpac.git /tmp/gpac && \
                    cd /tmp/gpac && ./configure --static-bin && make -j4 && make install && make distclean && cd && rm -rf /tmp/gpac && \
                    apk del ${buildDeps} && rm -rf /var/cache/apk/* && \
                    chmod +x /bin/transcode.sh && \
                    chmod +x /bin/sprite.sh

COPY                ./src /app/src

WORKDIR             /video
ENTRYPOINT          ["/bin/transcode.sh"]
CMD                 ["*.mkv"]
