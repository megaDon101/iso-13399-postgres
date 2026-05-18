-- CarbideIQ Phase 1 — dictionary layer DDL
-- Run after: createdb carbideiq
-- Usage:     psql -d carbideiq -f 01_schema.sql

CREATE SCHEMA IF NOT EXISTS dict;

-- ISO 13584 PLIB classes (538 rows from database.p21)
CREATE TABLE IF NOT EXISTS dict.plib_class (
    plib_code         TEXT PRIMARY KEY,
    mnemonic          TEXT,
    full_name         TEXT,
    description       TEXT,
    bsu_version       TEXT,
    owner_entity_type TEXT
);

-- ISO 13584 PLIB properties (321 rows from database.p21)
CREATE TABLE IF NOT EXISTS dict.plib_property (
    plib_code         TEXT PRIMARY KEY,
    mnemonic          TEXT,
    full_name         TEXT,
    description       TEXT,
    bsu_version       TEXT,
    owner_entity_type TEXT
);

-- GTC generic class hierarchy (476 rows from gtc-tools.com V1R10 Rev12)
-- Note: source xlsx has a blank-header column at position 8; loaded as unused_col_8.
CREATE TABLE IF NOT EXISTS dict.gtc_generic_class (
    modified_date              TEXT,
    gtc_vendor_id              TEXT PRIMARY KEY,
    gtc_vendor_parent_id       TEXT,
    gtc_vendor_node_name       TEXT,
    gtc_vendor_preferred_name  TEXT,
    gtc_vendor_icon            TEXT,
    gtc_vendor_image           TEXT,
    unused_col_8               TEXT,
    gtc_properties             TEXT,
    gtc_class_type             TEXT,
    gtc_products_allowed       TEXT,
    change_type                TEXT
);

-- GTC property canonical (220 deduped rows from 2016 GTCapplication_property_definition.xlsx)
-- Use this as the primary GTC→PLIB lookup; the full dictionary below is the un-deduped cross product.
CREATE TABLE IF NOT EXISTS dict.gtc_property_canonical (
    property_symbol      TEXT,
    property_name        TEXT,
    plib_property_code   TEXT,
    property_class_name  TEXT,
    item_type            TEXT,
    gtc_application_id   TEXT
);

-- GTC property dictionary full (4,763 rows, property × GTC application cross product)
-- Useful for "which GTC applications use property X" queries.
CREATE TABLE IF NOT EXISTS dict.gtc_property_dictionary (
    property_symbol      TEXT,
    property_name        TEXT,
    plib_property_code   TEXT,
    property_class_name  TEXT,
    item_type            TEXT,
    gtc_application_id   TEXT
);

-- ISO 513 material groups (6 rows: P/M/K/N/S/H)
-- Source: ToolSelection4claude_enhanced.pdf p2. Hex colors sampled from rendered page.
CREATE TABLE IF NOT EXISTS dict.material_group (
    group_code                CHAR(1) PRIMARY KEY,
    group_name                TEXT NOT NULL,
    typical_materials         TEXT,        -- comma-separated alloy callouts
    hardness_range_hb         TEXT,
    hardness_range_hrc        TEXT,
    machining_characteristics TEXT,
    chart_color_hex           CHAR(7)      -- e.g. '#4472C4'
);

-- Indexes for the queries we'll actually run
CREATE INDEX IF NOT EXISTS plib_class_mnemonic_idx
    ON dict.plib_class (mnemonic);
CREATE INDEX IF NOT EXISTS plib_property_mnemonic_idx
    ON dict.plib_property (mnemonic);
CREATE INDEX IF NOT EXISTS gtc_generic_class_parent_idx
    ON dict.gtc_generic_class (gtc_vendor_parent_id);
CREATE INDEX IF NOT EXISTS gtc_property_canonical_plib_idx
    ON dict.gtc_property_canonical (plib_property_code);
CREATE INDEX IF NOT EXISTS gtc_property_canonical_symbol_idx
    ON dict.gtc_property_canonical (property_symbol);
CREATE INDEX IF NOT EXISTS gtc_property_dictionary_plib_idx
    ON dict.gtc_property_dictionary (plib_property_code);

\echo 'Schema created. Run 02_load.sql next.'
\echo '(For the vendor knowledge layer — grades, chipbreakers, cutting parameters,'
\echo ' cross-vendor equivalents — see 04_knowledge_layer_schema.sql.)'
