FROM golang:1.16.1-alpine AS BUILD

RUN apk --update add git

#RTSP SIMPLE SERVER
WORKDIR /tmp
RUN git clone https://github.com/aler9/rtsp-simple-server.git
WORKDIR /tmp/rtsp-simple-server

#RUN git checkout v0.10.1
RUN go mod download
RUN go build -o /go/bin/rtsp-simple-server .

#RTSP SIMPLE PROXY
WORKDIR /tmp
RUN git clone https://github.com/aler9/rtsp-simple-proxy.git
WORKDIR /tmp/rtsp-simple-proxy

RUN go mod download
RUN go build -o /go/bin/rtsp-simple-proxy .

FROM jrottenberg/ffmpeg:4.4-alpine

ENV RTSP_PROTOCOLS=tcp
ENV SOURCE_URL ''
ENV STREAM_NAME 'stream'
ENV RTSP_PROXY_SOURCE_TCP 'yes'
ENV FORCE_FFMPEG 'true'
ENV FFMPEG_INPUT_ARGS ''
ENV FFMPEG_OUTPUT_ARGS='-c copy'

RUN apk --update add gettext bash

COPY --from=BUILD /go/bin/rtsp-simple-server /bin/rtsp-simple-server
COPY --from=BUILD /go/bin/rtsp-simple-proxy /bin/rtsp-simple-proxy

ADD proxy.yml /tmp/proxy.yml
ADD server.yml /tmp/server.yml
ADD start-relay.sh /

EXPOSE 8554
EXPOSE 8000
EXPOSE 8001

ENTRYPOINT [ "/bin/bash" ]
CMD ["/start-relay.sh"]
