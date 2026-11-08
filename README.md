# Yolks

Docker images for [Pterodactyl](https://pterodactyl.io) and [Pelican](https://pelican.dev) servers that
run scripts and apps. Each image is built for `linux/amd64` and `linux/arm64` and published to
`ghcr.io/artiomshosting/yolks`. Free to use in your own eggs.

| Image | Base | Includes |
| --- | --- | --- |
| `ghcr.io/artiomshosting/yolks:nodejs_26` | `node:26-trixie-slim` | Node.js 26, npm, pnpm 12, Yarn 1, Corepack, git, curl, tini, build tools for native modules |
| `ghcr.io/artiomshosting/yolks:nodejs_24` | `node:24-trixie-slim` | The same, with Node.js 24 |
| `ghcr.io/artiomshosting/yolks:nodejs_22` | `node:22-trixie-slim` | The same, with Node.js 22 (end of life April 2027) |
| `ghcr.io/artiomshosting/yolks:nodejs_20` | `node:20-trixie-slim` | The same, with Node.js 20. **End of life since April 2026: Node.js gets no security fixes.** Only for projects that cannot move yet. No TypeScript support |
| `ghcr.io/artiomshosting/yolks:python_3.15` | `python:3.15-slim-trixie` | Python 3.15, uv, pip in the virtual environment, git, curl, tini, gcc/g++/make for packages without wheels |
| `ghcr.io/artiomshosting/yolks:python_3.14` | `python:3.14-slim-trixie` | The same, with Python 3.14 |
| `ghcr.io/artiomshosting/yolks:python_3.13` | `python:3.13-slim-trixie` | The same, with Python 3.13 |
| `ghcr.io/artiomshosting/yolks:python_3.12` | `python:3.12-slim-trixie` | The same, with Python 3.12 |
| `ghcr.io/artiomshosting/yolks:python_3.11` | `python:3.11-slim-trixie` | The same, with Python 3.11 |
| `ghcr.io/artiomshosting/yolks:python_3.10` | `python:3.10-slim-trixie` | The same, with Python 3.10. **End of life since October 2026: Python gets no security fixes.** Only for projects that cannot move yet |
| `ghcr.io/artiomshosting/yolks:postgres_18` | `postgres:18-trixie` | PostgreSQL 18 with pgvector, psql, tini |
| `ghcr.io/artiomshosting/yolks:postgres_17` | `postgres:17-trixie` | The same, with PostgreSQL 17 |
| `ghcr.io/artiomshosting/yolks:postgres_16` | `postgres:16-trixie` | The same, with PostgreSQL 16 |
| `ghcr.io/artiomshosting/yolks:nginx_static` | `nginx:stable-trixie` | Nginx stable, git, tini |
| `ghcr.io/artiomshosting/yolks:nginx_php8.5` | `php:8.5-fpm-trixie` | Nginx stable from nginx.org, PHP 8.5 FPM, Composer, common PHP extensions, git, tini |
| `ghcr.io/artiomshosting/yolks:nginx_php8.4` | `php:8.4-fpm-trixie` | The same, with PHP 8.4 |
| `ghcr.io/artiomshosting/yolks:nginx_php8.3` | `php:8.3-fpm-trixie` | The same, with PHP 8.3 |
| `ghcr.io/artiomshosting/yolks:installer_debian` | `debian:trixie-slim` | For egg install scripts: runs as root with git, curl, jq, tar, unzip, xz |

Every image also gets a dated tag (`nodejs_26-20261028`) so a server can be pinned to a known build.

All Node.js images build from one `nodejs/Dockerfile` with `NODE_VERSION` as a build argument. Node.js 24
and older bundle Yarn 1 and Corepack, which the images keep; on newer versions the Dockerfile installs
them. Corepack is installed in its own prefix, because `npm install --global corepack` replaces pnpm and
Yarn with shims that download them again on every server.

## How the images behave

Wings runs every server container as its own user (not the image's `container` user), with a read-only
filesystem where only `/home/container` and `/tmp` are writable, and without an init process. The images
are built for that:

- `tini` is the entrypoint, so stop signals reach the app and zombie processes are reaped.
- `entrypoint.sh` changes to `/home/container`, turns `{{VARIABLE}}` in the egg's `STARTUP` command into
  `${VARIABLE}` and runs it with `bash -c`, so startup commands can use `if` and `&&`. Variable values
  are expanded as data, never evaluated as code.
- Package managers are installed at build time, because nothing can be installed globally at runtime.

## `start-app` (Node.js images)

The start logic lives in the image instead of the egg, so a fix here reaches every server on its next
restart (Wings pulls the image on every start; servers keep their own copy of an egg's startup command).
An egg's startup command is just `start-app`. It reads these variables:

| Variable | Default | What it does |
| --- | --- | --- |
| `AUTO_UPDATE` | `0` | `1` pulls the latest commit (fast-forward only) before starting, when the server is a git checkout |
| `GIT_USERNAME`, `GIT_TOKEN` | empty | Credentials for private repositories, passed to git without being written to `.git/config` |
| `INSTALL_DEPS` | `1` | `1` installs dependencies when there is a `package.json`, skipped when nothing changed since the last install |
| `PACKAGE_MANAGER` | `auto` | `npm`, `pnpm` or `yarn`; `auto` uses the `packageManager` field, then the lockfile, then npm |
| `MAIN_FILE` | empty | File started with `node` (TypeScript works through Node's type stripping on Node.js 22 and newer); empty = zero-config start |
| `NODE_ARGS` | empty | Extra arguments for `node` |
| `START_COMMAND` | empty | Replaces the start with a custom command, such as `npm run build && npm start` |

**Start order:** `START_COMMAND`, then `MAIN_FILE`, then the `start` script in `package.json`, then its `main`
file, then `index.js`, `index.mjs`, `index.cjs` or `index.ts`.

**Dependencies:** installed with devDependencies (so builds work), whatever `NODE_ENV` is. A hash of
`package.json`, the lockfile, the Node.js major version and the package manager is stored in
`node_modules/.dependencies-hash`; the install is skipped when it matches. A project that declares
`"packageManager": "pnpm@…"` or `"yarn@…"` gets exactly that version through Corepack; otherwise the
built-in pnpm 12 or Yarn 1 is used. pnpm is allowed to run dependencies' build scripts.

**Environment:** `PORT` (the server's port), `HOST=0.0.0.0` and `NODE_ENV=production` are set as defaults.
A key defined in the project's `.env` file is left unset so the project's own `.env` loader wins.
`NODE_OPTIONS` gets `--max-old-space-size` at 75% of the server's memory, unless `NODE_OPTIONS` or
`NODE_ARGS` already set one.

Right before the app starts it prints `[System] App starting`, which eggs use as their `done` marker.

## `start-app` (Python images)

All Python images build from one `python/Dockerfile` with `PYTHON_VERSION` as a build argument. The root
filesystem is read-only, so dependencies go into a virtual environment at `/home/container/.venv`, which is
first on `PATH`: `python` and `pip` in a start command use it (projects with a `uv.lock` get an exact
environment without pip; use `uv pip` there). Output is unbuffered (`PYTHONUNBUFFERED=1`),
so `print` shows in the console right away. The egg's startup command is just `start-app`, which reads:

| Variable | Default | What it does |
| --- | --- | --- |
| `AUTO_UPDATE`, `GIT_USERNAME`, `GIT_TOKEN` | `0`, empty | The same as in the Node.js images |
| `INSTALL_DEPS` | `1` | `1` installs dependencies, skipped when nothing changed since the last install |
| `MAIN_FILE` | empty | File started with `python`; empty = `main.py`, then `app.py`, then `bot.py` |
| `PYTHON_ARGS` | empty | Extra arguments for `python` |
| `START_COMMAND` | empty | Replaces the start with a custom command, such as `uvicorn app:app --host 0.0.0.0 --port $PORT` |

**Dependencies** are installed with [uv](https://docs.astral.sh/uv/) from the first of: `uv.lock` (`uv sync
--frozen --no-dev`), `requirements.txt` (`uv pip install`), or `pyproject.toml` with a `[project]` table (its
dependencies). A hash of that file and the Python version is stored in `.venv/.dependencies-hash`; the
install is skipped when it matches. When the server switches to another Python version, `.venv` is
recreated. uv keeps no cache, so it doesn't use the server's disk twice.

**Environment:** `PORT` (the server's port) and `HOST=0.0.0.0` are set as defaults, unless the project's `.env`
defines them, since `python-dotenv` does not override variables that are already set.

Right before the app starts it prints `[System] App starting`. Stopping sends SIGINT, which Python raises as
`KeyboardInterrupt`, so apps can shut down cleanly.

## `start-postgres` (PostgreSQL images)

All PostgreSQL images build from one `postgres/Dockerfile` with `PG_MAJOR` as a build argument, on the
official Debian images, and add pgvector from the PostgreSQL apt repository. An egg's startup command is
just `start-postgres`. It reads these variables:

| Variable | Default | What it does |
| --- | --- | --- |
| `POSTGRES_USER` | `postgres` | Superuser created with the database |
| `POSTGRES_PASSWORD` | none, required | Its password, applied again on every start so changing it in the panel works |
| `POSTGRES_DB` | `postgres` | Database the console opens, created on start when missing |

**First start:** creates the database in `/home/container/postgres_db` (UTF-8; the `builtin` C.UTF-8 locale on
PostgreSQL 17 and newer, which keeps text sorting stable across OS updates; libc C.UTF-8 on 16). Connections
over the network need the password (`scram-sha-256`); connections over the local socket in `/tmp` are trusted,
since only the container itself can reach it.

**SSL:** when `postgres_db` has neither `server.crt` nor `server.key`, a self-signed certificate (RSA 2048, valid
10 years, named after the container's hostname, which Wings sets to the server's UUID) is created, so existing
servers get one on their next start. SSL is on but not required: `sslmode=require` encrypts, `sslmode=disable`
still connects in plain text, and `verify-full` needs a certificate the client trusts. Replace both files with
your own to use a real certificate; with only one of them present, PostgreSQL starts without SSL.

**Every start:** PostgreSQL listens on the server's port on all addresses (given on the command line, so
`postgresql.conf` stays the user's to edit). Once it accepts connections, the password is applied, the
database is created if needed, `[System] Database ready` is printed (the eggs' `done` marker), and the console
becomes a `psql` session as that user. Leaving psql with `\q` opens a new one; stopping the server shuts
PostgreSQL down with a fast shutdown.

**Major versions:** data created by one major version can't be opened by another. Starting with a different
image stops with a message instead of touching the data; move between versions with `pg_dumpall` and a restore.

Wings runs the server as a user that isn't in `/etc/passwd` unless `system.passwd.enabled` is on, and
PostgreSQL refuses to run without one, so `start-postgres` provides it through `nss_wrapper` when needed.

## `start-nginx` (Nginx images)

`nginx/Dockerfile` builds the static image on the official Nginx image. `nginx/php.Dockerfile` builds the PHP
images on the official PHP-FPM images with `PHP_VERSION` as a build argument, adds Nginx stable from the
nginx.org apt repository and these extensions on top of PHP's defaults: bcmath, exif, gd, intl, mysqli,
opcache, pcntl, pdo_mysql, pdo_pgsql, pgsql, redis, zip. An egg's startup command is just `start-nginx`. It
reads these variables:

| Variable | Default | What it does |
| --- | --- | --- |
| `AUTO_UPDATE` | `0` | `1` pulls the latest commit (fast-forward only) into `www` before starting, when `www` is a git checkout |
| `GIT_USERNAME`, `GIT_TOKEN` | empty | Credentials for private repositories, passed to git without being written to `.git/config` |
| `INSTALL_DEPS` | `1` | PHP images: `1` runs `composer install --no-dev` when there is a `www/composer.json`, skipped when nothing changed |

**Files on the server:**

| Path | What it is |
| --- | --- |
| `www/` | The web root |
| `nginx/*.conf` | The site configuration, included in Nginx's `http` block. `default.conf` is created when the folder has no `.conf` file |
| `php/*.ini` | PHP images: PHP settings, loaded after the image's own. `php.ini` is created when the folder has no `.ini` file |

The image owns the main `nginx.conf` (`nginx/config/nginx.conf`): the pid file and temporary files in `/tmp`,
logs to the console, gzip, `server_tokens off`, and relative redirects, so redirects keep working behind a
proxy. Override its `http` settings inside a `server` block. Two files ship with the image for the site
configuration to include:

- `server-port.conf` is `listen <port>;` with the server's current port, written on every start, so a site
  keeps working when its port changes. Replace the include with your own `listen` line to add options such
  as `ssl`.
- `php.conf` passes `.php` files to PHP-FPM on the PHP images and answers them with 404 on the static image,
  so switching images never serves PHP source code.

The default site serves `www`, sends unknown paths to `index.php` when it exists (WordPress and Laravel
style front controllers), shows `404.html` when there is one, hides dotfiles (except `.well-known`),
`vendor/` and `composer.json`/`composer.lock`, and accepts uploads up to 32 MB (`client_max_body_size`;
raise `upload_max_filesize` and `post_max_size` in `php/php.ini` with it).

**Every start:** Nginx runs with one worker per CPU of the server's limit (at most 4). PHP-FPM starts first, on
a socket in `/tmp`, with workers started on demand: one per 64 MB of the server's memory, between 2 and 32.
PHP scripts don't see the server's environment variables. Once Nginx listens, `[System] Web server ready` is
printed (the eggs' `done` marker), with a warning when nothing listens on the server's port. Requests and
errors, PHP warnings included, are shown in the console; add `access_log off;` to a `server` block to hide the
requests.

**Console:** `reload` checks the Nginx and PHP configuration and applies it without a restart (a broken
configuration is reported and the running one is kept), `test` only checks it, `help` lists the commands.
Stopping the server shuts Nginx and PHP-FPM down with a fast shutdown. If either one stops on its own, the
other is stopped too, so the panel shows the server as crashed.

## Building

Images are built by GitHub Actions on every change to their folder, every Monday (without cache, so
base-image security fixes land) and on demand. To build one locally:

```sh
docker buildx build --platform linux/arm64 --build-arg NODE_VERSION=26 -f nodejs/Dockerfile -t yolks:nodejs_26 nodejs
docker buildx build --platform linux/arm64 --build-arg PYTHON_VERSION=3.14 -f python/Dockerfile -t yolks:python_3.14 python
docker buildx build --platform linux/arm64 --build-arg PG_MAJOR=18 -f postgres/Dockerfile -t yolks:postgres_18 postgres
docker buildx build --platform linux/arm64 -f nginx/Dockerfile -t yolks:nginx_static nginx
docker buildx build --platform linux/arm64 --build-arg PHP_VERSION=8.5 -f nginx/php.Dockerfile -t yolks:nginx_php8.5 nginx
```

## Credits

Inspired by [pterodactyl/yolks](https://github.com/pterodactyl/yolks) and
[pelican-eggs/yolks](https://github.com/pelican-eggs/yolks).
