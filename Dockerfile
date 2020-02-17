FROM ruby:2.6-alpine

COPY Gemfile Gemfile.lock /

RUN apk add --no-cache --virtual .build-deps build-base \
    && gem install bundler \
    && bundle install \
    && apk del .build-deps

RUN apk add bash curl git \
    && git clone https://github.com/tfutils/tfenv.git /opt/tfenv \
    && ln -s /opt/tfenv/bin/* /usr/local/bin \
    && tfenv install

ENV KITCHEN_YAML=.kitchen.tf.yml
ENV KITCHEN_LOCAL_YAML=.kitchen.tf.local.yml

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENV HOME=/tfkit
WORKDIR /tfkit
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["kitchen"]
