#!/usr/bin/env python3
"""
Parse file mappings from stdin.

Input format (one per line):
  source destination
  "path with space" destination
  'single quoted' "double quoted"

Output format (tab-separated):
  source\tdestination
"""

import sys
import shlex


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            parts = shlex.split(line)
            if len(parts) >= 2:
                print(f"{parts[0]}\t{parts[1]}")
        except ValueError as e:
            print(f"::error::Failed to parse line: {line}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
