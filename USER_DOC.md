# User Documentation

## Introduction

This document explains how to use and manage the Inception infrastructure as an end user or administrator.

The project provides a small web infrastructure composed of three main services:

* **NGINX** — receives HTTPS requests and provides secure access to the website.
* **WordPress** — provides the website and its administration interface.
* **MariaDB** — stores the WordPress database.

The services run inside Docker containers and communicate through a private Docker network.

---

# Services Provided

## NGINX

NGINX is the public entry point of the infrastructure.

It is responsible for:

* Accepting HTTPS connections.
* Using TLS/SSL encryption.
* Receiving requests from the browser.
* Forwarding requests to the WordPress service.

NGINX is the only service that should normally be directly accessible from outside the Docker network.

---

## WordPress

WordPress is the website application.

It provides:

* The public website.
* The WordPress administration panel.
* User management.
* Posts and pages.
* Website configuration.

The WordPress application communicates with MariaDB to store its data.

---

## MariaDB

MariaDB is the database service.

It stores WordPress information such as:

* Users.
* Posts.
* Pages.
* Website settings.
* Other application data.

MariaDB is intended to be accessed internally by WordPress rather than directly from the Internet.

---

# Starting the Project

From the root of the repository, run:

```bash
make
```

This should build the required Docker images and start the infrastructure.

You can check that the containers are running with:

```bash
docker ps
```

You should see the main services running, such as:

```text
nginx
wordpress
mariadb
```

The exact container names depend on the Docker Compose configuration.

---

# Stopping the Project

To stop the infrastructure:

```bash
make down
```

Alternatively, from the directory containing `docker-compose.yml`:

```bash
docker compose down
```

Stopping the containers does not necessarily delete persistent data stored in Docker volumes.

This means the WordPress website and database can be preserved when the containers are stopped.

---

# Accessing the Website

Open a web browser and go to the configured domain.

For example:

```text
https://elel-m-b.42.fr
```

The exact domain is defined by the project configuration.

If the domain does not work, verify that the domain is mapped correctly in `/etc/hosts`.

Example:

```text
127.0.0.1 elel-m-b.42.fr
```

---

# Accessing the WordPress Administration Panel

The WordPress administration panel is available through:

```text
https://elel-m-b.42.fr/wp-admin/
```

Log in using the WordPress administrator account configured during installation.

The administration panel allows an administrator to:

* Manage posts and pages.
* Manage WordPress users.
* Change website settings.
* Install and manage themes and plugins when permitted.
* Manage the website content.

---

# Credentials

## Where Credentials Are Stored

Credentials should not be hardcoded inside Dockerfiles or application source code.

Depending on the project configuration, credentials may be stored in:

```text
secrets/
```

or provided through protected configuration files/environment variables.

Typical credentials include:

* WordPress administrator username/password.
* WordPress database username/password.
* MariaDB root password.
* MariaDB database credentials.

---

## Managing Credentials

Before starting the project, verify that the required credential files exist and contain the expected values.

For example:

```text
secrets/
├── db_root_password
└── credentials
```

The exact names depend on the implementation.

Credentials should:

* Never be committed publicly.
* Never be written directly into Dockerfiles.
* Have appropriate file permissions.
* Be changed when necessary.
* Be kept separate from normal application configuration whenever possible.

If credentials are changed after the database has already been initialized, the existing database configuration may need to be updated as well.

---

# Checking the Services

## Check Running Containers

Run:

```bash
docker ps
```

Verify that the required containers are running.

---

## Check All Containers

To also see stopped containers:

```bash
docker ps -a
```

---

## Check Logs

To display logs for all services:

```bash
docker compose logs
```

To follow logs continuously:

```bash
docker compose logs -f
```

To inspect a specific service:

```bash
docker compose logs nginx
docker compose logs wordpress
docker compose logs mariadb
```

Look for errors if a service does not start correctly.

---

# Checking Docker Networks

List the available Docker networks:

```bash
docker network ls
```

Inspect the project's network:

```bash
docker network inspect <network_name>
```

The NGINX, WordPress, and MariaDB containers should be connected to the project's Docker network according to the Compose configuration.

---

# Checking Persistent Data

List Docker volumes:

```bash
docker volume ls
```

The project should have persistent volumes for important data.

For example:

```text
wordpress_data
mariadb_data
```

The exact names depend on the Docker Compose configuration.

Stopping or recreating containers should not remove these volumes unless they are explicitly deleted.

---

# Restarting the Infrastructure

If a service stops unexpectedly, first check its logs:

```bash
docker compose logs <service>
```

Then restart the project:

```bash
docker compose restart
```

Or recreate the containers:

```bash
docker compose up -d
```

If configuration or Dockerfiles have changed, rebuild:

```bash
docker compose up -d --build
```

---

# Troubleshooting

## Website Is Not Accessible

Check:

```bash
docker ps
```

Then check NGINX logs:

```bash
docker compose logs nginx
```

Verify that the domain is configured in `/etc/hosts`.

Also verify that port `443` is correctly exposed.

---

## WordPress Is Not Working

Check:

```bash
docker compose logs wordpress
```

Then verify that WordPress can communicate with MariaDB.

Check the MariaDB logs:

```bash
docker compose logs mariadb
```

---

## Database Problems

Check:

```bash
docker compose logs mariadb
```

Verify that:

* MariaDB is running.
* The database exists.
* The database credentials are correct.
* The WordPress configuration points to the correct MariaDB service.
* The MariaDB volume exists.

---

# Data Safety

Do not remove Docker volumes unless you intentionally want to delete persistent project data.

For example, commands such as:

```bash
docker compose down -v
```

can remove the project's volumes.

This may result in the loss of the WordPress database and other persistent data.

Always make sure you understand what a Docker cleanup command will remove before running it.

---

# Summary of Common Commands

| Action              | Command                        |
| ------------------- | ------------------------------ |
| Start project       | `make`                         |
| Stop project        | `make down`                    |
| List containers     | `docker ps`                    |
| List all containers | `docker ps -a`                 |
| View logs           | `docker compose logs`          |
| Follow logs         | `docker compose logs -f`       |
| Restart services    | `docker compose restart`       |
| Rebuild             | `docker compose up -d --build` |
| List volumes        | `docker volume ls`             |
| List networks       | `docker network ls`            |

---

# Expected Result

When everything is working correctly:

1. Docker containers are running.
2. NGINX accepts HTTPS connections.
3. WordPress is accessible through the configured domain.
4. The WordPress administration panel is accessible through `/wp-admin/`.
5. WordPress can communicate with MariaDB.
6. Database and WordPress data remain persistent after container restarts.
