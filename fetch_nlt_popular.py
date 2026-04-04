#!/usr/bin/env python3
"""
Fetch the 500 most popular Bible verses from the NLT API and save as JSON.
"""

import json
import time
import urllib.request
import urllib.parse
import re
import os
import html

NLT_API_KEY = "c29ccc51-8ace-4a5f-a7c3-0fc7f14eb5bf"
NLT_BASE_URL = "https://api.nlt.to/api/passages"


def strip_html(text: str) -> str:
    """Strip HTML tags and decode entities, preserving verse numbers."""
    # Extract verse numbers from <span class="vn">N</span>
    text = re.sub(r'<span class="vn">(\d+)</span>', r'[\1] ', text)
    # Remove footnote markers and content
    text = re.sub(r'<a class="a-tn">\*</a><span class="tn">.*?</span>', '', text, flags=re.DOTALL)
    # Remove red letter spans but keep content
    text = re.sub(r'<span class="red">(.*?)</span>', r'\1', text, flags=re.DOTALL)
    # Remove all remaining HTML tags
    text = re.sub(r'<[^>]+>', ' ', text)
    # Decode HTML entities
    text = html.unescape(text)
    # Clean up whitespace
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def fetch_nlt_passage(reference: str) -> dict | None:
    """Fetch a single passage from the NLT API."""
    params = urllib.parse.urlencode({
        "ref": reference,
        "version": "NLT",
        "key": NLT_API_KEY,
    })
    url = f"{NLT_BASE_URL}?{params}"

    try:
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'ScriptureShare/1.0')
        with urllib.request.urlopen(req) as response:
            raw_html = response.read().decode()
            # Extract text from HTML response
            text = strip_html(raw_html)
            # Remove the header (e.g., "John 3:16, NLT")
            text = re.sub(r'^[A-Z0-9].*?,\s*NLT\s*', '', text)
            text = text.strip()
            if text:
                return {
                    "reference": reference,
                    "text": text,
                    "canonical": reference,
                }
            return None
    except Exception as e:
        print(f"  Error fetching {reference}: {e}")
        return None


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    popular_path = os.path.join(script_dir, "Shared", "Resources", "popular_verses.json")

    with open(popular_path) as f:
        references = json.load(f)

    print(f"Fetching {len(references)} popular verses from NLT API...")

    results = []
    for i, ref in enumerate(references, 1):
        print(f"  [{i}/{len(references)}] {ref}...", end=" ", flush=True)
        result = fetch_nlt_passage(ref)
        if result:
            results.append(result)
            print("OK")
        else:
            print("SKIP")

        # Rate limit: be conservative
        time.sleep(0.5)

    output_path = os.path.join(script_dir, "Shared", "Resources", "nlt_popular_cache.json")
    with open(output_path, "w") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"\nDone! {len(results)}/{len(references)} verses saved to {output_path}")


if __name__ == "__main__":
    main()
