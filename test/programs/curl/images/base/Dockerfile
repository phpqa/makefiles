FROM gcc:latest as base

# Check GNU Make
RUN make --version

FROM base as with-curl-image
# Install Docker
RUN curl --fail --silent --show-error https://download.docker.com/linux/static/stable/x86_64/docker-24.0.6.tgz > docker.tgz \
    && tar -xzvf docker.tgz \
    && cp docker/* /usr/bin/ \
    && rm -rf docker.tgz \
    && docker --version
# Uninstall curl
RUN apt-get remove --yes curl

FROM base as without-curl
# Uninstall curl
RUN apt-get remove --yes curl

FROM base as with-curl
# Make sure curl exists
RUN curl --version
