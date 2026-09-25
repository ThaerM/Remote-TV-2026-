#!/usr/bin/env python3
"""Renders the public web pages from their Markdown sources.

    pip install markdown
    python3 tool/build_pages.py

docs/privacy-policy.md -> docs/privacy-policy.html
docs/support.md        -> docs/support.html

The .md files are the source of truth; never edit the .html by hand.
Publish both .html files at https://thaerm.github.io/remote-tv-2026/
(the addresses the app links to in lib/core/config/app_links.dart).
"""

from __future__ import annotations

import html
import re
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent.parent
PAGES = {
    "privacy-policy": "Privacy Policy — Remote TV 2026",
    "support": "Support — Remote TV 2026",
}

TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<meta name="description" content="{description}">
<style>
:root {{
  --bg: #f5f6f8; --surface: #ffffff; --text: #14161a; --muted: #5b6068;
  --border: #e0e2e7; --accent: #2f6fe0; --code: #f0f1f4;
}}
@media (prefers-color-scheme: dark) {{
  :root {{
    --bg: #0a0b0d; --surface: #16181c; --text: #f4f5f7; --muted: #a3a8b2;
    --border: #2a2d33; --accent: #4fd1ff; --code: #1f2227;
  }}
}}
* {{ box-sizing: border-box; }}
body {{
  margin: 0; background: var(--bg); color: var(--text);
  font: 16px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
    Helvetica, Arial, sans-serif;
}}
main {{
  max-width: 760px; margin: 0 auto; padding: 32px 16px 64px;
}}
article {{
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 14px; padding: 8px 24px 24px;
}}
h1 {{ font-size: 1.8rem; line-height: 1.25; }}
h2 {{ font-size: 1.25rem; margin-top: 2rem; }}
h3 {{ font-size: 1.05rem; margin-top: 1.5rem; }}
a {{ color: var(--accent); }}
code {{ background: var(--code); padding: 0 4px; border-radius: 4px; }}
table {{ border-collapse: collapse; width: 100%; display: block;
  overflow-x: auto; font-size: 0.95rem; }}
th, td {{ border: 1px solid var(--border); padding: 6px 10px;
  text-align: left; vertical-align: top; }}
th {{ background: var(--code); }}
hr {{ border: 0; border-top: 1px solid var(--border); margin: 2rem 0; }}
footer {{ color: var(--muted); font-size: 0.9rem; text-align: center;
  margin-top: 24px; }}
</style>
</head>
<body>
<main>
<article>
{body}
</article>
<footer>
<a href="support.html">Support</a> ·
<a href="privacy-policy.html">Privacy Policy</a> ·
<a href="https://thaerm.github.io/">thaerm.github.io</a>
</footer>
</main>
</body>
</html>
"""


def main() -> None:
    for name, title in PAGES.items():
        source = (ROOT / f"docs/{name}.md").read_text(encoding="utf-8")
        body = markdown.markdown(source, extensions=["tables", "sane_lists"])
        # Links between the pages point at their published .html names.
        body = re.sub(r'href="([a-z-]+)\.md"', r'href="\1.html"', body)
        first_paragraph = re.search(r"<p>(.*?)</p>", body, re.S)
        description = re.sub(r"<[^>]+>", "", first_paragraph.group(1)) if first_paragraph else title
        page = TEMPLATE.format(
            title=html.escape(title),
            description=html.escape(" ".join(description.split())[:160]),
            body=body,
        )
        out = ROOT / f"docs/{name}.html"
        out.write_text(page, encoding="utf-8")
        print(f"wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
