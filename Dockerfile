ARG ALPINE_BASE=3.12.9

ARG SNAPCAST_VERSION=v0.26.0
ARG SNAPWEB_VERSION=v0.2.0

# SnapCast build stage
FROM alpine:$ALPINE_BASE as snapcastbuild
WORKDIR /root
# Dummy file is needed, because there's no conditional copy
COPY dummy qemu-*-static /usr/bin/

RUN apk -U add alsa-lib-dev avahi-dev bash build-base ccache cmake expat-dev flac-dev git libvorbis-dev opus-dev soxr-dev
RUN git clone --recursive https://github.com/badaix/snapcast --branch $SNAPWEB_VERSION
RUN cd snapcast
RUN wget https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/boost_1_76_0.tar.bz2 && tar -xjf boost_1_76_0.tar.bz2
RUN cmake -S . -B build -DBOOST_ROOT=boost_1_76_0 -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DBUILD_WITH_PULSE=OFF -DCMAKE_BUILD_TYPE=Release -DBUILD_CLIENT=OFF ..
RUN cmake --build build --parallel 3

# SnapWeb build stage
FROM node:alpine as snapwebbuild
WORKDIR /root

RUN apk add build-base git
RUN npm install -g typescript@latest 
RUN npm install --save @types/wicg-mediasession@1.1.0
RUN git clone https://github.com/badaix/snapweb --branch $SNAPWEB_VERSION
RUN make -C snapweb

# Final stage
FROM alpine:$ALPINE_BASE
WORKDIR /root
# COPY dummy qemu-*-static /usr/bin/

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

RUN apk --no-cache add alsa-lib avahi-libs expat flac libvorbis opus soxr
# RUN rm -rf /etc/ssl /var/cache/apk/* /lib/apk/db/* /root/snapcast /usr/bin/dummy

COPY --from=snapcastbuild /root/snapcast/bin/snapserver /usr/bin
COPY --from=snapwebbuild /root/snapweb/dist/ /var/www/html/

RUN /usr/bin/snapserver -v
COPY snapserver.conf /etc/snapserver.conf
EXPOSE 1704 1705 1780
ENTRYPOINT ["/usr/bin/snapserver","-c","/etc/snapserver.conf"]
