FROM alpine AS system

WORKDIR /app

RUN apk add curl bash openssl git \
    && curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin \
    && curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


FROM python:3.12 as test

ARG BRANCH=local
ARG COMMIT=unknown
ARG TARGET=all

WORKDIR /app

ENV PYTHONPATH=/app
ENV BRANCH=${BRANCH}
ENV COMMIT=${COMMIT}
ENV TARGET=${TARGET}

COPY --from=system /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=system /usr/local/bin/helm /usr/local/bin/helm

RUN apt update && apt install -y zip curl git && \
	apt clean -y && \
	apt autoclean -y && \
	apt autoremove --purge -y && \
	rm -rf /var/lib/{apt,cache,log}/ /tmp/* /etc/systemd
COPY .coveragerc .coveragerc
COPY requirements.txt .
COPY dev-requirements.txt .
RUN pip install uv \
    && uv pip install --system -r requirements.txt \
    && uv pip install --system -r dev-requirements.txt

COPY terra terra
COPY plugins /opt/official-plugins/plugins/
COPY tests tests

CMD sh tests/run_tests.sh
