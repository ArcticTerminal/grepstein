FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    poppler-utils \
    less \
    fzf \
    httpie \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY grepstein.sh /usr/local/bin/grepstein
RUN chmod +x /usr/local/bin/grepstein

ENTRYPOINT ["grepstein"]
