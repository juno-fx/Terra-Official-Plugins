FROM alpine AS system

WORKDIR /app

RUN apk add curl bash openssl git \
    && curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin \
    && curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


FROM python:3.12-alpine as test

ARG BRANCH=local
ARG COMMIT=unknown

WORKDIR /app

ENV PYTHONPATH=/app
ENV BRANCH=${BRANCH}
ENV COMMIT=${COMMIT}

COPY --from=system /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=system /usr/local/bin/helm /usr/local/bin/helm

RUN apk add --no-cache zip curl git
COPY .coveragerc .coveragerc
COPY requirements.txt .
COPY dev-requirements.txt .
RUN pip install uv \
    && uv pip install --system -r requirements.txt \
    && uv pip install --system -r dev-requirements.txt \
    && rm -rfv requirements.txt \
    && apk add --no-cache zip curl git

COPY plugins /opt/plugins/
COPY tests tests
COPY terra terra
COPY dev_runner.py dev_runner.py

CMD sh tests/run_tests.sh
