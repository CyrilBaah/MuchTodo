# MuchTodo - Container Deployment Guide

This guide provides comprehensive instructions for deploying the MuchTodo backend application using Docker and Kubernetes.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Phase 1: Docker Setup](#phase-1-docker-setup)
- [Phase 2: Kubernetes Deployment](#phase-2-kubernetes-deployment)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software
- Docker (v20.10+)
- Docker Compose (v2.0+)
- kubectl (v1.25+)
- Kind (Kubernetes in Docker) (v0.17+)
- Go (v1.25.1) - for local development

### Installation Commands

**Docker & Docker Compose:**
```bash
# macOS
brew install docker docker-compose

# Linux
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

**kubectl:**
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Kind:**
```bash
# macOS
brew install kind

# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

## Project Structure

```
MuchToDo/
├── cmd/
│   └── api/
│       └── main.go
├── internal/
│   ├── handlers/
│   ├── models/
│   ├── middleware/
│   └── ...
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── kubernetes/
│   ├── namespace.yaml
│   ├── mongodb/
│   │   ├── mongodb-secret.yaml
│   │   ├── mongodb-configmap.yaml
│   │   ├── mongodb-pvc.yaml
│   │   ├── mongodb-deployment.yaml
│   │   └── mongodb-service.yaml
│   ├── backend/
│   │   ├── backend-secret.yaml
│   │   ├── backend-configmap.yaml
│   │   ├── backend-deployment.yaml
│   │   └── backend-service.yaml
│   └── ingress.yaml
├── scripts/
│   ├── docker-build.sh
│   ├── docker-run.sh
│   ├── k8s-deploy.sh
│   └── k8s-cleanup.sh
└── README.md
```

## Phase 1: Docker Setup

### 1. Build Docker Image

Build the optimized multi-stage Docker image:

```bash
# Using the script
./scripts/docker-build.sh

# Or manually
docker build -t muchtodo-backend:latest .
```

**Dockerfile Features:**
- Multi-stage build for optimization
- Non-root user for security
- Health check implementation
- Minimal Alpine-based final image
- Efficient layer caching

### 2. Run with Docker Compose

Start the application with MongoDB:

```bash
# Using the script
./scripts/docker-run.sh

# Or manually
docker-compose up -d
```

**Docker Compose Configuration:**
- Backend application on port 8080
- MongoDB with persistent storage
- Automatic dependency management
- Health checks for reliability
- Auto-restart on failure

### 3. Verify Docker Deployment

```bash
# Check running containers
docker-compose ps

# View logs
docker-compose logs -f backend

# Test the API
curl http://localhost:8080/health
curl http://localhost:8080/ping

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## Phase 2: Kubernetes Deployment

### 1. Create Kind Cluster

Create a local Kubernetes cluster:

```bash
# Create cluster
kind create cluster --name muchtodo

# Verify cluster
kubectl cluster-info --context kind-muchtodo
kubectl get nodes
```

### 2. Load Docker Image to Kind

```bash
# Build the image first
./scripts/docker-build.sh

# Load image into Kind cluster
kind load docker-image muchtodo-backend:latest --name muchtodo
```

### 3. Deploy to Kubernetes

Deploy all components:

```bash
# Using the script
./scripts/k8s-deploy.sh

# Or manually
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml
```

**Deployment includes:**
- Dedicated namespace (muchtodo)
- MongoDB with persistent storage
- Backend with 2 replicas
- ConfigMaps for configuration
- Secrets for sensitive data
- NodePort service for external access
- Ingress for routing

### 4. Verify Kubernetes Deployment

```bash
# Check all resources
kubectl get all -n muchtodo

# Check pods
kubectl get pods -n muchtodo

# Check services
kubectl get svc -n muchtodo

# Check ingress
kubectl get ingress -n muchtodo

# View pod logs
kubectl logs -f deployment/backend -n muchtodo

# Describe pod for details
kubectl describe pod -l app=backend -n muchtodo
```

### 5. Access the Application

**Via NodePort:**
```bash
# Access directly via NodePort
curl http://localhost:30080/health
curl http://localhost:30080/ping
```

**Via Ingress (optional):**
```bash
# Add to /etc/hosts
echo "127.0.0.1 muchtodo.local" | sudo tee -a /etc/hosts

# Install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Access via ingress
curl http://muchtodo.local
```

## Verification

### Health Checks

```bash
# Docker
curl http://localhost:8080/health

# Kubernetes (NodePort)
curl http://localhost:30080/health
```

Expected response:
```json
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2025-12-09T18:00:00Z"
}
```

### API Endpoints

```bash
# Root endpoint
curl http://localhost:30080/

# Ping endpoint
curl http://localhost:30080/ping

# Swagger documentation
curl http://localhost:30080/swagger/index.html
```

## Troubleshooting

### Docker Issues

**Container won't start:**
```bash
# Check logs
docker-compose logs backend

# Check MongoDB connection
docker-compose logs mongodb

# Restart services
docker-compose restart
```

**Port already in use:**
```bash
# Find process using port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>
```

### Kubernetes Issues

**Pods not starting:**
```bash
# Check pod status
kubectl get pods -n muchtodo

# Describe pod
kubectl describe pod <pod-name> -n muchtodo

# Check logs
kubectl logs <pod-name> -n muchtodo

# Check events
kubectl get events -n muchtodo --sort-by='.lastTimestamp'
```

**Image pull errors:**
```bash
# Verify image is loaded in Kind
docker exec -it muchtodo-control-plane crictl images | grep muchtodo

# Reload image
kind load docker-image muchtodo-backend:latest --name muchtodo
```

**MongoDB connection issues:**
```bash
# Check MongoDB pod
kubectl get pod -l app=mongodb -n muchtodo

# Check MongoDB logs
kubectl logs -l app=mongodb -n muchtodo

# Test MongoDB connection
kubectl exec -it deployment/mongodb -n muchtodo -- mongosh -u root -p example
```

**Service not accessible:**
```bash
# Check service
kubectl get svc -n muchtodo

# Port forward for testing
kubectl port-forward svc/backend 8080:8080 -n muchtodo

# Test via port forward
curl http://localhost:8080/health
```

## Cleanup

### Docker Cleanup

```bash
# Stop and remove containers
docker-compose down

# Remove volumes
docker-compose down -v

# Remove images
docker rmi muchtodo-backend:latest
```

### Kubernetes Cleanup

```bash
# Using the script
./scripts/k8s-cleanup.sh

# Or manually
kubectl delete namespace muchtodo

# Delete Kind cluster
kind delete cluster --name muchtodo
```

## Configuration

### Environment Variables

**Backend Configuration:**
- `PORT`: Application port (default: 8080)
- `MONGO_URI`: MongoDB connection string
- `DB_NAME`: Database name
- `JWT_SECRET_KEY`: Secret key for JWT tokens
- `JWT_EXPIRATION_HOURS`: Token expiration time
- `LOG_LEVEL`: Logging level (DEBUG, INFO, WARN, ERROR)
- `LOG_FORMAT`: Log format (json, text)
- `ENABLE_CACHE`: Enable Redis caching (true/false)

### Secrets Management

**MongoDB Credentials:**
- Username: `root` (base64: `cm9vdA==`)
- Password: `example` (base64: `ZXhhbXBsZQ==`)

**JWT Secret:**
- Secret: `your-super-secret-key-that-is-long-and-random`

**Note:** Change these values in production!

## Resource Limits

### Backend Pods
- Requests: 128Mi memory, 100m CPU
- Limits: 256Mi memory, 200m CPU

### MongoDB Pod
- Requests: 256Mi memory, 250m CPU
- Limits: 512Mi memory, 500m CPU

## Monitoring

```bash
# Watch pod status
kubectl get pods -n muchtodo -w

# Monitor resource usage
kubectl top pods -n muchtodo

# View real-time logs
kubectl logs -f deployment/backend -n muchtodo
```

## Additional Commands

```bash
# Scale backend replicas
kubectl scale deployment/backend --replicas=3 -n muchtodo

# Update deployment
kubectl rollout restart deployment/backend -n muchtodo

# Check rollout status
kubectl rollout status deployment/backend -n muchtodo

# View deployment history
kubectl rollout history deployment/backend -n muchtodo
```

## Support

For issues or questions:
1. Check the logs: `kubectl logs -f deployment/backend -n muchtodo`
2. Review events: `kubectl get events -n muchtodo`
3. Verify configuration: `kubectl get configmap,secret -n muchtodo`

