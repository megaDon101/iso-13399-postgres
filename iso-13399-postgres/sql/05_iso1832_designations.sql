-- CarbideIQ — load ISO 1832 insert designation positions and codes.
--
-- Source: Kennametal Milling Insert Identification System PDF (4 pages, 2006).
-- This populates the existing dict.insert_designation_position and
-- dict.insert_designation_value tables that have been awaiting data since the
-- knowledge layer schema was created (task #20).
--
-- ISO 1832 defines a multi-position alphanumeric code that uniquely describes
-- a cutting insert: shape, clearance angle, tolerance, hole type, dimensions,
-- edge preparation, rake face angle, and optional features. Every major vendor
-- uses these codes (Kennametal documentation just provides authoritative
-- explanations of what each position means).
--
-- Run AFTER 04_knowledge_layer_schema.sql.
-- Usage: cd ~/Desktop/g28workstoolselection && psql -d carbideiq -f sql/14_load_iso1832_designations.sql

-- ---------- DDL FIX + LOAD ----------
-- The original table created in 04_knowledge_layer_schema.sql has a CHECK constraint
-- limiting position_number to 1-10. Our CSV uses positions 1-13 (extending into
-- Kennametal extension positions). Drop and recreate the table without that constraint.

DROP TABLE IF EXISTS dict.insert_designation_value CASCADE;
DROP TABLE IF EXISTS dict.insert_designation_position CASCADE;

CREATE TABLE dict.insert_designation_position (
    position_number   SMALLINT PRIMARY KEY CHECK (position_number BETWEEN 1 AND 20),
    property_name     TEXT NOT NULL,
    description       TEXT,
    standard          TEXT NOT NULL DEFAULT 'ISO 1832'
);

CREATE TABLE dict.insert_designation_value (
    position_number   SMALLINT NOT NULL REFERENCES dict.insert_designation_position(position_number),
    code              TEXT NOT NULL,
    meaning           TEXT NOT NULL,
    sort_order        INT,
    PRIMARY KEY (position_number, code)
);

\echo
\echo '======================================================'
\echo 'Loading dict.insert_designation_position  (expecting 13 rows)'
\echo '======================================================'
\copy dict.insert_designation_position (position_number, property_name, description, standard) FROM 'iso1832_positions.csv' WITH (FORMAT csv, HEADER true);
SELECT COUNT(*) AS positions_loaded FROM dict.insert_designation_position;

\echo
\echo '======================================================'
\echo 'Loading dict.insert_designation_value  (expecting ~75 rows)'
\echo '======================================================'
TRUNCATE dict.insert_designation_value;
\copy dict.insert_designation_value (position_number, code, meaning, sort_order) FROM 'iso1832_values.csv' WITH (FORMAT csv, HEADER true);
SELECT COUNT(*) AS values_loaded FROM dict.insert_designation_value;

-- ---------- VALIDATION ----------

\echo
\echo '======================================================'
\echo 'TEST 1 — values per position (coverage by attribute)'
\echo '======================================================'
SELECT p.position_number, p.property_name, COUNT(v.code) AS value_count
FROM dict.insert_designation_position p
LEFT JOIN dict.insert_designation_value v ON v.position_number = p.position_number
GROUP BY p.position_number, p.property_name
ORDER BY p.position_number;

\echo
\echo '======================================================'
\echo 'TEST 2 — decode a real turning insert: CNMG120408'
\echo '  Position 1 (C)  → shape: rhomboid 80°'
\echo '  Position 2 (N)  → clearance angle 0° (negative)'
\echo '  Position 3 (M)  → tolerance class M (most common turning)'
\echo '  Position 4 (G)  → with cylindrical hole, double-sided chipbreaker'
\echo '  Position 5-7    → 12mm length / 4.76mm thickness / 0.8mm radius'
\echo '======================================================'
SELECT
    1 AS pos, 'C' AS code, (SELECT meaning FROM dict.insert_designation_value
                            WHERE position_number=1 AND code='C') AS meaning
UNION ALL SELECT 2, 'N', (SELECT meaning FROM dict.insert_designation_value
                          WHERE position_number=2 AND code='N')
UNION ALL SELECT 3, 'M', (SELECT meaning FROM dict.insert_designation_value
                          WHERE position_number=3 AND code='M')
UNION ALL SELECT 4, 'G', (SELECT meaning FROM dict.insert_designation_value
                          WHERE position_number=4 AND code='G')
ORDER BY pos;

\echo
\echo '======================================================'
\echo 'TEST 3 — rake face angle decoder (the chart from the screenshot)'
\echo '======================================================'
SELECT code, meaning
FROM dict.insert_designation_value
WHERE position_number = 12
ORDER BY sort_order;

\echo
\echo '======================================================'
\echo 'TEST 4 — KEYSTONE: full decode of any Kennametal insert designation'
\echo 'Pick CNGA120404S01225DMT — show what every position means'
\echo '======================================================'
WITH parts AS (
    SELECT
        'C' AS shape, 'N' AS clearance, 'G' AS tol, 'A' AS clamping
)
SELECT
    'shape ('|| p.shape ||')' AS pos, v.meaning
FROM parts p, dict.insert_designation_value v
WHERE v.position_number = 1 AND v.code = p.shape
UNION ALL
SELECT 'clearance ('|| p.clearance ||')', v.meaning
FROM parts p, dict.insert_designation_value v
WHERE v.position_number = 2 AND v.code = p.clearance
UNION ALL
SELECT 'tolerance ('|| p.tol ||')', v.meaning
FROM parts p, dict.insert_designation_value v
WHERE v.position_number = 3 AND v.code = p.tol
UNION ALL
SELECT 'clamping ('|| p.clamping ||')', v.meaning
FROM parts p, dict.insert_designation_value v
WHERE v.position_number = 4 AND v.code = p.clamping;

\echo
\echo 'ISO 1832 designation tables loaded.'
\echo 'You can now decode any standard insert designation by joining to these tables.'
\echo 'Example: SELECT meaning FROM dict.insert_designation_value WHERE position_number=12 AND code=''D''  → "Rake face angle: 15°"'
