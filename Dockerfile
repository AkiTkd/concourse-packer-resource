FROM python:3.7.1-alpine3.8
ENV PYTHONUNBUFFERED=1
WORKDIR /opt/resource
CMD ["/bin/sh"]

RUN pip3 --no-cache-dir install --upgrade pip

ARG PACKER_VERSION=0.0.0

COPY hashicorp.asc .

RUN apk add --update \
        curl \
        git \
        gnupg \
        openssh \
        ansible \
        && \
        apk add --no-cache --progress python3 openssl ca-certificates git openssh sshpass && \
        apk --update add --virtual build-dependencies python3-dev libffi-dev openssl-dev build-base && \
    curl https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS.sig > packer_${PACKER_VERSION}_SHA256SUMS.sig && \
    curl https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS > packer_${PACKER_VERSION}_SHA256SUMS && \
    gpg --import hashicorp.asc && \
    gpg --verify packer_${PACKER_VERSION}_SHA256SUMS.sig packer_${PACKER_VERSION}_SHA256SUMS && \
    curl https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip > packer_${PACKER_VERSION}_linux_amd64.zip && \
    cat packer_${PACKER_VERSION}_SHA256SUMS | grep packer_${PACKER_VERSION}_linux_amd64.zip | sha256sum -c && \
    unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /bin && \
    rm -f packer_${PACKER_VERSION}_SHA256SUMS.sig \
      packer_${PACKER_VERSION}_SHA256SUMS \
      packer_${PACKER_VERSION}_linux_amd64.zip \
      hashicorp.asc

RUN set -xe \
    && mkdir -p /etc/ansible \
    && echo -e "[local]\nlocalhost ansible_connection=local" > \
    /etc/ansible/hosts 

# COPY ansible/ansible.cfg /etc/ansible/

# COPY requirements.txt /app/requirements.txt

# RUN pip3 --no-cache-dir install -r /app/requirements.txt

# copy scripts
COPY \
  bin/check \
  bin/in \
  bin/out \
  /opt/resource/

# copy library files
COPY \
  lib/__init__.py \
  lib/concourse.py \
  lib/io.py \
  lib/log.py \
  lib/packer.py \
  /opt/resource/lib/

# apt update
RUN apk add --update sudo

# add sudo user
#user
RUN echo 'root:root' |chpasswd
RUN adduser -S packer \
    && echo "packer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo 'packer:packer' | chpasswd

USER packer