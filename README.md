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
| `ghcr.io/artiomshosting/yolks:postgres_18` | `postgres:18-trixie` | PostgreSQL 18 with pgvector, psql, tini |
| `ghcr.io/artiomshosting/yolks:postgres_17` | `postgres:17-trixie` | The same, with PostgreSQL 17 |
| `ghcr.io/artiomshosting/yolks:postgres_16` | `postgres:16-trixie` | The same, with PostgreSQL 16 |
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

**Every start:** PostgreSQL listens on the server's port on all addresses (given on the command line, so
`postgresql.conf` stays the user's to edit). Once it accepts connections, the password is applied, the
database is created if needed, `[System] Database ready` is printed (the eggs' `done` marker), and the console
becomes a `psql` session as that user. Leaving psql with `\q` opens a new one; stopping the server shuts
PostgreSQL down with a fast shutdown.

**Major versions:** data created by one major version can't be opened by another. Starting with a different
image stops with a message instead of touching the data; move between versions with `pg_dumpall` and a restore.

Wings runs the server as a user that isn't in `/etc/passwd` unless `system.passwd.enabled` is on, and
PostgreSQL refuses to run without one, so `start-postgres` provides it through `nss_wrapper` when needed.

## Building

Images are built by GitHub Actions on every change to their folder, every Monday (without cache, so
base-image security fixes land) and on demand. To build one locally:

```sh
docker buildx build --platform linux/arm64 --build-arg NODE_VERSION=26 -f nodejs/Dockerfile -t yolks:nodejs_26 nodejs
docker buildx build --platform linux/arm64 --build-arg PG_MAJOR=18 -f postgres/Dockerfile -t yolks:postgres_18 postgres
```

## Credits

Inspired by [pterodactyl/yolks](https://github.com/pterodactyl/yolks) and
[pelican-eggs/yolks](https://github.com/pelican-eggs/yolks).
