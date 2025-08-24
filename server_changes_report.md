# Server Changes Report: Local Repository vs Production Environment

## Overview

Changes were discovered on the server `ncrag.voronkov.club` in the `/srv/docker/nc-rag/` directory that need to be incorporated into the repository for correct future deployments.

## Git Status on Server

```
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   docker-compose.yml
        modified:   scripts/register_webhooks.sh

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        services/node-red/settings.js
```

## Detailed Changes

### 1. docker-compose.yml

**Main Changes:**

#### Traefik Service:
- **Environment variables removed** - replaced with hardcoded values:
  - `${LETSENCRYPT_EMAIL:-admin@voronkov.club}` → `admin@voronkov.club`
- **Log level changed**: `DEBUG` → `INFO`
- **Additional logging settings removed**:
  - Removed line `--accesslog.filepath=/var/log/traefik/access.log`
- **HSTS middleware settings removed**:
  - Removed all labels with `traefik.http.middlewares.hsts.*`
- **Port format changed**: `"80:80"` → `80:80` (quotes removed)

#### Database (db):
- **Environment variables removed** - replaced with hardcoded values:
  - `${POSTGRES_DB:-nextcloud}` → `nextcloud`
  - `${POSTGRES_USER:-nextcloud}` → `nextcloud`  
  - `${POSTGRES_PASSWORD:-nextcloudpass}` → `nextcloudpass`

#### Redis:
- **Command format changed**: `["redis-server", "--appendonly", "no"]` → `redis-server --appendonly no`

#### Memcached:
- **Memory setting removed**: removed `command: ["-m", "128"]`

#### Nextcloud:
- **Image version downgraded**: `nextcloud:31-apache` → `nextcloud:30-apache`
- **Traefik dependency removed** from `depends_on`
- **Environment variables removed** - replaced with hardcoded values:
  - All `${POSTGRES_*}` variables
  - `${NEXTCLOUD_ADMIN_USER:-admin}` → `admin`
  - `${NEXTCLOUD_ADMIN_PASSWORD:-adminpass}` → `j*yDCX<4ubIj_.w##>lhxDc?` (real password!)
  - `${NEXTCLOUD_TRUSTED_DOMAINS:-ncrag.voronkov.club}` → `ncrag.voronkov.club`
- **Traefik labels changed**:
  - Removed `hsts` middleware
  - Changed routing rule: `/webhooks/nextcloud` → `/nodered`
  - Changed priority: `100` → `1`

#### Nextcloud-cron:
- **Image version downgraded**: `nextcloud:31-apache` → `nextcloud:30-apache`
- **Environment variables removed** - replaced with hardcoded values

#### Node-RED:
- **Build method changed**: `build: context: ./services/node-red` → `image: nodered/node-red:4.1`
- **Environment variables removed** - replaced with hardcoded values:
  - `${TENANT_DEFAULT:-default}` → `default`
  - `${WEBHOOK_SECRET:-change-me}` → `changeme`
- **Volume mappings changed**:
  - Commented out: `#- ./services/node-red/flows.json:/data/flows.json`
  - Added: `- ./services/node-red/settings.js:/data/settings.js`
- **Traefik labels completely redesigned**:
  - Added two separate routers: `nodered-webhook` and `nodered-ui`
  - Changed paths: `/webhooks/nextcloud` → `/nodered/webhooks` and `/nodered`
  - Different priorities: 1000 and 900

#### Removed nc-webhook-seeder service:
- Completely removed `nc-webhook-seeder` service from the end of the file

### 2. scripts/register_webhooks.sh

**Main Changes:**

#### Webhook path correction:
- **Old path**: `uri="https://${NC_DOMAIN}/webhooks/nextcloud"`
- **New path**: `uri="https://${NC_DOMAIN}/nodered/webhooks/nextcloud"`

#### Logic improvements:
- **Idempotency removed**: removed check for existing webhooks
- **Added informative comments and emojis** for better readability
- **Simplified logic**: now always registers events without checking

#### Enhanced output:
- Added informative messages about the registration process
- More understandable final output

### 3. New file: services/node-red/settings.js

**Completely new file** with Node-RED settings:

```javascript
module.exports = {
    // Base URL path for Node-RED
    httpRoot: '/nodered',
    
    // UI settings  
    ui: { path: '/nodered/ui' },
    
    // Enable internal authentication
    adminAuth: {
        type: "credentials",
        users: [{
            username: "admin",
            password: "$2y$08$hUKXnOEmu9xHp48TbLdc2.7VqE1fhtxpwyW4/HRNupGn8Cikb23ta",
            permissions: "*"
        }]
    },
    
    // Other settings...
}
```

**Key Features:**
- Base path configuration `/nodered`
- Built-in authentication with hashed password
- Customized header and URL

### 4. Missing file: .env

A `.env` file was created on the server with real values:
- Real passwords and secrets
- Specific URLs and domains
- Settings for all services

## Recommendations for Repository Changes

### Critically Important Changes:

1. **Create .env.example** with updated variable structure
2. **Add services/node-red/settings.js** to repository
3. **Fix paths in scripts/register_webhooks.sh**
4. **Update docker-compose.yml** with correct Node-RED configuration

### Changes Requiring Caution:

1. **Image versions**: decide whether to use nextcloud:30 or 31
2. **Environment variables**: restore variable usage instead of hardcoded values
3. **Traefik settings**: restore HSTS and other security headers
4. **nc-webhook-seeder service**: decide if it's needed

### Security:

⚠️ **WARNING**: Real passwords are used in plain text in docker-compose.yml on the server. It's necessary to:
1. Restore environment variable usage
2. Ensure .env file is in .gitignore
3. Update passwords after making changes

## Next Steps

1. Create .env.example based on server .env
2. Copy settings.js to repository
3. Update docker-compose.yml with correct Node-RED paths
4. Fix register_webhooks.sh
5. Test deployment in staging environment