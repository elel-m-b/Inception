# 🐳 Inception — A Deep Dive into Docker & DevOps

> *"Tell me and I forget. Teach me and I remember. Involve me and I learn."* — Benjamin Franklin

---

## 📋 Table of Contents

1. [Introduction](#1-introduction)
2. [Core Docker Concepts](#2-core-docker-concepts)
3. [Dockerfile — Deep Dive](#3-dockerfile--deep-dive)
4. [Docker Compose — Core of the Project](#4-docker-compose--core-of-the-project)
5. [Networking](#5-networking)
6. [Volumes and Persistence](#6-volumes-and-persistence)
7. [Inception Architecture](#7-inception-architecture)
8. [Security and Best Practices](#8-security-and-best-practices)
9. [Debugging and Troubleshooting](#9-debugging-and-troubleshooting)
10. [Advanced Concepts — Low Level](#10-advanced-concepts--low-level)
11. [Evaluation Questions — 42 Style](#11-evaluation-questions--42-style)
12. [Full Example Project](#12-full-example-project)
13. [Makefile Explanation](#13-makefile-explanation)
14. [Conclusion](#14-conclusion)

---

## 1. Introduction

### What is Inception?

Inception is a **system administration project** at 42 School that requires you to set up a small **infrastructure composed of different services** using **Docker** and **Docker Compose**. You are not allowed to use pre-built images from Docker Hub (except for Alpine or Debian base images). You must build everything yourself.

The project forces you to understand:
- How Docker containers actually work at a fundamental level
- How multi-service architectures communicate
- How to manage data persistence, secrets, networking, and security
- The DevOps mindset: infrastructure as code, reproducibility, isolation

### The Goal

| Objective | Why It Matters |
|-----------|----------------|
| Understand Docker internals | You can't debug what you don't understand |
| Set up NGINX + WordPress + MariaDB | A classic, production-like web stack |
| Use Docker Compose | Industry-standard tool for multi-container apps |
| Practice DevOps thinking | Reproducible, isolated, maintainable infrastructure |

### Virtual Machines vs. Containers

This is **the most fundamental concept** to grasp before anything else.

```
┌─────────────────────────────────────────────────────────────┐
│                     VIRTUAL MACHINES                        │
├─────────────────────────────────────────────────────────────┤
│  App A         App B         App C                          │
│  ─────         ─────         ─────                          │
│  Bins/Libs     Bins/Libs     Bins/Libs                      │
│  ─────────     ─────────     ─────────                      │
│  Guest OS      Guest OS      Guest OS    ← Full OS per VM   │
│  (Ubuntu)      (CentOS)      (Debian)                       │
│  ──────────────────────────────────────                     │
│              Hypervisor                  ← VMware, VirtualBox│
│  ──────────────────────────────────────                     │
│              Host OS                                        │
│  ──────────────────────────────────────                     │
│              Hardware                                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                       CONTAINERS                            │
├─────────────────────────────────────────────────────────────┤
│  App A         App B         App C                          │
│  ─────         ─────         ─────                          │
│  Bins/Libs     Bins/Libs     Bins/Libs  ← Only what's needed│
│  ──────────────────────────────────────                     │
│              Docker Engine              ← Shared kernel     │
│  ──────────────────────────────────────                     │
│              Host OS                                        │
│  ──────────────────────────────────────                     │
│              Hardware                                       │
└─────────────────────────────────────────────────────────────┘
```

| Feature | Virtual Machine | Container |
|---------|----------------|-----------|
| **Startup time** | Minutes | Milliseconds |
| **Size** | Gigabytes | Megabytes |
| **Isolation** | Full OS isolation | Process-level isolation |
| **Kernel** | Own kernel per VM | Shares host kernel |
| **Overhead** | High (full OS) | Very low |
| **Use case** | Strong isolation needed | Microservices, fast deployments |

> **Key insight:** A container is NOT a mini-VM. It is a **regular Linux process** that is isolated using kernel features (namespaces and cgroups). The kernel is shared. This is why containers are so fast and lightweight.

---

## 2. Core Docker Concepts

### What is Docker?

Docker is a **platform for building, shipping, and running applications in containers**. It provides:

- A **standard format** for packaging apps (images)
- A **runtime** for running containers (Docker Engine)
- A **registry** for storing and sharing images (Docker Hub / your own registry)
- Tools like **Docker Compose** for orchestrating multi-container apps

### Docker Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      DOCKER ARCHITECTURE                     │
│                                                              │
│  ┌─────────────┐          ┌──────────────────────────────┐  │
│  │ Docker CLI  │          │      Docker Daemon           │  │
│  │             │          │      (dockerd)               │  │
│  │ docker run  │─────────▶│                              │  │
│  │ docker build│  REST    │  ┌──────────┐ ┌──────────┐  │  │
│  │ docker ps   │  API     │  │Container │ │Container │  │  │
│  │             │          │  │  nginx   │ │wordpress │  │  │
│  └─────────────┘          │  └──────────┘ └──────────┘  │  │
│                           │                              │  │
│  ┌─────────────┐          │  ┌──────────────────────┐   │  │
│  │ Docker      │          │  │    Image Cache       │   │  │
│  │ Compose     │─────────▶│  │  nginx:alpine        │   │  │
│  │             │          │  │  debian:bullseye      │   │  │
│  └─────────────┘          └──────────────────────────────┘  │
│                                        │                     │
│                                        │ pull/push           │
│                                        ▼                     │
│                           ┌────────────────────────┐        │
│                           │   Docker Registry      │        │
│                           │   (Docker Hub /        │        │
│                           │    private registry)   │        │
│                           └────────────────────────┘        │
└──────────────────────────────────────────────────────────────┘
```

**Three main components:**

1. **Docker Client (`docker` CLI):** The tool you type commands into. It speaks to the Docker daemon via a REST API over a Unix socket (`/var/run/docker.sock`).

2. **Docker Daemon (`dockerd`):** The background service that does all the heavy lifting: pulling images, creating containers, managing networks and volumes.

3. **Docker Registry:** A storage and distribution system for Docker images. Docker Hub is the default public registry. In production, companies run private registries.

---

### Images vs Containers

> **The relationship:** An image is to a container as a **class is to an object** in OOP, or a **recipe is to a meal**.

```
           BUILD                    RUN
┌──────────────┐      docker run    ┌──────────────────┐
│ Dockerfile   │─────────────────▶ │   Container      │
│              │                    │  (running image) │
│ Instructions │                    │                  │
│ + Base image │ docker build       │  Has its own:    │
│              │─────────────────▶ │  - Filesystem    │
│              │     ┌──────────┐   │  - Network       │
│              │     │  Image   │   │  - Process space │
│              │     │ (frozen  │   │                  │
│              │     │ snapshot)│   └──────────────────┘
└──────────────┘     └──────────┘
```

**Image:** A read-only template. A stack of filesystem layers. Immutable. Can be stored and shared.

**Container:** A running instance of an image. Has a writable layer on top. Lives and dies. Can be stopped/started.

#### Container Lifecycle

```
                    docker run
                        │
                        ▼
              ┌─────────────────┐
              │    CREATED      │ ◀─── docker create
              └────────┬────────┘
                       │ docker start
                       ▼
              ┌─────────────────┐
              │    RUNNING      │ ◀─── docker start / docker run
              └────────┬────────┘
                       │ process exits / docker stop
                       ▼
              ┌─────────────────┐
              │    STOPPED      │ ──── docker start ──▶ RUNNING
              │    (Exited)     │
              └────────┬────────┘
                       │ docker rm
                       ▼
              ┌─────────────────┐
              │    DELETED      │
              └─────────────────┘

Special state:
              ┌─────────────────┐
              │    PAUSED       │ ◀─── docker pause (SIGSTOP)
              └─────────────────┘ ──── docker unpause ──▶ RUNNING
```

---

### Layers and Union File System

This is how Docker makes images efficient. Every instruction in a Dockerfile creates a **new layer**. Layers are stacked on top of each other.

```
┌─────────────────────────────────────────────┐
│           UNION FILESYSTEM (OverlayFS)      │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  Container Layer (READ/WRITE)       │   │  ← Your running container writes here
│  │  /tmp/newfile.txt                   │   │    This layer is DELETED when container
│  │  /etc/nginx/nginx.conf (modified)   │   │    is removed (unless volume used!)
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │  Image Layer 4 (READ ONLY)          │   │  ← COPY ./nginx.conf /etc/nginx/
│  │  /etc/nginx/nginx.conf              │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │  Image Layer 3 (READ ONLY)          │   │  ← RUN apt-get install nginx
│  │  /usr/sbin/nginx                    │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │  Image Layer 2 (READ ONLY)          │   │  ← RUN apt-get update
│  │  /var/lib/apt/lists/...             │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │  Image Layer 1 (READ ONLY)          │   │  ← FROM debian:bullseye
│  │  / (base filesystem)                │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

**Key facts:**
- Layers are **shared** between images. If two images use the same `debian:bullseye` base, that layer is stored only once on disk.
- This is called **Copy-on-Write (CoW)**: when a container needs to modify a read-only file, it copies that file up to the writable container layer.
- This is why Docker images are efficient in both **storage** and **startup time**.

---

### How Docker Uses the Linux Kernel

Docker is NOT magic. It uses two fundamental Linux kernel features:

#### 1. Namespaces — Isolation

Namespaces make a process *think* it is alone on the system.

| Namespace | Isolates |
|-----------|----------|
| `pid` | Process IDs (container sees its own PID 1) |
| `net` | Network interfaces, IP addresses, routing |
| `mnt` | Filesystem mount points |
| `uts` | Hostname and domain name |
| `ipc` | Inter-process communication (shared memory) |
| `user` | User and group IDs |

```
┌────────────────────────────────────────────────┐
│  Host: PID 1=systemd, PID 1234=dockerd, ...    │
│                                                │
│  ┌──────────────────────────────────────────┐ │
│  │  Container (nginx)                        │ │
│  │  PID namespace: PID 1 = nginx            │ │
│  │  Net namespace: eth0 = 172.18.0.2        │ │
│  │  Mnt namespace: / = overlay filesystem   │ │
│  │  UTS namespace: hostname = "nginx"       │ │
│  └──────────────────────────────────────────┘ │
│                                                │
│  ┌──────────────────────────────────────────┐ │
│  │  Container (mariadb)                     │ │
│  │  PID namespace: PID 1 = mysqld           │ │
│  │  Net namespace: eth0 = 172.18.0.3        │ │
│  │  Mnt namespace: / = overlay filesystem   │ │
│  └──────────────────────────────────────────┘ │
└────────────────────────────────────────────────┘
```

#### 2. cgroups — Resource Control

Control Groups (cgroups) limit and measure resource usage of a group of processes.

```
cgroups can limit:
  ├── CPU:    max 50% of 2 cores
  ├── Memory: max 512MB RAM
  ├── I/O:    max 100MB/s disk read
  └── Net:    network bandwidth (via tc)
```

You can set these in Docker Compose:
```yaml
services:
  wordpress:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

> **Summary:** A Docker container is just a Linux process running with namespaces (isolation) and cgroups (resource limits). There is no emulation, no virtualization, no separate kernel. This is why containers start in milliseconds.

---

## 3. Dockerfile — Deep Dive

A `Dockerfile` is a **text file with instructions** to build a Docker image. Each instruction creates a new layer.

### Every Instruction Explained

#### `FROM` — The Starting Point

```dockerfile
FROM debian:bullseye
FROM alpine:3.18
FROM debian:bullseye AS builder   # Multi-stage build
```

- Every Dockerfile **must** start with `FROM`
- Specifies the **base image** to start from
- `alpine` is ~5MB; `debian:bullseye` is ~80MB
- `AS builder` names a stage for multi-stage builds

#### `RUN` — Execute Commands During Build

```dockerfile
RUN apt-get update && apt-get install -y nginx \
    && rm -rf /var/lib/apt/lists/*
```

- Executes a command **during the image build**
- Creates a new layer for each `RUN` instruction
- **Best practice:** Chain commands with `&&` and `\` to reduce layers
- **Always** clean package manager caches in the **same** `RUN` to keep layers small

#### `COPY` vs `ADD`

```dockerfile
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY --chown=www-data:www-data ./html /var/www/html

ADD https://example.com/file.tar.gz /tmp/    # ← Can fetch URLs
ADD archive.tar.gz /app/                      # ← Auto-extracts tar
```

| Instruction | Use case |
|-------------|----------|
| `COPY` | Copy local files/dirs into the image. **Prefer this.** |
| `ADD` | Like COPY, but can also fetch URLs and auto-extract archives. Use sparingly. |

> **Best practice:** Use `COPY` unless you specifically need `ADD`'s extra features. `COPY` is more explicit and predictable.

#### `CMD` vs `ENTRYPOINT`

This is one of the most misunderstood parts of Dockerfiles.

```dockerfile
# CMD — default command, can be overridden at runtime
CMD ["nginx", "-g", "daemon off;"]

# ENTRYPOINT — always runs, even if you pass arguments
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]   # These become default args to ENTRYPOINT

# Shell form vs Exec form
CMD nginx -g "daemon off;"         # Shell form (spawns /bin/sh -c)
CMD ["nginx", "-g", "daemon off;"] # Exec form (runs directly, PREFERRED)
```

**The exec form (`["cmd", "arg"]`) is strongly preferred** because:
- Signals (like `SIGTERM` from `docker stop`) go directly to your process
- In shell form, signals go to `sh`, not your app — the app may not shut down cleanly

```
ENTRYPOINT + CMD combination:
  ENTRYPOINT ["nginx"]  +  CMD ["-g", "daemon off;"]
  → runs: nginx -g "daemon off;"

  docker run myimage -g "daemon off; error_log /dev/stderr;"
  → runs: nginx -g "daemon off; error_log /dev/stderr;"
  (CMD is replaced by what you pass at runtime; ENTRYPOINT stays)
```

#### `WORKDIR` — Set Working Directory

```dockerfile
WORKDIR /var/www/html
# All subsequent COPY, RUN, CMD instructions use this directory
COPY index.php .    # Copies to /var/www/html/index.php
```

- Creates the directory if it doesn't exist
- Better than `RUN cd /some/dir` (which doesn't persist between layers)

#### `ENV` — Environment Variables

```dockerfile
ENV PHP_VERSION=8.1
ENV WORDPRESS_DB_HOST=mariadb
ENV APP_ENV=production
```

- Sets environment variables **in the image and all containers** created from it
- Available at both build time and run time
- Can be overridden at runtime: `docker run -e APP_ENV=staging myimage`

#### `EXPOSE` — Document Ports

```dockerfile
EXPOSE 443
EXPOSE 9000   # PHP-FPM
```

- **Does NOT publish the port** to the host
- It's documentation: "this container listens on this port"
- Actual publishing happens with `-p` flag or `ports:` in docker-compose

#### `ARG` — Build-time Variables

```dockerfile
ARG DEBIAN_FRONTEND=noninteractive
ARG USER=www-data

RUN useradd -r $USER
```

- Only available **during the build** (unlike ENV, which persists in the image)
- Pass with `docker build --build-arg USER=nginx .`
- **Never use ARG for secrets** — they appear in image history

#### `USER` — Set the Running User

```dockerfile
RUN useradd -r -s /bin/false www-data
USER www-data
```

- All subsequent instructions and the container run as this user
- **Critical for security:** never run containers as root

#### `VOLUME` — Declare Mount Points

```dockerfile
VOLUME ["/var/lib/mysql"]
VOLUME ["/var/www/html"]
```

- Declares that this path should be managed as a volume
- Bypasses the union filesystem for performance
- Data in these paths is NOT deleted when the container is removed (if using named volumes)

---

### Layers and Caching — Understanding Build Performance

Docker caches each layer. When you rebuild, it only rebuilds layers that changed.

```dockerfile
# ❌ BAD — COPY source before installing dependencies
FROM debian:bullseye
COPY . /app          ← Any source code change invalidates ALL layers below
RUN apt-get update
RUN apt-get install -y php

# ✅ GOOD — Install dependencies first, copy source last
FROM debian:bullseye
RUN apt-get update && apt-get install -y php   ← This layer is cached!
COPY . /app                                     ← Only this layer rebuilds on source change
```

**Cache invalidation rules:**
- If a layer changes, **all subsequent layers** are invalidated
- `COPY` and `ADD` invalidate the cache if the file contents changed
- `RUN` invalidates if the instruction text changed

---

### Real Examples

#### NGINX Dockerfile

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/CN=login.42.fr"

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
```

#### WordPress + PHP-FPM Dockerfile

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4 \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-mbstring \
    php7.4-xml \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Download and install wp-cli
RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -O /usr/local/bin/wp && chmod +x /usr/local/bin/wp

WORKDIR /var/www/html

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm7.4", "-F"]
```

#### MariaDB Dockerfile

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

COPY conf/my.cnf /etc/mysql/my.cnf
COPY tools/init_db.sh /init_db.sh
RUN chmod +x /init_db.sh

VOLUME ["/var/lib/mysql"]

EXPOSE 3306

ENTRYPOINT ["/init_db.sh"]
CMD ["mysqld_safe"]
```

---

### Best Practices Summary

```
✅ DO:
  - Use specific base image tags (debian:bullseye, not debian:latest)
  - Combine RUN commands to minimize layers
  - Clean package caches in the same RUN layer
  - Use exec form for CMD/ENTRYPOINT
  - Copy only what you need (use .dockerignore)
  - Run as non-root user
  - Use multi-stage builds for compiled languages

❌ DON'T:
  - Use root user unnecessarily
  - Store secrets in ENV or ARG
  - Use latest tags in production
  - Install unnecessary packages
  - Leave build tools in final image
```

---

## 4. Docker Compose — Core of the Project

Docker Compose lets you define and run **multi-container applications** using a YAML file. It's the core tool for Inception.

### docker-compose.yml Structure

```yaml
version: '3.8'                     # Compose file format version

services:                          # Define your containers here
  nginx:                           # Service name (also used as hostname!)
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    image: nginx:inception         # Tag for the built image
    container_name: nginx          # Optional: explicit container name
    ports:
      - "443:443"
    networks:
      - inception_network
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - wordpress
    restart: unless-stopped        # Restart policy

  wordpress:
    build: ./requirements/wordpress
    container_name: wordpress
    networks:
      - inception_network
    volumes:
      - wordpress_data:/var/www/html
    environment:
      - WORDPRESS_DB_HOST=mariadb
      - WORDPRESS_DB_NAME=${DB_NAME}
      - WORDPRESS_DB_USER=${DB_USER}
      - WORDPRESS_DB_PASSWORD=${DB_PASSWORD}
    depends_on:
      - mariadb
    restart: unless-stopped

  mariadb:
    build: ./requirements/mariadb
    container_name: mariadb
    networks:
      - inception_network
    volumes:
      - mariadb_data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=${DB_NAME}
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PASSWORD}
    restart: unless-stopped

volumes:                           # Declare named volumes
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/wordpress

  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/mariadb

networks:                          # Declare custom networks
  inception_network:
    driver: bridge
```

---

### Services

Each `service` is a container definition. Key fields:

| Field | Description |
|-------|-------------|
| `build` | Path to Dockerfile or build context config |
| `image` | Image name (used when building or pulling) |
| `container_name` | Override the auto-generated container name |
| `ports` | `"host:container"` port mapping |
| `networks` | Which networks this service joins |
| `volumes` | Volume mounts for this service |
| `environment` | Environment variables |
| `depends_on` | Start order (see limitations below) |
| `restart` | Restart policy: `no`, `always`, `unless-stopped`, `on-failure` |

---

### Volumes in Compose

```yaml
volumes:
  wordpress_data:        # Named volume — Docker manages the location
    driver: local

  # OR bind to a specific host path:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/user/data/mariadb  # Host path
```

- **Named volumes:** Docker stores them under `/var/lib/docker/volumes/`
- **Bind mounts:** Directly map a host path into the container
- **Inception requirement:** You must use a specific host path, hence `driver_opts`

---

### Networks in Compose

```yaml
networks:
  inception_network:
    driver: bridge    # Default driver, creates a virtual bridge
```

When services share a network, they can communicate using **service names as hostnames**. This is Docker's built-in DNS. See [Section 5](#5-networking) for deep explanation.

---

### `build` vs `image`

```yaml
# Option 1: build from Dockerfile
build:
  context: ./requirements/nginx    # Directory containing Dockerfile
  dockerfile: Dockerfile           # Optional if named "Dockerfile"

# Option 2: use existing image from registry
image: nginx:alpine

# Option 3: build AND tag the resulting image
build: ./requirements/nginx
image: nginx:inception   # The built image will be tagged with this name
```

---

### `depends_on` — Limitations (Very Important!)

```yaml
depends_on:
  - mariadb
```

> ⚠️ **Critical misunderstanding:** `depends_on` only controls **start order**. It does **NOT** wait for the service to be *ready*.

This means:
- Docker starts `mariadb` before `wordpress`
- But `wordpress` might try to connect to MariaDB **before MariaDB has finished initializing**
- This causes "can't connect to database" errors

**The solution:** Handle this in your entrypoint script:

```bash
#!/bin/bash
# WordPress entrypoint.sh

# Wait for MariaDB to be ready
until mysql -h mariadb -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" &>/dev/null; do
    echo "Waiting for MariaDB..."
    sleep 2
done

echo "MariaDB is ready. Starting WordPress..."
exec php-fpm7.4 -F
```

---

### Environment Variables and `.env`

Docker Compose automatically reads a `.env` file in the same directory:

```bash
# .env file (NEVER commit this to Git!)
DB_NAME=wordpress
DB_USER=wp_user
DB_PASSWORD=secure_password_here
DB_ROOT_PASSWORD=even_more_secure
USER=yourlogin
DOMAIN_NAME=yourlogin.42.fr
```

In `docker-compose.yml`, reference with `${VARIABLE}`:

```yaml
environment:
  - MYSQL_DATABASE=${DB_NAME}
  - MYSQL_USER=${DB_USER}
  - MYSQL_PASSWORD=${DB_PASSWORD}
```

> **Security note:** Never hardcode passwords in `docker-compose.yml`. Always use `.env` files — and add `.env` to your `.gitignore`.

---

## 5. Networking

### Bridge Networks

When Docker is installed, it creates a default `bridge` network. Containers on the same bridge network can communicate with each other.

```
┌─────────────────────────────────────────────────────────────┐
│                      Host Machine                           │
│                                                             │
│  ┌───────────┐     ┌───────────┐     ┌───────────┐        │
│  │  nginx    │     │ wordpress │     │  mariadb  │        │
│  │172.18.0.2 │     │172.18.0.3 │     │172.18.0.4 │        │
│  └─────┬─────┘     └─────┬─────┘     └─────┬─────┘        │
│        └─────────────────┴─────────────────┘               │
│                           │                                 │
│               ┌───────────┴──────────┐                     │
│               │    docker0 bridge    │                     │
│               │    172.18.0.1/16     │                     │
│               └───────────┬──────────┘                     │
│                           │                                 │
│               ┌───────────┴──────────┐                     │
│               │      eth0 (NIC)      │ ← Physical/Virtual  │
│               │      192.168.1.x     │   network interface  │
│               └──────────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

### Custom Networks vs Default

Inception uses a **custom bridge network** defined in `docker-compose.yml`. This is better than the default network because:

1. Better **DNS resolution** (service names work as hostnames)
2. Better **isolation** (containers not in your network can't reach yours)
3. More **control** over IP ranges and configuration

### How Docker DNS Works — Why "mariadb" Works as Hostname

This is a magical-seeming feature that has a simple explanation.

Docker runs an **embedded DNS server** at `127.0.0.11` inside each container. When a container tries to resolve `mariadb`:

```
Container (wordpress) wants to connect to "mariadb:3306"
         │
         ▼
  DNS query: "mariadb" → 127.0.0.11 (Docker's embedded DNS)
         │
         ▼
  Docker DNS checks: which container on this network has
  the service name "mariadb"?
         │
         ▼
  Returns: 172.18.0.4 (mariadb container's IP)
         │
         ▼
  Connection: 172.18.0.4:3306 ✅
```

This is why in WordPress config you write `DB_HOST=mariadb` — Docker resolves it to the MariaDB container's IP address automatically. The service name in `docker-compose.yml` **IS** the hostname.

---

### Ports vs EXPOSE

```yaml
# EXPOSE — documentation only, does NOT publish to host
EXPOSE 9000   # In Dockerfile — just says "I listen here"

# ports — actually publishes to the host
ports:
  - "443:443"    # host_port:container_port
  - "127.0.0.1:8080:80"   # bind to specific host IP

# expose (Compose) — similar to EXPOSE in Dockerfile
expose:
  - "9000"   # Available to other containers, not to host
```

```
┌─────────────────────────────────────────────────────┐
│                 Host Machine                        │
│                                                     │
│  Browser → port 443 ─────┐                         │
│                           ▼                         │
│               ┌──────────────────┐                 │
│               │  nginx container │                 │
│               │  port 443 (TLS)  │                 │
│               └────────┬─────────┘                 │
│                         │ port 9000 (internal)      │
│               ┌──────────────────┐                 │
│               │ wordpress (PHP)  │  ← NOT exposed  │
│               │  port 9000       │    to host!     │
│               └────────┬─────────┘                 │
│                         │ port 3306 (internal)      │
│               ┌──────────────────┐                 │
│               │ mariadb container│  ← NOT exposed  │
│               │  port 3306       │    to host!     │
│               └──────────────────┘                 │
└─────────────────────────────────────────────────────┘
```

> **Security principle:** Only the NGINX container should be accessible from outside. MariaDB and WordPress should only be reachable by other containers on the internal network.

---

### Reverse Proxy Concept (NGINX)

A reverse proxy sits **in front of** your application servers and handles incoming requests.

```
Internet Browser
       │
       │  HTTPS Request: https://login.42.fr/
       ▼
┌─────────────────────────────────┐
│           NGINX                 │
│  - Terminates TLS/SSL           │
│  - Serves static files          │
│  - Forwards PHP requests to     │
│    WordPress (FastCGI/PHP-FPM)  │
└───────────────┬─────────────────┘
                │  FastCGI (port 9000)
                ▼
┌─────────────────────────────────┐
│         WordPress/PHP-FPM       │
│  - Processes PHP code           │
│  - Queries database             │
└───────────────┬─────────────────┘
                │  MySQL protocol (port 3306)
                ▼
┌─────────────────────────────────┐
│           MariaDB               │
│  - Stores all data              │
│  - Returns query results        │
└─────────────────────────────────┘
```

Benefits of NGINX as reverse proxy:
- **SSL termination:** Handles TLS once; backend communication is unencrypted (within trusted internal network)
- **Single entry point:** Only port 443 is exposed to the internet
- **Performance:** NGINX is extremely efficient at handling concurrent connections
- **Static files:** NGINX serves CSS, images, JS directly without involving PHP

---

## 6. Volumes and Persistence

### Why Containers Are Ephemeral

When a container is stopped and removed, **everything written to its writable layer is lost**. This is by design — containers are supposed to be stateless and reproducible.

```
Container created from Image
        │
        ▼
┌───────────────────┐
│  Container        │
│  Writable Layer   │  ← You write a database row here
│  (overlay fs)     │
└──────────┬────────┘
           │
      docker rm
           │
           ▼
   ❌ DATA IS GONE
```

For databases and user uploads, we need **persistence** beyond the container's lifecycle.

---

### Named Volumes vs Bind Mounts

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  NAMED VOLUME                    BIND MOUNT               │
│                                                            │
│  volumes:                        volumes:                  │
│    mydata:                         - /host/path:/cnt/path  │
│                                                            │
│  Docker manages the location     You specify the location  │
│  /var/lib/docker/volumes/...     on the host               │
│                                                            │
│  Good for:                       Good for:                 │
│  - Production data               - Development (live code) │
│  - Portability                   - Config files            │
│  - Managed by Docker             - Specific host paths     │
│                                  (required by Inception!)  │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### Inception Volume Configuration

The project requires data to be stored at a specific host path:

```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/wordpress   # Host path

  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/mariadb     # Host path
```

This is technically a **bind mount** expressed as a named volume. The data physically lives at those host paths.

### Data Flow

```
Container: mariadb
  /var/lib/mysql/  ←──── Volume: mariadb_data ────→ Host: ~/data/mariadb/
       │                        (bind)                       │
       │                                                     │
  INSERT INTO posts...                              Files on host disk:
  writes to /var/lib/mysql/                         ibdata1, wordpress/...
       │
  docker rm mariadb  ←── Container deleted
       │
  docker run mariadb  ←── New container started
       │
  /var/lib/mysql/  ← Volume mounted again → same data! ✅
```

---

## 7. Inception Architecture

### Full System Diagram

```
                            INTERNET
                                │
                                │ HTTPS (port 443)
                                ▼
                   ┌────────────────────────┐
                   │        NGINX           │
                   │                        │
                   │  • TLS termination     │
                   │    (self-signed cert)  │
                   │  • SSL: TLSv1.2/1.3   │
                   │  • Reverse proxy       │
                   │  • Static files        │
                   └──────────┬─────────────┘
                              │
                              │ FastCGI (port 9000)
                              │ Internal Docker network
                              ▼
                   ┌────────────────────────┐
                   │     WordPress          │
                   │     (PHP-FPM)          │
                   │                        │
                   │  • Processes PHP       │
                   │  • Serves WP pages     │
                   │  • wp-config.php       │
                   │    reads env vars      │
                   └──────────┬─────────────┘
                              │
                              │ MySQL protocol (port 3306)
                              │ Internal Docker network
                              ▼
                   ┌────────────────────────┐
                   │       MariaDB          │
                   │                        │
                   │  • Stores all data     │
                   │  • Users, posts, etc.  │
                   │  • InnoDB engine       │
                   └──────────┬─────────────┘
                              │
                              ▼
                   ┌────────────────────────┐
                   │  Volume: mariadb_data  │
                   │  Host: ~/data/mariadb  │
                   └────────────────────────┘


Volume mounts:
  wordpress_data (~/data/wordpress) ──→ nginx:/var/www/html
                                    ──→ wordpress:/var/www/html
```

### Request Flow — Step by Step

A user visits `https://yourlogin.42.fr/`:

```
1. Browser → DNS → resolves yourlogin.42.fr → Host machine IP
2. Host machine → Docker port mapping → NGINX container port 443
3. NGINX terminates TLS (decrypts HTTPS)
4. NGINX reads the request path: /wp-login.php → PHP file
5. NGINX sends FastCGI request to wordpress:9000
6. PHP-FPM (WordPress) receives request, runs wp-login.php
7. WordPress code connects to mariadb:3306
8. MariaDB processes SQL query, returns data
9. WordPress builds HTML response
10. Response travels back: WordPress → NGINX → Browser (re-encrypted)
```

---

## 8. Security and Best Practices

### No Root Containers

Running containers as root is dangerous. If a vulnerability is exploited, the attacker has root inside the container — and potentially on the host if there are container escape vulnerabilities.

```dockerfile
# Create a dedicated user
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 --gid 1001 --no-create-home appuser

# Switch to that user
USER appuser

# All subsequent commands and the container run as appuser
CMD ["nginx", "-g", "daemon off;"]
```

> **Exception:** Some services like NGINX need to bind to port 443 (privileged port < 1024). The master process starts as root, then drops privileges for worker processes.

---

### Secrets Management

**Never** put secrets in:
- Docker images (they are visible in image history with `docker history`)
- `docker-compose.yml` (it's in version control)
- Environment variables (visible with `docker inspect`)

**Options for Inception:**
1. **`.env` file** (minimum viable, kept outside git) — acceptable for 42 project
2. **Docker Secrets** (proper production approach):

```yaml
# docker-compose.yml
services:
  mariadb:
    secrets:
      - db_password
    environment:
      - MYSQL_PASSWORD_FILE=/run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt   # Content: just the password
```

```bash
# In container, read the secret
DB_PASSWORD=$(cat /run/secrets/db_password)
```

---

### SSL Certificates

Inception requires TLS 1.2 or 1.3 only (no older TLS/SSL versions).

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt \
    -subj "/C=FR/L=Paris/O=42Network/CN=${DOMAIN_NAME}"
```

```nginx
# nginx.conf SSL configuration
server {
    listen 443 ssl;
    server_name yourlogin.42.fr;

    ssl_certificate     /etc/ssl/certs/nginx.crt;
    ssl_certificate_key /etc/ssl/private/nginx.key;

    # Only allow TLSv1.2 and TLSv1.3 (no TLS 1.0, 1.1, no SSLv3)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;
}
```

---

### Environment Variable Risks

```bash
# ❌ DANGEROUS - visible in process list
docker run -e DB_PASSWORD=secret myimage

# ❌ DANGEROUS - visible in docker inspect
environment:
  - DB_PASSWORD=mysecretpassword

# ✅ BETTER - use .env file (not in git)
environment:
  - DB_PASSWORD=${DB_PASSWORD}   # References .env

# ✅ BEST - Docker secrets (not visible in inspect)
secrets:
  - db_password
```

---

## 9. Debugging and Troubleshooting

### Essential Commands

#### `docker logs` — View Container Output

```bash
# Show all logs
docker logs nginx

# Follow (stream) logs in real time
docker logs -f wordpress

# Show last 50 lines
docker logs --tail 50 mariadb

# Show logs with timestamps
docker logs -t nginx

# Show logs since a time
docker logs --since 2024-01-01T00:00:00 mariadb
```

#### `docker exec` — Run Commands Inside a Running Container

```bash
# Open an interactive shell
docker exec -it nginx bash
docker exec -it nginx sh    # Alpine uses sh, not bash

# Run a single command
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"

# Check nginx configuration
docker exec nginx nginx -t

# Check PHP-FPM is running
docker exec wordpress ps aux | grep php

# Check environment variables inside container
docker exec wordpress env
```

#### `docker inspect` — Get Detailed Container Info

```bash
# Full JSON info
docker inspect nginx

# Get IP address of container
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx

# Get mounted volumes
docker inspect -f '{{json .Mounts}}' wordpress | python3 -m json.tool

# Get environment variables
docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' mariadb
```

#### Other Useful Commands

```bash
# List containers (running)
docker ps

# List all containers (including stopped)
docker ps -a

# List images
docker images

# List volumes
docker volume ls

# List networks
docker network ls

# Show network details (containers connected, IPs)
docker network inspect inception_inception_network

# Show resource usage (CPU, memory, network)
docker stats

# Show disk usage
docker system df
```

---

### Common Inception Errors and Fixes

#### 1. WordPress can't connect to MariaDB

```
Error: "Error establishing a database connection"
```

**Diagnoses:**
```bash
# Is MariaDB running?
docker ps | grep mariadb

# Check MariaDB logs
docker logs mariadb

# Test connection from WordPress container
docker exec -it wordpress bash
mysql -h mariadb -u wp_user -p wordpress
# If this works, the connection is fine — check wp-config.php
```

**Causes:**
- MariaDB not fully initialized yet → add wait loop in entrypoint
- Wrong hostname (not `mariadb` but something else)
- Wrong password
- User doesn't have permissions on the database

---

#### 2. NGINX returns 502 Bad Gateway

```
502 Bad Gateway — nginx
```

**Meaning:** NGINX can't reach the WordPress FastCGI backend.

```bash
# Check if WordPress is running
docker ps | grep wordpress
docker logs wordpress

# Check PHP-FPM is listening on port 9000
docker exec wordpress ss -tlnp | grep 9000

# Test FastCGI connection from NGINX container
docker exec nginx nc -zv wordpress 9000
```

**Causes:**
- WordPress/PHP-FPM container crashed
- PHP-FPM not listening on `0.0.0.0:9000` (check `www.conf`)
- `fastcgi_pass` in nginx.conf points to wrong hostname

---

#### 3. Container keeps restarting

```bash
docker ps
# STATUS: Restarting (1) 5 seconds ago
```

```bash
# Check exit code
docker inspect --format '{{.State.ExitCode}}' mariadb

# Read the logs
docker logs mariadb

# Run interactively to debug
docker run -it --entrypoint /bin/bash myimage:mariadb
```

**Causes:**
- Entrypoint script fails (syntax error, missing file)
- Permission error on volume mount
- Service fails to start (config error)

---

#### 4. Volume permissions denied

```
mkdir: cannot create directory '/var/lib/mysql': Permission denied
```

```bash
# Check the host directory exists and has correct permissions
ls -la ~/data/
# Create it if needed:
mkdir -p ~/data/wordpress ~/data/mariadb
```

---

#### 5. SSL/TLS handshake errors

```bash
# Test SSL from outside
curl -kv https://localhost:443

# Check certificate details
docker exec nginx openssl x509 -in /etc/ssl/certs/nginx.crt -text -noout

# Test specific TLS version
curl -k --tlsv1.2 https://yourlogin.42.fr
```

---

## 10. Advanced Concepts — Low Level

### How Containers Isolate Processes

When Docker runs a container, it calls the Linux `clone()` syscall with special flags:

```c
// Simplified — what Docker does to create a container
pid_t child = clone(
    container_main,    // Function to run
    stack_top,
    CLONE_NEWPID |     // New PID namespace
    CLONE_NEWNET |     // New network namespace
    CLONE_NEWNS  |     // New mount namespace
    CLONE_NEWUTS |     // New UTS (hostname) namespace
    CLONE_NEWIPC |     // New IPC namespace
    SIGCHLD,
    &args
);
```

Inside the new namespace, the process (e.g., nginx) has PID 1. It can't see any other processes on the system. It thinks it's alone.

---

### Namespaces Deep Dive

```
Host process tree:
  systemd (PID 1)
    ├── dockerd (PID 847)
    │     ├── [nginx container] ──── PID namespace: nginx = PID 1
    │     │                                (host PID: 2341)
    │     └── [mariadb container] ── PID namespace: mysqld = PID 1
    │                                        (host PID: 2567)
    └── sshd (PID 1123)
```

```bash
# See the host PID of a container's PID 1
docker inspect --format '{{.State.Pid}}' nginx
# Returns e.g. 2341

# From the host, you can see it:
ps aux | grep 2341   # Shows nginx

# From inside the container:
docker exec nginx ps aux
# Shows only nginx's processes, starting from PID 1
```

**Network Namespace:**
```bash
# Each container has its own network interfaces
docker exec nginx ip addr show
# eth0 with container IP — completely separate from host's eth0

# On host, Docker creates veth pairs:
ip link show
# Shows: vethXXXXXX@docker0 — one end in container, one in host bridge
```

---

### cgroups Resource Limits

```bash
# On the host, find your container's cgroup:
cat /proc/$(docker inspect --format '{{.State.Pid}}' nginx)/cgroup

# View memory limit (0 = unlimited)
cat /sys/fs/cgroup/memory/docker/<container-id>/memory.limit_in_bytes

# Set limits in docker-compose.yml:
services:
  mariadb:
    mem_limit: 512m
    cpus: "0.5"
```

---

### How Docker Networking Works Internally (iptables)

When you run `docker-compose up`, Docker creates iptables rules to enable networking:

```bash
# View Docker's iptables rules
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v
```

```
Docker networking internals:

1. Creates a bridge: docker0 (or custom bridge for Compose networks)
   ip link add docker0 type bridge

2. Assigns IP range: 172.18.0.0/16 to the bridge
   ip addr add 172.18.0.1/16 dev docker0

3. For each container, creates a veth pair:
   ip link add veth0 type veth peer name veth1
   # veth0 goes into container (renamed to eth0)
   # veth1 stays on host, attached to docker0 bridge

4. NAT for outbound traffic (containers reaching internet):
   iptables -t nat -A POSTROUTING -s 172.18.0.0/16 ! -o docker0 -j MASQUERADE

5. Port publishing (443:443):
   iptables -t nat -A DOCKER -p tcp --dport 443 -j DNAT --to-destination 172.18.0.2:443
```

---

## 11. Evaluation Questions — 42 Style

### Q: What is the difference between a VM and a container?

**A:** A **Virtual Machine** emulates complete hardware and runs a full operating system with its own kernel. It provides strong isolation but is resource-heavy (GB of RAM, minutes to boot). A **container** shares the host's kernel and uses Linux namespaces and cgroups for process-level isolation. It's lightweight (MB of RAM, milliseconds to start) but all containers share the same kernel. VMs are isolated at the hardware level; containers at the process level.

---

### Q: What is a Docker image?

**A:** A Docker image is an **immutable, layered filesystem snapshot** that contains everything needed to run an application: the OS libraries, dependencies, application code, and configuration. Images are built from Dockerfiles. Each instruction creates a read-only layer. Images are stored in registries (like Docker Hub). When you run an image, Docker adds a writable container layer on top. The image itself is never modified.

---

### Q: What is a Dockerfile and what do the main instructions do?

**A:** A Dockerfile is a text file containing sequential instructions to build a Docker image. Key instructions: `FROM` sets the base image; `RUN` executes commands during build; `COPY` copies files from host to image; `CMD` defines the default command to run; `ENTRYPOINT` defines the executable that always runs; `WORKDIR` sets the working directory; `ENV` sets environment variables; `EXPOSE` documents which ports the container listens on; `USER` sets the user for subsequent commands.

---

### Q: How does networking work in Docker Compose?

**A:** Docker Compose creates a **custom bridge network** for all services. Each service gets a network interface with an IP address. Docker runs an **embedded DNS server** at `127.0.0.11` inside each container. When a container queries a hostname (like `mariadb`), Docker's DNS resolves it to the corresponding container's IP address. This is why services can connect to each other using service names as hostnames. Traffic between containers stays on the internal bridge network and never leaves the host.

---

### Q: Why do we need volumes? What happens without them?

**A:** Without volumes, all data written inside a container is stored in its **writable layer** (part of the union filesystem). When the container is deleted (e.g., `docker rm`), this layer is destroyed and all data is lost permanently. Volumes provide **persistence** by storing data outside the container's lifecycle — either in a Docker-managed location or a specific host path. MariaDB data (databases, tables) and WordPress uploads must persist across container restarts, which is why volumes are essential.

---

### Q: How do the three services communicate?

**A:** All three services are on the same Docker network (`inception_network`). The browser connects to NGINX on port 443 (the only port exposed to the outside). NGINX handles TLS termination and forwards PHP requests to WordPress using the **FastCGI protocol** on port 9000 (WordPress's PHP-FPM server). WordPress connects to MariaDB on port 3306 using the MySQL protocol. Docker's DNS resolves `wordpress` and `mariadb` to the correct container IPs. MariaDB and WordPress are not exposed to the host — they're only accessible within the Docker network.

---

### Q: What is PHP-FPM and why does WordPress use it?

**A:** PHP-FPM (FastCGI Process Manager) is a high-performance PHP interpreter. It runs as a separate service, manages a pool of PHP worker processes, and listens for FastCGI connections. NGINX itself cannot execute PHP code — it only serves static files efficiently. For dynamic PHP pages, NGINX passes the request to PHP-FPM via the FastCGI protocol, PHP-FPM executes the PHP code, and returns HTML to NGINX. This separation is more efficient than older methods like `mod_php`.

---

### Q: What is TLS and why must we use TLSv1.2/1.3 only?

**A:** TLS (Transport Layer Security) encrypts the communication between the browser and NGINX, preventing eavesdropping and tampering. Older versions (SSL 3.0, TLS 1.0, TLS 1.1) have known vulnerabilities (POODLE, BEAST, CRIME) and are considered insecure. TLSv1.2 and TLSv1.3 use modern cipher suites and are currently considered secure. The project requires disabling older protocols to follow current security best practices.

---

### Q: What is `docker-compose up --build` vs `docker-compose up`?

**A:** `docker-compose up` starts services using existing images if available. `docker-compose up --build` forces a rebuild of all images before starting, even if they already exist. Use `--build` when you've changed a Dockerfile or the code copied into an image. Without `--build`, you might run outdated images without realizing it.

---

### Q: What is the role of NGINX in this project?

**A:** NGINX serves three roles: (1) **Reverse proxy** — it's the single entry point; it receives all HTTPS requests and forwards them to the appropriate backend. (2) **TLS terminator** — it handles SSL/TLS encryption/decryption so backend services don't need to. (3) **Static file server** — it serves CSS, JavaScript, and image files directly (very efficiently) without involving PHP.

---

## 12. Full Example Project

### Directory Structure

```
inception/
├── Makefile
├── .env                          ← NOT in git
├── .gitignore
├── srcs/
│   ├── docker-compose.yml
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   └── conf/
│       │       └── nginx.conf
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   ├── conf/
│       │   │   └── www.conf
│       │   └── tools/
│       │       └── entrypoint.sh
│       └── mariadb/
│           ├── Dockerfile
│           ├── conf/
│           │   └── my.cnf
│           └── tools/
│               └── init_db.sh
```

---

### `docker-compose.yml`

```yaml
version: '3.8'

services:

  nginx:
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    image: nginx:inception
    container_name: nginx
    ports:
      - "443:443"
    networks:
      - inception_network
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - wordpress
    restart: unless-stopped

  wordpress:
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    image: wordpress:inception
    container_name: wordpress
    networks:
      - inception_network
    volumes:
      - wordpress_data:/var/www/html
    environment:
      - WORDPRESS_DB_HOST=mariadb
      - WORDPRESS_DB_NAME=${DB_NAME}
      - WORDPRESS_DB_USER=${DB_USER}
      - WORDPRESS_DB_PASSWORD=${DB_PASSWORD}
      - WORDPRESS_ADMIN_USER=${WP_ADMIN_USER}
      - WORDPRESS_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}
      - WORDPRESS_ADMIN_EMAIL=${WP_ADMIN_EMAIL}
      - WORDPRESS_URL=https://${DOMAIN_NAME}
      - DOMAIN_NAME=${DOMAIN_NAME}
    depends_on:
      - mariadb
    restart: unless-stopped

  mariadb:
    build:
      context: ./requirements/mariadb
      dockerfile: Dockerfile
    image: mariadb:inception
    container_name: mariadb
    networks:
      - inception_network
    volumes:
      - mariadb_data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=${DB_NAME}
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PASSWORD}
    restart: unless-stopped

volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/wordpress

  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/mariadb

networks:
  inception_network:
    driver: bridge
```

---

### `.env`

```bash
# Domain
DOMAIN_NAME=yourlogin.42.fr
USER=yourlogin

# MariaDB
DB_NAME=wordpress
DB_USER=wp_user
DB_PASSWORD=wp_secure_password_123
DB_ROOT_PASSWORD=root_secure_password_456

# WordPress admin
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin_secure_password_789
WP_ADMIN_EMAIL=admin@yourlogin.42.fr

# WordPress second user
WP_USER=editor
WP_USER_PASSWORD=editor_password_321
WP_USER_EMAIL=editor@yourlogin.42.fr
```

---

### NGINX Dockerfile

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Generate SSL certificate at build time
# Note: In production, this should be a real certificate
RUN mkdir -p /etc/ssl/private /etc/ssl/certs && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx-selfsigned.key \
        -out /etc/ssl/certs/nginx-selfsigned.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=Student/CN=yourlogin.42.fr"

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

# Nginx must run in foreground (not as daemon) for Docker
CMD ["nginx", "-g", "daemon off;"]
```

### NGINX Configuration (`conf/nginx.conf`)

```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    sendfile      on;

    server {
        listen 443 ssl;
        server_name yourlogin.42.fr;

        # SSL Configuration
        ssl_certificate     /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
        ssl_protocols       TLSv1.2 TLSv1.3;
        ssl_ciphers         ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305;

        root /var/www/html;
        index index.php index.html;

        # Try files, then pass to WordPress
        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        # Pass PHP files to PHP-FPM (WordPress container)
        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_pass wordpress:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $fastcgi_path_info;
        }

        # Deny access to .htaccess
        location ~ /\.ht {
            deny all;
        }
    }
}
```

---

### WordPress Dockerfile

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4 \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    wget \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        -O /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# PHP-FPM configuration
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Entrypoint script
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create www-data user directories
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm7.4", "-F"]
```

### WordPress Entrypoint (`tools/entrypoint.sh`)

```bash
#!/bin/bash
set -e

# Wait for MariaDB to be ready
echo "Waiting for MariaDB..."
until mysql -h mariadb \
            -u "${WORDPRESS_DB_USER}" \
            -p"${WORDPRESS_DB_PASSWORD}" \
            "${WORDPRESS_DB_NAME}" \
            -e "SELECT 1;" &>/dev/null; do
    echo "MariaDB not ready yet. Retrying in 2s..."
    sleep 2
done
echo "MariaDB is ready!"

# Check if WordPress is already installed
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Downloading WordPress..."
    wp core download \
        --path=/var/www/html \
        --locale=en_US \
        --allow-root

    echo "Configuring WordPress..."
    wp config create \
        --path=/var/www/html \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="${WORDPRESS_DB_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root

    echo "Installing WordPress..."
    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --allow-root

    echo "Creating second user..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    chown -R www-data:www-data /var/www/html
    echo "WordPress installed successfully!"
else
    echo "WordPress already installed. Skipping setup."
fi

# Execute the CMD
exec "$@"
```

### WordPress PHP-FPM Config (`conf/www.conf`)

```ini
[www]
user = www-data
group = www-data

; Listen on all interfaces on port 9000 (required for Docker networking)
listen = 0.0.0.0:9000

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

---

### MariaDB Dockerfile

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# MariaDB configuration
COPY conf/my.cnf /etc/mysql/my.cnf

# Database initialization script
COPY tools/init_db.sh /init_db.sh
RUN chmod +x /init_db.sh

# Ensure data directory exists and has correct permissions
RUN mkdir -p /var/lib/mysql /run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /run/mysqld

VOLUME ["/var/lib/mysql"]

EXPOSE 3306

ENTRYPOINT ["/init_db.sh"]
```

### MariaDB Config (`conf/my.cnf`)

```ini
[mysqld]
# Listen on all interfaces (required for Docker networking)
bind-address = 0.0.0.0

# Data directory
datadir = /var/lib/mysql

# Socket
socket = /run/mysqld/mysqld.sock

# Basic settings
user = mysql
port = 3306

[client]
socket = /run/mysqld/mysqld.sock
```

### MariaDB Init Script (`tools/init_db.sh`)

```bash
#!/bin/bash
set -e

# Initialize MariaDB data directory if empty
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db
fi

# Start MariaDB temporarily for setup
mysqld_safe --skip-networking &
MYSQL_PID=$!

# Wait for MariaDB to start
echo "Waiting for MariaDB to start..."
until mysql -u root -e "SELECT 1" &>/dev/null; do
    sleep 1
done
echo "MariaDB started."

# Create database and user if not exists
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo "Database setup complete."

# Stop the temporary mysqld
kill "$MYSQL_PID"
wait "$MYSQL_PID" 2>/dev/null || true

echo "Starting MariaDB in foreground..."
exec mysqld_safe
```

---

## 13. Makefile Explanation

The Makefile provides convenient shortcuts for managing your Docker Compose project.

```makefile
# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR_WP  = /home/$(shell whoami)/data/wordpress
DATA_DIR_DB  = /home/$(shell whoami)/data/mariadb

# Default target — what runs when you just type "make"
all: setup up

# Create host data directories (required before first run)
setup:
	@echo "Creating data directories..."
	@mkdir -p $(DATA_DIR_WP) $(DATA_DIR_DB)

# Start all services (build if needed, then start in background)
up: setup
	@docker-compose -f $(COMPOSE_FILE) up -d --build

# Stop and remove containers (keep volumes)
down:
	@docker-compose -f $(COMPOSE_FILE) down

# Stop all services without removing containers
stop:
	@docker-compose -f $(COMPOSE_FILE) stop

# Start previously stopped services
start:
	@docker-compose -f $(COMPOSE_FILE) start

# Show running containers
ps:
	@docker-compose -f $(COMPOSE_FILE) ps

# Show logs (all services)
logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f

# Show logs for a specific service: make log SERVICE=nginx
log:
	@docker-compose -f $(COMPOSE_FILE) logs -f $(SERVICE)

# Rebuild images without using cache
rebuild:
	@docker-compose -f $(COMPOSE_FILE) build --no-cache
	@docker-compose -f $(COMPOSE_FILE) up -d

# Full cleanup: stop, remove containers, images, volumes, and data
clean: down
	@docker-compose -f $(COMPOSE_FILE) down --rmi all -v
	@docker system prune -af

# Nuclear option: remove EVERYTHING including host data
fclean: clean
	@sudo rm -rf $(DATA_DIR_WP) $(DATA_DIR_DB)
	@docker volume prune -f
	@docker network prune -f

# Full rebuild from scratch
re: fclean all

.PHONY: all setup up down stop start ps logs log rebuild clean fclean re
```

### How `make` Works

When you run `make`, Make reads `Makefile` and executes the recipe for the **first target** (or the target you specify).

```
make             → runs 'all' target → runs 'setup' then 'up'
make up          → runs 'up' target
make clean       → runs 'clean' target
make re          → runs 'fclean' then 'all' (full rebuild)
make log SERVICE=nginx  → shows nginx logs
```

The `@` prefix silences the command itself from being printed:
```makefile
up:
	@docker-compose up    # ← @ suppresses "docker-compose up" from printing
	docker-compose up     # ← Without @, the command itself is printed, then executed
```

`.PHONY` tells Make these are not filenames but always-run targets:
```makefile
.PHONY: all up down clean fclean re
# Without .PHONY, if a file named "clean" existed, "make clean" might not run
```

---

## 14. Conclusion

### What You Should Have Learned

By completing this project and deeply understanding this README, you now know:

**Docker Fundamentals:**
- Containers are not VMs — they are isolated Linux processes using namespaces and cgroups
- Images are immutable, layered filesystem snapshots
- Containers add a writable layer on top of the image, which is ephemeral
- The Union File System (OverlayFS) makes layers efficient through copy-on-write

**Dockerfile Mastery:**
- Every instruction creates a layer — design them for cache efficiency
- The difference between `CMD` and `ENTRYPOINT`, and why exec form matters
- Security: never run as root, clean caches, use multi-stage builds

**Docker Compose:**
- How to orchestrate multi-service applications declaratively
- `depends_on` only controls order, not readiness — handle it in entrypoints
- Named volumes, bind mounts, and how to persist data

**Networking:**
- Docker's bridge network and embedded DNS resolver
- Why service names resolve as hostnames
- Reverse proxy architecture: NGINX → WordPress → MariaDB
- The difference between `ports`, `expose`, and internal communication

**Security:**
- Non-root containers, secret management, TLS configuration
- Environment variable risks and how to mitigate them

**Debugging:**
- `docker logs`, `docker exec`, `docker inspect` are your best friends
- How to diagnose connection issues, restart loops, and permission errors

**Linux Internals:**
- Namespaces (pid, net, mnt, uts) provide isolation
- cgroups control resource limits
- iptables rules power Docker's networking under the hood

---

### The DevOps Mindset

Inception is not just about making three services talk to each other. It's about learning to think like a DevOps engineer:

- **Infrastructure as Code:** Your entire infrastructure is defined in files (`docker-compose.yml`, `Dockerfiles`, `Makefile`) — reproducible on any machine
- **Isolation:** Each service has a single responsibility; they communicate through defined interfaces
- **Persistence vs Ephemerality:** Know what needs to survive container restarts and what doesn't
- **Least Privilege:** Every service runs with the minimum permissions it needs
- **Observability:** Know how to inspect and debug your running system

---

### What to Explore Next

Once you've mastered Inception, these are the natural next steps in the DevOps/infrastructure journey:

| Topic | Tools |
|-------|-------|
| Container orchestration | Kubernetes (k8s), Docker Swarm |
| CI/CD pipelines | GitHub Actions, GitLab CI, Jenkins |
| Monitoring | Prometheus, Grafana, ELK Stack |
| Service mesh | Istio, Linkerd |
| Infrastructure as Code | Terraform, Ansible |
| Cloud containers | AWS ECS/EKS, Google Cloud Run, Azure AKS |

---

> **Final word from your mentor:** The point of Inception is not to have NGINX, WordPress, and MariaDB running. The point is to understand *why* and *how* they run — to read an error message and know exactly where in the chain something broke, to look at a `docker-compose.yml` and visualize the network topology in your head. If you've built this project and can answer every question in Section 11 without looking, you've genuinely learned something that will serve you throughout your career.

---

*Made with ❤️ for 42 students by a fellow engineer who once stared at `502 Bad Gateway` for four hours.*

*If this helped you, share it with your cluster mates.*
