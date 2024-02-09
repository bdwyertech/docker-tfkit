FROM ruby:3.1-alpine3.17

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
      org.label-schema.vcs-url="https://github.com/bdwyertech/docker-tfkit.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.build-date=$BUILD_DATE \
      org.tooling.user=tfkit \
      org.tooling.uid=1000 \
      org.tooling.gid=1000

COPY Gemfile Gemfile.lock /

USER root

RUN apk add --no-cache --virtual .build-deps build-base git \
    && gem uninstall -i /usr/local/lib/ruby/gems/3.1.0 minitest \
    && gem uninstall -i /usr/local/lib/ruby/gems/3.1.0 rake -x \
    && gem install bundler:2.3.7 \
    && bundle install \
    && apk del .build-deps \
    && rm -rf ~/.bundle Gemfile Gemfile.lock

# Hide deprecation warnings (dry-logic-0.6.1 and dry-types-0.14.1)
ENV RUBYOPT='-W:no-deprecated -W:no-experimental'

RUN apk add bash curl git make openssh-client \
    && git clone https://github.com/tfutils/tfenv.git /opt/tfenv \
    && ln -s /opt/tfenv/bin/* /usr/local/bin \
    && adduser tfkit -h /home/tfkit -D -u 1000 \
    && echo 'latest' > /opt/tfenv/version \
    && mkdir /opt/tfenv/versions/ \
    && chown -R root:tfkit /opt/tfenv/version* \
    && chmod g+rw /opt/tfenv/version*

# InSpec Iggy
RUN apk add --no-cache --virtual .build-deps build-base \
    && su tfkit -c 'CHEF_LICENSE=accept-no-persist inspec plugin install inspec-iggy' \
    && apk del .build-deps

ENV KITCHEN_YAML=.kitchen.tf.yml
ENV KITCHEN_LOCAL_YAML=.kitchen.tf.local.yml

# TerraScan (Python)
COPY requirements.txt /
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main python3 \
    && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community py3-pip \
    && python3 -m pip install --upgrade pip wheel \
    && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main --virtual .build-deps build-base python3-dev openssl-dev \
    && python3 -m pip install --no-cache-dir -r requirements.txt --ignore-installed six \
    && apk del .build-deps \
    && rm -rf ~/.cache requirements.txt

# YQ
RUN (curl -sfL "$(curl -Ls https://api.github.com/repos/mikefarah/yq/releases/latest | grep -o -E "https://.+?_linux_amd64" -m 1)" -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq)

# TFLint
RUN (curl -sfL "$(curl -Ls https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E "https://.+?_linux_amd64.zip")" -o tflint.zip && unzip tflint.zip -d /usr/local/bin && rm tflint.zip)

# Terrascan
RUN (curl -sfL "$(curl -Ls https://api.github.com/repos/accurics/terrascan/releases/latest | grep -o -E "https://.+?Linux_x86_64.tar.gz")" | tar zxf - --directory /usr/local/bin)

# TFSec
RUN (curl -sfL "$(curl -Ls https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o -E "https://.+?tfsec-linux-amd64" | head -1)" -o /usr/local/bin/tfsec && chmod +x /usr/local/bin/tfsec)

# TerraGrunt
RUN (curl -sfL "$(curl -Ls https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep -o -E "https://.+?terragrunt_linux_amd64")" -o /usr/local/bin/terragrunt && chmod +x /usr/local/bin/terragrunt)

# Azure CLI Login
RUN (curl -sfL "$(curl -Ls https://api.github.com/repos/bdwyertech/go-az/releases/latest | grep -o -E "https://.+?az_linux_arm64.tar.gz")" | tar zxf - --directory /usr/local/bin)

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

USER tfkit
WORKDIR /tfkit
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["kitchen"]
