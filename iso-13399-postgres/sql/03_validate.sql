-- CarbideIQ Phase 1 — proof of life
-- Each query below is a load-bearing assumption that, if it returns the expected row,
-- means the dictionary layer is working as designed.

\echo
\echo '======================================================'
\echo 'TEST 1 — resolve PLIB hex code 71D08096F930C'
\echo 'EXPECT: drva | drive angle | "angle between the driving mechanism..."'
\echo '======================================================'
SELECT plib_code, mnemonic, full_name, substring(description, 1, 80) AS description_preview
FROM dict.plib_property
WHERE plib_code = '71D08096F930C';

\echo
\echo '======================================================'
\echo 'TEST 2 — resolve all 5 unknown codes from the MTConnect sample'
\echo 'EXPECT: 5 rows total, 2 properties + 3 classes'
\echo '======================================================'
SELECT 'PROPERTY' AS kind, plib_code, mnemonic, full_name
FROM dict.plib_property
WHERE plib_code IN ('71D08096F930C','71D08462F8185')
UNION ALL
SELECT 'CLASS', plib_code, mnemonic, full_name
FROM dict.plib_class
WHERE plib_code IN ('71E01A05D27A8','71E01A0E9CBA9','71EAD37F18F34')
ORDER BY kind, mnemonic;

\echo
\echo '======================================================'
\echo 'TEST 3 — GTC hierarchy walk: CTL down through the turning branch'
\echo 'EXPECT: a tree starting at CTL, descending through TL → TRN → ...'
\echo '======================================================'
WITH RECURSIVE walk AS (
    SELECT gtc_vendor_id, gtc_vendor_parent_id, gtc_vendor_node_name, gtc_class_type, 0 AS depth
    FROM dict.gtc_generic_class
    WHERE gtc_vendor_id = 'CTL'
    UNION ALL
    SELECT c.gtc_vendor_id, c.gtc_vendor_parent_id, c.gtc_vendor_node_name, c.gtc_class_type, w.depth + 1
    FROM dict.gtc_generic_class c
    JOIN walk w ON c.gtc_vendor_parent_id = w.gtc_vendor_id
    WHERE w.depth < 5
)
SELECT depth, gtc_vendor_id, gtc_vendor_node_name, gtc_class_type
FROM walk
WHERE gtc_vendor_id IN ('CTL','TL','TRN','TRNG','TRNGE','TRNGEI','MIL','DRL','INS','ADP')
ORDER BY depth, gtc_vendor_id;

\echo
\echo '======================================================'
\echo 'TEST 4 — GTC → PLIB cross-walk for DC (external cutting diameter)'
\echo 'EXPECT: GTC symbol DC → PLIB code 71D084653E57F'
\echo '======================================================'
SELECT
    g.property_symbol           AS gtc_symbol,
    g.property_name             AS gtc_name,
    g.plib_property_code        AS plib_code,
    p.mnemonic                  AS plib_mnemonic,
    p.full_name                 AS plib_full_name
FROM dict.gtc_property_canonical g
LEFT JOIN dict.plib_property p ON p.plib_code = g.plib_property_code
WHERE upper(g.property_symbol) = 'DC'
LIMIT 5;

\echo
\echo '======================================================'
\echo 'TEST 5 — coverage check: how many GTC canonical properties resolve to a PLIB row?'
\echo 'EXPECT: most resolve; gaps are the GTC-only mnemonics noted in the digest'
\echo '======================================================'
SELECT
    COUNT(*)                                                AS canonical_rows,
    COUNT(p.plib_code)                                      AS plib_resolved,
    COUNT(*) - COUNT(p.plib_code)                           AS plib_unresolved,
    ROUND(100.0 * COUNT(p.plib_code) / NULLIF(COUNT(*),0), 1) AS pct_resolved
FROM dict.gtc_property_canonical g
LEFT JOIN dict.plib_property p ON p.plib_code = g.plib_property_code;

\echo
\echo '======================================================'
\echo 'TEST 6 — ISO 513 material group lookup (6 rows P/M/K/N/S/H)'
\echo 'EXPECT: 6 rows, each with a hex color, in P/M/K/N/S/H order'
\echo '======================================================'
SELECT group_code, chart_color_hex, group_name
FROM dict.material_group
ORDER BY CASE group_code
    WHEN 'P' THEN 1 WHEN 'M' THEN 2 WHEN 'K' THEN 3
    WHEN 'N' THEN 4 WHEN 'S' THEN 5 WHEN 'H' THEN 6
END;

\echo
\echo '======================================================'
\echo 'TEST 7 — final row counts across all dictionary tables'
\echo '======================================================'
SELECT 'plib_class'              AS table_name, COUNT(*) AS rows FROM dict.plib_class
UNION ALL SELECT 'plib_property',              COUNT(*) FROM dict.plib_property
UNION ALL SELECT 'gtc_generic_class',          COUNT(*) FROM dict.gtc_generic_class
UNION ALL SELECT 'gtc_property_canonical',     COUNT(*) FROM dict.gtc_property_canonical
UNION ALL SELECT 'gtc_property_dictionary',    COUNT(*) FROM dict.gtc_property_dictionary
UNION ALL SELECT 'material_group',             COUNT(*) FROM dict.material_group
ORDER BY table_name;

\echo
\echo 'If TEST 1, TEST 2, and TEST 6 returned the expected rows, the foundation is live.'
