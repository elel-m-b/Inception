# Developer Documentation

## Introduction

This document explains how to set up, build, run, and manage the Inception project from a developer's perspective.

The infrastructure is built with Docker and Docker Compose and contains three main services:

```text
NGINX
  │
  ▼
WordPress + PHP-FPM
  │
  ▼
MariaDB
```

The services are isolated into separate containers and communicate through a dedicated Docker network.

Persistent data is stored using Docker volumes.

---

# Prerequisites

Before setting up the project, install the required tools.

## Required Software

The development environment should provide:

* Linux or a compatible virtual machine.
* Docker.
* Docker Compose.
* GNU Make.
* Git.
* A text editor or IDE.

Check Docker:

```bash
docker --version
```

Check Docker Compose:

```bash
docker compose version
```

Check Make:

```bash
make --version
```

---

# Clone the Repository

Clone the repository:

```bash
git clone https://github.com/elel-m-b/Inception
```

Enter the project directory:

```bash
cd <project-directory>
```

The root directory should contain at least:

```text
README.md
USER_DOC.md
DEV_DOC.md
Makefile
srcs/
```

---

# Project Structure

A typical structure is:

```text
.
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── Makefile
│
├── secrets/
│   ├── db_password
│   └── db_root_password
│
└── srcs/
    ├── .env
    ├── docker-compose.yml
    │
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        │
        ├── wordpress/
        │   ├── Dockerfile
        │   └── tools/
        │
        └── mariadb/
            ├── Dockerfile
            └── tools/
```

The exact structure can differ depending on the implementation.

---

# Configuration

## Environment Variables

The project can use an `.env` file for non-sensitive configuration.

For example:

```text
DOMAIN_NAME=elel-m-b.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
```

The actual variables depend on the implementation.

Environment variables should be used for configuration rather than storing sensitive passwords directly in Dockerfiles.

---

# Secrets

Sensitive credentials should be stored separately from normal configuration.

For example:

```text
secrets/
├── db_root_password
└── credentials
```

Possible secrets include:

* MariaDB root password.
* MariaDB user password.
* WordPress administrator credentials.

Secret files should not be committed to a public Git repository.

If the repository uses Git, verify that sensitive files are excluded when appropriate:

```text
.gitignore
```

For example:

```text
secrets/
srcs/.env
```

The exact `.gitignore` configuration depends on how the project handles secrets.

---

# Domain Configuration

The project requires the configured domain to resolve to the local machine.

For a local 42 environment, `/etc/hosts` may contain:

```text
127.0.0.1 elel-m-b.42.fr
```

Check the file:

```bash
cat /etc/hosts
```

The actual IP address and domain must match the environment used to run the project.

---

# Building the Project

The recommended way to build the project is through the Makefile.

From the repository root:

```bash
make
```

The Makefile normally performs operations such as:

1. Creating required directories.
2. Building Docker images.
3. Creating the Docker network.
4. Creating Docker volumes.
5. Starting the containers.

The exact commands depend on the Makefile implementation.

---

# Building with Docker Compose

The infrastructure can also be started directly using Docker Compose.

Move into the directory containing `docker-compose.yml`:

```bash
cd srcs
```

Build and start the services:

```bash
docker compose up --build
```

To run in detached mode:

```bash
docker compose up -d --build
```

---

# Stopping the Project

Using the Makefile:

```bash
make down
```

Or with Docker Compose:

```bash
docker compose down
```

Stopping the containers does not necessarily remove persistent volumes.

---

# Rebuilding

When modifying a Dockerfile or installation configuration, rebuild the images:

```bash
docker compose build --no-cache
```

Then start the infrastructure:

```bash
docker compose up -d
```

A simpler rebuild is:

```bash
docker compose up -d --build
```

---

# Container Management

## List Running Containers

```bash
docker ps
```

## List All Containers

```bash
docker ps -a
```

## Inspect a Container

```bash
docker inspect <container_name>
```

## Execute a Command Inside a Container

```bash
docker exec -it <container_name> /bin/sh
```

If Bash is installed:

```bash
docker exec -it <container_name> /bin/bash
```

---

# Logs

Display logs:

```bash
docker compose logs
```

Follow logs:

```bash
docker compose logs -f
```

Display logs for one service:

```bash
docker compose logs nginx
docker compose logs wordpress
docker compose logs mariadb
```

Logs are particularly useful when diagnosing:

* Configuration errors.
* Startup failures.
* Database connection problems.
* NGINX errors.
* PHP-FPM problems.

---

# Docker Images

List images:

```bash
docker images
```

Build a specific service:

```bash
docker compose build <service>
```

For example:

```bash
docker compose build nginx
```

---

# Docker Networks

List networks:

```bash
docker network ls
```

Inspect the project's network:

```bash
docker network inspect <network_name>
```

The Docker network allows services to communicate without exposing every service to the host.

For example:

```text
nginx ──► wordpress ──► mariadb
```

MariaDB does not need to be publicly exposed for WordPress to access it.

---

# Docker Volumes

List volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect <volume_name>
```

The project normally uses persistent volumes for WordPress and MariaDB data.

For example:

```text
wordpress_data
mariadb_data
```

The exact volume names depend on the Compose configuration.

---

# Data Storage and Persistence

The most important persistent data belongs to:

### WordPress

WordPress files and uploaded content should be stored in a persistent volume.

### MariaDB

The MariaDB database files should be stored in a persistent volume.

Conceptually:

```text
Container
   │
   ▼
Docker Volume
   │
   ▼
Persistent Data
```

If a container is removed and recreated, the volume can be attached again and the data remains available.

This separates the lifecycle of the application containers from the lifecycle of the application data.

---

# Volumes vs Containers

A container is temporary and can be recreated.

A volume is intended to persist data.

For example:

```text
Remove MariaDB container
          │
          ▼
MariaDB volume remains
          │
          ▼
Create new MariaDB container
          │
          ▼
Attach existing volume
          │
          ▼
Database data remains
```

Developers should avoid deleting volumes unless they intentionally want to remove the project's persistent data.

---

# Dangerous Cleanup Commands

Be careful with:

```bash
docker compose down -v
```

The `-v` option can remove the project's Docker volumes.

Also be careful with:

```bash
docker system prune
```

and especially commands that remove all unused volumes.

Before deleting resources, check:

```bash
docker volume ls
```

and:

```bash
docker ps -a
```

---

# Development Workflow

A typical development workflow is:

### 1. Modify the source or configuration

For example:

```text
srcs/requirements/nginx/
srcs/requirements/wordpress/
srcs/requirements/mariadb/
```

### 2. Rebuild the affected service

```bash
docker compose build nginx
```

### 3. Restart the infrastructure

```bash
docker compose up -d
```

### 4. Check the service

```bash
docker ps
```

### 5. Inspect logs

```bash
docker compose logs nginx
```

Repeat the process for the service being developed.

---

# Testing the Infrastructure

After starting the project, verify the following.

## Containers

```bash
docker ps
```

All required services should be running.

## Network

```bash
docker network ls
```

Verify that the project's network exists.

## Volumes

```bash
docker volume ls
```

Verify that persistent volumes exist.

## NGINX

Check the NGINX logs:

```bash
docker compose logs nginx
```

## WordPress

Check:

```bash
docker compose logs wordpress
```

## MariaDB

Check:

```bash
docker compose logs mariadb
```

## Website

Open:

```text
https://elel-m-b.42.fr
```

The website should load through HTTPS.

---

# Useful Docker Compose Commands

Start services:

```bash
docker compose up -d
```

Start and rebuild:

```bash
docker compose up -d --build
```

Stop services:

```bash
docker compose down
```

Restart services:

```bash
docker compose restart
```

Show service status:

```bash
docker compose ps
```

Show logs:

```bash
docker compose logs
```

Follow logs:

```bash
docker compose logs -f
```

Build images:

```bash
docker compose build
```

---

# Makefile

The Makefile provides a convenient interface for managing the project.

Typical commands may include:

```bash
make
make up
make down
make clean
make fclean
make re
```

The exact targets depend on the implementation.

Before using a target, inspect the Makefile:

```bash
cat Makefile
```

A typical workflow is:

```bash
make
```

to start the project, and:

```bash
make down
```

to stop it.

---

# Development Notes

Each service should have its own Dockerfile and configuration.

The services should remain separated according to their responsibilities:

```text
NGINX
 └── Web server / HTTPS / reverse proxy

WordPress
 └── Application / PHP-FPM

MariaDB
 └── Database
```

This separation makes the infrastructure easier to understand, maintain, rebuild, and troubleshoot.

---

# Data Persistence Summary

| Data                 | Storage       | Persistent? |
| -------------------- | ------------- | ----------- |
| WordPress data       | Docker volume | Yes         |
| MariaDB database     | Docker volume | Yes         |
| Container filesystem | Container     | No          |
| NGINX image          | Docker image  | Rebuildable |
| WordPress image      | Docker image  | Rebuildable |
| MariaDB image        | Docker image  | Rebuildable |

The important application data should therefore be stored in Docker volumes rather than only inside containers.

---

# Troubleshooting

## A Container Exits Immediately

Run:

```bash
docker ps -a
```

Then inspect its logs:

```bash
docker compose logs <service>
```

---

## WordPress Cannot Connect to MariaDB

Check:

```bash
docker compose logs wordpress
docker compose logs mariadb
```

Verify:

* MariaDB is running.
* The database name is correct.
* The database username is correct.
* The password is correct.
* The WordPress database host points to the MariaDB Compose service name.
* Both services are connected to the same Docker network.

---

## NGINX Cannot Reach WordPress

Check:

```bash
docker compose logs nginx
docker compose logs wordpress
```

Verify:

* WordPress/PHP-FPM is running.
* The internal port is correct.
* The Docker network is configured correctly.
* NGINX is using the correct service name.

---

# Conclusion

The Inception development environment is based on a multi-container Docker architecture.

Developers should work with the following principles:

* Keep services separated.
* Use Dockerfiles to build reproducible images.
* Use Docker Compose to manage the infrastructure.
* Use Docker networks for internal communication.
* Use Docker volumes for persistent data.
* Keep sensitive credentials outside source code.
* Check logs when troubleshooting.
* Avoid deleting persistent volumes unintentionally.

This approach makes the project reproducible and allows the complete infrastructure to be rebuilt while keeping important application data persistent.
