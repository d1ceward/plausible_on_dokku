![](.github/images/repo_header.png)

[![Plausible](https://img.shields.io/badge/Plausible-2.1.4-blue.svg)](https://github.com/plausible/analytics/releases/tag/v2.1.4)
[![Dokku](https://img.shields.io/badge/Dokku-Repo-blue.svg)](https://github.com/dokku/dokku)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/d1ceward-on-dokku/plausible_on_dokku/graphs/commit-activity)

# Run Plausible on Dokku

## Perquisites

### What is Plausible?

Plausible is a lightweight and open-source website analytics tool. No cookies and fully compliant with GDPR,
CCPA and PECR.

### What is Dokku?

[Dokku](http://dokku.viewdocs.io/dokku/) is a lightweight implementation of a Platform as a Service (PaaS) that is powered by Docker. It can be thought of as a mini-Heroku.

### Requirements

* A working [Dokku host](http://dokku.viewdocs.io/dokku/getting-started/installation/)
* [PostgreSQL](https://github.com/dokku/dokku-postgres) plugin for Dokku
* [Clickhouse](https://github.com/dokku/dokku-clickhouse) plugin for Dokku
* [Letsencrypt](https://github.com/dokku/dokku-letsencrypt) plugin for SSL (optionnal)

# Setup

**Note:** Throughout this guide, we will use the domain `plausible.example.com` for demonstration purposes. Make sure to replace it with your actual domain name.

## App and plugins

### Create the app

Log into your Dokku host and create the Minio app:
```bash
dokku apps:create plausible
```

### Install, create and link PostgreSQL and Clickhouse plugins

```bash
# Install Dokku plugins
dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
dokku plugin:install https://github.com/dokku/dokku-clickhouse.git clickhouse
```

```bash
# Create running plugins
dokku postgres:create plausible
dokku clickhouse:create plausible -i clickhouse/clickhouse-server
```

```bash
# Link plugins to the main app
dokku postgres:link plausible plausible
dokku clickhouse:link plausible plausible
```

## Configuration

### Setting up secret key

Configures the secret used for sessions in the dashboard.

```bash
dokku config:set plausible SECRET_KEY_BASE=$(openssl rand -base64 48 | tr -d '\n')
```

### Setting up TOTP vault key

Configures the secret used for encrypting TOTP secrets at rest using AES256-GCM.

```bash
dokku config:set plausible TOTP_VAULT_KEY=$(openssl rand -base64 32 | tr -d '\n')
```

### Setting up BASE_URL

Configures the base URL to use in link generation.

```bash
dokku config:set plausible BASE_URL=https://plausible.example.com
```

### Setting up SMTP information

```bash
dokku config:set plausible MAILER_EMAIL=admin@example.com \
                           SMTP_HOST_ADDR=mail.example.com \
                           SMTP_HOST_PORT=465 \
                           SMTP_USER_NAME=admin@example.com \
                           SMTP_USER_PWD=example1234 \
                           SMTP_HOST_SSL_ENABLED=true
```

### Disable registration (optional)

Restricts registration of new users. Possible values are true (full restriction), false (no restriction), and invite_only (only the invited users can register).

```bash
dokku config:set plausible DISABLE_REGISTRATION=true
```

### Persistent storage

To ensure that data persists between restarts, we create a folder on the host machine, grant write permissions to the user defined in the Dockerfile, and instruct Dokku to mount it to the app container. Follow these steps:

```bash
dokku storage:ensure-directory plausible --chown false
chown 999:65533 /var/lib/dokku/data/storage/plausible
dokku storage:mount plausible /var/lib/dokku/data/storage/plausible:/var/lib/plausible
```

## Domain

To enable routing for the Plausible app, we need to configure the domain. Execute the following command:

```bash
dokku domains:set plausible plausible.example.com
```

## Push Plausible to Dokku

### Grabbing the repository

Begin by cloning this repository onto your local machine.

```bash
# Via SSH
git clone git@github.com:d1ceward-on-dokku/plausible_on_dokku.git

# Via HTTPS
git clone https://github.com/d1ceward-on-dokku/plausible_on_dokku.git
```

### Set up git remote

Now, set up your Dokku server as a remote repository.

```bash
git remote add dokku dokku@example.com:plausible
```

### Push Plausible

Now, you can push the Plausible app to Dokku. Ensure you have completed this step before moving on to the [next section](#ssl-certificate).

```bash
git push dokku master
```

## SSL certificate

Lastly, let's obtain an SSL certificate from [Let's Encrypt](https://letsencrypt.org/).

```bash
# Install letsencrypt plugin
dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

# Set certificate contact email
dokku letsencrypt:set plausible email you@example.com

# Generate certificate
dokku letsencrypt:enable plausible
```

## Wrapping up

Congratulations! Your Plausible instance is now up and running, and you can access it at [https://plausible.example.com](https://plausible.example.com).

### Possible issue with proxy ports mapping

If the Plausible instance is not available at the address https://plausible.example.com check the return of this command:

```bash
dokku ports:list plausible
```

```bash
### Valid return
-----> Port mappings for plausible
    -----> scheme  host port  container port
    http           80         8000

### Invalid return
-----> Port mappings for plausible
    -----> scheme  host port  container port
    http           8000       8000
```

If the return is not as expected, execute this command:

```bash
dokku ports:set plausible http:80:8000

# if you also setup SSL:
dokku ports:set plausible http:80:5000 https:443:5000
```

If the command's return was valid and Plausible is still not available, please create an issue in the issue tracker.

## Bonus : Rename script file

By default, Plausible will use a file called `/js/plausible.js` which is blocked by most adblockers. To overcome this, you can add an Nginx configuration file:  `vi /home/dokku/plausible/nginx.conf.d/rewrite.conf`:

```nginx
rewrite ^/js/pls.js$ /js/plausible.js last;
```

Rename `pls.js` to whatever fits your need, and use this file name from now on.
