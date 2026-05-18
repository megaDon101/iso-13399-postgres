-- CarbideIQ — load canonical ISO 13399 property + reference symbol list.
--
-- Source: public ISO 13399 reference (the symbols list Don pasted, sourced from a
-- mainstream cutting-tool publisher). 203 property symbols, 5 reference symbols.
--
-- Run AFTER 01_schema.sql.
-- Usage: cd ~/Desktop/g28workstoolselection && psql -d carbideiq -f sql/06_load_iso13399_symbols.sql

-- ---------- DDL ----------

CREATE TABLE IF NOT EXISTS dict.iso13399_property_symbol (
    symbol         TEXT PRIMARY KEY,
    description    TEXT NOT NULL,
    standard       TEXT NOT NULL DEFAULT 'ISO 13399'
);

CREATE TABLE IF NOT EXISTS dict.iso13399_reference_symbol (
    symbol         TEXT PRIMARY KEY,
    description    TEXT NOT NULL,
    standard       TEXT NOT NULL DEFAULT 'ISO 13399'
);

-- ---------- LOAD ----------

\echo
\echo '======================================================'
\echo 'Loading dict.iso13399_property_symbol  (expecting 203 rows)'
\echo '======================================================'
TRUNCATE dict.iso13399_property_symbol;
\copy dict.iso13399_property_symbol (symbol, description) FROM 'iso13399_property_symbols.csv' WITH (FORMAT csv, HEADER true);
SELECT COUNT(*) AS rows_loaded FROM dict.iso13399_property_symbol;

\echo
\echo '======================================================'
\echo 'Loading dict.iso13399_reference_symbol  (expecting 5 rows)'
\echo '======================================================'
TRUNCATE dict.iso13399_reference_symbol;
\copy dict.iso13399_reference_symbol (symbol, description) FROM 'iso13399_reference_symbols.csv' WITH (FORMAT csv, HEADER true);
SELECT * FROM dict.iso13399_reference_symbol ORDER BY symbol;

-- ---------- CROSS-REFERENCE QUERIES ----------

\echo
\echo '======================================================'
\echo 'TEST 1 — overlap with existing dict.plib_property'
\echo 'EXPECT: ~172 symbols already in PLIB'
\echo '======================================================'
SELECT
    COUNT(*) FILTER (WHERE p.plib_code IS NOT NULL) AS in_plib,
    COUNT(*) FILTER (WHERE p.plib_code IS NULL)     AS plib_only_iso_has,
    COUNT(*)                                        AS total_iso_symbols
FROM dict.iso13399_property_symbol i
LEFT JOIN dict.plib_property p ON UPPER(p.mnemonic) = UPPER(i.symbol);

\echo
\echo '======================================================'
\echo 'TEST 2 — symbols in ISO 13399 list but missing from PLIB'
\echo 'EXPECT: ~14 rows (the gap fillers — internal diameters, connection sides, etc.)'
\echo '======================================================'
SELECT i.symbol, i.description
FROM dict.iso13399_property_symbol i
LEFT JOIN dict.plib_property p ON UPPER(p.mnemonic) = UPPER(i.symbol)
WHERE p.plib_code IS NULL
ORDER BY i.symbol;

\echo
\echo '======================================================'
\echo 'TEST 3 — keystone three-way join: any symbol → all our names'
\echo 'EXPECT: rows showing each of our three reference sources, side by side, for some common symbols'
\echo '======================================================'
SELECT
    i.symbol,
    i.description           AS iso13399_name,
    g.property_name         AS gtc_canonical_name,
    p.full_name             AS plib_name
FROM dict.iso13399_property_symbol i
LEFT JOIN dict.gtc_property_canonical g ON UPPER(g.property_symbol) = UPPER(i.symbol)
LEFT JOIN dict.plib_property p          ON UPPER(p.mnemonic)         = UPPER(i.symbol)
WHERE i.symbol IN ('DC','KAPR','APMX','RE','LF','OAL','DRVA','BD','S','IC')
ORDER BY i.symbol;

\echo
\echo 'ISO 13399 symbol load complete.'
\echo 'You now have three reference sources for property symbols (PLIB, GTC canonical, ISO 13399).'
\echo 'A property can be looked up in any one and joined against the others.'
