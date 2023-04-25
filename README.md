![](.github/images/repo_header.png)

[![Plausible](https://img.shields.io/badge/Plausible-1.5.1-blue.svg)](https://github.com/plausible/analytics/releases/tag/v1.5.1)
[![Dokku](https://img.shields.io/badge/Dokku-Repo-blue.svg)](https://github.com/dokku/dokku)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/d1ceward/plausible_on_dokku/graphs/commit-activity)

# Run Plausible on Dokku

## Perquisites

### What is Plausible?

Plausible is a lightweight and open-source website analytics tool. No cookies and fully compliant with GDPR,
CCPA and PECR.

### What is Dokku?

[Dokku](http://dokku.viewdocs.io/dokku/) is the smallest PaaS implementation you've ever seen - _Docker
powered mini-Heroku_.

### Requirements

* A working [Dokku host](http://dokku.viewdocs.io/dokku/getting-started/installation/)
* [PostgreSQL](https://github.com/dokku/dokku-postgres) plugin for Dokku
* [Clickhouse](https://github.com/dokku/dokku-clickhouse) plugin for Dokku
* [Letsencrypt](https://github.com/dokku/dokku-letsencrypt) plugin for SSL (optionnal)

# Setup

**Note :** We are going to use the domain `plausible.example.com` for demonstration purposes. Make sure to
replace it with your own domain name.

## App and plugins

### Create the app

Log onto your Dokku Host to create the Plausible app :
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
dokku postgres:create plausible -I 14.6
dokku clickhouse:create plausible -i clickhouse/clickhouse-server -I 22.9.7.34
```

```bash
# Link plugins to the main app
dokku postgres:link plausible plausible
dokku clickhouse:link plausible plausible
```

## Configuration

### Setting up secret key

```bash
dokku config:set plausible SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')
```

### Setting up BASE_URL

```bash
dokku config:set plausible BASE_URL=https://plausible.example.com
```

### Setting up smtp information

```bash
dokku config:set plausible MAILER_EMAIL=admin@example.com \
                           SMTP_HOST_ADDR=mail.example.com \
                           SMTP_HOST_PORT=465 \
                           SMTP_USER_NAME=admin@example.com \
                           SMTP_USER_PWD=example1234 \
                           SMTP_HOST_SSL_ENABLED=true
```

### Disable registration (optional)

```bash
dokku config:set plausible DISABLE_REGISTRATION=true
```

## Domain

To get the routing working, we need to apply a few settings. First we set the domain.

```bash
dokku domains:set plausible plausible.example.com
```

## Push Plausible to Dokku

### Grabbing the repository

First clone this repository onto your machine.

```bash
# Via SSH
git clone git@github.com:d1ceward/plausible_on_dokku.git

# Via HTTPS
git clone https://github.com/d1ceward/plausible_on_dokku.git
```

### Set up your Dokku server as a Git remote

```bash
git remote add dokku dokku@example.com:plausible
```

### Push Plausible to Dokku

```bash
git push dokku master
```

## SSL certificate

Last but not least, we can go and grab the SSL certificate from [Let's
Encrypt](https://letsencrypt.org/).

```bash
# Install letsencrypt plugin
dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

# Set certificate contact email
dokku config:set --no-restart plausible DOKKU_LETSENCRYPT_EMAIL=you@example.com

# Generate certificate
dokku letsencrypt:enable plausible
```

## Wrapping up

Your Plausible instance should now be available on [https://plausible.example.com](https://plausible.example.com).

### Possible issue with proxy ports mapping

If the Plausible instance is not available at the address https://plausible.example.com check the return of this command :
```bash
dokku proxy:ports plausible
```

```bash
### Valid return
-----> Port mappings for plausible
    -----> scheme  host port  container port
    http           80         5000

### Invalid return
-----> Port mappings for plausible
    -----> scheme  host port  container port
    http           5000       5000
```

If the return is not the expected one, execute this command :

```bash
dokku proxy:ports-set plausible http:80:5000
# if you also setup ssl:
dokku proxy:ports-set plausible https:443:5000
```

If the return of the command was valid and Plausible is still not available, feel free to fill an issue in the issue tracker.

## Bonus : Rename script file
By default, Plausible will use a file called `/js/plausible.js` which is blocked by most adblockers (Adblock business lets you pay to display your ads, but privacy-focused analytics are blocked by default. Yay).

Since Plausible respects user privacy, it seems fair to collect anonymous traffic data. You can add a nginx config file: `vi /home/dokku/plausible/nginx.conf.d/rewrite.conf`:

```nginx
rewrite ^/js/pls.js$ /js/plausible.js last;
```

Rename `pls.js` to whatever fits your need, and use this file name from now on.
