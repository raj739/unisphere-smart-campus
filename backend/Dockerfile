FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir gunicorn

COPY . .

RUN mkdir -p /app/logs

EXPOSE 8000

CMD ["sh", "-c", "alembic upgrade head && gunicorn app.main:app -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 --workers ${WEB_CONCURRENCY:-2} --timeout ${WEB_TIMEOUT:-120}"]