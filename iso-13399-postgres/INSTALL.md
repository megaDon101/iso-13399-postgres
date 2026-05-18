# Installation

## Prerequisites

- **PostgreSQL 12 or later** — any flavor (Homebrew, Postgres.app, Docker, RDS, etc.)
- **`psql` command-line client** — usually installed alongside Postgres
- **`bash`** — for the wrapper script (or run the SQL files manually if you prefer)

That's it. No Python, no Node, no other runtime. The CSVs load through psql's built-in `\copy`.

## macOS

```bash
brew install postgresql@16
brew services start postgresql@16
```

## Linux (Debian/Ubuntu)

```bash
sudo apt install postgresql-client postgresql
sudo systemctl start postgresql
```

## Docker (any host)

```bash
docker run -d --name iso13399 \
  -e POSTGRES_PASSWORD=changeme \
  -e POSTGRES_DB=iso13399 \
  -p 5432:5432 \
  postgres:16
```

Then from inside the container or with a port-forwarded client:

```bash
psql -h localhost -U postgres -d iso13399 -f sql/01_schema.sql
# ...etc
```

## Loading the database

From the repo root:

```bash
createdb iso13399              # if you haven't already
bash sql/run_all.sh            # runs all 5 scripts in order
```

Expected runtime: 30-60 seconds. Expected output: ~5,700 rows across 8 tables in the `dict` schema.

## Verifying the load

```bash
psql -d iso13399 -f sql/03_validate.sql
```

You should see nine validation tests, all returning the expected row counts. If any test returns 0 rows or errors, the load is incomplete.

## Troubleshooting

**"createdb: command not found"** → Postgres isn't on your `PATH`. Add `/usr/local/opt/postgresql@16/bin` (Homebrew) or `/usr/lib/postgresql/16/bin` (Debian) to your shell's `PATH`.

**"role 'postgres' does not exist"** → On macOS, Postgres creates a role named after your current user, not "postgres". Pass `-U $(whoami)` or omit `-U`.

**"could not connect to server"** → Postgres isn't running. `brew services start postgresql@16` (macOS) or `sudo systemctl start postgresql` (Linux).

**`\copy` errors on Windows** → Use forward slashes in paths even on Windows, and run psql from the repo root so the relative CSV paths resolve.

**Encoding errors** → All CSVs are UTF-8. If your locale is set to something else, run psql with `PGCLIENTENCODING=UTF8 psql ...`.

## What gets created

- One schema: `dict`
- Eight tables: `plib_class`, `plib_property`, `gtc_generic_class`, `gtc_property_canonical`, `gtc_property_dictionary`, `material_group`, `iso13399_property_symbol`, `iso13399_reference_symbol`, `insert_designation_position`, `insert_designation_value`
- Thirteen indexes
- Zero functions, zero triggers, zero procedural code — just data and lookups

Drop the database (`dropdb iso13399`) to reset.
