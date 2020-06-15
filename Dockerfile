# Dockerfile for iperf3:
# version 2006.6
# copyright reserved by angusnoach

# Information:
# bash   - used to run the script
# iperf3 - run as server to test network bandwidth
# /data  - volume to save the report

FROM alpine:latest

MAINTAINER angusnoach

RUN apk update \
  && apk add --no-cache bash iperf3 \
  && mkdir -p /data

EXPOSE 5201/udp 5201/tcp

VOLUME ["/data"]

COPY run.sh /run.sh
RUN chmod +x /run.sh
ENTRYPOINT ["/run.sh"]
