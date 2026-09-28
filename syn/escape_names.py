#!/usr/bin/env python3
import sys, re

def clean_escaped_names(text: str) -> str:
    # Matches \followed_by_chars up to the trailing space/whitespace
    def replace(match):
        raw = match.group(1)
        # Convert special characters to underscores
        cleaned = re.sub(r'[\[\]\.\-]', '_', raw)
        # Collapse multiple underscores (e.g., ___ -> _)
        return re.sub(r'_+', '_', cleaned)

    return re.sub(r'\\([^\s]+)\s', replace, text)

for filepath in sys.argv[1:]:
    with open(filepath, 'r+', encoding='utf-8') as f:
        content = clean_escaped_names(f.read())
        f.seek(0)
        f.truncate()
        f.write(content)
    print(f"Cleaned: {filepath}")
