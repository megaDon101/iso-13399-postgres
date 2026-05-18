-- CarbideIQ Phase 1 — load the four dictionary CSVs
-- Run from the directory that contains the CSVs (the workspace folder).
-- Usage: cd ~/Desktop/g28workstoolselection && psql -d carbideiq -f sql/02_load.sql

\echo
\echo '======================================================'
\echo 'Loading dict.plib_class  (expecting 538 rows)'
\echo '======================================================'
TRUNCATE dict.plib_class;
\copy dict.plib_class FROM 'PLIB_classes.csv' WITH (FORMAT csv, HEADER true);
SELECT COUNT(*) AS plib_class_loaded FROM dict.plib_class;

\echo
\echo '======================================================'
\echo 'Loading dict.plib_property  (expecting 321 rows)'
\echo '======================================================'
TRUNCATE dict.plib_property;
\copy dict.plib_property FROM 'PLIB_properties.csv' WITH (FORMAT csv, HEADER true);
SELECT COUNT(*) AS plib_property_loaded FROM dict.plib_property;

\echo
\echo '======================================================'
\echo 'Loading dict.gtc_generic_class  (expecting 476 rows)'
\echo '======================================================'
TRUNCATE dict.gtc_generic_class;
\copy dict.gtc_generic_class FROM 'GTC_generic_hierarchy.csv' WITH (FORMAT csv, HEADER true);
SELECT COUNT(*) AS gtc_generic_class_loaded FROM dict.gtc_generic_class;

\echo
\echo '======================================================'
\echo 'Loading dict.gtc_property_canonical  (expecting 220 rows, then 219 after pruning the dash row)'
\echo '======================================================'
TRUNCATE dict.gtc_property_canonical;
\copy dict.gtc_property_canonical FROM 'GTC_mnemonics_canonical.csv' WITH (FORMAT csv, HEADER true);
DELETE FROM dict.gtc_property_canonical WHERE property_symbol = '-';
SELECT COUNT(*) AS gtc_property_canonical_loaded FROM dict.gtc_property_canonical;

\echo
\echo '======================================================'
\echo 'Loading dict.gtc_property_dictionary  (expecting 4,763 rows)'
\echo '======================================================'
TRUNCATE dict.gtc_property_dictionary;
\copy dict.gtc_property_dictionary FROM 'GTC_property_dictionary.csv' WITH (FORMAT csv, HEADER true);
SELECT COUNT(*) AS gtc_property_dictionary_loaded FROM dict.gtc_property_dictionary;

\echo
\echo '======================================================'
\echo 'Loading dict.material_group  (expecting 6 rows: P/M/K/N/S/H)'
\echo '======================================================'
-- CASCADE because know.cutting_parameter (from 04_knowledge_layer_schema.sql) has an FK
-- reference to material_group. Cascading is safe here — those tables are repopulated by
-- later scripts.
TRUNCATE dict.material_group CASCADE;
\copy dict.material_group FROM 'material_groups.csv' WITH (FORMAT csv, HEADER true);
SELECT group_code, chart_color_hex, group_name FROM dict.material_group ORDER BY group_code;

\echo
\echo 'Load complete. Run 03_validate.sql to prove the dictionary works end to end.'
