# Restaurant Management System Helm Chart

This Helm chart deploys the complete Restaurant Management System on Kubernetes, including all microservices, databases, and infrastructure components.

## Architecture

The system consists of the following components:

- **API Gateway**: Routes requests to appropriate microservices with rate limiting
- **Auth Service**: Handles user authentication and authorization
- **Restaurant Service**: Manages restaurant, menu, table, and order operations
- **POS Service**: Point of Sale service (disabled by default, planned for future)
- **Frontend**: React-based web application
- **PostgreSQL**: Primary database (using Bitnami chart)
- **Redis**: Caching and session storage (using Bitnami chart)

## Prerequisites

- Kubernetes 1.20+
- Helm 3.0+
- kubectl configured to access your cluster

## Installation

### Add Bitnami Repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### Install the Chart

```bash
# Install with default values
helm install restaurant-system ./helm/restaurant-system --namespace restaurant-system --create-namespace

# Install with custom values
helm install restaurant-system ./helm/restaurant-system \
  --namespace restaurant-system \
  --create-namespace \
  --set apiGateway.image.tag=v1.0.0 \
  --set authService.image.tag=v1.0.0
```

### Upgrade the Chart

```bash
helm upgrade restaurant-system ./helm/restaurant-system --namespace restaurant-system
```

### Uninstall the Chart

```bash
helm uninstall restaurant-system --namespace restaurant-system
```

## Configuration

The following table lists the configurable parameters and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Docker registry | `docker.io` |
| `global.imagePullSecrets` | Image pull secrets | `[]` |
| `namespace` | Kubernetes namespace | `restaurant-system` |

### API Gateway

| Parameter | Description | Default |
|-----------|-------------|---------|
| `apiGateway.enabled` | Enable API Gateway | `true` |
| `apiGateway.replicaCount` | Number of replicas | `2` |
| `apiGateway.image.repository` | Image repository | `yourdockerhub/restaurant-api-gateway` |
| `apiGateway.image.tag` | Image tag | `latest` |
| `apiGateway.service.type` | Service type | `ClusterIP` |
| `apiGateway.service.port` | Service port | `8000` |
| `apiGateway.resources.limits.cpu` | CPU limit | `500m` |
| `apiGateway.resources.limits.memory` | Memory limit | `512Mi` |
| `apiGateway.autoscaling.enabled` | Enable HPA | `true` |
| `apiGateway.autoscaling.minReplicas` | Minimum replicas | `2` |
| `apiGateway.autoscaling.maxReplicas` | Maximum replicas | `10` |

### Auth Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `authService.enabled` | Enable Auth Service | `true` |
| `authService.replicaCount` | Number of replicas | `2` |
| `authService.image.repository` | Image repository | `yourdockerhub/restaurant-auth-service` |
| `authService.image.tag` | Image tag | `latest` |
| `authService.service.port` | Service port | `8001` |

### Restaurant Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `restaurantService.enabled` | Enable Restaurant Service | `true` |
| `restaurantService.replicaCount` | Number of replicas | `2` |
| `restaurantService.image.repository` | Image repository | `yourdockerhub/restaurant-restaurant-service` |
| `restaurantService.image.tag` | Image tag | `latest` |
| `restaurantService.service.port` | Service port | `8003` |

### POS Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `posService.enabled` | Enable POS Service | `false` |
| `posService.replicaCount` | Number of replicas | `2` |
| `posService.image.repository` | Image repository | `yourdockerhub/restaurant-pos-service` |
| `posService.image.tag` | Image tag | `latest` |
| `posService.service.port` | Service port | `8004` |

### Frontend

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.enabled` | Enable Frontend | `true` |
| `frontend.replicaCount` | Number of replicas | `2` |
| `frontend.image.repository` | Image repository | `yourdockerhub/restaurant-frontend` |
| `frontend.image.tag` | Image tag | `latest` |
| `frontend.service.type` | Service type | `LoadBalancer` |
| `frontend.service.port` | Service port | `3000` |

### PostgreSQL

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `postgresql.auth.username` | Database username | `restaurant_admin` |
| `postgresql.auth.password` | Database password | `restaurant_password` |
| `postgresql.auth.database` | Database name | `restaurant_db` |
| `postgresql.primary.persistence.size` | Storage size | `10Gi` |

### Redis

| Parameter | Description | Default |
|-----------|-------------|---------|
| `redis.enabled` | Enable Redis | `true` |
| `redis.architecture` | Redis architecture | `standalone` |
| `redis.auth.enabled` | Enable auth | `false` |
| `redis.master.persistence.size` | Storage size | `5Gi` |

### Secrets

| Parameter | Description | Default |
|-----------|-------------|---------|
| `secrets.jwtSecretKey` | JWT secret key | `change-me-in-production` |
| `secrets.sessionSecret` | Session secret | `change-me-in-production` |
| `secrets.postgresPassword` | PostgreSQL password | `restaurant_password` |

## Accessing the Application

### Frontend (LoadBalancer)

```bash
# Get the frontend URL
kubectl get svc frontend -n restaurant-system

# If using LoadBalancer
export FRONTEND_URL=$(kubectl get svc frontend -n restaurant-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend URL: http://$FRONTEND_URL:3000"
```

### API Gateway (via Port Forward)

```bash
kubectl port-forward svc/api-gateway 8000:8000 -n restaurant-system
# Access at http://localhost:8000
```

## Using with ArgoCD

This chart is designed to work with ArgoCD for GitOps deployments. See [argocd/application.yaml](../../argocd/application.yaml) for the ArgoCD application manifest.

```bash
# Apply the ArgoCD application
kubectl apply -f argocd/application.yaml -n argocd

# Check sync status
argocd app get restaurant-system
```

## CI/CD Integration

The system includes a GitHub Actions workflow that:
1. Runs tests for all services
2. Builds and pushes Docker images
3. Deploys to a KIND cluster for testing
4. Updates Helm values for ArgoCD production deployment

See [.github/workflows/ci-cd.yml](../../.github/workflows/ci-cd.yml) for details.

## Monitoring and Scaling

### Horizontal Pod Autoscaling

All services have HPA configured by default:

```bash
# Check HPA status
kubectl get hpa -n restaurant-system

# Scale manually (overrides HPA)
kubectl scale deployment api-gateway --replicas=5 -n restaurant-system
```

### View Logs

```bash
# API Gateway logs
kubectl logs -l app=api-gateway -n restaurant-system --tail=100 -f

# Auth Service logs
kubectl logs -l app=auth-service -n restaurant-system --tail=100 -f

# Restaurant Service logs
kubectl logs -l app=restaurant-service -n restaurant-system --tail=100 -f
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n restaurant-system
kubectl describe pod <pod-name> -n restaurant-system
```

### Check Services

```bash
kubectl get svc -n restaurant-system
```

### Check ConfigMaps and Secrets

```bash
kubectl get configmap restaurant-config -n restaurant-system -o yaml
kubectl get secret restaurant-secrets -n restaurant-system
```

### Database Connection Issues

```bash
# Check PostgreSQL pod
kubectl get pods -l app.kubernetes.io/name=postgresql -n restaurant-system

# Connect to PostgreSQL
kubectl exec -it <postgres-pod> -n restaurant-system -- psql -U restaurant_admin -d restaurant_db
```

### Redis Connection Issues

```bash
# Check Redis pod
kubectl get pods -l app.kubernetes.io/name=redis -n restaurant-system

# Connect to Redis
kubectl exec -it <redis-pod> -n restaurant-system -- redis-cli
```

## Security Considerations

1. **Change default secrets**: Update `secrets.jwtSecretKey`, `secrets.sessionSecret`, and `secrets.postgresPassword` in production
2. **Use image pull secrets**: Configure `global.imagePullSecrets` for private registries
3. **Enable ingress TLS**: Configure TLS certificates for production ingress
4. **Network policies**: Consider adding Kubernetes network policies for service isolation
5. **RBAC**: Ensure proper RBAC policies are in place

## Enabling POS Service

The POS service is disabled by default. To enable it:

```bash
helm upgrade restaurant-system ./helm/restaurant-system \
  --namespace restaurant-system \
  --set posService.enabled=true \
  --set posService.image.repository=yourdockerhub/restaurant-pos-service \
  --set posService.image.tag=v1.0.0
```

## Support

For issues and questions, please refer to the main repository documentation or open an issue on GitHub.
