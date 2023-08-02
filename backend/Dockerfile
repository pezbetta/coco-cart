ARG PYTHON_VER=3.10

FROM python:${PYTHON_VER}-slim AS base

WORKDIR /app

ENV PYTHONUNBUFFERED=1

RUN apt-get -y update; apt-get -y install curl

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | POETRY_HOME=/opt/poetry python && \
    cd /usr/local/bin && \
    ln -s /opt/poetry/bin/poetry && \
    poetry config virtualenvs.create false

COPY ./pyproject.toml ./poetry.lock* /app/

RUN poetry install --no-root

COPY . /app

FROM base

WORKDIR /app

CMD uvicorn --host 0.0.0.0 --port 8000 main:app
