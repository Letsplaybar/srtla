# build stage
FROM alpine:latest as build

RUN apk update &&\
    apk upgrade &&\
    apk add --no-cache linux-headers alpine-sdk cmake tcl openssl-dev zlib-dev

WORKDIR /tmp

RUN git clone https://github.com/gabime/spdlog.git && \
    cd spdlog && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make -j8 && \
    make install

COPY irl-srt-server /tmp/srt-live-server/

RUN git clone https://github.com/irlserver/srt.git

COPY strla /tmp/strla

WORKDIR /tmp/srt

RUN git checkout belabox && ./configure && make -j8 && make install

WORKDIR /tmp/srt-live-server

RUN cmake . -DCMAKE_BUILD_TYPE=Release
RUN make -j8

WORKDIR /tmp/strla

RUN mkdir build && cd build && cmake .. && make -j8 && make install

# final stage
FROM alpine:latest

ENV LD_LIBRARY_PATH /lib:/usr/lib:/usr/local/lib64

RUN apk update &&\
    apk upgrade &&\
    apk add --no-cache openssl libstdc++ bash &&\
    adduser -D srt &&\
    mkdir -p /etc/sls /logs /tmp/sls /tmp/mov/sls &&\
    chown -R srt /logs /tmp/sls /tmp/mov/sls /etc/sls

COPY --from=build /usr/local/bin/srt-* /usr/local/bin/
COPY --from=build /usr/local/lib/libsrt* /usr/local/lib/
COPY --from=build /tmp/srt-live-server/bin/* /usr/local/bin/
COPY --from=build /usr/local/lib/spd* /usr/local/lib/
COPY --from=build /tmp/strla/build/srtla* /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME /logs

EXPOSE 8181 8080/udp 5000/udp

USER srt

WORKDIR /home/srt

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]