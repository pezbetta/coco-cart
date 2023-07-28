ARG PYTHON_VER=
ARG PYTHON_TAG=3.10-slim
ARG POETRY_VERSION=1.5.1

FROM python:$PYTHON_TAG as base-image

ARG POETRY_VERSION

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONFAULTHANDLER=1
ENV PYTHONUNBUFFERED=1

ENV PIP_DEFAULT_TIMEOUT=120
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1

ENV POETRY_VIRTUALENVS_CREATE=False
ENV POETRY_HOME=/opt/poetry

ENV PATH="$POETRY_HOME/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        curl \
        librdkafka-dev \
    && curl -sSL https://install.python-poetry.org | python3 - --version $POETRY_VERSION \
    && rm -rf /var/lib/apt/lists/*

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USER_NAME=1000
ARG GROUP_NAME=1000

RUN groupadd --gid $GROUP_ID $GROUP_NAME
RUN useradd --create-home --no-log-init --uid $USER_ID --gid $GROUP_ID $USER_NAME

ENV HOME ${HOME:-/home/${USER_NAME}}
ENV PATH $HOME/.local/bin:$PATH
ENV PYTHONPATH /code:${PYTHONPATH}

WORKDIR /code

COPY poetry.lock pyproject.toml ./

FROM base-image as builder-image

RUN poetry install --without dev

USER $USER_NAME

# -------------------------------
# Dev image
FROM builder-image as dev-image

USER root
RUN poetry install
USER $USER_NAME

# -------------------------------
# Runtime image
FROM builder-image as runtime-image
USER root

USER $USER_NAME
CMD uvicorn --host 0.0.0.0 --port 8000 main:app
