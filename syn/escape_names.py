#!/usr/bin/env python3
import sys, re

def clean_escaped_names(text: str) -> str:
    # Matches \followed_by_chars up to the trailing space/whitespace
    def replace(match):
        raw = match.group(1)
        # Convert special characters to underscores
        # (also the ones of parametrized modules, e.g. $paramod\FINE_DELAY\NDELS=s32'...)
        cleaned = re.sub(r'[^A-Za-z0-9_]', '_', raw)
        # Collapse multiple underscores (e.g., ___ -> _)
        cleaned = re.sub(r'_+', '_', cleaned)
        # Keep the whitespace, it may separate the name from the next identifier
        return cleaned + match.group(2)

    return re.sub(r'\\([^\s]+)(\s)', replace, text)

for filepath in sys.argv[1:]:
    with open(filepath, 'r+', encoding='utf-8') as f:
        content = clean_escaped_names(f.read())
        f.seek(0)
        f.truncate()
        f.write(content)
    print(f"Cleaned: {filepath}")
