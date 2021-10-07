# Virtual RTSP

This project creates a virtual RTSP connection, based on a looping MP4. It is inspired by and build on top of [flaviostutz's work](https://github.com/flaviostutz/rtsp-relay).

The idea of a virtual RTSP is to simulate real-world IP cameras forwarding a RTSP H264 encoded stream. The project is build for demo purposes, when no RTSP connection is available.

## Build with Docker

To build the container you can simply build the Dockerfile using following command.

    docker build -t kerberos/virtual-rtsp .

## Run Docker container

To run the container you can have to specify a couple of environment variables, and important load in a m4p which can be streamed (and looped) through a RTSP connection.

### Download MP4

We've published a couple of MP4s in the [v1.0.0 release](https://github.com/kerberos-io/virtual-rtsp/releases/tag/v1.0.0) which you can use to stream. The MP4s are IP camera footage recorded by real-world IP cameras (Axis/HIKVision).

Go ahead and download a mp4 from the [v1.0.0 release](https://github.com/kerberos-io/virtual-rtsp/releases/tag/v1.0.0).

    mkdir samples && cd samples
    wget https://github.com/kerberos-io/virtual-rtsp/releases/download/v1.0.0/cars.mp4
    
If the mp4 is downloaded, we can inject the mp4 into our container by using volumes and specifying the environment variable `-e SOURCE_URL`.

    docker run -p 8554:8554 \
    -e SOURCE_URL=file:///samples/cars.mp4 \
    -v $(pwd)/samples:/samples \
    kerberos/virtual-rtsp

## Deploy to Kubernetes

To be written