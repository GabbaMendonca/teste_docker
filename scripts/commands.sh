#!/bin/sh

# O shell irá encerrar a execução do script quando um comando falhar
set -e

# Aguarda o banco de dados PostgreSQL estar pronto antes de prosseguir
while ! nc -z $POSTGRES_HOST $POSTGRES_PORT; do
  echo "🟡 Waiting for Postgres Database Startup ($POSTGRES_HOST:$POSTGRES_PORT) ..."
  sleep 2
done

echo "✅ Postgres Database Started Successfully ($POSTGRES_HOST:$POSTGRES_PORT)"

# 1. Coleta os arquivos estáticos (CSS, JS, Imagens) para a pasta global do duser
echo "📦 Collecting static files..."
uv run python manage.py collectstatic --noinput

# 2. Aplica as migrações pendentes no banco de dados
# Removemos o makemigrations daqui. Você rodará ele manualmente no WSL.
echo "🚀 Applying database migrations..."
uv run python manage.py migrate --noinput

# 3. Inicia o servidor de desenvolvimento do Django
echo "🔥 Starting Django Development Server..."
uv run python manage.py runserver 0.0.0.0:8000
