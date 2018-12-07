FROM debian:jessie

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
    && curl https://s3.amazonaws.com/skyed/skyed_0.1.16%2B20160825111737.tar.gz > /tmp/skyed_latest.tar.gz \
    && cd / \
    && tar xzvf /tmp/skyed_latest.tar.gz \
    && rm /tmp/skyed_latest.tar.gz \
    && apt-get purge -y curl ca-certificates \
    && apt-get autoremove -y

RUN apt-get install -y --no-install-recommends \
       git \
       openssh-client \
    && mkdir ~/.ssh && ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts

ENTRYPOINT ["/tmp/opt/skyed/bin/skyed"]
