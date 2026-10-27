#!/usr/bin/env bash
# iso-13399-postgres — load all five SQL scripts in order.
# Run from the repo root (the folder containing the CSV files).
#
# Idempotent: TRUNCATEs existing dictionary tables and reloads. Safe to re-run.

set -euo pipefail

DB="${ISO13399_DB:-iso13399}"
PSQL="psql -d $DB -v ON_ERROR_STOP=1 -q"

echo "==> Using database: $DB"

# Create DB if missing
if ! psql -lqt | cut -d \| -f 1 | grep -qw "$DB"; then
    echo "==> Creating database $DB"
    createdb "$DB"
else
    echo "==> Database $DB exists, reusing"
fi

echo "==> [01] schema (dict.* tables, 13 indexes)"
$PSQL -f sql/01_schema.sql

echo "==> [02] load PLIB + GTC + material groups (~5,500 rows)"
$PSQL -f sql/02_load.sql

echo "==> [03] validate dictionary (9 end-to-end tests)"
$PSQL -f sql/03_validate.sql

echo "==> [04] load ISO 13399 property symbols (~205 rows)"
$PSQL -f sql/04_iso13399_symbols.sql

echo "==> [05] load ISO 1832 insert designation decoder (~88 rows)"
$PSQL -f sql/05_iso1832_designations.sql

echo
echo "============================================================="
echo "  iso-13399-postgres loaded — all five scripts ran"
echo "============================================================="
echo
echo "Try a query:"
echo "  psql -d $DB -c \"SELECT plib_code, mnemonic, full_name FROM dict.plib_property WHERE plib_code = '71D084653E57F';\""
