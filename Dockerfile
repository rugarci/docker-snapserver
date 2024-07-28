ARG ALPINE_BASE=3.20

ARG SNAPCAST_VERSION=0.28.0
ARG SNAPWEB_VERSION=v0.7.0

# SnapCast build stage
#FROM alpine:$ALPINE_BASE as snapcastbuild
#ARG SNAPCAST_VERSION

#WORKDIR /root
# Dummy file is needed, because there's no conditional copy
#COPY dummy qemu-*-static /usr/bin/

#RUN apk -U add alsa-lib-dev avahi-dev bash build-base ccache cmake expat-dev flac-dev git libvorbis-dev opus-dev soxr-dev alsa-utils  libpulse

#RUN git clone --recursive https://github.com/badaix/snapcast --branch $SNAPCAST_VERSION \
# && cd snapcast \
# && wget https://boostorg.jfrog.io/artifactory/main/release/1.83.0/source/boost_1_83_0.tar.bz2 && tar -xjf boost_1_83_0.tar.bz2 \
# && cmake -S . -B build -DWERROR=ON -DBUILD_TESTS=ON -DBOOST_ROOT=boost_1_83_0 -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-DCMAKE_CXX_FLAGS=-DJSON_HAS_CPP_14" .. \
# && cmake --build build --parallel 3 --verbose

# SnapWeb build stage
#FROM alpine:$ALPINE_BASE as snapwebbuild
FROM ubuntu:latest as snapwebbuild

ARG SNAPWEB_VERSION

WORKDIR /root

RUN apt-get update && apt-get -yq install debhelper fakeroot nodejs git
#RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -

#RUN apk add build-base git npm
#RUN npm install --verbose -g typescript@latest 
#RUN npm install --save @types/wicg-mediasession@1.1.0

RUN npm install -g npm@latest
RUN git clone https://github.com/badaix/snapweb --branch $SNAPWEB_VERSION
#RUN make -C snapweb
RUN cd snapweb
RUN npm ci

WORKDIR /root/snapweb   

# Final stage
FROM alpine:$ALPINE_BASE
WORKDIR /root

ARG SNAPCAST_VERSION
ARG SNAPWEB_VERSION
ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="docker-snapserver" \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/rugarci/docker-snapserver" \
    org.label-schema.vcs-type="Git" \
    org.label-schema.schema-version="1.0" \
    org.opencord.component.snapcast.version=$SNAPCAST_VERSION \
    org.opencord.component.snapcast.vcs-url="https://github.com/badaix/snapcast" \
    org.opencord.component.snapweb.version=$SNAPWEB_VERSION \
    org.opencord.component.snapweb.vcs-url="https://github.com/badaix/snapweb"
    
RUN mkdir -p /var/www/html

RUN apk --no-cache add alsa-lib avahi-libs expat flac libvorbis opus soxr snapcast=${SNAPCAST_VERSION}
# RUN rm -rf /etc/ssl /var/cache/apk/* /lib/apk/db/* /root/snapcast /usr/bin/dummy

#COPY --from=snapcastbuild /root/snapcast/bin/snapserver /usr/bin
COPY --from=snapwebbuild /root/snapweb/dist/ /var/www/html/

RUN /usr/bin/snapserver -v
COPY snapserver.conf /etc/snapserver.conf
EXPOSE 1704 1705 1780
ENTRYPOINT ["/usr/bin/snapserver","-c","/etc/snapserver.conf"]
