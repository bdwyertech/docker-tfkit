FROM ruby:2.7.1-alpine

ARG BUILD_DATE
ARG VCS_REF

LABEL org.opencontainers.image.title="bdwyertech/tfkit" \
      org.opencontainers.image.description="Infrastructure as code development & testing via kitchen-terraform" \
      org.opencontainers.image.authors="Brian Dwyer <bdwyertech@github.com>" \
      org.opencontainers.image.url="https://hub.docker.com/r/bdwyertech/tfkit" \
      org.opencontainers.image.source="https://github.com/bdwyertech/docker-tfkit.git" \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.created=$BUILD_DATE \
      org.label-schema.name="bdwyertech/tfkit" \
      org.label-schema.description="Infrastructure as code development & testing via kitchen-terraform" \
      org.label-schema.url="https://hub.docker.com/r/bdwyertech/tfkit" \
      org.label-schema.vcs-url="https://github.com/bdwyertech/docker-tfkit.git"\
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.build-date=$BUILD_DATE

COPY Gemfile Gemfile.lock /

RUN apk add --no-cache --virtual .build-deps build-base \
    && gem uninstall -i /usr/local/lib/ruby/gems/2.6.0 minitest \
    && gem install bundler \
    && bundle install \
    && apk del .build-deps

RUN apk add bash curl git \
    && git clone https://github.com/tfutils/tfenv.git /opt/tfenv \
    && ln -s /opt/tfenv/bin/* /usr/local/bin \
    && adduser tfkit -h /home/tfkit -D \
    && echo 'latest' > /opt/tfenv/version \
    && chown -R root:tfkit /opt/tfenv/version* \
    && chmod g+rw /opt/tfenv/version*

ENV KITCHEN_YAML=.kitchen.tf.yml
ENV KITCHEN_LOCAL_YAML=.kitchen.tf.local.yml

# TerraScan (Python)
COPY requirements.txt /
RUN apk add python3 && python3 -m pip install --upgrade pip \
    && python3 -m pip install -r requirements.txt

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

USER tfkit
WORKDIR /tfkit
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["kitchen"]
