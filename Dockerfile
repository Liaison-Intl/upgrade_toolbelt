FROM alpine:3.4

RUN echo 'apk update && apk add "$1"' > /usr/local/bin/pkg-apk
RUN echo 'gem install --no-ri --no-rdoc "$1"' > /usr/local/bin/pkg-gem
RUN chmod +x /usr/local/bin/pkg-*

RUN echo 'export PATH="/opt/bin:$PATH"' > /etc/profile.d/travis_toolbelt.sh

RUN pkg-apk ca-certificates
RUN update-ca-certificates

RUN pkg-apk ruby=2.3.6-r0
RUN pkg-apk ruby-dev=2.3.6-r0

RUN pkg-apk grep
RUN pkg-apk build-base
RUN pkg-apk libffi-dev

RUN pkg-gem travis:1.8.2
