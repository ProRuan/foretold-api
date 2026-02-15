#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-${DJANGO_ROLE:-web}}"

echo "Waiting for PostgreSQL on ${DB_HOST}:${DB_PORT}..."
until pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -q; do
  echo "PostgreSQL not ready - sleeping 1s"
  sleep 1
done
echo "PostgreSQL is ready."

python manage.py migrate --noinput

if [ "$ROLE" = "web" ]; then
  python manage.py collectstatic --noinput
fi

if [ "${DJANGO_CREATE_SUPERUSER:-false}" = "true" ]; then
  python manage.py shell <<'PY'
import os
from django.contrib.auth import get_user_model

username = os.getenv('DJANGO_SUPERUSER_USERNAME')
email = os.getenv('DJANGO_SUPERUSER_EMAIL')
password = os.getenv('DJANGO_SUPERUSER_PASSWORD')

if not (username and email and password):
    print('Superuser vars missing -> skipping.')
else:
    User = get_user_model()
    if User.objects.filter(username=username).exists():
        print(f"Superuser '{username}' already exists.")
    else:
        User.objects.create_superuser(username=username, email=email, password=password)
        print(f"Superuser '{username}' created.")
PY
fi

if [ "$ROLE" = "worker" ]; then
  exec python manage.py rqworker default
fi

exec gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers "${GUNICORN_WORKERS:-3}" --timeout 60
