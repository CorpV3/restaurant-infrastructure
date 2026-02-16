# Restaurant Infrastructure

Kubernetes manifests and deployment configuration for the Restaurant Management System.

## Directory Structure

```
restaurant-infrastructure/
├── kubernetes/           # All Kubernetes manifests
│   ├── namespace.yaml
│   ├── secrets.yaml
│   ├── configmap.yaml
│   ├── postgres-statefulset.yaml
│   ├── rabbitmq-statefulset.yaml
│   ├── redis-statefulset.yaml
│   ├── api-gateway-deployment.yaml
│   ├── auth-service-deployment.yaml
│   ├── order-service-deployment.yaml
│   ├── restaurant-service-deployment.yaml
│   ├── customer-service-deployment.yaml
│   ├── integration-service-deployment.yaml
│   └── frontend-deployment.yaml
├── scripts/              # Deployment and utility scripts
│   ├── setup-test-namespace.sh
│   └── replicate-database.sh
└── argocd-application.yaml
```

## Deployment Strategy

### Test Environment (restaurant-test namespace)

1. **Initial Setup**:
   ```bash
   cd scripts
   chmod +x *.sh
   ./setup-test-namespace.sh
   ```

2. **Database Replication**:
   The setup script automatically replicates data from production (`restaurant-system`) to test (`restaurant-test`).

3. **Verify Deployment**:
   ```bash
   kubectl get pods -n restaurant-test
   ```

### Production Migration

Once testing is complete:

1. Update the namespace in all manifests from `restaurant-test` to `restaurant-system`
2. Update ArgoCD to point to the new infrastructure repo
3. Decommission the old monorepo deployment

## CI/CD Integration

Each service repository has its own GitHub Actions pipeline that:

1. Builds and tests the code
2. Builds and pushes Docker image to Docker Hub
3. Updates the image tag in this infrastructure repo
4. ArgoCD automatically syncs the change to Kubernetes

## Service Repositories

| Service | Repository |
|---------|------------|
| Frontend | `restaurant-frontend` |
| API Gateway | `restaurant-api-gateway` |
| Auth Service | `restaurant-auth-service` |
| Order Service | `restaurant-order-service` |
| Restaurant Service | `restaurant-service` |
| Customer Service | `restaurant-customer-service` |
| Integration Service | `restaurant-integration-service` |

## Required Secrets

### GitHub Secrets (in each service repo)

| Secret | Description |
|--------|-------------|
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token |
| `GH_PAT` | GitHub Personal Access Token (repo scope) |

### Kubernetes Secrets

Located in `kubernetes/secrets.yaml`:
- Database credentials
- JWT secrets
- RabbitMQ credentials
- Redis password
