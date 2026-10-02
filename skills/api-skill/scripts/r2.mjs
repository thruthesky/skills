#!/usr/bin/env node
// Cloudflare R2 배포 — 정보 API 의 빌드 폴더(_site/v2 등)를 R2 버킷에 올려 웹·앱이 공개 주소에서 곧바로 받게 한다.
// 규격은 ../references/pipeline.md §7. 외부 패키지 없음 (Node 22+ — S3 호환 API 를 SigV4 로 직접 서명한다).
//
// 키 파일: ~/Documents/Keys/Cloudflare/r2/admin-permissions-all-r2.txt (R2_KEYS 로 바꿀 수 있다)
//   node r2.mjs check [--prefix ph-travel-api/v2/]                       키 파일·접속 확인 (읽기 전용)
//   node r2.mjs ls <prefix>                                              올라가 있는 파일
//   node r2.mjs deploy --dir _site/v2 --prefix ph-travel-api/v2/ [--dry-run] [--prune] [--allow-few-images]
//   node r2.mjs deploy --dir _site/v2 --country ph                       prefix 를 apis.json 의 r2_prefix 로
//   node r2.mjs verify --dir _site/v2 --prefix ph-travel-api/v2/          공개 주소로 받아 version·사진·CORS 확인
//   node r2.mjs cors [--set [--origins https://a,https://b] [--force]]    버킷 CORS 보기·설정 (키에 R2 관리 권한 필요)
//
// 모듈로도 쓴다: loadConfig · r2Request · listObjects · putObject · deleteObject · getCors · putCors
import { createHash, createHmac } from 'node:crypto';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, extname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkBuild } from './content.mjs';

const here = dirname(fileURLToPath(import.meta.url));
/** 키 파일 후보 — 앞의 것부터 있는 파일을 쓴다. 2026-10-01 에 r2/admin-permissions-all-r2.txt 로 옮겼다(R2 관리 권한). */
const KEY_FILES = [
  join(homedir(), 'Documents', 'Keys', 'Cloudflare', 'r2', 'admin-permissions-all-r2.txt'),
  join(homedir(), 'Documents', 'Keys', 'Cloudflare', 'files.withcenter.com', 'files.withcenter.com-r2.txt'),
];
export const DEFAULT_KEYS = KEY_FILES.find((f) => existsSync(f)) ?? KEY_FILES[0];
/** 공유 버킷이라 반드시 <이름>/v<숫자>/ 아래에만 올리고 지운다 — 버킷 뿌리나 다른 프로젝트 파일을 건드리지 않는다. */
const PREFIX_RE = /^[a-z0-9][a-z0-9-]*(\/[a-z0-9][a-z0-9-]*)*\/v\d+\/$/;

const fail = (message) => {
  console.error(message);
  process.exit(1);
};
const sha256 = (data) => createHash('sha256').update(data).digest('hex');
const md5 = (data) => createHash('md5').update(data).digest('hex');
const hmac = (key, data) => createHmac('sha256', key).update(data).digest();
/** RFC 3986 — S3 서명은 encodeURIComponent 가 남기는 !'()* 도 바꿔야 한다. */
const enc = (s) => encodeURIComponent(s).replace(/[!'()*]/g, (c) => `%${c.charCodeAt(0).toString(16).toUpperCase()}`);
const mask = (s) => (s ? `${s.slice(0, 4)}…(${s.length}자)` : '없음');

// ───────────── 설정 — 키 파일 ─────────────

/**
 * 키 파일을 읽는다. Cloudflare 대시보드가 보여 주는 그대로 「이름:」 줄 다음 줄에 값이 있는 형식이다.
 *   Custom Domain: → 공개 주소 도메인 · Buckets: → 버킷 · Access Key ID: · Secret Access Key: · …endpoints for S3 clients: → S3 주소
 * 값 줄 앞의 목록 기호(`- `·`* `)와 공개 도메인의 `https://`·끝 `/` 는 떼고 읽는다. 「이름:」으로 끝나지 않는 설명 줄은 건너뛴다.
 * 환경 변수(R2_ACCESS_KEY_ID · R2_SECRET_ACCESS_KEY · R2_ENDPOINT · R2_BUCKET · R2_PUBLIC_URL)가 있으면 그 값이 앞선다 (CI 용).
 * 값은 화면·로그에 찍지 않는다.
 */
export function loadConfig(file = process.env.R2_KEYS ?? DEFAULT_KEYS) {
  const found = {};
  if (existsSync(file)) {
    const lines = readFileSync(file, 'utf8').split(/\r?\n/).map((l) => l.trim());
    for (let i = 0; i < lines.length; i++) {
      if (!lines[i].endsWith(':')) continue;
      const label = lines[i].toLowerCase();
      const value = lines.slice(i + 1).find((l) => l !== '')?.replace(/^[-*•]\s*/, '').trim();
      if (!value || value.endsWith(':')) continue;
      if (label.startsWith('custom domain')) found.domain = value.replace(/^https?:\/\//, '').replace(/\/+$/, '');
      else if (label.startsWith('bucket')) found.bucket = value.split(/[,\s]+/)[0];
      else if (label.startsWith('access key id')) found.accessKeyId = value;
      else if (label.startsWith('secret access key')) found.secretAccessKey = value;
      else if (label.includes('endpoint')) found.endpoint = value;
    }
  }
  const env = process.env;
  const cfg = {
    file,
    accessKeyId: env.R2_ACCESS_KEY_ID ?? found.accessKeyId,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY ?? found.secretAccessKey,
    endpoint: (env.R2_ENDPOINT ?? found.endpoint ?? '').replace(/\/+$/, ''),
    bucket: env.R2_BUCKET ?? found.bucket,
    publicUrl: (env.R2_PUBLIC_URL ?? (found.domain ? `https://${found.domain}` : '')).replace(/\/+$/, ''),
  };
  const missing = ['accessKeyId', 'secretAccessKey', 'endpoint', 'bucket', 'publicUrl'].filter((k) => !cfg[k]);
  if (missing.length) fail(`R2 설정이 모자란다 — ${missing.join(', ')}. 키 파일: ${file}${existsSync(file) ? '' : ' (없음)'}`);
  if (!/^https:\/\/[a-z0-9.-]+$/i.test(cfg.endpoint)) fail(`S3 endpoint 형식 오류 — ${cfg.endpoint.replace(/\/\/[^.]+/, '//…')}`);
  if (!/^https:\/\/[a-z0-9.-]+$/i.test(cfg.publicUrl)) fail(`공개 주소 형식 오류 — ${cfg.publicUrl} (키 파일의 Custom Domain 다음 줄에 도메인만 적는다)`);
  return cfg;
}

// ───────────── S3 호환 요청 — SigV4 서명 ─────────────

/** R2 에 S3 요청을 보낸다. region 은 auto, service 는 s3, 주소는 path-style(/<버킷>/<키>)이다. */
export async function r2Request(cfg, method, key = '', { query = {}, body = null, headers = {} } = {}) {
  const url = new URL(cfg.endpoint);
  const path = `/${cfg.bucket}${key ? `/${key.split('/').map(enc).join('/')}` : ''}`;
  const amzDate = new Date().toISOString().replace(/[-:]|\.\d{3}/g, ''); // 20261001T051233Z
  const day = amzDate.slice(0, 8);
  const payloadHash = sha256(body ?? '');
  const qs = Object.keys(query).sort().map((k) => `${enc(k)}=${enc(String(query[k]))}`).join('&');
  const h = { host: url.host, 'x-amz-content-sha256': payloadHash, 'x-amz-date': amzDate };
  for (const [k, v] of Object.entries(headers)) h[k.toLowerCase()] = String(v).trim();
  const names = Object.keys(h).sort();
  const canonical = [method, path, qs, names.map((k) => `${k}:${h[k]}\n`).join(''), names.join(';'), payloadHash].join('\n');
  const scope = `${day}/auto/s3/aws4_request`;
  const toSign = ['AWS4-HMAC-SHA256', amzDate, scope, sha256(canonical)].join('\n');
  const signingKey = hmac(hmac(hmac(hmac(`AWS4${cfg.secretAccessKey}`, day), 'auto'), 's3'), 'aws4_request');
  const signature = createHmac('sha256', signingKey).update(toSign).digest('hex');
  const { host, ...send } = h; // host 는 fetch 가 주소에서 붙인다 — 서명한 값과 같다
  send.authorization = `AWS4-HMAC-SHA256 Credential=${cfg.accessKeyId}/${scope}, SignedHeaders=${names.join(';')}, Signature=${signature}`;
  for (let attempt = 1; ; attempt++) {
    const res = await fetch(`${url.origin}${path}${qs ? `?${qs}` : ''}`, { method, headers: send, body: body ?? undefined });
    if (res.ok || res.status < 500 || attempt === 3) {
      if (!res.ok) {
        const text = await res.text();
        const code = text.match(/<Code>([^<]+)<\/Code>/)?.[1] ?? '';
        throw new Error(`R2 ${method} ${key || '/'} → HTTP ${res.status} ${code}`);
      }
      return res;
    }
    await new Promise((r) => setTimeout(r, 500 * attempt)); // 5xx 는 잠깐 쉬고 다시
  }
}

const tag = (xml, name) => xml.match(new RegExp(`<${name}>([\\s\\S]*?)</${name}>`))?.[1] ?? '';
const unxml = (s) => s.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&');

/** prefix 아래의 파일 목록 — { key, size, etag(MD5) }. 1,000개씩 이어 받는다. */
export async function listObjects(cfg, prefix, { max = Infinity } = {}) {
  const out = [];
  let token = '';
  do {
    const query = { 'list-type': 2, prefix, 'max-keys': Math.min(1000, max) };
    if (token) query['continuation-token'] = token;
    const xml = await (await r2Request(cfg, 'GET', '', { query })).text();
    for (const [, c] of xml.matchAll(/<Contents>([\s\S]*?)<\/Contents>/g)) {
      out.push({ key: unxml(tag(c, 'Key')), size: Number(tag(c, 'Size')), etag: unxml(tag(c, 'ETag')).replace(/"/g, '') });
    }
    token = tag(xml, 'IsTruncated') === 'true' ? unxml(tag(xml, 'NextContinuationToken')) : '';
  } while (token && out.length < max);
  return out;
}

export const putObject = (cfg, key, body, headers) => r2Request(cfg, 'PUT', key, { body, headers });
export const deleteObject = (cfg, key) => r2Request(cfg, 'DELETE', key);

// ───────────── 배포 ─────────────

const TYPES = {
  '.json': 'application/json; charset=utf-8', '.webp': 'image/webp', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg',
  '.gif': 'image/gif', '.svg': 'image/svg+xml', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8', '.txt': 'text/plain; charset=utf-8', '.md': 'text/markdown; charset=utf-8',
  '.gz': 'application/gzip', '.db': 'application/vnd.sqlite3',
};
const IMAGE_EXT = new Set(['.webp', '.png', '.jpg', '.jpeg', '.gif', '.svg']);

/**
 * 캐시 방침 — JSON 은 주소가 그대로라 no-cache(받을 때마다 ETag 로 확인, 안 바뀌었으면 304).
 * 사진은 JSON 이 ?v=<해시> 를 붙여 가리키므로 바뀌면 주소가 바뀐다 → 1년 immutable.
 */
const cacheOf = (key) => (key.endsWith('.json') ? 'no-cache' : IMAGE_EXT.has(extname(key)) ? 'public, max-age=31536000, immutable' : 'public, max-age=3600');

function walkFiles(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    if (name.startsWith('.')) continue;
    const full = join(dir, name);
    if (statSync(full).isDirectory()) out.push(...walkFiles(full));
    else out.push(full);
  }
  return out;
}

async function pool(items, n, fn) {
  let i = 0;
  await Promise.all(Array.from({ length: Math.min(n, items.length) }, async () => {
    while (i < items.length) await fn(items[i++]);
  }));
}

function resolvePrefix(opts) {
  let prefix = opts.prefix;
  if (!prefix && opts.country) {
    const registry = JSON.parse(readFileSync(join(here, 'apis.json'), 'utf8'));
    prefix = registry.countries?.[opts.country]?.r2_prefix;
    if (!prefix) fail(`apis.json 의 ${opts.country} 에 r2_prefix 가 없다 — --prefix 로 준다`);
  }
  if (!prefix) fail('--prefix <이름>/v<schema>/ 또는 --country <나라> 를 준다 (예: --prefix ph-travel-api/v2/)');
  if (!prefix.endsWith('/')) prefix += '/';
  if (!PREFIX_RE.test(prefix)) fail(`prefix 형식 오류 — ${prefix}. <이름>/v<숫자>/ 형식만 된다 (공유 버킷이라 버킷 뿌리에는 올리지 않는다)`);
  return prefix;
}

/**
 * 올리는 순서가 곧 안전장치다. 클라이언트는 manifest.json 을 보고 나머지를 받으므로
 * 사진 → 언어별 항목 파일 → meta.json → manifest.json 순서로 올린다. 중간에 멈춰도 manifest 가 옛 것이라 옛 데이터를 그대로 받는다.
 * 지우기(--prune)는 manifest 를 바꾼 뒤에 한다 — 옛 manifest 를 받은 클라이언트가 아직 옛 사진을 가리킬 수 있어서다.
 */
async function deploy(dir, opts) {
  const prefix = resolvePrefix(opts);
  const gate = checkBuild(dir, { allowFewImages: Boolean(opts['allow-few-images']) });
  for (const w of gate.warnings.filter((x) => /미만/.test(x))) console.log(`(알림) ${w}`);
  if (gate.errors.length) fail(`배포 규격 오류 ${gate.errors.length}건 — 올리지 않는다.\n${gate.errors.slice(0, 50).map((e) => `  - ${e}`).join('\n')}`);
  const cfg = loadConfig(opts.keys);
  const { manifest, meta, itemsKey } = gate;

  const local = walkFiles(dir).map((full) => {
    const rel = relative(dir, full).split(sep).join('/');
    const body = readFileSync(full);
    return { rel, key: prefix + rel, body, md5: md5(body), size: body.length };
  });
  const remote = new Map((await listObjects(cfg, prefix)).map((o) => [o.key, o]));
  const changed = local.filter((f) => remote.get(f.key)?.etag !== f.md5);
  const itemFiles = new Set(Object.values(manifest[itemsKey]));
  const order = (f) => (f.rel === 'manifest.json' ? 3 : f.rel === manifest.meta ? 2 : itemFiles.has(f.rel) ? 1 : 0);
  const stages = [0, 1, 2, 3].map((s) => changed.filter((f) => order(f) === s));
  const keep = new Set(local.map((f) => f.key));
  const stale = [...remote.keys()].filter((k) => !keep.has(k));
  const mb = (n) => (n / 1048576).toFixed(1);

  console.log(`R2 ${cfg.bucket} → ${cfg.publicUrl}/${prefix}`);
  console.log(`version ${manifest.version} · data_version ${meta.data_version} · ${itemsKey} ${manifest.count}건 × ${manifest.languages.length}개 언어`);
  console.log(`올릴 것 ${changed.length}개 (${mb(changed.reduce((s, f) => s + f.size, 0))}MB) — 사진·기타 ${stages[0].length} · 항목 파일 ${stages[1].length} · meta ${stages[2].length} · manifest ${stages[3].length} | 그대로 ${local.length - changed.length}개`);
  console.log(`버킷에만 있는 것 ${stale.length}개${stale.length ? (opts.prune ? ' — 마지막에 지운다' : ' — 그대로 둔다 (--prune 이면 지운다)') : ''}`);
  if (opts['dry-run']) {
    for (const f of changed.slice(0, 20)) console.log(`  올림 ${f.rel}`);
    if (changed.length > 20) console.log(`  … 외 ${changed.length - 20}개`);
    for (const k of stale.slice(0, 20)) console.log(`  ${opts.prune ? '지움' : '남김'} ${k.slice(prefix.length)}`);
    console.log('(--dry-run — 아무것도 올리지 않았다)');
    return;
  }

  let done = 0;
  for (const [i, files] of stages.entries()) {
    await pool(files, i === 0 ? 8 : 4, async (f) => {
      await putObject(cfg, f.key, f.body, { 'content-type': TYPES[extname(f.rel)] ?? 'application/octet-stream', 'cache-control': cacheOf(f.rel) });
      if (++done % 50 === 0) console.log(`  … ${done}/${changed.length}`);
    });
  }
  console.log(`올림 ${done}개`);
  if (opts.prune && stale.length) {
    await pool(stale, 8, (k) => deleteObject(cfg, k));
    console.log(`지움 ${stale.length}개`);
  }
  await verify(dir, { ...opts, prefix }, cfg);
}

/** 공개 주소로 받아 본다 — manifest version, meta data_version, 항목 파일 크기, 모든 사진의 응답, CORS. */
async function verify(dir, opts, cfg = loadConfig(opts.keys)) {
  const prefix = resolvePrefix(opts);
  const base = `${cfg.publicUrl}/${prefix}`;
  const local = JSON.parse(readFileSync(join(dir, 'manifest.json'), 'utf8'));
  const problems = [];
  const res = await fetch(`${base}manifest.json?t=${Date.now()}`, { headers: { origin: 'https://example.com' } });
  if (!res.ok) fail(`공개 주소에서 manifest 를 받지 못했다 — HTTP ${res.status} ${base}manifest.json`);
  const remote = await res.json();
  if (remote.version !== local.version) problems.push(`manifest version 이 다르다 — 공개 ${remote.version} · 로컬 ${local.version}`);
  if (!/^application\/json/.test(res.headers.get('content-type') ?? '')) problems.push(`manifest content-type — ${res.headers.get('content-type')}`);
  const cors = res.headers.get('access-control-allow-origin');
  const meta = await (await fetch(`${base}${remote.meta}?t=${Date.now()}`)).json();
  if (meta.version !== local.version) problems.push(`meta version 이 다르다 — ${meta.version}`);
  const gate = checkBuild(dir, { allowFewImages: true });
  const files = [...Object.values(local[gate.itemsKey] ?? {}), ...gate.images];
  // ETag 는 R2 가 준 MD5 다. 압축해서 보내면 ETag 가 W/"…" 로 바뀌고 길이가 빠지므로 identity 로 묻고, W/ 와 따옴표를 떼고 비교한다.
  await pool(files, 16, async (rel) => {
    const r = await fetch(`${base}${rel}`, { method: 'HEAD', headers: { 'accept-encoding': 'identity' } });
    const etag = (r.headers.get('etag') ?? '').replace(/^W\//, '').replace(/"/g, '');
    if (!r.ok) problems.push(`${rel} → HTTP ${r.status}`);
    else if (etag !== md5(readFileSync(join(dir, rel)))) problems.push(`${rel} 내용이 다르다 — 공개 ETag ${etag || '없음'}`);
    else if (rel.endsWith('.json') ? !/^application\/json/.test(r.headers.get('content-type') ?? '') : !/^image\//.test(r.headers.get('content-type') ?? '')) {
      problems.push(`${rel} content-type — ${r.headers.get('content-type')}`);
    }
  });
  console.log(`공개 주소 ${base}manifest.json — version ${remote.version} · data_version ${meta.data_version} · 파일 ${files.length}개 확인`);
  if (!cors) console.log('(알림) Access-Control-Allow-Origin 이 없다 — 다른 도메인의 웹 브라우저는 JSON 을 못 받는다(앱·서버는 상관없다). 키에 R2 관리 권한이 있으면 node r2.mjs cors --set 으로 연다(버킷 전체 설정). 없으면 대시보드 R2 > 버킷 > Settings > CORS Policy');
  else console.log(`CORS — Access-Control-Allow-Origin: ${cors}`);
  if (problems.length) fail(`확인 실패 ${problems.length}건\n${problems.slice(0, 30).map((p) => `  - ${p}`).join('\n')}`);
  console.log('확인 끝 — 웹·앱이 이 주소에서 바로 받을 수 있다');
}

// ───────────── 버킷 CORS ─────────────

/** 버킷 CORS 규칙을 읽는다. 설정이 없으면 []. 키에 R2 관리(Admin Read) 권한이 있어야 한다. */
export async function getCors(cfg) {
  let xml;
  try {
    xml = await (await r2Request(cfg, 'GET', '', { query: { cors: '' } })).text();
  } catch (e) {
    if (/NoSuchCORSConfiguration/.test(e.message)) return [];
    if (/AccessDenied/.test(e.message)) throw new Error(`${e.message} — 버킷 CORS 를 읽고 바꾸려면 키에 R2 관리(Admin Read & Write) 권한이 있어야 한다`);
    throw e;
  }
  const all = (block, name) => [...block.matchAll(new RegExp(`<${name}>([\\s\\S]*?)</${name}>`, 'g'))].map((m) => unxml(m[1]));
  return [...xml.matchAll(/<CORSRule>([\s\S]*?)<\/CORSRule>/g)].map(([, r]) => ({
    origins: all(r, 'AllowedOrigin'), methods: all(r, 'AllowedMethod'), headers: all(r, 'AllowedHeader'),
    expose: all(r, 'ExposeHeader'), maxAge: Number(tag(r, 'MaxAgeSeconds') || 0),
  }));
}

/** 버킷 CORS 를 이 규칙 하나로 바꾼다(PutBucketCors 는 통째로 바꾼다). 키에 R2 관리(Admin Read & Write) 권한이 있어야 한다. */
export async function putCors(cfg, rule) {
  const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  const xml = `<?xml version="1.0" encoding="UTF-8"?><CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><CORSRule>${
    rule.origins.map((o) => `<AllowedOrigin>${esc(o)}</AllowedOrigin>`).join('')}${
    rule.methods.map((m) => `<AllowedMethod>${esc(m)}</AllowedMethod>`).join('')}${
    rule.headers.map((h) => `<AllowedHeader>${esc(h)}</AllowedHeader>`).join('')}${
    rule.expose.map((h) => `<ExposeHeader>${esc(h)}</ExposeHeader>`).join('')}<MaxAgeSeconds>${rule.maxAge}</MaxAgeSeconds></CORSRule></CORSConfiguration>`;
  const body = Buffer.from(xml);
  await r2Request(cfg, 'PUT', '', { query: { cors: '' }, body, headers: { 'content-type': 'application/xml', 'content-md5': createHash('md5').update(body).digest('base64') } });
}

const showRules = (rules) => (rules.length
  ? rules.map((r, i) => `  규칙 ${i + 1}: origin ${r.origins.join(', ')} · method ${r.methods.join(', ')} · header ${r.headers.join(', ') || '-'} · expose ${r.expose.join(', ') || '-'} · max-age ${r.maxAge}s`).join('\n')
  : '  (설정 없음 — 다른 도메인의 웹 브라우저는 받지 못한다)');

/**
 * 버킷 CORS 를 보거나(`cors`) 공개 데이터에 맞는 규칙으로 바꾼다(`cors --set [--origins a,b] [--force]`).
 * 공개 읽기 전용 데이터라 GET·HEAD 만 연다. 버킷 전체에 걸리는 설정이라, 이미 다른 규칙이 있으면 --force 없이는 바꾸지 않는다.
 */
async function cors(opts) {
  const cfg = loadConfig(opts.keys);
  const now = await getCors(cfg);
  console.log(`버킷 ${cfg.bucket} 의 CORS\n${showRules(now)}`);
  if (!opts.set) return;
  const want = {
    origins: typeof opts.origins === 'string' ? opts.origins.split(',').map((s) => s.trim()).filter(Boolean) : ['*'],
    methods: ['GET', 'HEAD'], headers: ['*'], expose: ['ETag'], maxAge: 86400,
  };
  const same = now.length === 1 && JSON.stringify(now[0]) === JSON.stringify(want);
  if (same) return console.log('이미 같은 규칙이다 — 바꾸지 않는다');
  if (now.length && !opts.force) fail('이미 다른 CORS 규칙이 있다 — 버킷 전체 설정이라 그대로 둔다. 바꾸려면 --force (기존 규칙은 사라진다)');
  await putCors(cfg, want);
  console.log(`바꿨다\n${showRules(await getCors(cfg))}`);
  console.log('공개 주소에 반영되기까지 몇 초~몇 분 걸릴 수 있다 — node r2.mjs verify 로 Access-Control-Allow-Origin 을 확인한다');
}

async function check(opts) {
  const cfg = loadConfig(opts.keys);
  console.log(`키 파일 ${cfg.file}`);
  console.log(`버킷 ${cfg.bucket} · 공개 주소 ${cfg.publicUrl} · endpoint ${cfg.endpoint.replace(/\/\/([^.]{4})[^.]*/, '//$1…')} · access key ${mask(cfg.accessKeyId)}`);
  const prefix = opts.prefix ? (opts.prefix.endsWith('/') ? opts.prefix : `${opts.prefix}/`) : '';
  const list = await listObjects(cfg, prefix, { max: 5 });
  console.log(`접속 됨 — ${prefix || '(버킷 뿌리)'} 아래 처음 ${list.length}개: ${list.map((o) => o.key).join(', ') || '(없음)'}`);
}

async function ls(prefix, opts) {
  if (!prefix) fail('prefix 를 준다 — node r2.mjs ls ph-travel-api/v2/');
  const list = await listObjects(loadConfig(opts.keys), prefix);
  for (const o of list) console.log(`${String(o.size).padStart(10)}  ${o.key}`);
  console.log(`${list.length}개 · ${(list.reduce((s, o) => s + o.size, 0) / 1048576).toFixed(1)}MB`);
}

function parseArgs(argv) {
  const opts = {};
  const rest = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const [k, v] = a.slice(2).split('=');
      if (v !== undefined) opts[k] = v;
      else if (argv[i + 1] && !argv[i + 1].startsWith('--')) opts[k] = argv[++i];
      else opts[k] = true;
    } else rest.push(a);
  }
  return { opts, rest };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [command, ...args] = process.argv.slice(2);
  const { opts, rest } = parseArgs(args);
  const dir = resolve(opts.dir ?? '_site/v2');
  try {
    if (command === 'check') await check(opts);
    else if (command === 'cors') await cors(opts);
    else if (command === 'ls') await ls(rest[0] ?? opts.prefix, opts);
    else if (command === 'deploy') await deploy(dir, opts);
    else if (command === 'verify') await verify(dir, opts);
    else {
      console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').slice(1, 12).map((l) => l.replace(/^\/\/ ?/, '')).join('\n'));
      if (command && command !== 'help') process.exit(1);
    }
  } catch (e) {
    fail(e.message);
  }
}
