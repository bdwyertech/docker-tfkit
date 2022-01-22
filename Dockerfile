FROM ruby:3.0-alpine3.13

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

RUN apk add --no-cache --virtual .build-deps build-base \
    && gem uninstall -i /usr/local/lib/ruby/gems/3.0.0 minitest \
    && gem uninstall -i /usr/local/lib/ruby/gems/3.0.0 rake -x \
    && gem install bundler:2.3.5 \
    && bundle install \
    && apk del .build-deps

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
RUN apk add python3 py3-pip && python3 -m pip install --upgrade pip wheel \
    && apk add --no-cache --virtual .build-deps build-base python3-dev openssl-dev \
    && python3 -m pip install -r requirements.txt --ignore-installed six \
    && apk del .build-deps

# TFLint
RUN (curl -sfL "$(curl -Ls https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E "https://.+?_linux_amd64.zip")" -o tflint.zip && unzip tflint.zip -d /usr/local/bin && rm tflint.zip)

# Terrascan
RUN wget -qO- https://github.com/accurics/terrascan/releases/download/v1.13.0/terrascan_1.13.0_Linux_x86_64.tar.gz | tar zxf - --directory /usr/local/bin

# TerraGrunt
ADD https://github.com/gruntwork-io/terragrunt/releases/download/v0.36.0/terragrunt_linux_amd64 /usr/local/bin/terragrunt
RUN chmod +x /usr/local/bin/terragrunt

# Azure CLI Login
RUN wget -qO- https://github.com/bdwyertech/go-az/releases/download/v0.0.12/az_linux_amd64.tar.gz | tar zxf - --directory /usr/local/bin

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

USER tfkit
WORKDIR /tfkit
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["kitchen"]
