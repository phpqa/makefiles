FROM gcc:latest as base

# Check GNU Make
RUN make --version

FROM base as with-jq-image
# Install Docker
RUN curl --fail --silent --show-error https://download.docker.com/linux/static/stable/x86_64/docker-24.0.6.tgz > docker.tgz \
    && tar -xzvf docker.tgz \
    && cp docker/* /usr/bin/ \
    && rm -rf docker.tgz \
    && docker --version

FROM base as without-jq

FROM base as with-jq
# Install jq
RUN apt-get update --yes && apt-get install --yes --no-install-recommends jq && apt-get clean && rm -rf /var/lib/apt/lists/*
