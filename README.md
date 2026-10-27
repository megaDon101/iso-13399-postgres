# iso-13399-postgres

**A working PostgreSQL bridge between the major manufacturing-tooling standards: ISO 13584 PLIB, the GTC (Generic Tool Catalog) class hierarchy, ISO 13399 property symbols, and ISO 1832 insert designations.**

If you're building manufacturing software — CAM systems, ERP integrations, MES tooling, custom shop-floor tools — and you've ever stared at a STEP file containing PLIB hex codes like `71D08096F930C` and asked "what *is* that?", this repo is for you. It loads the codes, the cross-walks, and the validation queries you need to make sense of them.

This project is the open-source dictionary layer underneath [CarbideIQ](https://www.carbideiq.com/), a commercial carbide tool recommendation engine. The standards work is not the commercial product — it's the foundation. Releasing it publicly because the manufacturing-software community needs a shared, queryable starting point for this data, and right now there isn't one.

## What's inside

| Standard | Rows | Purpose |
|---|---:|---|
| ISO 13584 PLIB classes | 538 | Hierarchical class taxonomy for cutting tools (insert, end mill, drill, etc.) |
| ISO 13584 PLIB properties | 321 | Property definitions (diameter, angle, length, hardness, etc.) with hex codes and mnemonics |
| GTC generic class hierarchy | 476 | The Generic Tool Catalog tree (CTL → TL → TRN → TRNG → TRNGE → TRNGEI) |
| GTC canonical mnemonics | 219 | GTC's preferred property symbols mapped to PLIB codes |
| GTC property dictionary | 4,763 | Multi-language property descriptions across the GTC taxonomy |
| ISO 13399 property symbols | 203 | Industry-standard symbol set (DC, APMX, KAPR, RE, etc.) |
| ISO 1832 insert designations | 75+ codes | The four-letter prefix that decodes any standard turning insert (CNMG, TNMG, WNMG, etc.) |
| ISO 513 material groups | 6 | P/M/K/N/S/H material classification |

All of it loads into a PostgreSQL database in under a minute. All of it is queryable. All of it cross-references cleanly — a PLIB hex code resolves to a GTC mnemonic resolves to an ISO 13399 symbol, in a single join.

## Why this matters

The manufacturing-tooling world has three overlapping standards bodies — IEC, ISO TC 29, and the GTC consortium — that all describe the same physical things (insert nose radius, cutting diameter, drive angle) in slightly different vocabularies. Tool catalogs from Sandvik, Kennametal, ISCAR, etc. use these standards downstream, but the dictionaries that decode them are scattered across PDF appendices and proprietary XML schemas.

This repo is the bridge. Load it, and any of these become a one-line query:

- *"Given PLIB hex code `71D084653E57F`, what property is that?"* → external cutting diameter (DC), defined in both GTC and ISO 13399
- *"What GTC classes describe an indexable external turning tool holder?"* → walk the hierarchy: CTL → TL → TRN → TRNG → TRNGE → TRNGEI
- *"Decode the insert designation `CNMG120408`:"* → C (rhomboid 80°), N (negative clearance), M (tolerance class M), G (cylindrical hole + chipbreaker), 12mm length, 4.76mm thickness, 0.8mm corner radius
- *"What symbol is used across all three standards for tool cutting edge angle?"* → KAPR

## Quick start

```bash
# Prerequisites: PostgreSQL 12+
createdb iso13399

# Clone and load
git clone https://github.com/megaDon101/iso-13399-postgres.git
cd iso-13399-postgres
bash sql/run_all.sh
```

Five scripts run in ~30 seconds and populate a `dict` schema with eight tables.

After loading, try a few representative queries:

```sql
-- Resolve a PLIB hex code
SELECT plib_code, mnemonic, full_name, description
FROM dict.plib_property
WHERE plib_code = '71D084653E57F';

-- Walk the GTC turning-tool hierarchy
WITH RECURSIVE walk AS (
    SELECT gtc_vendor_id, gtc_vendor_node_name, 0 AS depth
    FROM dict.gtc_generic_class WHERE gtc_vendor_id = 'CTL'
    UNION ALL
    SELECT c.gtc_vendor_id, c.gtc_vendor_node_name, w.depth + 1
    FROM dict.gtc_generic_class c JOIN walk w ON c.parent_vendor_id = w.gtc_vendor_id
)
SELECT * FROM walk WHERE depth < 6;

-- Decode an ISO 1832 designation
SELECT position_number, code, meaning
FROM dict.insert_designation_value
WHERE (position_number, code) IN ((1,'C'),(2,'N'),(3,'M'),(4,'G'));
```

The full validation suite is in `sql/03_validate.sql` — runs nine end-to-end tests that prove the cross-walks resolve correctly.

## Structure

```
iso-13399-postgres/
├── README.md                              this file
├── LICENSE                                MIT
├── INSTALL.md                             prerequisites + troubleshooting
├── sql/
│   ├── 01_schema.sql                      dict.* DDL (8 tables, 13 indexes)
│   ├── 02_load.sql                        loads the 8 CSV files
│   ├── 03_validate.sql                    9 validation queries
│   ├── 04_iso13399_symbols.sql            loads ISO 13399 symbol tables
│   ├── 05_iso1832_designations.sql        loads ISO 1832 turning insert decoder
│   └── run_all.sh                         runs all five scripts in order
├── docs/
│   └── standards-reference.md             citations + further reading
└── *.csv                                  10 dictionary data files (~605 KB total)
```

## What this is not

This repo is **not** a tool recommendation engine, not a cutting-parameter database, and not a vendor catalog. It contains zero proprietary vendor data — no Sandvik grade tables, no Kennametal cutting parameters, no ISCAR chipformer specs. Those live in the commercial CarbideIQ product. What's here is the standards infrastructure that *underlies* such products and that nobody has previously made available as a working, loadable database.

If you want the commercial layer on top, reach out: [carbideiq.com](https://www.carbideiq.com/).

## Contributing

PRs welcome, especially:

- Additional ISO 1832 insert codes (we cover 75+ of the most common; the standard has more)
- Translations of GTC property names beyond English
- Validation queries that catch new edge cases
- Bug fixes in the cross-walks

## License

MIT. See [LICENSE](LICENSE).

## Citations

The standards summarized in this repo are owned by their respective bodies. This repo redistributes only factual content (codes, mnemonics, hierarchical relationships) — not the standard texts themselves. Refer to the originals for normative usage:

- **ISO 13584-42** (PLIB / IEC 61360-1) — Industrial automation systems and integration: parts library
- **ISO 13399** — Cutting tool data representation and exchange
- **ISO 1832** — Indexable inserts for cutting tools: designation
- **ISO 513** — Classification and application of hard cutting materials
- **GTC Specification v2.1.1** — Generic Tool Catalog Schema (ISO TC 29 / industry consortium)

See [docs/standards-reference.md](docs/standards-reference.md) for full attribution and links.

## About

Built by Don Fite at [G28 Works](https://g28works.com/), founder of [CarbideIQ](https://www.carbideiq.com/). Over a decade in CNC; this is the part of the toolbox the industry should share.

This is one person working through a lot of fragmented standards documentation and manufacturer reference material. Mistakes are mine, and there will be some — corrections, additions, and pull requests are genuinely welcome. More eyes catch more errors than mine alone.

Questions, issues, or interested in CarbideIQ proper: don@g28works.com
