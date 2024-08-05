# use base image for ARM64
FROM --platform=linux/arm64 ubuntu:20.04

# install deps
RUN apt-get update && apt-get install -y \
    cmake \
    build-essential \
    python3 \
    python3-pip

# copy
COPY . /workspace
WORKDIR /workspace

# install requirement
RUN pip3 install -r requirements.txt

# build
RUN mkdir build && cd build && cmake .. && cmake --build .

# path
CMD ["/bin/bash"]
