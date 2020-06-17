FROM ruby:2.7-alpine

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
    && gem uninstall -i /usr/local/lib/ruby/gems/2.7.0 minitest \
    && gem uninstall -i /usr/local/lib/ruby/gems/2.7.0 rake -x \
    && gem install bundler \
    && bundle install \
    && apk del .build-deps

# Hide deprecation warnings (dry-logic-0.6.1 and dry-types-0.14.1)
ENV RUBYOPT='-W:no-deprecated -W:no-experimental'

RUN apk add bash curl git make openssh-client \
    && git clone https://github.com/tfutils/tfenv.git /opt/tfenv \
    && ln -s /opt/tfenv/bin/* /usr/local/bin \
    && adduser tfkit -h /home/tfkit -D \
    && echo 'latest' > /opt/tfenv/version \
    && mkdir /opt/tfenv/versions/ \
    && chown -R root:tfkit /opt/tfenv/version* \
    && chmod g+rw /opt/tfenv/version*

# InSpec Iggy
RUN su tfkit -c 'CHEF_LICENSE=accept-no-persist inspec plugin install inspec-iggy'

ENV KITCHEN_YAML=.kitchen.tf.yml
ENV KITCHEN_LOCAL_YAML=.kitchen.tf.local.yml

# TerraScan (Python)
COPY requirements.txt /
RUN apk add python3 py3-pip && python3 -m pip install --upgrade pip \
    && python3 -m pip install -r requirements.txt

# TFLint
RUN (curl -sfL "$(curl -Ls https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E "https://.+?_linux_amd64.zip")" -o tflint.zip && unzip tflint.zip -d /usr/local/bin && rm tflint.zip)

# TerraGrunt
ADD https://github.com/gruntwork-io/terragrunt/releases/download/v0.23.23/terragrunt_linux_amd64 /usr/local/bin/terragrunt
RUN chmod +x /usr/local/bin/terragrunt

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

USER tfkit
WORKDIR /tfkit
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["kitchen"]
