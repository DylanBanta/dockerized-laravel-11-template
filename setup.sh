#!/bin/bash

# Check if the environment file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <environment file>"
  echo "Example: $0 config/testing.env"
  exit 1
fi

# Load the environment file
ENV_FILE=$1
if [ ! -f "$ENV_FILE" ]; then
  echo "Environment file '$ENV_FILE' not found."
  exit 1
fi

# Function to replace placeholders in variables
function process_placeholders() {
  local input=$1
  echo "$input" | sed -e "s/{PROJECT_NAME}/${PROJECT_NAME}/g"
}

# Source and process the environment variables
declare -A ENV_VARS
while IFS='=' read -r key value; do
  key=$(echo "$key" | xargs)  # Trim whitespace
  value=$(echo "$value" | xargs)  # Trim whitespace
  if [[ -n "$key" && "$key" != "#"* ]]; then
    processed_value=$(process_placeholders "$value")
    export "$key=$processed_value"
    ENV_VARS["$key"]="$processed_value"
  fi
done < "$ENV_FILE"

# Create the project directory
PROJECT_DIR="../${PROJECT_NAME}"
echo "Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"

# Create project-specific subdirectories
mkdir -p "$PROJECT_DIR/app-volume-${PROJECT_NAME}"
mkdir -p "$PROJECT_DIR/nginx-volume-${PROJECT_NAME}"
mkdir -p "$PROJECT_DIR/mysql-volume-${PROJECT_NAME}"

# Generate Nginx configuration
echo "Generating Dockerfile..."
sed \
  -e "s|\${APP_SERVICE_NAME}|${APP_SERVICE_NAME}|g" \
  < nginx.conf.template > "$PROJECT_DIR/nginx-volume-$PROJECT_NAME/default.conf"

# Generate Dockerfile
echo "Generating Dockerfile..."
sed \
  -e "s|\${PHP_VERSION}|${PHP_VERSION}|g" \
  -e "s|\${PHP_EXTENSIONS}|${PHP_EXTENSIONS}|g" \
  < Dockerfile.template > "$PROJECT_DIR/Dockerfile"

# Generate docker-compose.yml
echo "Generating docker-compose.yml..."
sed \
  -e "s|\${PROJECT_NAME}|${PROJECT_NAME}|g" \
  -e "s|\${APP_SERVICE_NAME}|${APP_SERVICE_NAME}|g" \
  -e "s|\${NGINX_SERVICE_NAME}|${NGINX_SERVICE_NAME}|g" \
  -e "s|\${MYSQL_SERVICE_NAME}|${MYSQL_SERVICE_NAME}|g" \
  -e "s|\${NETWORK_NAME}|${NETWORK_NAME}|g" \
  -e "s|\${NGINX_PORT}|${NGINX_PORT}|g" \
  -e "s|\${MYSQL_PORT}|${MYSQL_PORT}|g" \
  -e "s|\${MYSQL_DATABASE}|${MYSQL_DATABASE}|g" \
  -e "s|\${MYSQL_USER}|${MYSQL_USER}|g" \
  -e "s|\${MYSQL_PASSWORD}|${MYSQL_PASSWORD}|g" \
  -e "s|\${MYSQL_ROOT_PASSWORD}|${MYSQL_ROOT_PASSWORD}|g" \
  < docker-compose.yml.template > "$PROJECT_DIR/docker-compose.yml"

# Start the containers
echo "Starting containers..."
cd "$PROJECT_DIR" || exit
docker compose up --build -d

# Wait for the app container to become ready
echo "Waiting for app container (${APP_SERVICE_NAME}) to initialize..."
while ! docker exec -it "${APP_SERVICE_NAME}" bash -c "php -v" >/dev/null 2>&1; do
  echo "Waiting for ${APP_SERVICE_NAME} to become ready..."
  sleep 2
done

# Run Composer to create the Laravel project inside the container
echo "Creating Laravel project inside the app container..."
docker exec -it "${APP_SERVICE_NAME}" bash -c "composer create-project --prefer-dist laravel/laravel ."

# Adjust permissions for Laravel's storage and cache directories
echo "Setting permissions for Laravel directories..."
docker exec -it "${APP_SERVICE_NAME}" bash -c "chown -R www-data:www-data /var/www/html && chmod -R 775 /var/www/html"

echo "Laravel project setup complete. Access your application at http://<your-server>:${NGINX_PORT}"
