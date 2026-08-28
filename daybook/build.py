#!/usr/bin/env python3
"""Assemble the standalone artifact page from the source files.

The published Artifact is wrapped in its own <!doctype>/<head>/<body>, so this
emits only body-level content with the CSS and JS inlined. Non-ASCII characters
in the scripts are escaped so the page renders identically regardless of the
charset the host declares.
"""
import re, pathlib

here = pathlib.Path(__file__).parent
read = lambda n: (here / n).read_text(encoding="utf-8")

def esc(js):
    out = []
    for ch in js:
        if ord(ch) < 128:
            out.append(ch)
        else:
            out.extend("\\u%04x" % c for c in
                       (ord(ch),) if ord(ch) <= 0xFFFF)
            if ord(ch) > 0xFFFF:
                v = ord(ch) - 0x10000
                out.append("\\u%04x\\u%04x" % (0xD800 + (v >> 10), 0xDC00 + (v & 0x3FF)))
    return "".join(out)

html = read("index.html")
body = re.search(r"<body>(.*)</body>", html, re.S).group(1)
body = re.sub(r'\s*<script src="[^"]+"></script>', "", body)

fonts = re.search(r'<link rel="stylesheet" href="https://fonts\.googleapis[^"]+">', html).group(0)

out = [
    "<title>Day Book</title>",
    '<link rel="preconnect" href="https://fonts.googleapis.com">',
    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>',
    fonts,
    "<style>\n" + read("styles.css") + "</style>",
    body.strip(),
    "<script>\n" + esc(read("observances.js")) + "</script>",
    "<script>\n" + esc(read("app.js")) + "</script>",
]
(here / "artifact.html").write_text("\n".join(out) + "\n", encoding="utf-8")
print("artifact.html", (here / "artifact.html").stat().st_size, "bytes")
