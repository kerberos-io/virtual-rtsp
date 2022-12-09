# Virtual RTSP (IP Camera)

This project creates a virtual RTSP connection, based on a looping MP4. It is inspired by and build on top of [flaviostutz's work](https://github.com/flaviostutz/rtsp-relay) and [RTSP Simple Server](https://github.com/aler9/rtsp-simple-server).

The idea of a virtual RTSP is to simulate real-world IP cameras forwarding a RTSP H264 encoded stream. The project is build for demo purposes, when no RTSP connection is available. Please read below paragraph "How to use MP4s" to understand the limitations and best practices.

Running this project as following:

    docker run -p 554:8554 \
    -e SOURCE_URL=file:///samples/highway-10min-640x480-1.mp4 \
    -v $(pwd)/samples:/samples \
    -d --restart=always kerberos/virtual-rtsp:1.0.6

Will generate following demo RTSP url:

    rtsp://fake.kerberos.io/stream

## Build with container image

To build the container you can simply build the Dockerfile using following command.

    docker build -t kerberos/virtual-rtsp .
    docker tag kerberos/virtual-rtsp kerberos/virtual-rtsp:1.0.6

## Run container with Docker

To run the container you can have to specify a couple of environment variables. These will make sure the MP4 is loaded and streamed through a RTSP connection.

### Download MP4

We've published a couple of MP4s in the [v1.0.0 release](https://github.com/kerberos-io/virtual-rtsp/releases/tag/v1.0.0) which you can use to stream. The MP4s are IP camera footage recorded by real-world IP cameras (Axis/HIKVision).

Go ahead and download a mp4 from the [v1.0.0 release](https://github.com/kerberos-io/virtual-rtsp/releases/tag/v1.0.0).

    wget https://github.com/kerberos-io/virtual-rtsp/releases/download/v1.0.0/highway-10min-640x480-1.mp4
    mkdir samples && mv highway-10min-640x480-1.mp4 samples

If the mp4 is downloaded, we can inject the mp4 into our container by using volumes and specifying the environment variable `-e SOURCE_URL`.

    docker run -p 554:8554 \
    -e SOURCE_URL=file:///samples/highway-10min-640x480-1.mp4 \
    -v $(pwd)/samples:/samples \
    -d --restart=always kerberos/virtual-rtsp:1.0.6
    
## Deploy to Kubernetes

Now we have a container build, we can deploy a Kubernetes Deployment resource that will run the virtual-rtsp container. Next to that, we also create Kubernetes Service resource, so we can access the RTSP connection on `:8554` from within the cluster; please note that you could also use the `LoadBalancer` service type if you would run a cluster on a managed Kubernetes provider.

Start by having a look at the `virtual-rtsp-deployment.yaml` manifest, this includes the previously mentioned `Deployment` and `Service`. Go ahead and apply the manifest in the namespace you prefer.

    kubectl apply -f virtual-rtsp-deployment.yaml 

or within a namespace

    kubectl create namespace my-namespace
    kubectl apply -f virtual-rtsp-deployment.yaml -n my-namespace

Once deployed you should see it being created and deployed. It will first execute an init step `initContainer` to download a specific MP4 into the container; you [could change the url](https://github.com/kerberos-io/virtual-rtsp/blob/master/virtual-rtsp-deployment.yaml#L28) to whatever you want.

Once the MP4 is downloaded it will be loaded and served through the RTSP proxy. The RTSP stream is served on port `:8554` by default, but nothing is stopping you to change that as well.

If everything is properly deployed, you should see your service available, in the namespace you've specified. Once you validated everything is as it should be, go a head and test the endpoint.

### Port-forward

One way to test is start a port-forwarding to the service, you can achieve that as following:

    kubectl port-forward svc/virtual-rtsp 8554:8554

or within a namespace

    kubectl port-forward svc/virtual-rtsp 8554:8554 -n my-namespace

This will open a port `8554` on your host machine, and redirect all traffic to your service on port `8554` in the Kubernetes cluster.

### Internal access

If you want to access the RTSP stream from within the cluster, for example for your [Kerberos Agent and Kerberos Factory](https://doc.kerberos.io/factory/first-things-first/), there is no need for port-forwarding. We access the stream [using the internal DNS resolving of Kubernetes](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/).

You can access the stream as following `rtsp://{serviceName}.{namespaces}:8554/stream`, so for our example that would be

    rtsp://virtual-rtsp:8554/stream

or within a namespace

    rtsp://virtual-rtsp.my-namespace:8554/stream

## How to use MP4s

We noticed that some MP4s are encoded in a different way, and therefore will not work properly with the Kerberos Agent. Some MP4s will work, others will not. At the moment of writing, we didn't had the time to dig into this deeper. You will notice that most MP4s will be accepted by the `virtual-rtsp` client, and the relevant RTSP stream will even open in tools such as VLC. However once connected the RTSP stream to your Kerberos Agent, the agent might fail and crash, without any information/indications.

The preferred way of using MP4s is to generate them through the Kerberos Agent. This means that a real RTSP camera is connected to a Kerberos Agent, and configured in a continuous recording mode (of for example 10min). The Kerberos Agent will then generate a 10 min video, or more, which you can use as a MP4 for your virtual RTSP stream.

To make it easier we have supplied a several of recordings with different resolutions in the [1.0.0 release](https://github.com/kerberos-io/virtual-rtsp/releases/tag/v1.0.0). In this release you will find a couple of assets, MP4s, of different resoltions and durations.

[By changing the url to the MP4 file](https://github.com/kerberos-io/virtual-rtsp/blob/master/virtual-rtsp-deployment.yaml#L28) you prefer you can simulate the relevant RTSP connection. This useful for testing and benchmarking specific hardware, that you consider for your Kerberos Factory/Agent deployment.

    initContainers:
      - name: init-samples
        image: busybox
        command:
        - wget
        - "-O"
        - "/samples/cars.mp4"
        - https://github.com/kerberos-io/virtual-rtsp/releases/download/v1.0.0/highway-10min-640x480-1.mp4
        volumeMounts:
        - name: tmp-samples
          mountPath: /samples

