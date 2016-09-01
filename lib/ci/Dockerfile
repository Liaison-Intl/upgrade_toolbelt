FROM alpine:3.4

RUN echo 'apk update && apk add "$1"' > /usr/local/bin/pkg-apk
RUN echo 'gem install --no-ri --no-rdoc "$1"' > /usr/local/bin/pkg-gem
RUN chmod +x /usr/local/bin/pkg-*

RUN pkg-apk ca-certificates
RUN update-ca-certificates

RUN pkg-apk ruby=2.3.1-r0
RUN pkg-apk ruby-dev=2.3.1-r0
RUN pkg-apk build-base=0.4-r1
RUN pkg-apk libffi-dev=3.2.1-r2
RUN pkg-apk ruby-irb=2.3.1-r0
RUN pkg-gem rdoc
RUN pkg-gem io-console

RUN gem install bundler

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install

COPY . .

WORKDIR lib/ci/

CMD ./bin/rails_upgrade_analyzer
