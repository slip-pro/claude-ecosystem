# Woodpecker CI Setup

Self-hosted CI/CD as a replacement for GitHub Actions. Repos stay on GitHub,
pipelines run on your VPS.

## Server Installation

### 1. GitHub OAuth App

Go to **GitHub Settings -> Developer Settings -> OAuth Apps -> New OAuth App**

| Field | Value |
|-------|-------|
| Application name | Woodpecker CI |
| Homepage URL | `https://ci.YOUR-DOMAIN.com` |
| Callback URL | `https://ci.YOUR-DOMAIN.com/authorize` |

Save **Client ID** and **Client Secret**.

### 2. Deploy to VPS

```bash
# Create directory
mkdir -p /opt/woodpecker && cd /opt/woodpecker

# Copy files from this template
# docker-compose.yml and .env.example -> .env

# Fill in .env values
cp .env.example .env
nano .env  # set all values

# Generate agent secret
openssl rand -hex 32  # paste into WOODPECKER_AGENT_SECRET

# Start
docker compose up -d
```

### 3. Reverse Proxy

Add to your existing reverse proxy config.

**Nginx:**
```nginx
server {
    listen 443 ssl http2;
    server_name ci.YOUR-DOMAIN.com;
    ssl_certificate /etc/letsencrypt/live/ci.YOUR-DOMAIN.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ci.YOUR-DOMAIN.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;
        proxy_buffering off;
    }
}
```

**Caddy:**
```
ci.YOUR-DOMAIN.com {
    reverse_proxy 127.0.0.1:8000
}
```

**Traefik:** add labels to woodpecker-server in docker-compose.yml:
```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.woodpecker.rule=Host(`ci.YOUR-DOMAIN.com`)
  - traefik.http.routers.woodpecker.tls.certresolver=letsencrypt
  - traefik.http.services.woodpecker.loadbalancer.server.port=8000
```

### 4. First Login

1. Open `https://ci.YOUR-DOMAIN.com`
2. Log in with GitHub
3. Go to **Repos** -> enable a repository
4. Woodpecker auto-creates the GitHub webhook
5. Set `WOODPECKER_OPEN=false` in .env, restart: `docker compose restart`

## Project Setup

### Add Pipeline

Copy the appropriate template to your project root as `.woodpecker.yml`:

| Template | Use Case |
|----------|----------|
| `node-fullstack.yml` | Node.js app: lint + test + build + SSH deploy |
| `docker-deploy.yml` | Docker image: build + push to registry + deploy |
| `static-site.yml` | Static site: build + rsync deploy |

### Add Secrets

In Woodpecker UI -> Repo Settings -> Secrets:

| Secret | Description |
|--------|-------------|
| `DEPLOY_HOST` | Server IP or domain |
| `DEPLOY_USER` | SSH username |
| `DEPLOY_SSH_KEY` | Private SSH key |
| `REGISTRY_USER` | Docker registry username (docker-deploy only) |
| `REGISTRY_TOKEN` | Docker registry token (docker-deploy only) |

For secrets shared across repos: use **Organization Secrets** or **Global Secrets** (Admin Panel).

### Migrate from GitHub Actions

1. Add `.woodpecker.yml` to the project
2. Push and verify pipeline runs
3. Delete `.github/workflows/` directory
4. Commit

## Resources

- [Woodpecker CI Docs](https://woodpecker-ci.org/docs/intro)
- [Workflow Syntax](https://woodpecker-ci.org/docs/usage/workflow-syntax)
- [Plugin Index](https://woodpecker-ci.org/plugins)
- [Secrets Management](https://woodpecker-ci.org/docs/usage/secrets)
