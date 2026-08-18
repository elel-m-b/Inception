Absolutely. **Inception** is one of the most important 42 projects because it forces you to understand **Docker, Linux administration, networking, containers, volumes, secrets, TLS, reverse proxies, and service architecture** rather than just writing application code.

I'll explain it from **zero → complete architecture → every required concept → how the pieces communicate**.

---

# 1. What is Inception?

The goal of the 42 Inception project is essentially:

> Build a small infrastructure composed of multiple services, where each service runs in its own Docker container.

The classic architecture is:

```text
                         Internet
                            │
                            │ HTTPS :443
                            ▼
                    ┌─────────────────┐
                    │     NGINX       │
                    │ Reverse Proxy   │
                    │ TLS / HTTPS     │
                    └────────┬────────┘
                             │
                             │ HTTP
                             ▼
                    ┌─────────────────┐
                    │    WORDPRESS    │
                    │   PHP-FPM       │
                    └────────┬────────┘
                             │
                             │ MariaDB protocol
                             ▼
                    ┌─────────────────┐
                    │    MARIADB      │
                    │    Database     │
                    └─────────────────┘

          Persistent data
               │
       ┌───────┴────────┐
       ▼                ▼
 WordPress volume   MariaDB volume
```

The important idea is:

**NGINX ≠ WordPress ≠ MariaDB**

Each is a separate service/container.

---

# 2. Why does 42 make you do this?

Because Inception isn't primarily about WordPress.

WordPress is just the application used to force you to learn infrastructure.

You learn:

```text
Linux
  ↓
Docker
  ↓
Containers
  ↓
Networking
  ↓
Reverse Proxy
  ↓
TLS
  ↓
Databases
  ↓
Volumes
  ↓
Secrets
  ↓
Service orchestration
```

This is very close to real DevOps work.

---

# 3. The three main services

The mandatory infrastructure normally contains:

### 1. NGINX

Responsible for:

```text
HTTPS
TLS
Reverse proxy
Incoming requests
```

### 2. WordPress + PHP-FPM

Responsible for:

```text
Website
PHP execution
WordPress application
Communication with database
```

### 3. MariaDB

Responsible for:

```text
Database
Users
Passwords
WordPress data
```

---

# 4. Why separate containers?

You could theoretically install everything in one container:

```text
Container
├── NGINX
├── PHP
├── WordPress
└── MariaDB
```

But that's bad container architecture.

Instead:

```text
Container 1
└── NGINX

Container 2
└── WordPress + PHP-FPM

Container 3
└── MariaDB
```

This follows the idea:

> **One container = one main responsibility**

Advantages:

* easier to manage
* easier to restart
* easier to update
* easier to debug
* better isolation
* easier scaling
* clearer architecture

---

# 5. What is Docker?

Docker allows you to package an application and its environment into a **container**.

Think:

```text
Traditional computer

OS
├── NGINX
├── PHP
├── MariaDB
├── dependencies
└── configuration
```

Docker:

```text
Docker
│
├── NGINX container
│
├── WordPress container
│
└── MariaDB container
```

Each container has its own isolated environment.

---

# 6. Container vs Virtual Machine

This is an important concept.

### Virtual machine

```text
Physical machine
│
├── Host OS
│
├── Hypervisor
│
│   ├── VM 1
│   │   └── Guest OS
│   │
│   └── VM 2
│       └── Guest OS
```

Each VM contains an entire operating system.

### Docker

```text
Physical machine
│
├── Host OS
│
└── Docker
    ├── Container
    ├── Container
    └── Container
```

Containers share the host's Linux kernel.

Therefore containers are generally much lighter than VMs.

---

# 7. Docker Image

An **image** is a template used to create containers.

For example:

```text
Dockerfile
     │
     ▼
Docker image
     │
     ▼
Docker container
```

Example:

```dockerfile
FROM debian:bookworm

RUN apt-get update
RUN apt-get install -y nginx

COPY conf/nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]
```

The Dockerfile describes how to build the image.

---

# 8. Dockerfile

A Dockerfile is basically a recipe.

Example:

```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
```

Let's understand every instruction.

---

# 9. `FROM`

```dockerfile
FROM debian:bookworm
```

Means:

> Start from Debian Bookworm.

The image becomes the base environment.

---

# 10. `RUN`

```dockerfile
RUN apt-get update && apt-get install -y nginx
```

Executes commands while **building the image**.

Important distinction:

```text
docker build
      │
      ▼
RUN commands happen
      │
      ▼
Image created
```

---

# 11. `COPY`

```dockerfile
COPY nginx.conf /etc/nginx/nginx.conf
```

Copies files from your project into the image.

---

# 12. `CMD`

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

Defines the default process executed when the container starts.

This is extremely important in Inception.

A container should have a foreground process.

Bad:

```bash
nginx
```

because NGINX may daemonize/background itself.

Better:

```bash
nginx -g "daemon off;"
```

because NGINX remains in the foreground.

---

# 13. Why must the process stay in foreground?

Docker considers the main process of the container as PID 1.

For example:

```text
NGINX container

PID 1
  │
  └── nginx
```

If PID 1 exits:

```text
PID 1 exits
    ↓
container stops
```

That's why:

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

is common.

---

# 14. Docker Compose

Managing three containers manually would be annoying.

You could do:

```bash
docker build ...
docker run ...
docker network create ...
docker run ...
docker run ...
```

Instead, Inception normally uses:

```text
docker-compose.yml
```

or:

```text
compose.yaml
```

It describes the infrastructure.

Example conceptually:

```yaml
services:

  nginx:
    build: ./requirements/nginx

  wordpress:
    build: ./requirements/wordpress

  mariadb:
    build: ./requirements/mariadb
```

Then:

```bash
docker compose up
```

starts the infrastructure.

---

# 15. Docker Compose architecture

Think of Compose as the manager:

```text
              Docker Compose
                    │
       ┌────────────┼────────────┐
       ▼            ▼            ▼
     NGINX       WordPress     MariaDB
   container     container     container
```

Compose can define:

* services
* networks
* volumes
* environment variables
* dependencies
* restart policies
* ports

---

# 16. Docker Network

How does WordPress communicate with MariaDB?

Not through:

```text
localhost
```

This is a very important concept.

Inside WordPress:

```text
localhost
```

means:

> The WordPress container itself.

It does **not** mean MariaDB.

Instead Docker provides a network:

```text
                  inception network
                         │
          ┌──────────────┼──────────────┐
          │              │              │
        NGINX        WordPress       MariaDB
```

WordPress can communicate with:

```text
mariadb:3306
```

because Docker's internal DNS resolves:

```text
mariadb
```

to the MariaDB container.

---

# 17. Docker DNS

Suppose your Compose file has:

```yaml
services:
  wordpress:
  mariadb:
```

Inside WordPress:

```text
mariadb
```

can resolve to the MariaDB container.

Conceptually:

```text
WordPress
    │
    │ "mariadb"
    ▼
Docker DNS
    │
    ▼
MariaDB container IP
```

This is why WordPress configuration often uses:

```text
DB_HOST=mariadb:3306
```

instead of:

```text
DB_HOST=localhost
```

---

# 18. Ports

There are two important worlds:

```text
Internet
   │
   ▼
Host machine
   │
   ▼
Container
```

Suppose:

```yaml
ports:
  - "443:443"
```

This means:

```text
Host port 443
       │
       ▼
Container port 443
```

So:

```text
Browser
   │
   │ HTTPS :443
   ▼
Host
   │
   ▼
NGINX container :443
```

---

# 19. Why only NGINX exposes port 443?

Because NGINX is the public entry point.

You don't want:

```text
Internet
   │
   ├── NGINX
   ├── WordPress
   └── MariaDB
```

Instead:

```text
Internet
   │
   ▼
NGINX
   │
   ▼
WordPress
   │
   ▼
MariaDB
```

MariaDB should be accessible only internally.

WordPress should also normally be behind NGINX.

---

# 20. Reverse Proxy

This is one of the most important Inception concepts.

A reverse proxy receives requests from clients and forwards them to another service.

```text
Browser
   │
   │ HTTPS
   ▼
NGINX
   │
   │ HTTP
   ▼
WordPress
```

NGINX is therefore the **reverse proxy**.

---

# 21. Why use NGINX?

NGINX can handle:

* HTTPS
* TLS certificates
* HTTP requests
* reverse proxying
* static files
* connection handling
* security rules

For Inception, the important part is:

```text
TLS + reverse proxy
```

---

# 22. HTTP vs HTTPS

HTTP:

```text
Browser ───────── HTTP ─────────> Server
```

HTTPS:

```text
Browser ───── encrypted HTTPS ───> Server
```

HTTPS uses TLS.

---

# 23. TLS

TLS provides encryption between the browser and server.

Conceptually:

```text
Browser
   │
   │ encrypted communication
   ▼
NGINX
```

Without TLS:

```text
Browser ── plaintext ──> Server
```

With TLS:

```text
Browser ══ encrypted ══> NGINX
```

---

# 24. TLS Certificate

NGINX needs a certificate and private key.

Conceptually:

```text
/etc/nginx/ssl/
├── certificate.crt
└── private.key
```

The certificate helps establish the identity of the server and the TLS connection.

For the 42 project, you commonly generate a local/self-signed certificate rather than using a public certificate authority.

---

# 25. Why port 443?

Standard ports:

```text
HTTP   → 80
HTTPS  → 443
```

Inception requires HTTPS, so NGINX listens on:

```text
443
```

---

# 26. NGINX configuration

Conceptually:

```nginx
server {
    listen 443 ssl;

    server_name your-domain;

    ssl_certificate /path/cert.crt;
    ssl_certificate_key /path/private.key;

    location / {
        proxy_pass http://wordpress:9000;
    }
}
```

But there is an important detail:

**PHP-FPM normally speaks FastCGI, not HTTP.**

So a typical WordPress architecture may involve:

```text
NGINX
   │
   │ FastCGI
   ▼
PHP-FPM
```

rather than NGINX simply proxying HTTP directly to PHP-FPM.

---

# 27. WordPress

WordPress is the web application.

Its files might look conceptually like:

```text
WordPress
├── wp-admin
├── wp-content
├── wp-includes
├── wp-config.php
└── index.php
```

WordPress itself is written in PHP.

But NGINX doesn't execute PHP.

That's why we need PHP-FPM.

---

# 28. PHP-FPM

FPM = **FastCGI Process Manager**.

It manages PHP processes.

Architecture:

```text
Browser
   │
HTTPS
   ▼
NGINX
   │
FastCGI
   ▼
PHP-FPM
   │
   ▼
WordPress PHP
```

PHP-FPM executes PHP code.

---

# 29. FastCGI

FastCGI is a protocol allowing a web server such as NGINX to communicate with application processes such as PHP-FPM.

Conceptually:

```text
NGINX
  │
  │ FastCGI
  ▼
PHP-FPM
```

PHP-FPM then executes:

```php
index.php
```

---

# 30. MariaDB

MariaDB is the database server.

WordPress needs a database to store information such as:

```text
Users
Posts
Pages
Comments
Settings
Plugins data
Themes data
```

Architecture:

```text
WordPress
    │
    │ SQL
    ▼
MariaDB
```

---

# 31. Database credentials

WordPress needs credentials such as:

```text
Database name
Database user
Database password
Database host
```

Conceptually:

```text
DB_NAME=wordpress
DB_USER=wp_user
DB_PASSWORD=********
DB_HOST=mariadb
```

---

# 32. Why secrets matter

You should not casually put passwords directly into source code or Git.

Bad:

```yaml
MYSQL_PASSWORD: mypassword123
```

Better architecture:

```text
Secrets
   │
   ├── DB password
   ├── DB root password
   └── WordPress credentials
```

Then services consume those secrets.

The exact secret mechanism depends on the project requirements and implementation.

---

# 33. Environment Variables

Environment variables allow configuration to be supplied to applications.

For example:

```text
MYSQL_DATABASE
MYSQL_USER
MYSQL_PASSWORD
```

Then the application can read them.

Conceptually:

```text
Docker Compose
      │
      ▼
Environment
      │
      ▼
Container
      │
      ▼
Application
```

---

# 34. Volumes

This is one of the **most important Inception concepts**.

Containers are disposable.

Suppose MariaDB stores its database inside the container:

```text
MariaDB container
└── database
```

If you delete the container:

```bash
docker rm mariadb
```

the data could disappear.

We need persistent storage.

That's what volumes provide.

---

# 35. Docker Volume

Conceptually:

```text
MariaDB container
       │
       │
       ▼
   DB Volume
       │
       ▼
Persistent storage
```

Now:

```text
Container deleted
       ↓
Volume remains
       ↓
Database remains
```

---

# 36. WordPress volume

WordPress also needs persistent files.

Typically:

```text
WordPress container
       │
       ▼
WordPress volume
       │
       ▼
persistent WordPress files
```

The two important persistent areas are therefore roughly:

```text
MariaDB
   ↓
database volume

WordPress
   ↓
website volume
```

---

# 37. Bind Mount vs Volume

You should understand this distinction.

### Bind mount

Maps a host directory:

```text
Host directory
     │
     ▼
Container directory
```

Example conceptually:

```text
./data:/var/lib/mysql
```

### Named volume

Docker manages the storage:

```text
Docker volume
      │
      ▼
Container
```

Inception often requires particular volume paths/mount arrangements, so follow the project's exact subject requirements.

---

# 38. Persistent vs Ephemeral

Without persistence:

```text
Container
   ↓
Data
   ↓
Delete container
   ↓
Data gone
```

With persistence:

```text
Container
   ↓
Volume
   ↓
Delete container
   ↓
Create new container
   ↓
Same data
```

This is fundamental DevOps knowledge.

---

# 39. WordPress installation

WordPress needs to be configured.

Typically your setup needs to:

```text
Download/install WordPress
        ↓
Configure wp-config.php
        ↓
Connect to MariaDB
        ↓
Create WordPress site
        ↓
Create admin/user
```

42 generally expects this to be automated rather than requiring you to manually configure everything after starting the containers.

---

# 40. Initialization scripts

This is where scripts such as:

```text
setup.sh
init.sh
entrypoint.sh
```

can be useful.

For example:

```text
Container starts
      ↓
Entry script
      ↓
Check configuration
      ↓
Initialize database
      ↓
Start service
```

But don't blindly put every command in an entrypoint script.

Each service should have a clear startup responsibility.

---

# 41. Entrypoint

An entrypoint is the startup logic for a container.

Example:

```text
Container starts
      ↓
entrypoint.sh
      ↓
prepare environment
      ↓
execute main service
```

For MariaDB:

```text
Start container
      ↓
Check database directory
      ↓
Initialize if necessary
      ↓
Start MariaDB
```

For WordPress:

```text
Start container
      ↓
Check WordPress files
      ↓
Configure WordPress
      ↓
Start PHP-FPM
```

---

# 42. PID 1

You should understand this before your defense.

Inside a container:

```text
PID 1
 │
 └── main process
```

For example:

```text
MariaDB container
└── mysqld

NGINX container
└── nginx

WordPress container
└── php-fpm
```

PID 1 is special because it is the main process whose lifetime determines the container.

---

# 43. Restart policies

Compose can specify something like:

```yaml
restart: always
```

Meaning Docker can restart the service when it exits.

Conceptually:

```text
Service crashes
      ↓
Docker detects exit
      ↓
Restart container
```

This is useful for resilient services.

---

# 44. Dependency between services

WordPress depends on MariaDB.

Conceptually:

```text
MariaDB
   ↓
Database available
   ↓
WordPress
   ↓
NGINX
```

But be careful:

```yaml
depends_on:
```

doesn't automatically mean:

> MariaDB is fully ready to accept connections.

It mainly controls startup ordering depending on the Compose configuration.

A robust application may still need a readiness check/retry mechanism.

---

# 45. Health Checks

A health check asks:

> Is this service actually working?

For example:

```text
MariaDB container
      │
      ▼
healthcheck
      │
      ├── healthy
      └── unhealthy
```

This is different from:

```text
container is running
```

A container can be running while the application inside isn't ready.

---

# 46. Docker DNS + service names

Suppose:

```yaml
services:
  nginx:
  wordpress:
  mariadb:
```

Then the network can conceptually resolve:

```text
nginx
wordpress
mariadb
```

So:

```text
WordPress → mariadb:3306
```

and:

```text
NGINX → wordpress
```

depending on your exact WordPress/PHP-FPM architecture.

---

# 47. The complete request flow

This is probably the **single most important thing to understand for your defense**.

User enters:

```text
https://your-domain/
```

### Step 1

Browser performs DNS resolution.

```text
your-domain
     ↓
server IP
```

### Step 2

Browser connects to:

```text
server:443
```

### Step 3

NGINX receives the HTTPS request.

```text
Internet
   │
 HTTPS
   ▼
NGINX
```

### Step 4

TLS is handled by NGINX.

```text
HTTPS
 ↓
TLS termination
 ↓
HTTP/application request
```

### Step 5

NGINX sends the request toward the WordPress/PHP-FPM layer.

```text
NGINX
   │
   ▼
WordPress / PHP-FPM
```

### Step 6

WordPress needs information.

```text
WordPress
    │
    │ SQL
    ▼
MariaDB
```

### Step 7

MariaDB returns data.

```text
MariaDB
   │
   ▼
WordPress
```

### Step 8

WordPress generates the response.

```text
WordPress
    ↓
NGINX
    ↓
HTTPS
    ↓
Browser
```

Complete:

```text
                  INTERNET
                     │
                     │ HTTPS :443
                     ▼
              ┌──────────────┐
              │    NGINX     │
              │ TLS + Proxy  │
              └──────┬───────┘
                     │
                     │ FastCGI
                     ▼
              ┌──────────────┐
              │  PHP-FPM +   │
              │  WordPress   │
              └──────┬───────┘
                     │
                     │ SQL
                     ▼
              ┌──────────────┐
              │   MariaDB    │
              └──────┬───────┘
                     │
                     ▼
                DB Volume
```

---

# 48. Docker architecture

The whole Docker architecture looks like:

```text
                         HOST MACHINE
                              │
                         Docker Engine
                              │
                 ┌────────────┴────────────┐
                 │                         │
              Network                  Volumes
                 │                         │
       ┌─────────┼─────────┐          ┌────┴────┐
       │         │         │          │         │
       ▼         ▼         ▼          ▼         ▼
     NGINX   WORDPRESS  MARIADB     WP data   DB data
       │         │         │
       └─────────┴─────────┘
             Docker network
```

---

# 49. Docker Compose architecture

Think of your `docker-compose.yml` as defining:

```text
             docker-compose.yml
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
        nginx     wordpress   mariadb
          │          │          │
          └──────────┼──────────┘
                     │
                  network
                     
              ┌──────┴──────┐
              ▼             ▼
          WP volume      DB volume
```

---

# 50. Docker image vs container vs volume vs network

You absolutely need to distinguish these four.

### Image

Template:

```text
Dockerfile
    ↓
Image
```

### Container

Running instance:

```text
Image
  ↓
Container
```

### Network

Allows containers to communicate:

```text
Container ←→ Container
```

### Volume

Stores persistent data:

```text
Container ←→ Volume
```

So:

```text
IMAGE
  ↓
CONTAINER
  │
  ├── NETWORK ──→ other containers
  │
  └── VOLUME ──→ persistent data
```

---

# 51. Build vs Run

Another common defense question.

### Build

```bash
docker compose build
```

Creates images.

```text
Dockerfile
    ↓
Image
```

### Run

```bash
docker compose up
```

Creates/starts containers.

```text
Image
  ↓
Container
```

---

# 52. `docker compose up`

Conceptually:

```bash
docker compose up -d
```

means:

```text
Read compose file
      ↓
Build missing images
      ↓
Create network
      ↓
Create volumes
      ↓
Create containers
      ↓
Start services
```

`-d` means detached mode.

---

# 53. `docker compose down`

```bash
docker compose down
```

stops/removes the Compose-created containers and network.

Depending on options, volumes may or may not be removed.

This is important:

```bash
docker compose down
```

is not equivalent to:

```bash
docker compose down -v
```

The latter removes Compose-managed volumes, which can destroy persistent database data.

---

# 54. Why deleting volumes is dangerous

Imagine:

```text
MariaDB
   │
   ▼
DB volume
   │
   ├── users
   ├── posts
   └── settings
```

Then:

```bash
docker compose down -v
```

can remove the volume.

Result:

```text
Database data
      ↓
DELETED
```

So always understand what you're deleting.

---

# 55. Docker logs

Very important for debugging.

```bash
docker logs <container>
```

or:

```bash
docker compose logs
```

For one service:

```bash
docker compose logs nginx
```

Follow logs:

```bash
docker compose logs -f nginx
```

This helps answer:

```text
Why isn't NGINX starting?
Why isn't MariaDB starting?
Why can't WordPress connect?
```

---

# 56. `docker ps`

Shows running containers:

```bash
docker ps
```

You might see:

```text
nginx
wordpress
mariadb
```

All should normally be running.

---

# 57. `docker exec`

Allows you to execute commands inside a running container.

Example:

```bash
docker exec -it mariadb bash
```

Then you're inside:

```text
MariaDB container
```

You can inspect:

```bash
ls
ps
env
cat ...
```

depending on what's installed.

---

# 58. Container isolation

Containers are isolated from each other.

For example:

```text
NGINX container
       X
   cannot simply
       ↓
access every file
of MariaDB
```

They communicate through defined mechanisms:

```text
network
volume
```

depending on the architecture.

---

# 59. Why not install everything directly on Ubuntu?

You could install:

```bash
apt install nginx
apt install mariadb-server
apt install php
```

But then your host becomes tightly coupled to the infrastructure.

Docker gives:

```text
Host
 │
 └── Docker
      ├── NGINX
      ├── WordPress
      └── MariaDB
```

You can destroy/recreate the environment much more easily.

---

# 60. Dockerfile vs Compose file

Don't confuse them.

### Dockerfile

Answers:

> How do I build this service's image?

Example:

```text
Dockerfile
   ↓
NGINX image
```

### Compose

Answers:

> How do all my services work together?

Example:

```text
compose.yaml
   ↓
NGINX
WordPress
MariaDB
network
volumes
```

---

# 61. Why custom images?

42 generally wants you to understand what's happening rather than simply doing:

```yaml
image: wordpress
image: mariadb
image: nginx
```

Instead, you build your own images from appropriate base images.

Conceptually:

```text
Your Dockerfile
      ↓
Your image
      ↓
Your container
```

This forces you to understand:

* packages
* configuration
* processes
* filesystem
* startup
* dependencies

---

# 62. Debian base image

A common approach is:

```dockerfile
FROM debian:bookworm
```

Then install only what you need.

For example:

```text
NGINX image
├── Debian
├── nginx
└── configuration

MariaDB image
├── Debian
├── mariadb-server
└── configuration

WordPress image
├── Debian
├── PHP
├── PHP-FPM
├── WordPress
└── configuration
```

---

# 63. Why not use Ubuntu everywhere?

The project typically specifies an allowed base distribution/version.

For Inception, you should follow the exact subject requirements for the allowed base image and service versions.

Don't choose an arbitrary image just because it works.

---

# 64. Security concepts

Inception also introduces basic security.

You need to think about:

```text
TLS
Passwords
Secrets
Network isolation
Least exposure
Permissions
Container isolation
```

---

# 65. Least exposure

Only expose what needs to be public.

Ideal:

```text
Internet
   │
   ▼
NGINX :443
   │
   ▼
internal network
   │
   ├── WordPress/PHP
   │
   └── MariaDB
```

Not:

```text
Internet
   │
   ├── :443 NGINX
   ├── :9000 PHP
   └── :3306 MariaDB
```

The second architecture unnecessarily exposes internal services.

---

# 66. Database port

MariaDB normally uses:

```text
3306
```

But that doesn't mean you need to publish:

```yaml
ports:
  - "3306:3306"
```

If only WordPress needs MariaDB, Docker's internal network is enough.

```text
WordPress
    │
    │ mariadb:3306
    ▼
MariaDB
```

No public port required.

---

# 67. WordPress and database are separate

Another important distinction:

```text
WordPress ≠ database
```

WordPress stores application files:

```text
wp-content
plugins
themes
PHP files
```

MariaDB stores structured application data:

```text
users
posts
settings
comments
```

---

# 68. Stateful vs Stateless

This is a major DevOps concept.

### MariaDB

Stateful:

```text
Data must persist
```

### NGINX

Mostly stateless:

```text
Configuration + process
```

### PHP/WordPress

Application files may require persistence depending on architecture, especially uploaded content.

This distinction becomes extremely important later with Kubernetes.

---

# 69. Why volumes are essential for MariaDB

MariaDB is stateful.

Therefore:

```text
MariaDB container
       │
       ▼
Persistent volume
```

Without persistence:

```text
Delete container
     ↓
Database lost
```

With persistence:

```text
Delete container
     ↓
Volume remains
     ↓
New container
     ↓
Database still exists
```

---

# 70. Configuration files

Each service normally has its own configuration.

For example:

```text
NGINX
└── nginx.conf

MariaDB
└── mariadb configuration

WordPress
└── wp-config.php
```

Don't mix everything together.

A clean project might look like:

```text
Inception/
│
├── Makefile
├── README.md
│
└── srcs/
    ├── docker-compose.yml
    │
    ├── requirements/
    │   ├── nginx/
    │   │   ├── Dockerfile
    │   │   ├── conf/
    │   │   └── tools/
    │   │
    │   ├── wordpress/
    │   │   ├── Dockerfile
    │   │   └── tools/
    │   │
    │   └── mariadb/
    │       ├── Dockerfile
    │       ├── conf/
    │       └── tools/
    │
    └── ...
```

Exact directory names depend on how you've organized your project.

---

# 71. Makefile

42 projects often use a Makefile to simplify commands.

For example:

```text
make
   ↓
docker compose up --build
```

Other useful targets might conceptually be:

```text
make build
make up
make down
make logs
make clean
make re
```

The exact targets are your choice unless the subject specifies them.

---

# 72. `.env`

Environment configuration can be separated into an environment file.

Conceptually:

```text
.env
├── DOMAIN_NAME
├── DB_NAME
├── DB_USER
└── ...
```

Then Compose can consume the values.

But **do not commit real secrets to GitHub**.

---

# 73. Domain name

Inception commonly involves configuring a domain such as:

```text
yourlogin.42.fr
```

The domain resolves to your machine's IP.

For local testing, you may use `/etc/hosts` so the domain resolves to localhost.

Conceptually:

```text
yourlogin.42.fr
       ↓
127.0.0.1
       ↓
NGINX
```

---

# 74. `/etc/hosts`

Your machine can map a domain to an IP locally.

Conceptually:

```text
127.0.0.1    yourlogin.42.fr
```

Then:

```text
https://yourlogin.42.fr
```

can resolve locally.

This is useful during development.

---

# 75. Self-signed certificate warning

When using a self-signed certificate, your browser may show a warning because the certificate isn't trusted by a public certificate authority.

That's expected in many local Inception setups.

The important part is understanding:

```text
Browser
   ↓
TLS handshake
   ↓
Certificate
   ↓
HTTPS connection
```

---

# 76. TLS handshake — simplified

You don't need to become a cryptography expert for Inception.

Understand the idea:

```text
Client
  │
  │ ClientHello
  ▼
Server
  │
  │ Certificate
  ▼
Client
  │
  │ validates/establishes keys
  ▼
Encrypted communication
```

After TLS is established:

```text
Browser ═══════════ NGINX
        encrypted
```

---

# 77. What happens when NGINX dies?

Suppose:

```text
NGINX ❌
WordPress ✅
MariaDB ✅
```

The website becomes inaccessible externally because NGINX is the entry point.

But internally:

```text
WordPress
MariaDB
```

may still be running.

This demonstrates service isolation.

---

# 78. What happens when MariaDB dies?

```text
NGINX ✅
WordPress ✅
MariaDB ❌
```

The web server may still respond, but WordPress can't access the database.

You might get database connection errors.

---

# 79. What happens when WordPress dies?

```text
NGINX ✅
WordPress ❌
MariaDB ✅
```

NGINX is alive, but the application backend isn't.

The website won't function correctly.

---

# 80. This gives you a dependency graph

```text
Internet
   │
   ▼
 NGINX
   │
   ▼
WordPress
   │
   ▼
MariaDB
```

Dependencies:

```text
NGINX
  ↓
WordPress
  ↓
MariaDB
```

---

# 81. Important Linux concepts you learn

Inception isn't only Docker.

You'll use Linux concepts such as:

```text
processes
PID
permissions
users
groups
filesystem
ports
DNS
network interfaces
services
logs
shell scripting
environment variables
```

---

# 82. Shell scripting

You may write scripts such as:

```bash
#!/bin/bash

...
```

Scripts automate:

```text
installation
configuration
initialization
startup
```

Instead of manually executing 20 commands every time.

---

# 83. Permissions

Linux permissions matter.

Example:

```text
-rwxr-xr-x
```

Understanding:

```text
owner
group
others
```

is useful when configuring:

```text
WordPress files
NGINX files
MariaDB directories
certificates
scripts
```

---

# 84. Users

Services shouldn't necessarily run everything as root.

You should understand:

```text
root
www-data
mysql
```

depending on the service and distribution.

This is part of basic container security.

---

# 85. Filesystem

Inside a container, you'll encounter paths such as:

```text
/etc
/var
/usr
/home
/run
/tmp
```

For example:

```text
/etc/nginx/
```

contains NGINX configuration.

MariaDB stores its database files in its configured data directory.

PHP-FPM has its own configuration files.

---

# 86. Processes

You should know how to inspect processes.

For example:

```bash
ps
```

or:

```bash
ps aux
```

The exact commands available depend on the base image.

The key concept:

```text
Container
   │
   └── PID 1
        │
        └── service
```

---

# 87. Logs

Logs are your primary debugging tool.

Think:

```text
Application broken
      ↓
Check logs
      ↓
Find error
      ↓
Identify service
      ↓
Fix configuration
```

Examples:

```bash
docker compose logs nginx
docker compose logs wordpress
docker compose logs mariadb
```

---

# 88. Debugging networking

Suppose WordPress says:

```text
Can't connect to database
```

Don't immediately change random configuration.

Check systematically:

```text
1. Is MariaDB running?
2. Is MariaDB healthy?
3. Are both containers on the same network?
4. Is hostname "mariadb" correct?
5. Is port 3306 correct internally?
6. Are credentials correct?
7. Is MariaDB accepting connections?
8. Is the database initialized?
```

This is real DevOps troubleshooting.

---

# 89. Debugging NGINX

If browser cannot connect:

```text
1. Is container running?
2. Is port 443 published?
3. Is NGINX listening on 443?
4. Is TLS configuration correct?
5. Is certificate path correct?
6. Is DNS/hosts configuration correct?
7. Is firewall blocking it?
8. Are logs showing errors?
```

---

# 90. Debugging WordPress

If WordPress doesn't work:

```text
1. Is PHP-FPM running?
2. Are WordPress files present?
3. Is wp-config.php correct?
4. Can WordPress reach MariaDB?
5. Are database credentials correct?
6. Are permissions correct?
7. Are PHP extensions installed?
```

---

# 91. Docker layers

Docker images are built in layers.

For example:

```dockerfile
FROM debian:bookworm
RUN apt-get update
RUN apt-get install -y nginx
COPY nginx.conf /etc/nginx/
```

Conceptually:

```text
Layer 1 → Debian
Layer 2 → apt update/install
Layer 3 → nginx configuration
```

Docker can reuse cached layers.

This is why changing the last part of a Dockerfile can sometimes avoid rebuilding everything.

---

# 92. Why combine `apt-get update` and `apt-get install`?

You'll often see:

```dockerfile
RUN apt-get update && apt-get install -y nginx
```

instead of separate layers:

```dockerfile
RUN apt-get update
RUN apt-get install -y nginx
```

It helps avoid stale package index problems and can reduce unnecessary layers.

---

# 93. Don't install unnecessary packages

A good container should be relatively minimal.

Instead of:

```text
Debian
+ everything
```

prefer:

```text
Debian
+ only what the service needs
```

This reduces:

* image size
* attack surface
* complexity

---

# 94. Container lifecycle

Understand:

```text
Image
  │
  ▼
Create container
  │
  ▼
Start
  │
  ▼
Running
  │
  ▼
Stop
  │
  ▼
Start again
  │
  ▼
Remove
```

Images and containers are different objects.

---

# 95. Container recreation

One of Docker's strengths:

```text
Old container
     ↓
destroy
     ↓
new container
     ↓
same image
     ↓
same volume
     ↓
persistent data
```

This is why separating application state from container filesystem is important.

---

# 96. The 4 major Inception pillars

If you want to remember the project quickly, think about these:

```text
        INCEPTION
            │
   ┌────────┼────────┐
   ▼        ▼        ▼
Docker   Networking  Storage
   │        │        │
Images    DNS       Volumes
Containers Ports     Persistence
Compose   Services
            │
            ▼
          Security
          TLS
          Secrets
```

---

# 97. Concepts you should know for the defense

I would divide your Inception knowledge into **10 groups**:

### Group 1 — Docker

```text
Docker
Image
Container
Dockerfile
Build
Run
Exec
Logs
```

### Group 2 — Compose

```text
docker-compose.yml
services
networks
volumes
environment
depends_on
restart
```

### Group 3 — Networking

```text
IP
Port
DNS
Docker network
Service name
localhost
```

### Group 4 — Web

```text
HTTP
HTTPS
TLS
NGINX
Reverse proxy
```

### Group 5 — PHP

```text
PHP
PHP-FPM
FastCGI
WordPress
```

### Group 6 — Database

```text
MariaDB
SQL
Database
User
Password
3306
```

### Group 7 — Storage

```text
Volume
Persistence
Bind mount
Stateful service
```

### Group 8 — Linux

```text
Processes
PID 1
Users
Permissions
Filesystem
Shell
```

### Group 9 — Security

```text
TLS
Secrets
Passwords
Network isolation
Minimal exposure
```

### Group 10 — Debugging

```text
docker ps
docker logs
docker exec
network inspection
volume inspection
configuration inspection
```

---

# 98. The most important mental model

Don't memorize random commands.

Understand this:

```text
                  USER
                   │
                   │ HTTPS
                   ▼
             ┌────────────┐
             │   NGINX    │
             │    :443    │
             └─────┬──────┘
                   │
                   │ internal communication
                   ▼
             ┌────────────┐
             │ WORDPRESS  │
             │ PHP-FPM    │
             └─────┬──────┘
                   │
                   │ SQL
                   ▼
             ┌────────────┐
             │  MARIADB   │
             │    :3306   │
             └─────┬──────┘
                   │
                   ▼
             ┌────────────┐
             │ DB VOLUME  │
             └────────────┘
```

And:

```text
             Docker Compose
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
      NGINX      WordPress    MariaDB
        │           │           │
        └───────────┼───────────┘
                    │
             Docker Network
```

---

# 99. What you should be able to explain without looking at your code

Before defending Inception, you should be able to answer these:

**Docker**

* What is Docker?
* What is a container?
* What is an image?
* What is a Dockerfile?
* Image vs container?
* Why one service per container?

**Networking**

* What is a Docker network?
* Why can WordPress use `mariadb` as hostname?
* Why isn't `localhost` correct?
* What is a port?
* Why expose 443 but not 3306 publicly?

**NGINX**

* What is NGINX?
* What is a reverse proxy?
* Why NGINX?
* Why HTTPS?
* What is TLS?
* What is a certificate?

**WordPress**

* What is WordPress?
* What is PHP?
* What is PHP-FPM?
* What is FastCGI?

**MariaDB**

* Why does WordPress need MariaDB?
* What is a database?
* What is port 3306?
* How does WordPress connect to MariaDB?

**Storage**

* What is a Docker volume?
* Why does MariaDB need persistent storage?
* What happens if you delete a container?

**Linux**

* What is PID 1?
* Why should the main service remain in the foreground?
* What are permissions?
* What are environment variables?

**Security**

* Why HTTPS?
* Why shouldn't MariaDB be publicly exposed?
* What are secrets?
* Why shouldn't passwords be committed to Git?

**Debugging**

* How do you check running containers?
* How do you check logs?
* How do you enter a container?
* How do you verify networking?
* How do you determine which service is broken?

---

# 100. Inception in one sentence

If the evaluator asks:

> **"What is the purpose of Inception?"**

A good conceptual answer is:

**Inception is a project where you build a small containerized infrastructure using Docker, separating NGINX, WordPress/PHP-FPM, and MariaDB into services, connecting them through a private Docker network, using persistent volumes for data, and securing external access with TLS/HTTPS.**

That sentence captures the **core architecture**.

---

## The learning order I recommend

Since you're currently working on your Inception implementation, don't try to memorize all 100 concepts at once. Learn them in this order:

```text
PHASE 1
Linux fundamentals
      ↓
PHASE 2
Docker fundamentals
      ↓
PHASE 3
Dockerfile
      ↓
PHASE 4
Docker Compose
      ↓
PHASE 5
Docker networking
      ↓
PHASE 6
Volumes / persistence
      ↓
PHASE 7
MariaDB
      ↓
PHASE 8
WordPress + PHP-FPM
      ↓
PHASE 9
NGINX + Reverse Proxy
      ↓
PHASE 10
TLS / HTTPS
      ↓
PHASE 11
Secrets + security
      ↓
PHASE 12
Debugging
      ↓
PHASE 13
Full Inception architecture
      ↓
PHASE 14
42 defense questions
```

**The most important thing:** don't learn Inception as a collection of Docker commands. Learn it as a **distributed system of 3 services**:

```text
                ┌──────────────┐
                │    NGINX     │
                │ Public Entry │
                └──────┬───────┘
                       │
                 HTTPS/TLS
                       │
                       ▼
                ┌──────────────┐
                │  WORDPRESS   │
                │  PHP-FPM     │
                │ Application  │
                └──────┬───────┘
                       │
                     SQL
                       │
                       ▼
                ┌──────────────┐
                │   MARIADB    │
                │   Database   │
                └──────┬───────┘
                       │
                       ▼
                ┌──────────────┐
                │    VOLUME    │
                │ Persistent   │
                │    Data      │
                └──────────────┘
```

That mental model makes the individual Docker commands, configuration files, and scripts much easier to understand.

