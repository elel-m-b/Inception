---
Docker

What is Docker?
What is a container?
What is an image?
What is a Dockerfile?
Image vs container?
Why one service per container?

Networking

What is a Docker network?
Why can WordPress use mariadb as hostname?
Why isn't localhost correct?
What is a port?
Why expose 443 but not 3306 publicly?

NGINX

What is NGINX?
What is a reverse proxy?
Why NGINX?
Why HTTPS?
What is TLS?
What is a certificate?

WordPress

What is WordPress?
What is PHP?
What is PHP-FPM?
What is FastCGI?

MariaDB

Why does WordPress need MariaDB?
What is a database?
What is port 3306?
How does WordPress connect to MariaDB?

Storage

What is a Docker volume?
Why does MariaDB need persistent storage?
What happens if you delete a container?

Linux

What is PID 1?
Why should the main service remain in the foreground?
What are permissions?
What are environment variables?

Security

Why HTTPS?
Why shouldn't MariaDB be publicly exposed?
What are secrets?
Why shouldn't passwords be committed to Git?

Debugging

How do you check running containers?
How do you check logs?
How do you enter a container?
How do you verify networking?
How do you determine which service is broken?"

---

# 🐳 1. Docker

## 1. What is Docker?

**Docker is a platform that allows us to package and run applications inside isolated environments called containers.**

Instead of installing everything directly on your machine, you package:

```text
Application
+ Dependencies
+ Configuration
        ↓
     Docker Image
        ↓
     Container
```

For Inception:

```text
NGINX Container
WordPress Container
MariaDB Container
```

Each service runs in its own container.

### Why use Docker?

Without Docker:

```text
Host Linux
 ├── NGINX
 ├── PHP
 ├── MariaDB
 └── WordPress
```

Everything is installed directly on the machine.

With Docker:

```text
Host Linux
 └── Docker
      ├── NGINX container
      ├── WordPress container
      └── MariaDB container
```

This gives isolation and reproducibility.

---

# 2. What is a container?

A **container is an isolated running environment for a process/application**.

Think of it as:

> "A small isolated Linux environment where my application runs."

For example:

```text
WordPress Container
 ├── PHP
 ├── PHP-FPM
 └── WordPress files
```

Important:

**A container is not a virtual machine.**

A VM contains a complete guest operating system.

A container shares the host's Linux kernel.

```text
VM:

Host
 └── Virtual Machine
      └── Guest OS
           └── Application


Container:

Host Linux Kernel
 └── Docker
      └── Container
           └── Application
```

---

# 3. What is an image?

An **image is a template used to create containers**.

Think:

```text
Image = Recipe / Blueprint
Container = Running instance
```

For example:

```text
Dockerfile
    ↓
Docker Image
    ↓
Container
```

An image contains things such as:

* filesystem
* binaries
* libraries
* configuration
* application files
* startup command

---

# 4. What is a Dockerfile?

A **Dockerfile is a text file containing instructions for building a Docker image.**

Example:

```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx

COPY conf/nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]
```

Meaning:

```text
FROM → choose base image
RUN  → execute commands during build
COPY → copy files
CMD  → default process when container starts
```

---

# 5. Image vs Container

Very important.

| Image                     | Container                  |
| ------------------------- | -------------------------- |
| Template                  | Running instance           |
| Static                    | Runtime                    |
| Used to create containers | Created from image         |
| Doesn't normally change   | Has writable runtime layer |

Example:

```text
nginx image
     ↓
     ├── container 1
     ├── container 2
     └── container 3
```

One image can create many containers.

---

# 6. Why one service per container?

Because each container should generally have **one main responsibility**.

In Inception:

```text
             Internet
                 ↓
             NGINX
                 ↓
           WordPress/PHP
                 ↓
              MariaDB
```

Each container has one main service:

```text
NGINX       → web server / reverse proxy
WordPress   → PHP application
MariaDB     → database
```

This gives:

* isolation
* easier debugging
* independent restart
* independent configuration
* easier scaling
* clearer architecture

If MariaDB crashes, you don't want your NGINX process to be tied to it.

---

# 🌐 2. Networking

## 7. What is a Docker network?

A Docker network allows containers to communicate with each other.

For example:

```text
          inception network
       ┌──────────────────────┐
       │                      │
       │ NGINX ←→ WordPress   │
       │          ↓           │
       │       MariaDB        │
       │                      │
       └──────────────────────┘
```

Containers connected to the same Docker network can communicate using container/service names.

---

# 8. Why can WordPress use `mariadb` as hostname?

Suppose your Compose file has:

```yaml
services:
  wordpress:
    ...
  
  mariadb:
    ...
```

Docker Compose creates DNS/service-name resolution inside the network.

Therefore WordPress can connect to:

```text
mariadb:3306
```

Docker resolves:

```text
mariadb
   ↓
MariaDB container IP
```

So:

```text
WordPress
    |
    | mariadb:3306
    ↓
MariaDB
```

You don't need to know MariaDB's IP address.

---

# 9. Why isn't `localhost` correct?

This is a **very important Docker concept**.

Inside the WordPress container:

```text
localhost
```

means:

> **the WordPress container itself.**

It does NOT mean the MariaDB container.

So:

```text
WordPress container
localhost:3306
      ↓
WordPress container
```

But MariaDB is somewhere else:

```text
WordPress container
       |
       | mariadb:3306
       ↓
MariaDB container
```

Therefore:

```text
localhost ❌
mariadb   ✅
```

---

# 10. What is a port?

A **port is a logical endpoint used by network applications to communicate.**

Think of an IP address as:

```text
Building address
```

and a port as:

```text
Apartment number
```

For example:

```text
192.168.1.10:443
              ↑
            port
```

Common ports:

```text
22   → SSH
80   → HTTP
443  → HTTPS
3306 → MariaDB/MySQL
```

---

# 11. Why expose 443 but not 3306 publicly?

Because users need access to the web server, not directly to the database.

Correct:

```text
Internet
   ↓
443
   ↓
NGINX
   ↓
WordPress
   ↓
MariaDB
```

Incorrect:

```text
Internet
   ↓
3306
   ↓
MariaDB
```

If MariaDB is publicly accessible, attackers could directly target your database.

The database should be accessible only inside the Docker network.

---

# 🔥 3. NGINX

## 12. What is NGINX?

NGINX is a web server and reverse proxy.

In Inception, NGINX is the **entry point**.

```text
Browser
   ↓
HTTPS :443
   ↓
NGINX
   ↓
WordPress
```

NGINX handles the incoming HTTP/HTTPS requests.

---

# 13. What is a reverse proxy?

A reverse proxy is a server that receives requests from clients and forwards them to another server/application.

Example:

```text
Browser
   ↓
NGINX
   ↓
WordPress/PHP-FPM
```

The browser communicates with NGINX.

NGINX communicates with the backend.

So the client doesn't directly communicate with the internal application.

---

# 14. Why NGINX?

In Inception, NGINX can:

* accept HTTPS connections
* handle TLS
* receive HTTP requests
* serve static files
* forward dynamic requests
* communicate with PHP-FPM

Architecture:

```text
             Client
                |
             HTTPS
                |
                ↓
             NGINX
                |
          FastCGI request
                |
                ↓
           PHP-FPM
                |
                ↓
           WordPress
                |
                ↓
             MariaDB
```

---

# 15. Why HTTPS?

HTTPS protects communication between the browser and server.

Without HTTPS:

```text
Browser ───── HTTP ─────> Server
```

Information can potentially be observed or modified in transit.

With HTTPS:

```text
Browser ─── encrypted ───> NGINX
```

This is especially important for:

* passwords
* login sessions
* cookies
* personal data

---

# 16. What is TLS?

**TLS = Transport Layer Security.**

TLS is the cryptographic protocol used to secure HTTPS communication.

Very simplified:

```text
HTTP
 +
TLS
 ↓
HTTPS
```

TLS provides:

### Encryption

Others shouldn't be able to read the traffic.

### Authentication

The certificate helps the browser verify the server identity.

### Integrity

Data shouldn't be silently modified during transmission.

---

# 17. What is a certificate?

A TLS certificate helps establish the identity of a server and is used during the TLS handshake.

It contains information such as:

```text
Domain
Public key
Issuer
Validity period
Digital signature
```

In your Inception project, you may create a **self-signed certificate**.

Important distinction:

```text
Private key → secret
Certificate → public information
```

Never publish your private key.

---

# 📝 4. WordPress

## 18. What is WordPress?

WordPress is a **content management system (CMS)** written primarily in PHP.

It allows you to create/manage websites.

In Inception:

```text
Browser
   ↓
NGINX
   ↓
PHP-FPM
   ↓
WordPress
   ↓
MariaDB
```

WordPress needs both:

```text
PHP → execute application
MariaDB → store application data
```

---

# 19. What is PHP?

PHP is a server-side programming language commonly used for web applications.

For example, WordPress contains PHP code.

The browser doesn't execute that PHP directly.

Instead:

```text
Browser
   ↓
NGINX
   ↓
PHP-FPM
   ↓
PHP executes WordPress
   ↓
HTML response
   ↓
Browser
```

---

# 20. What is PHP-FPM?

**PHP-FPM = PHP FastCGI Process Manager.**

It manages PHP processes that execute PHP applications.

Instead of NGINX executing PHP itself:

```text
NGINX
   ↓
PHP-FPM
   ↓
PHP
```

PHP-FPM manages worker processes that execute PHP scripts.

---

# 21. What is FastCGI?

FastCGI is a protocol/interface that allows a web server such as NGINX to communicate with an application server such as PHP-FPM.

Example:

```text
Browser
   ↓
NGINX
   ↓
FastCGI
   ↓
PHP-FPM
   ↓
WordPress PHP
```

So:

```text
NGINX = receives request
FastCGI = communication protocol
PHP-FPM = executes PHP
```

---

# 🗄️ 5. MariaDB

## 22. Why does WordPress need MariaDB?

WordPress needs a database to store dynamic information.

For example:

```text
Users
Posts
Pages
Comments
Settings
Plugins
Themes
```

The WordPress PHP application uses SQL queries to read/write this data.

```text
WordPress
    |
    | SQL
    ↓
MariaDB
```

---

# 23. What is a database?

A database is a system for storing and organizing data so applications can efficiently create, read, update, and delete information.

MariaDB is a **relational database management system (RDBMS)**.

It organizes data into tables.

Simplified:

```text
WordPress database

wp_users
wp_posts
wp_comments
wp_options
...
```

---

# 24. What is port 3306?

3306 is the default TCP port commonly used by MySQL/MariaDB.

So:

```text
mariadb:3306
```

means:

```text
Host = mariadb
Port = 3306
```

Inside Docker:

```text
WordPress
    |
    | TCP connection
    | mariadb:3306
    ↓
MariaDB
```

---

# 25. How does WordPress connect to MariaDB?

WordPress uses database configuration such as:

```text
Database host: mariadb
Database name: wordpress
Database user: ...
Database password: ...
```

Conceptually:

```text
WordPress
   |
   | host=mariadb
   | port=3306
   | user=wordpress
   | password=******
   | database=wordpress
   ↓
MariaDB
```

Docker resolves `mariadb` to the MariaDB container.

---

# 💾 6. Storage

## 26. What is a Docker volume?

A Docker volume is persistent storage managed by Docker.

Normally:

```text
Container
   ↓
Container filesystem
```

If the container is removed, its writable filesystem is removed.

A volume gives you:

```text
Container
    |
    ↓
 Docker Volume
    |
    ↓
Persistent data
```

---

# 27. Why does MariaDB need persistent storage?

Because the database contains important data.

Imagine:

```text
MariaDB container
      ↓
Database
      ↓
Users / Posts / Settings
```

If the database exists only inside the container filesystem:

```text
Delete container
      ↓
Database disappears
```

With a volume:

```text
MariaDB container
      ↓
Docker volume
      ↓
Database data
```

You can remove/recreate the container while keeping the data.

---

# 28. What happens if you delete a container?

The container itself disappears.

Its writable container filesystem also disappears.

But **volumes are separate**.

Therefore:

```text
Container deleted
      ↓
Container filesystem → gone
Volume               → remains
```

If you recreate the container and attach the same volume:

```text
New MariaDB container
        ↓
Existing volume
        ↓
Existing database data
```

That's why persistent volumes matter.

---

# 🐧 7. Linux

## 29. What is PID 1?

PID means **Process ID**.

The first/main process inside a container normally has:

```text
PID = 1
```

Example:

```text
MariaDB container

PID 1
 ↓
MariaDB
```

Or:

```text
NGINX container

PID 1
 ↓
NGINX
```

PID 1 has special responsibilities for process management and signal handling.

---

# 30. Why should the main service remain in the foreground?

This is one of the most important Docker concepts.

A container is considered running while its main process is running.

For example:

```text
Container
   ↓
PID 1 = nginx
   ↓
nginx running
   ↓
Container running
```

If PID 1 exits:

```text
PID 1 exits
   ↓
Container stops
```

Therefore services in containers are normally configured to run in the foreground.

For NGINX:

```bash
nginx -g "daemon off;"
```

The `daemon off` part prevents NGINX from going into the background.

---

# 31. What are permissions?

Linux permissions control who can:

* read
* write
* execute

a file or directory.

Example:

```text
-rwxr-xr--
```

There are permissions for:

```text
Owner
Group
Others
```

For example:

```text
chmod 755 script.sh
```

means roughly:

```text
Owner  → read/write/execute
Group  → read/execute
Others → read/execute
```

Permissions matter in Docker because the process inside the container runs as a particular user.

---

# 32. What are environment variables?

Environment variables are key-value configuration values provided to a process.

Example:

```text
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=secret
```

Applications can read these values at runtime.

Instead of hardcoding:

```text
database = "wordpress"
```

you can configure:

```text
DATABASE_NAME=wordpress
```

This makes configuration easier to change between environments.

---

# 🔐 8. Security

## 33. Why HTTPS?

HTTPS protects traffic between client and server using TLS.

```text
HTTP:
Browser ───────────> Server

HTTPS:
Browser ══encrypted══> Server
```

For login pages, this is especially important because credentials and session data travel over the connection.

---

# 34. Why shouldn't MariaDB be publicly exposed?

Because MariaDB is an internal service.

You want:

```text
Internet
   ↓
443
   ↓
NGINX
   ↓
WordPress
   ↓
MariaDB
```

Not:

```text
Internet
   ↓
3306
   ↓
MariaDB
```

Keeping 3306 internal reduces the attack surface.

**Important:** Docker's internal port `3306` does not need to be published to the host for WordPress to use it.

---

# 35. What are secrets?

Secrets are sensitive pieces of information such as:

```text
Database passwords
Private keys
API keys
Access tokens
```

Example:

```text
MYSQL_PASSWORD=SuperSecretPassword
```

That should be treated as sensitive.

---

# 36. Why shouldn't passwords be committed to Git?

Because Git history is persistent.

If you commit:

```text
DB_PASSWORD=my_real_password
```

then even if you delete it later, it may remain in the repository's history.

Attackers who obtain the repository could potentially find it.

Instead use mechanisms appropriate to your environment, such as:

```text
.env
Docker secrets
Secret manager
Environment configuration
```

And make sure sensitive files are properly excluded from Git when appropriate.

---

# 🛠️ 9. Debugging

This section is **very important during the Inception evaluation**.

---

# 37. How do you check running containers?

Use:

```bash
docker ps
```

It shows running containers.

Example:

```text
CONTAINER ID   IMAGE       STATUS
abc123         nginx       Up
def456         wordpress   Up
ghi789         mariadb     Up
```

To see all containers, including stopped ones:

```bash
docker ps -a
```

---

# 38. How do you check logs?

Use:

```bash
docker logs <container>
```

Example:

```bash
docker logs nginx
```

For live logs:

```bash
docker logs -f nginx
```

Very useful when:

```text
Container starts
       ↓
Container immediately stops
```

You inspect:

```bash
docker logs <container>
```

to discover why.

---

# 39. How do you enter a container?

Usually:

```bash
docker exec -it <container> bash
```

If Bash isn't installed:

```bash
docker exec -it <container> sh
```

Example:

```bash
docker exec -it wordpress bash
```

Now you're inside the container.

You can inspect:

```bash
ls
ps
env
cat /etc/hosts
```

etc.

---

# 40. How do you verify networking?

First inspect the networks:

```bash
docker network ls
```

Then:

```bash
docker network inspect <network>
```

You can see which containers are connected.

Inside WordPress, you can test MariaDB:

```bash
getent hosts mariadb
```

If available, you can also test the port:

```bash
nc -zv mariadb 3306
```

Conceptually you want to verify:

```text
wordpress
    |
    | DNS
    ↓
mariadb
    |
    | TCP 3306
    ↓
MariaDB
```

---

# 41. How do you determine which service is broken?

Don't randomly change configuration.

Debug from the outside toward the inside.

Your architecture is:

```text
                    INTERNET
                       |
                      443
                       |
                       ↓
                    NGINX
                       |
                       ↓
                WordPress/PHP
                       |
                       ↓
                    MariaDB
                       |
                       ↓
                     Volume
```

So check each layer.

### Step 1 — Containers

```bash
docker ps
```

Are all expected containers running?

---

### Step 2 — NGINX logs

```bash
docker logs nginx
```

Look for:

```text
configuration errors
TLS errors
permission errors
```

---

### Step 3 — WordPress logs

```bash
docker logs wordpress
```

Look for:

```text
PHP errors
connection errors
permission problems
```

---

### Step 4 — MariaDB logs

```bash
docker logs mariadb
```

Look for:

```text
initialization errors
permission errors
database errors
```

---

### Step 5 — Networking

Check:

```bash
docker network inspect <network>
```

Verify:

```text
NGINX
WordPress
MariaDB
```

are connected correctly.

---

### Step 6 — Test DNS

From WordPress:

```bash
getent hosts mariadb
```

If it resolves, Docker DNS is working.

---

### Step 7 — Test MariaDB port

From WordPress:

```bash
nc -zv mariadb 3306
```

If successful:

```text
WordPress
   |
   | TCP connection
   ↓
MariaDB:3306
```

The network path is working.

---

# 🧠 The Complete Inception Architecture

You should be able to draw this during your evaluation:

```text
                       INTERNET
                           |
                           | HTTPS :443
                           ↓
                    ┌──────────────┐
                    │    NGINX     │
                    │  Web Server  │
                    │ Reverse Proxy│
                    └──────┬───────┘
                           |
                           | FastCGI
                           ↓
                    ┌──────────────┐
                    │  WORDPRESS   │
                    │    PHP-FPM   │
                    └──────┬───────┘
                           |
                           | MySQL protocol
                           | mariadb:3306
                           ↓
                    ┌──────────────┐
                    │   MARIADB    │
                    │   Database   │
                    └──────┬───────┘
                           |
                           ↓
                    ┌──────────────┐
                    │    VOLUME    │
                    │ Persistent   │
                    │    Data      │
                    └──────────────┘
```

And Docker provides:

```text
                    Docker Network
        ┌────────────────────────────────┐
        │                                │
        │   NGINX ←→ WordPress ←→ MariaDB│
        │                                │
        └────────────────────────────────┘
```

---

# 🎯 The 10 Answers You Absolutely Must Remember

If the evaluator asks very quickly, these are the key answers:

### 1. Docker?

> A platform for packaging and running applications in isolated containers.

### 2. Image?

> A read-only template used to create containers.

### 3. Container?

> A running isolated instance created from an image.

### 4. Why `mariadb` instead of `localhost`?

> Because `localhost` refers to the current container. `mariadb` is the Docker service hostname that resolves to the MariaDB container.

### 5. Why NGINX?

> It is the public entry point, handles HTTPS/TLS, and acts as a reverse proxy.

### 6. Why PHP-FPM?

> It manages PHP worker processes and executes WordPress PHP code.

### 7. Why MariaDB?

> WordPress needs a relational database to store users, posts, settings, and other data.

### 8. Why volume?

> To keep database data persistent when the MariaDB container is removed or recreated.

### 9. Why foreground?

> Docker considers the container alive while its main process/PID 1 is running. If that process exits, the container stops.

### 10. Why don't we expose 3306?

> MariaDB only needs to communicate with WordPress through the internal Docker network. Publishing 3306 publicly would unnecessarily increase the attack surface.

---

## 🔥 The most important mental model

Remember this:

```text
IMAGE
  │
  │ docker run
  ↓
CONTAINER
  │
  ├── PID 1 → main service
  │
  ├── NETWORK
  │      └── service names / DNS
  │
  └── VOLUME
         └── persistent data
```

And for **Inception specifically**:

```text
        PUBLIC
          │
       HTTPS 443
          │
          ▼
       NGINX
          │
       FastCGI
          │
          ▼
      PHP-FPM
          │
       WordPress
          │
      mariadb:3306
          │
          ▼
       MariaDB
          │
          ▼
       Volume
```

If you understand **why every arrow exists**, rather than just memorizing Docker commands, you are in a much stronger position for the 42 Inception evaluation.

