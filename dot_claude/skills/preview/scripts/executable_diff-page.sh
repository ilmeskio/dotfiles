#!/usr/bin/env bash
# Render a git diff as a responsive HTML page (preview skill, recipe 2):
# side by side on a wide window, one column on a narrow panel; light or dark
# following the system.
# Usage: diff-page.sh <out.html> "<title>" -- <git diff args>
set -euo pipefail
out=${1:?out.html}; title=${2:?title}; shift 2
[ "${1:-}" = "--" ] && shift
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git diff -M "$@" > "$tmp/changes.diff"
if [ ! -s "$tmp/changes.diff" ]; then echo "no changes for: git diff $*" >&2; exit 1; fi
for style in line side; do
  npx -y diff2html-cli@5 -i file -s "$style" -d word --cs auto --su hidden -t "$title" \
    -F "$tmp/$style.html" -- "$tmp/changes.diff" >/dev/null 2>&1
done
python3 - "$tmp/line.html" "$tmp/side.html" "$out" <<'PY'
import sys
line, side, out = open(sys.argv[1]).read(), open(sys.argv[2]).read(), sys.argv[3]

def inner(html):
    start = html.index('<div id="diff">') + len('<div id="diff">')
    end = html.rindex('</div>', 0, html.index('</body>'))
    return html[start:end]

css = """<meta name="viewport" content="width=device-width,initial-scale=1"><style>
:root{color-scheme:light dark}
body{margin:0;font-size:13px;background:#fff;color:#1f2328}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]) body{background:#0d1117;color:#e6edf3}}
:root[data-theme="dark"]{color-scheme:dark} :root[data-theme="light"]{color-scheme:light}
:root[data-theme="dark"] body{background:#0d1117;color:#e6edf3}
.theme{position:fixed;top:8px;right:8px;z-index:5;display:flex;gap:2px;font:12px -apple-system,system-ui,sans-serif}
.theme button{border:1px solid #8b949e66;background:transparent;color:inherit;padding:2px 8px;cursor:pointer}
.theme button:first-child{border-radius:10px 0 0 10px}.theme button:last-child{border-radius:0 10px 10px 0}
.theme button[aria-pressed="true"]{background:#8b949e44;font-weight:600}
h1{font-size:17px;margin:10px 8px;color:inherit}
.d2h-wrapper{padding:0 4px;text-align:left}
.d2h-file-header{position:sticky;top:0;z-index:2}
.d2h-code-line-ctn{white-space:pre-wrap!important;word-break:break-word;overflow-wrap:anywhere}
.d2h-diff-table{font-size:12.5px;line-height:1.45}
.d2h-file-name{white-space:normal;word-break:break-all}
/* narrow: one column, one line number */
.v-line .d2h-code-line{width:auto!important;padding-left:4.5em!important;padding-right:4px!important}
.v-line .d2h-code-linenumber{width:4em!important;font-size:10px}
.v-line .d2h-code-linenumber .line-num1{display:none}
.v-line .d2h-code-linenumber .line-num2{width:auto!important;float:none!important}
.v-line .d2h-file-diff{overflow-x:hidden!important}
/* wide: side by side */
.v-side{display:none}
.v-side .d2h-code-side-line{width:auto!important;padding-right:4px!important}
.v-side .d2h-files-diff{display:flex}.v-side .d2h-file-side-diff{flex:1 1 0;min-width:0;overflow-x:hidden!important}
@media (min-width:900px){.v-side{display:block}.v-line{display:none}}
</style>"""
both = f'<div id="diff"><div class="v-line">{inner(line)}</div><div class="v-side">{inner(side)}</div></div>'
start = line.index('<div id="diff">')
end = line.rindex('</div>', 0, line.index('</body>')) + len('</div>')
html = line[:start] + both + line[end:]
switch = '''<div class="theme" role="group" aria-label="Tema">
<button type="button" data-t="auto">Auto</button><button type="button" data-t="light">Chiaro</button><button type="button" data-t="dark">Scuro</button></div>
<script>
(function(){
  var KEY = 'diff-page-theme';
  function apply(t){
    var cls = {auto:'d2h-auto-color-scheme', light:'d2h-light-color-scheme', dark:'d2h-dark-color-scheme'}[t];
    if (t === 'auto') document.documentElement.removeAttribute('data-theme'); else document.documentElement.setAttribute('data-theme', t);
    document.querySelectorAll('.d2h-wrapper').forEach(function(w){
      w.classList.remove('d2h-auto-color-scheme','d2h-light-color-scheme','d2h-dark-color-scheme'); w.classList.add(cls); });
    document.querySelectorAll('.theme button').forEach(function(b){ b.setAttribute('aria-pressed', String(b.dataset.t === t)); });
    // the syntax-highlighting sheets are picked by a media query on the viewer's scheme: force the right one
    document.querySelectorAll('link[rel="stylesheet"][href*="highlight.js"]').forEach(function(l){
      if (!l.dataset.media) l.dataset.media = l.getAttribute('media') || '';
      var dark = /github-dark/.test(l.href);
      l.setAttribute('media', t === 'auto' ? l.dataset.media : ((t === 'dark') === dark ? 'all' : 'not all'));
    });
    try { localStorage.setItem(KEY, t); } catch (e) {}
  }
  var saved = 'auto'; try { saved = localStorage.getItem(KEY) || 'auto'; } catch (e) {}
  document.querySelector('.theme').addEventListener('click', function(e){ var b = e.target.closest('[data-t]'); if (b) apply(b.dataset.t); });
  apply(saved);
})();
</script>'''
html = html.replace("</head>", css + "</head>", 1)
html = html.replace("</body>", switch + "</body>", 1)
open(out, "w").write(html)
PY
echo "$out ($(grep -c '^diff --git' "$tmp/changes.diff") files)"
