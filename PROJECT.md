# Laravel 11 + Oracle (yajra/laravel-oci8) Template

Template project: Laravel 11 using Oracle as the default database through `yajra/laravel-oci8`.

- Location: `/root/work/service/test`
- Created: 2026-10-28
- Scaffolded with: `composer create-project laravel/laravel:^11.0`, then `composer require yajra/laravel-oci8:^11`

---

## 1. Stack

| Item | Version | Notes |
|------|---------|-------|
| PHP (required) | `^8.2` | Laravel 11 minimum |
| PHP (Docker image) | 8.3.36 | `Dockerfile` (`php:8.3-cli`); the host has no PHP |
| Laravel Framework | **11.57.1** | Last 11.x release (`composer.json`: `^11.31`) |
| yajra/laravel-oci8 | **11.6.7** | Latest 11.x (`composer.json`: `^11`) |
| yajra/laravel-pdo-via-oci8 | 3.8.0 | Pulled in by laravel-oci8 (PDO wrapper over OCI8) |
| PHP extension `oci8` | 3.4.0 | Built into the Docker image (package needs >= 3.0.1) |
| Oracle Instant Client | 23.26 (Basic + SDK) | Installed in the Docker image at `/opt/oracle/instantclient` |
| Composer | 2.x | Included in the Docker image |
| Node.js (Docker `node:22`) | 22.x, npm 10.9.9 | Only used for the Vite build; installed via Docker, not on the host |

---

## 2. Composer packages

### Runtime (`require`)

| Package | Constraint | Installed |
|---------|-----------|-----------|
| laravel/framework | ^11.31 | v11.57.1 |
| laravel/tinker | ^2.9 | v2.11.1 |
| yajra/laravel-oci8 | ^11 | v11.6.7 |

### Development (`require-dev`)

| Package | Constraint | Installed |
|---------|-----------|-----------|
| fakerphp/faker | ^1.23 | v1.24.1 |
| laravel/pail | ^1.1 | v1.2.7 |
| laravel/pint | ^1.13 | v1.32.1 |
| laravel/sail | ^1.26 | v1.69.0 |
| mockery/mockery | ^1.6 | 1.6.15 |
| nunomaduro/collision | ^8.1 | v8.9.5 |
| phpunit/phpunit | ^11.0.1 | 11.5.57 |

`composer.lock` pins all 113 packages (78 runtime, 35 dev), including transitive ones. All are installed in `vendor/`. They were resolved on PHP 8.3, so Symfony components are 7.x (for example `symfony/clock` v7.4.21). It is the source of truth for exact versions. Run `composer show` to list them.

### Frontend (`package.json`, devDependencies; installed in `node_modules/`, production build tested)

| Package | Constraint | Installed |
|---------|-----------|-----------|
| vite | ^6.0.11 | 6.4.5 |
| laravel-vite-plugin | ^1.2.0 | 1.3.0 |
| tailwindcss | ^3.4.13 | 3.4.19 |
| postcss | ^8.4.47 | 8.5.32 |
| autoprefixer | ^10.4.20 | 10.6.2 |
| axios | ^1.7.4 | 1.21.0 |
| concurrently | ^9.0.1 | 9.2.5 |

`npm run build` writes the compiled assets to `public/build/`.

---------|-----------|
| vite | ^6.0.11 |
| laravel-vite-plugin | ^1.2.0 |
| tailwindcss | ^3.4.13 |
| postcss | ^8.4.47 |
| autoprefixer | ^10.4.20 |
| axios | ^1.7.4 |
| concurrently | ^9.0.1 |

---

## 3. Oracle configuration

The `oracle` connection is defined in `config/database.php`, and `DB_CONNECTION` defaults to `oracle`.

`.env` / `.env.example`:

```dotenv
DB_CONNECTION=oracle
DB_HOST=127.0.0.1
DB_PORT=1521
DB_SERVICE_NAME=XEPDB1     # or use DB_TNS
DB_DATABASE=               # SID, if you use a SID instead of a service name
DB_USERNAME=
DB_PASSWORD=
DB_SERVER_VERSION=12c      # package default is 11g; 12c+ is needed for identity columns
DB_CHARSET=AL32UTF8
```

Optional variables: `DB_TNS`, `DB_PREFIX`, `DB_SCHEMA_PREFIX`, `DB_EDITION`, `DB_LOAD_BALANCE`, `ORA_MAX_NAME_LEN`.

**Session, cache and queue** are set to `file`, `file` and `sync` (they default to `database` in a fresh Laravel 11 app). That way the app boots before Oracle is configured. To use the database drivers, run `php artisan migrate` and set `SESSION_DRIVER=database`, `CACHE_STORE=database` and `QUEUE_CONNECTION=database`.

**Oracle limits:** identifiers are limited to 30 characters by default (`ORA_MAX_NAME_LEN`, raise it to 128 for 12.2+). Keep table, index and column names short.

---

## 4. Running the project

### 4.1 Docker image (recommended, already built as `laravel11-oci8`)

The `Dockerfile` builds PHP 8.3 with `pdo`, `mbstring`, `zip`, `bcmath`, `pcntl`, Oracle Instant Client 23 and `oci8` 3.4.0. It also includes Composer. The project directory is mounted into the container, so nothing is installed on the host.

```bash
# build (once)
docker build -t laravel11-oci8 .

# run the dev server on http://localhost:8000
docker run --rm -p 8000:8000 -v "$PWD":/var/www/html laravel11-oci8

# one-off commands
docker run --rm -v "$PWD":/var/www/html laravel11-oci8 php artisan <command>
docker run --rm -v "$PWD":/var/www/html laravel11-oci8 composer <command>
docker run --rm -v "$PWD":/app -w /app node:22 npm <command>
```

If the Oracle database runs on the Docker host, use `--add-host=host.docker.internal:host-gateway` and set `DB_HOST=host.docker.internal`. `127.0.0.1` inside the container points at the container itself.

### 4.2 First-time setup (after cloning or copying the template)

```bash
cp .env.example .env
docker run --rm -v "$PWD":/var/www/html laravel11-oci8 sh -c 'composer install --no-security-blocking && php artisan key:generate'
docker run --rm -v "$PWD":/app -w /app node:22 sh -c 'npm install && npm run build'
# edit .env: DB_HOST / DB_SERVICE_NAME / DB_USERNAME / DB_PASSWORD
docker run --rm -v "$PWD":/var/www/html laravel11-oci8 php artisan migrate    # optional
```

`APP_KEY` is already generated in this copy's `.env`.

### 4.3 Commands

Run these through the Docker image (see 4.1), or directly if PHP with `oci8` is installed on the host.

| Purpose | Command |
|---------|---------|
| Dev server | `php artisan serve` |
| Full dev stack (server + queue + logs + Vite) | `composer run dev` (needs Node in the same environment) |
| Frontend dev / build | `npm run dev` / `npm run build` |
| Queue worker (when `QUEUE_CONNECTION=database`) | `php artisan queue:work` |
| Tail logs | `php artisan pail` |
| Tinker (REPL) | `php artisan tinker` |
| Tests | `php artisan test` (in-memory SQLite, no Oracle needed) |
| Code style | `./vendor/bin/pint` |
| Check the DB connection | `php artisan db:show`, or in tinker `DB::select('select 1 from dual')` |

### 4.4 Running on the host without Docker

Install PHP >= 8.2 with `oci8`, `pdo`, `mbstring`, `xml`, `curl`, `zip` and `openssl`, plus Oracle Instant Client (Basic + SDK), Composer 2 and Node 18+. Then:

```bash
echo "instantclient,/opt/oracle/instantclient" | pecl install oci8
# add `extension=oci8.so` to php.ini and set LD_LIBRARY_PATH to the Instant Client directory
```

The Dockerfile is a working reference for these steps.

---

## 5. Verification status

| Check | Result |
|-------|--------|
| `php artisan --version` in Docker (PHP 8.3) | Laravel Framework 11.57.1 |
| `oci8` extension | Loaded (3.4.0, Instant Client 23.26) |
| `php artisan test` | 2 passed |
| `npm run build` | Succeeds |
| Connection to a real Oracle database | **Not tested.** No Oracle server is available here. The driver reaches Oracle's client library: with empty credentials it returns `ORA-24415: Missing or null username` |

## 5.1 Known issues and notes

- **End-of-life framework.** Laravel 11 no longer gets security fixes. `composer audit` reports 5 advisories on `laravel/framework`, and Composer blocks all 11.x versions by default. The install used `--no-security-blocking`. To make this permanent, add `"policy": {"advisories": {"block": false}}` under `config` in `composer.json`. Consider moving to Laravel 12 or newer for production.
- **Keep one PHP version.** `composer.lock` was resolved on PHP 8.3. Running `composer update` on PHP 8.4 or newer can pull Symfony 8.x, which does not run on PHP 8.2 or 8.3. If you install with the Docker image, you avoid this.
- **The package has no `oci8:*` Artisan commands.** Use `php artisan vendor:publish` or edit `config/database.php` directly.
- **The default migrations haven't run.** Nothing has touched Oracle yet.
- **Port and credentials.** `DB_USERNAME`, `DB_PASSWORD` and `DB_SERVICE_NAME` are placeholders in `.env`.

---

## 6. Layout

```
app/            application code (Models, Http, Providers)
bootstrap/      framework bootstrap, providers
config/         app, auth, cache, database (oracle connection), filesystems, logging, mail, queue, services, session
database/       migrations (users, cache, jobs), factories, seeders
public/         web root (index.php)
resources/      views, css, js
routes/         web.php, console.php
storage/        logs, cache, sessions (file driver)
tests/          Feature / Unit (PHPUnit 11)
PROJECT.md      this file
Dockerfile      PHP 8.3 + Oracle Instant Client + oci8 image
```
