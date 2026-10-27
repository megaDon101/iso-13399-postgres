# Standards Reference

The data in this repository is structured factual content extracted from several manufacturing-tooling standards. The standard texts themselves are copyrighted by their respective bodies and are not redistributed here. This document cites each source and explains what's included.

## ISO 13584 / IEC 61360 — PLIB (Parts Library)

**Owner:** ISO TC 184/SC 4 and IEC TC 3
**Scope:** Standardized representation of part data and properties via a hierarchical class library with globally unique hex-encoded identifiers.
**What's in this repo:** 538 class codes (e.g., `71E01A0E9CBA9` = boring bar) and 321 property codes (e.g., `71D08096F930C` = drive angle). Each row carries the hex code, mnemonic, full name, and short description.
**Where to get the standard:** [ISO 13584 family](https://www.iso.org/standard/27632.html) | [IEC 61360 dictionary browser](https://cdd.iec.ch/)

## GTC — Generic Tool Catalog Schema

**Owner:** Industry consortium operating under ISO TC 29 governance; published as XSD by participating tool manufacturers.
**Scope:** A class hierarchy (CTL → Tool item → Turning tool → Tool holder → External turning tool → indexable) and a property dictionary that maps to PLIB codes. Used by Sandvik Coromant and others as the basis for machine-readable catalog distribution.
**What's in this repo:** 476 generic class entries (with parent/child relationships), 219 canonical property mnemonics, and 4,763 property dictionary entries with multi-language descriptions.
**Where to get the standard:** [GTC-Package-Specification at sandvik.coromant.com](https://www.sandvik.coromant.com/) (search for "GTC package")

## ISO 13399 — Cutting Tool Data Representation and Exchange

**Owner:** ISO TC 29/SC 9
**Scope:** Defines property symbols and reference geometries for cutting tools — DC for cutting diameter, APMX for maximum depth of cut, KAPR for tool cutting edge angle, etc.
**What's in this repo:** 205 property symbols and 5 coordinate-reference symbols, each with their canonical description.
**Where to get the standard:** [ISO 13399 family](https://www.iso.org/standard/53534.html)

## ISO 1832 — Indexable Inserts for Cutting Tools: Designation

**Owner:** ISO TC 29
**Scope:** The four-letter-plus-numbers code system that names every standard turning insert. `CNMG120408` = C (shape, 80° rhomboid) + N (clearance, 0°) + M (tolerance class) + G (chipbreaker + cylindrical hole) + 12 (cutting edge length) + 04 (thickness) + 08 (corner radius).
**What's in this repo:** 13 position definitions and ~75 code values covering the most common turning insert designations. Sufficient to decode any standard CNMG, TNMG, WNMG, DCMT, etc.
**Where to get the standard:** [ISO 1832:2017](https://www.iso.org/standard/68526.html)

## ISO 513 — Classification and Application of Hard Cutting Materials

**Owner:** ISO TC 29
**Scope:** The P/M/K/N/S/H material classification used across virtually every cutting tool catalog. P=steel, M=stainless, K=cast iron, N=non-ferrous, S=heat-resistant superalloys + titanium, H=hardened steel.
**What's in this repo:** All 6 group rows with the canonical hex color codes used in vendor charts.
**Where to get the standard:** [ISO 513:2012](https://www.iso.org/standard/57892.html)

## Attribution and copyright

This repository contains structured representations of factual content from the above standards (codes, mnemonics, hierarchical relationships, classifications). Factual data is not copyrightable; what's copyrighted are the standard documents themselves, which are not reproduced here. For normative usage in any product or system, consult the original standards.

Translations and descriptive text in property tables are extracted from publicly distributed reference materials (notably the IEC 61360 Common Data Dictionary, the GTC package documentation, and Sandvik Coromant's published technical documentation). Where descriptive language is borrowed substantially, it has been paraphrased.

## Further reading

- **MTConnect Foundation** — [github.com/mtconnect](https://github.com/mtconnect) — adjacent ISO standard for machine-tool data interchange. Several MTConnect repositories also reference ISO 13399 property symbols.
- **EXPRESS / STEP Part 21** — the data format inside Sandvik's GTC package distribution (`*.p21` files). Not parsed by this repo, but worth knowing about if you want to extract per-tool property values.
