#!/usr/bin/env python3
"""
Fetch the 500 most popular Bible verses from the ESV API and save as JSON.
This creates a bundled cache so the app doesn't need API calls for common verses.

Usage:
    python3 fetch_popular_verses.py

Output:
    Shared/Resources/esv_popular_cache.json
    Shared/Resources/nlt_popular_cache.json (when NLT key is available)
"""

import json
import time
import urllib.request
import urllib.parse
import sys
import os

ESV_API_KEY = "7bc9da317eef33cdab67d76f07b85f005db1216c"
ESV_BASE_URL = "https://api.esv.org/v3/passage/text/"

# NLT_API_KEY = None  # Set when available
# NLT_BASE_URL = "https://api.nlt.to/api/passages"

def fetch_esv_passage(reference: str) -> dict | None:
    """Fetch a single passage from the ESV API."""
    params = urllib.parse.urlencode({
        "q": reference,
        "include-passage-references": "false",
        "include-footnotes": "false",
        "include-headings": "false",
        "include-short-copyright": "false",
        "include-verse-numbers": "true",
        "include-first-verse-numbers": "true",
        "indent-paragraphs": "0",
        "indent-poetry": "false",
        "indent-declares": "0",
        "indent-psalm-doxology": "0",
    })
    url = f"{ESV_BASE_URL}?{params}"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Token {ESV_API_KEY}")

    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            if data.get("passages"):
                text = data["passages"][0].strip()
                # Parse verse numbers from bracketed format [1] text [2] text
                return {
                    "reference": reference,
                    "text": text,
                    "canonical": data.get("canonical", reference),
                }
            return None
    except Exception as e:
        print(f"  Error fetching {reference}: {e}")
        return None


def main():
    # Load popular verses list
    script_dir = os.path.dirname(os.path.abspath(__file__))
    popular_path = os.path.join(script_dir, "Shared", "Resources", "popular_verses.json")

    with open(popular_path) as f:
        references = json.load(f)

    print(f"Fetching {len(references)} popular verses from ESV API...")
    print(f"Rate limit: ~60/min, this will take ~{len(references) // 55 + 1} minutes\n")

    results = []
    for i, ref in enumerate(references, 1):
        print(f"  [{i}/{len(references)}] {ref}...", end=" ", flush=True)
        result = fetch_esv_passage(ref)
        if result:
            results.append(result)
            print("OK")
        else:
            print("SKIP")

        # Rate limit: 60 requests per minute
        if i % 55 == 0:
            print("  (pausing 60s for rate limit...)")
            time.sleep(60)
        else:
            time.sleep(0.3)  # Small delay between requests

    # Save results
    output_path = os.path.join(script_dir, "Shared", "Resources", "esv_popular_cache.json")
    with open(output_path, "w") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"\nDone! {len(results)}/{len(references)} verses saved to {output_path}")


if __name__ == "__main__":
    main()
