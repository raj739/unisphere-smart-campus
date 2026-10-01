# UniSphere Production Deployment

## Architecture

Client
  |
  v
Reverse Proxy / HTTPS
  |
  v
UniSphere FastAPI
  |
  v
PostgreSQL 18

The backend container runs:

1. Alembic migration
2. Gunicorn
3. Uvicorn workers

## Required production secrets

Set these outside source control:

- POSTGRES_PASSWORD
- JWT_SECRET_KEY
- GEMINI_API_KEY

JWT_SECRET_KEY should contain at least 32 characters.

## Start

From the backend directory:

docker compose --env-file .env.production -f docker-compose.production.yml up -d --build

## Logs

docker compose -f docker-compose.production.yml logs -f backend

## Status

docker compose -f docker-compose.production.yml ps

## Stop

docker compose -f docker-compose.production.yml down

## Important

Do not commit:

.env
.env.production
real API keys
real database passwords
JWT secrets

Production database changes must use:

alembic upgrade head

Do not rely on SQLAlchemy create_all for production schema management.
