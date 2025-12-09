#!/bin/bash

set -e

echo "Starting MuchTodo application with Docker Compose..."

docker-compose up -d

echo "Waiting for services to be healthy..."
sleep 10

echo "Services status:"
docker-compose ps

echo ""
echo "Application is running!"
echo "Backend API: http://localhost:8080"
echo "Health check: http://localhost:8080/health"
