// Local page for answering questions one at a time (preview skill, recipe 1).
// GET /            -> index.html
// GET /questions.json
// GET /state       -> { answers, replies }
// POST /answer     -> stores an answer and prints one line to stdout (the agent's signal)
import { createServer } from 'node:http';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const dir = dirname(fileURLToPath(import.meta.url));
const ANSWERS = join(dir, 'answers.json');
const REPLIES = join(dir, 'replies.json');
const PORT = Number(process.env.PORT || 4777);

const readJson = (p) => {
  try { return existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : {}; } catch { return {}; }
};

createServer((req, res) => {
  // The page is reopened with `?v=<timestamp>` to dodge the viewer's cache: route on the path alone.
  const path = new URL(req.url, 'http://localhost').pathname;
  if (req.method === 'GET' && (path === '/' || path === '/index.html')) {
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store' });
    return res.end(readFileSync(join(dir, 'index.html')));
  }
  if (req.method === 'GET' && path === '/questions.json') {
    res.writeHead(200, { 'content-type': 'application/json', 'cache-control': 'no-store' });
    return res.end(JSON.stringify(readJson(join(dir, 'questions.json'))));
  }
  if (req.method === 'GET' && path === '/state') {
    res.writeHead(200, { 'content-type': 'application/json', 'cache-control': 'no-store' });
    return res.end(JSON.stringify({ answers: readJson(ANSWERS), replies: readJson(REPLIES) }));
  }
  if (req.method === 'POST' && path === '/answer') {
    let body = '';
    req.on('data', (c) => { body += c; if (body.length > 1e5) req.destroy(); });
    req.on('end', () => {
      try {
        const { id, choice, note } = JSON.parse(body);
        if (!id) throw new Error('missing id');
        const answers = readJson(ANSWERS);
        answers[id] = { choice: choice ?? null, note: note ?? '', at: new Date().toISOString() };
        writeFileSync(ANSWERS, JSON.stringify(answers, null, 2));
        const flat = (s) => String(s ?? '').replace(/\s+/g, ' ').slice(0, 300);
        console.log(`ANSWER ${id} | choice: ${flat(choice) || '—'} | note: ${flat(note) || '—'}`);
        res.writeHead(200, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ ok: true, at: answers[id].at }));
      } catch (e) {
        res.writeHead(400, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ ok: false, error: e.message }));
      }
    });
    return;
  }
  res.writeHead(404); res.end();
}).listen(PORT, '127.0.0.1', () => console.log(`READY http://127.0.0.1:${PORT}`));
