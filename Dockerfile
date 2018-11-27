FROM ubuntu:14.04
RUN apt-get update && apt-get install -y \
    python \
    python-dev \
    python-pip \
 && rm -rf /var/lib/apt/lists/*
RUN pip install awscli && mkdir -m 775 /data
ADD run.sh /data/run.sh
RUN chmod +x /data/run.sh
WORKDIR /data
CMD ./run.sh
