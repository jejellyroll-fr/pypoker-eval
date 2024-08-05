FROM --platform=linux/arm64 ubuntu:20.04


ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    echo "Etc/UTC" > /etc/timezone

RUN apt-get update && apt-get install -y \
    cmake \
    build-essential \
    python3.11 \
    python3.11-dev \
    python3-pip


COPY . /workspace
WORKDIR /workspace


RUN pip3 install -r requirements.txt


RUN mkdir build && cd build && cmake .. && cmake --build .


CMD ["/bin/bash"]
