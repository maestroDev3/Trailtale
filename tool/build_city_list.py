#!/usr/bin/env python3
"""Builds assets/places/cities.tsv.gz from GeoNames (CC BY 4.0).

Run by the GitHub workflow "Update city list" (geonames.org is not reachable
from Claude's environment). Output, one city per line, most populous first:

    name<TAB>country<TAB>country code<TAB>latitude<TAB>longitude<TAB>population<TAB>alternate names (|-separated)
"""
import gzip
import io
import os
import unicodedata
import urllib.request
import zipfile

BASE = "https://download.geonames.org/export/dump/"
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "places")
MAX_ALTERNATES = 12

# Exonyms in these languages are kept as alternate names (e.g. "Lissabon").
LANGUAGES = {"en", "de", "fr", "es", "it", "pt", "nl"}


def fetch(name: str) -> bytes:
    request = urllib.request.Request(
        BASE + name, headers={"User-Agent": "Trailtale city list builder (github.com/maestroDev3/Trailtale)"}
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read()


def fold(text: str) -> str:
    """Lower case without accents, to compare names."""
    decomposed = unicodedata.normalize("NFKD", text)
    return "".join(c for c in decomposed if not unicodedata.combining(c)).lower()


def is_latin_name(text: str) -> bool:
    if not 2 <= len(text) <= 40 or any(c.isdigit() for c in text):
        return False
    for c in text:
        if c in " -'’.":
            continue
        if not c.isalpha() or "LATIN" not in unicodedata.name(c, ""):
            return False
    return True


def main() -> None:
    countries = {}
    for line in fetch("countryInfo.txt").decode("utf-8").splitlines():
        if line.startswith("#") or not line.strip():
            continue
        fields = line.split("\t")
        countries[fields[0]] = fields[4]

    archive = zipfile.ZipFile(io.BytesIO(fetch("cities15000.zip")))
    cities = [
        line.split("\t")
        for line in archive.read("cities15000.txt").decode("utf-8").splitlines()
    ]
    ids = {f[0] for f in cities}

    # Language-tagged names; skip historic and colloquial ones and codes.
    names_by_city = {}
    alternates_zip = zipfile.ZipFile(io.BytesIO(fetch("alternateNamesV2.zip")))
    with alternates_zip.open("alternateNamesV2.txt") as raw:
        for raw_line in io.TextIOWrapper(raw, encoding="utf-8"):
            f = raw_line.rstrip("\n").split("\t")
            if len(f) < 8 or f[1] not in ids or f[2] not in LANGUAGES:
                continue
            if f[6] == "1" or f[7] == "1":
                continue
            names_by_city.setdefault(f[1], []).append(f[3])

    rows = []
    for f in cities:
        name, ascii_name = f[1], f[2]
        seen = {fold(name)}
        kept = []
        for alternate in [ascii_name, *names_by_city.get(f[0], [])]:
            alternate = alternate.strip()
            key = fold(alternate)
            if key in seen or not is_latin_name(alternate) or alternate.isupper():
                continue
            seen.add(key)
            kept.append(alternate)
            if len(kept) == MAX_ALTERNATES:
                break
        population = int(f[14] or 0)
        rows.append((
            population,
            "\t".join([
                name,
                countries.get(f[8], f[8]),
                f[8],
                f"{float(f[4]):.4f}",
                f"{float(f[5]):.4f}",
                str(population),
                "|".join(kept),
            ]),
        ))
    rows.sort(key=lambda row: (-row[0], row[1]))

    os.makedirs(OUT_DIR, exist_ok=True)
    text = "\n".join(row for _, row in rows) + "\n"
    with open(os.path.join(OUT_DIR, "cities.tsv.gz"), "wb") as out:
        with gzip.GzipFile(fileobj=out, mode="wb", mtime=0, filename="") as gz:
            gz.write(text.encode("utf-8"))
    print(f"{len(rows)} cities written")


if __name__ == "__main__":
    main()
