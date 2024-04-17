FROM ubuntu:22.04

RUN apt-get update -y && apt-get install -y schema2ldif

CMD ["tail", "-f", "/dev/null"]
