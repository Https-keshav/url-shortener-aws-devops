#!/bin/bash
set -euxo pipefail

dnf install -y docker jq
systemctl enable --now docker

# --- Read DB credentials from Secrets Manager ---
SECRET=$(aws secretsmanager get-secret-value \
  --region ${region} --secret-id ${secret_arn} \
  --query SecretString --output text)
DB_USER=$(echo "$SECRET" | jq -r .username)
DB_PASS=$(echo "$SECRET" | jq -r .password)
DB_HOST=$(echo "$SECRET" | jq -r .host)
DB_PORT=$(echo "$SECRET" | jq -r .port)
DB_NAME=$(echo "$SECRET" | jq -r .dbname)

# --- Create the table if it does not exist (safe to run on every boot) ---
docker run --rm -e PGPASSWORD="$DB_PASS" -e PGSSLMODE=require postgres:16-alpine \
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
CREATE TABLE IF NOT EXISTS public.urls (
    id SERIAL PRIMARY KEY,
    original_url TEXT NOT NULL,
    short_code VARCHAR(20) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# --- Pull and run the app ---
aws ecr get-login-password --region ${region} | \
  docker login --username AWS --password-stdin ${registry}
docker pull ${image}

docker run -d --name app --restart unless-stopped \
  -p ${app_port}:${app_port} \
  -e PORT=${app_port} \
  -e BASE_URL="${base_url}" \
  -e DATABASE_URL="postgres://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=no-verify" \
  ${image}
  