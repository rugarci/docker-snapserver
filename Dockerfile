ARG ALPINE_BASE=3.22.1

ARG SNAPCAST_VERSION=0.31.0
ARG SNAPWEB_VERSION=v0.9.1

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
    org.opencord.component.snapcast.vcs-url="https://github.com/badaix/snapcast"
    
RUN mkdir -p /var/www/html

RUN apk --no-cache add alsa-lib avahi-libs expat flac libvorbis opus soxr snapcast~=${SNAPCAST_VERSION}
RUN apk --no-cache add snapweb~=${SNAPWEB_VERSION} --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing
RUN cp -r /usr/share/snapweb/* /var/www/html

RUN /usr/bin/snapserver -v
COPY snapserver.conf /etc/snapserver.conf
EXPOSE 1704 1705 1780
ENTRYPOINT ["/usr/bin/snapserver","-c","/etc/snapserver.conf"]
