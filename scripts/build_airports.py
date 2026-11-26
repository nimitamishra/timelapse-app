#!/usr/bin/env python3
"""Build Layover's bundled airport list from the OurAirports dataset.

OurAirports (https://ourairports.com/data/) is public domain. Its
airports.csv lists ~85,000 airfields, heliports and seaplane bases; the app
only needs large commercial airports, so this keeps rows that are:
  - type "large_airport"
  - marked as having scheduled passenger service
  - have a 3-letter IATA code (the "SFO" people know)

Usage (download the CSV first):
  curl -L -o airports.csv https://davidmegginson.github.io/ourairports-data/airports.csv
  python3 scripts/build_airports.py airports.csv Layover/Resources/airports.json
"""

import csv
import json
import sys


def main(csv_path: str, out_path: str) -> None:
    airports = []
    with open(csv_path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            iata = row["iata_code"].strip().upper()
            if (
                row["type"] != "large_airport"
                or row["scheduled_service"] != "yes"
                or len(iata) != 3
                or not iata.isalpha()
            ):
                continue
            airports.append(
                {
                    "iata": iata,
                    "name": row["name"].strip(),
                    "city": row["municipality"].strip() or row["name"].strip(),
                    "country": row["iso_country"].strip(),
                    # 4 decimals ≈ 11 m — plenty for a route map, keeps the file small
                    "lat": round(float(row["latitude_deg"]), 4),
                    "lon": round(float(row["longitude_deg"]), 4),
                }
            )

    # A code should appear once; if the source ever duplicates one, keep the first.
    seen = set()
    unique = []
    for a in sorted(airports, key=lambda a: a["iata"]):
        if a["iata"] not in seen:
            seen.add(a["iata"])
            unique.append(a)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(unique, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")

    print(f"Wrote {len(unique)} airports to {out_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: build_airports.py <airports.csv> <out.json>")
    main(sys.argv[1], sys.argv[2])
