FROM gcc:latest as base

# Check GNU Make
RUN make --version

# Install Docker
RUN curl --fail --silent --show-error https://download.docker.com/linux/static/stable/x86_64/docker-24.0.6.tgz > docker.tgz \
    && tar -xzvf docker.tgz \
    && cp docker/* /usr/bin/ \
    && rm -rf docker.tgz \
    && docker --version

# Install the Compose plugin for Docker
RUN mkdir -p ${HOME}/.docker/cli-plugins \
    && curl -SL https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-x86_64 -o ${HOME}/.docker/cli-plugins/docker-compose \
    && chmod +x ${HOME}/.docker/cli-plugins/docker-compose \
    && docker compose --version
