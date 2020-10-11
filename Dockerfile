FROM i386/debian:buster-slim as base

#-------------------------------------------------------------------------------
# Download and install BYOND
#-------------------------------------------------------------------------------
FROM base as byond_install

#
# Install Debian packages
#
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    make \
    unzip \
    && rm -rf /var/lib/apt/lists/*

#
# Determine which version of BYOND we are installing
#
ARG MAJOR
ENV BYOND_MAJOR=$MAJOR
ARG MINOR
ENV BYOND_MINOR=$MINOR

#
# Install BYOND
#
RUN curl "https://secure.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" -o byond.zip \
    && unzip byond.zip \
    && cd /byond \
    && make here

#-------------------------------------------------------------------------------
# Create the docker image for BYOND
#-------------------------------------------------------------------------------
FROM base as byond_image

#
# Copy the BYOND installation into our docker image
#
COPY --from=byond_install /byond /byond
