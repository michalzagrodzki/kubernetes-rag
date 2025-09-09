#!/usr/bin/env python3
import os
import json
import urllib.request

def main() -> int:
    port = os.getenv("PORT", "8000")
    url = f"http://127.0.0.1:{port}/v1/models"
    try:
        with urllib.request.urlopen(url, timeout=3) as r:
            data = json.loads(r.read().decode("utf-8"))
            if isinstance(data, dict) and "data" in data:
                return 0
    except Exception:
        pass
    return 1

if __name__ == "__main__":
    raise SystemExit(main())

