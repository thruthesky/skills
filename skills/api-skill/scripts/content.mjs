#!/usr/bin/env node
// 콘텐츠 도구 — 정보 API(ph-travel-api 와 같은 형태)의 콘텐츠를 가공한 뒤, 배포하기 전에 쓴다.
// 규격은 ../references/pipeline.md. 외부 패키지 없음 (Node 22+).
//
//   node content.mjs stamp <meta.json>                 meta.json 의 data_version 을 지금 UTC 시각으로 쓴다 (가공·수정 커밋 직전)
//   node content.mjs check --dir <빌드 폴더>            배포 규격 검사 — 8개 언어·data_version·version 일치·모든 항목의 사진·credit·source
//   node content.mjs images --dir <빌드 폴더> [--ids 1,2] [--km 15] [--json]
//                                                      사진마다 Wikimedia Commons 정보(촬영 위치·라이선스·작가·설명)를 항목과 대조
//
// 모듈로도 쓴다 — r2.mjs 가 import 한다: checkBuild · REQUIRED_LANGS · DATA_VERSION_RE · utcNow
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

/** 배포에 반드시 있어야 하는 8개 언어. 하나라도 없으면 배포하지 않는다. */
export const REQUIRED_LANGS = ['ar', 'en', 'ja', 'ko', 'ru', 'th', 'vi', 'zh'];
/** data_version 형식 — 초까지의 UTC 시각(ISO 8601). 날짜로 시작해 글자 순서가 곧 시간 순서다. */
export const DATA_VERSION_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;
export const utcNow = () => new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

const isObject = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
const readJson = (file) => JSON.parse(readFileSync(file, 'utf8'));
const stripQuery = (url) => String(url).split('?')[0];

/** 노드를 끝까지 따라가며 type 이 image 인 노드를 모은다 (대표 사진·gallery·본문 안의 사진). */
function imageNodes(node, out = []) {
  if (Array.isArray(node)) for (const v of node) imageNodes(v, out);
  else if (isObject(node)) {
    if (node.type === 'image') out.push(node);
    for (const v of Object.values(node)) imageNodes(v, out);
  }
  return out;
}

/** manifest 에서 항목 파일 키를 찾는다 — 언어 코드 → 파일 이름 객체인 키(여행은 places, 밤문화라면 venues …). */
function itemsKeyOf(manifest) {
  const langs = manifest.languages ?? [];
  return Object.keys(manifest).find((k) => k !== 'meta' && isObject(manifest[k]) && langs.length > 0 && langs.every((l) => typeof manifest[k][l] === 'string'));
}

/**
 * 빌드 폴더(_site/v2 등)를 배포 규격으로 검사한다. 오류가 하나라도 있으면 배포하지 않는다.
 * 돌려주는 값: { errors, warnings, manifest, meta, itemsKey, items: { <lang>: 항목 배열 }, images: [사진 경로] }
 */
export function checkBuild(dir) {
  const errors = [];
  const warnings = [];
  const result = { errors, warnings, manifest: null, meta: null, itemsKey: null, items: {}, images: [] };
  if (!existsSync(join(dir, 'manifest.json'))) {
    errors.push(`manifest.json 이 없다 — ${dir} (먼저 node scripts/build.mjs)`);
    return result;
  }
  const manifest = (result.manifest = readJson(join(dir, 'manifest.json')));
  const langs = manifest.languages ?? [];
  const missing = REQUIRED_LANGS.filter((l) => !langs.includes(l));
  if (missing.length) errors.push(`8개 언어(${REQUIRED_LANGS.join('·')})가 모두 있어야 한다 — 빠진 언어: ${missing.join('·')}`);

  const itemsKey = (result.itemsKey = itemsKeyOf(manifest));
  if (!itemsKey) {
    errors.push('manifest 에 언어별 항목 파일 목록(places 등)이 없다');
    return result;
  }
  if (typeof manifest.meta !== 'string' || !existsSync(join(dir, manifest.meta))) {
    errors.push(`meta 파일이 없다 — ${manifest.meta}`);
    return result;
  }
  const meta = (result.meta = readJson(join(dir, manifest.meta)));
  if (!DATA_VERSION_RE.test(meta.data_version ?? '')) {
    errors.push(`meta.json 에 data_version(가공한 UTC 시각, 예 2026-10-01T05:12:33Z)이 없거나 형식이 틀리다 — 지금 값: ${meta.data_version ?? '없음'}. `
      + 'content.mjs stamp data/meta.json 으로 찍고 다시 빌드한다');
  } else if (Date.parse(meta.data_version) > Date.now() + 10 * 60 * 1000) {
    errors.push(`data_version 이 미래 시각이다 — ${meta.data_version}`);
  }
  if (meta.version !== manifest.version) errors.push(`meta.json 의 version(${meta.version})이 manifest(${manifest.version})와 다르다 — 원본 meta.json 에 version 키를 넣지 않는다`);

  const images = new Set();
  for (const lang of langs) {
    const name = manifest[itemsKey][lang];
    if (!existsSync(join(dir, name))) {
      errors.push(`${lang}: 항목 파일 없음 — ${name}`);
      continue;
    }
    const file = readJson(join(dir, name));
    const items = file[itemsKey];
    if (!Array.isArray(items)) {
      errors.push(`${name}: ${itemsKey} 배열이 없다`);
      continue;
    }
    result.items[lang] = items;
    if (file.version !== manifest.version) errors.push(`${name}: version(${file.version})이 manifest 와 다르다`);
    if (file.count !== items.length || file.count !== manifest.count) errors.push(`${name}: count 가 manifest·항목 수와 다르다`);
    for (const item of items) {
      const where = `${lang}/${String(item.id).padStart(3, '0')}-${item.slug}`;
      if (item.image?.type !== 'image' || !item.image.url) errors.push(`${where}: 대표 사진(image)이 없다 — 모든 항목에 정보와 맞는 사진이 있어야 한다`);
      if (lang === manifest.source_language && Array.isArray(item.gallery?.items) && item.gallery.items.length < 2) {
        warnings.push(`${where}: gallery 사진 ${item.gallery.items.length}장 — 새로 만드는 항목은 대표 1장 + gallery 2장을 채운다`);
      }
      for (const img of imageNodes(item)) {
        if (!/^images\/[a-z0-9-]+\.(webp|jpg|jpeg|png)$/.test(stripQuery(img.url ?? ''))) errors.push(`${where}: 사진 url 형식 오류 — ${img.url}`);
        if (!img.credit) errors.push(`${where}: 사진 credit(작가 / 라이선스 / 출처) 없음 — ${img.url}`);
        if (!/^https:\/\//.test(img.source ?? '')) errors.push(`${where}: 사진 source(원본 페이지 https 주소) 없음 — ${img.url}`);
        if (!img.alt) errors.push(`${where}: 사진 alt 없음 — ${img.url}`);
        images.add(stripQuery(img.url));
      }
    }
  }
  for (const url of images) if (!existsSync(join(dir, url))) errors.push(`사진 파일 없음 — ${url}`);
  result.images = [...images].sort();
  return result;
}

/** meta.json 의 data_version 을 지금 UTC 시각으로 쓴다. 파일의 다른 줄(한 줄로 쓴 짧은 객체 등)은 그대로 둔다. */
function stamp(file) {
  if (!file || !existsSync(file)) fail(`meta.json 경로를 준다 — node content.mjs stamp data/meta.json`);
  const text = readFileSync(file, 'utf8');
  JSON.parse(text); // 형식이 틀린 파일에는 쓰지 않는다
  const now = utcNow();
  const line = `"data_version": "${now}"`;
  const out = /"data_version"\s*:\s*"[^"]*"/.test(text)
    ? text.replace(/"data_version"\s*:\s*"[^"]*"/, line)
    : /^\{\s*\n([ \t]*)/.test(text)
      ? text.replace(/^\{\s*\n([ \t]*)/, (_, indent) => `{\n${indent}${line},\n${indent}`)
      : text.replace(/^\{/, `{${line},`);
  if (JSON.parse(out).data_version !== now) fail('data_version 을 쓰지 못했다 — 최상위에 다른 data_version 이 있는지 본다');
  writeFileSync(file, out);
  console.log(`data_version = ${now} — ${file}\n다음: node scripts/build.mjs 로 다시 빌드한다 (version 이 바뀐다)`);
}

function check(dir) {
  const r = checkBuild(dir);
  for (const w of r.warnings.slice(0, 30)) console.log(`(알림) ${w}`);
  if (r.warnings.length > 30) console.log(`(알림) … 외 ${r.warnings.length - 30}건`);
  if (r.errors.length) {
    console.error(`배포 규격 오류 ${r.errors.length}건 — 배포하지 않는다.\n${r.errors.slice(0, 100).map((e) => `  - ${e}`).join('\n')}`);
    process.exit(1);
  }
  const count = r.manifest.count;
  console.log(`통과 — ${r.itemsKey} ${count}건 × ${r.manifest.languages.length}개 언어(${r.manifest.languages.join('·')}) · 사진 ${r.images.length}장 · version ${r.manifest.version} · data_version ${r.meta.data_version}`);
}

// ───────────── 사진 검증 — Wikimedia Commons 정보와 대조 ─────────────

const COMMONS_API = 'https://commons.wikimedia.org/w/api.php';
const UA = 'api-skill-content/1.0 (https://github.com/thruthesky/skills; image check)';
const fileTitle = (source) => {
  const m = String(source ?? '').match(/commons\.wikimedia\.org\/wiki\/(File:[^?#]+)/);
  return m ? decodeURIComponent(m[1]).replace(/_/g, ' ') : null;
};
const plain = (html) => String(html ?? '').replace(/<[^>]+>/g, ' ').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#0?39;/g, "'").replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
const toRad = (d) => (d * Math.PI) / 180;
function km(lat1, lng1, lat2, lng2) {
  const a = Math.sin(toRad(lat2 - lat1) / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(toRad(lng2 - lng1) / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.sqrt(a));
}

/** 파일 제목 50개씩 Commons API 로 정보(촬영 위치·라이선스·작가·설명·분류)를 받는다. */
async function commonsInfo(titles) {
  const info = new Map();
  for (let i = 0; i < titles.length; i += 50) {
    const batch = titles.slice(i, i + 50);
    const params = new URLSearchParams({
      action: 'query', format: 'json', formatversion: '2', prop: 'imageinfo|coordinates', iiprop: 'extmetadata', colimit: 'max', coprimary: 'all',
      iiextmetadatafilter: 'LicenseShortName|Artist|GPSLatitude|GPSLongitude|ImageDescription|Categories|DateTimeOriginal', titles: batch.join('|'),
    });
    const res = await fetch(`${COMMONS_API}?${params}`, { headers: { 'user-agent': UA } });
    if (!res.ok) fail(`Commons API HTTP ${res.status}`);
    const data = await res.json();
    const back = new Map((data.query?.normalized ?? []).map((n) => [n.to, n.from]));
    for (const page of data.query?.pages ?? []) {
      const em = page.imageinfo?.[0]?.extmetadata ?? {};
      const co = page.coordinates?.[0];
      const lat = co?.lat ?? (em.GPSLatitude ? Number(em.GPSLatitude.value) : null);
      const lng = co?.lon ?? (em.GPSLongitude ? Number(em.GPSLongitude.value) : null);
      info.set(back.get(page.title) ?? page.title, {
        missing: Boolean(page.missing), lat: Number.isFinite(lat) ? lat : null, lng: Number.isFinite(lng) ? lng : null,
        license: plain(em.LicenseShortName?.value), artist: plain(em.Artist?.value), date: plain(em.DateTimeOriginal?.value).slice(0, 10),
        description: plain(em.ImageDescription?.value).slice(0, 120), categories: plain(em.Categories?.value).split('|').filter(Boolean).slice(0, 4),
      });
    }
    if (i + 50 < titles.length) await new Promise((r) => setTimeout(r, 300)); // Commons 에 부담을 주지 않는다
  }
  return info;
}

async function images(dir, opts) {
  const r = checkBuild(dir);
  if (!r.manifest || !r.itemsKey) fail(r.errors.join('\n'));
  const items = r.items[r.manifest.source_language] ?? Object.values(r.items)[0];
  if (!items) fail('항목 파일을 읽지 못했다');
  const ids = opts.ids ? new Set(String(opts.ids).split(',').map(Number)) : null;
  const limitKm = Number(opts.km ?? 15);
  const rows = [];
  for (const item of items) {
    if (ids && !ids.has(item.id)) continue;
    for (const img of imageNodes(item)) rows.push({ id: item.id, slug: item.slug, lat: item.latitude?.value, lng: item.longitude?.value, img, title: fileTitle(img.source) });
  }
  const info = await commonsInfo([...new Set(rows.map((x) => x.title).filter(Boolean))]);
  const report = rows.map(({ id, slug, lat, lng, img, title }) => {
    const c = title ? info.get(title) : null;
    const flags = [];
    let dist = null;
    if (!title) flags.push('commons 아님 — 출처 페이지를 직접 확인');
    else if (!c || c.missing) flags.push('commons 에 없는 파일');
    else {
      if (c.lat !== null && Number.isFinite(lat)) {
        dist = km(lat, lng, c.lat, c.lng);
        if (dist > limitKm) flags.push(`촬영 위치가 ${dist.toFixed(1)}km 떨어짐`);
      } else flags.push('위치 정보 없음 — 눈으로 확인');
      if (c.license && !String(img.credit).toLowerCase().includes(c.license.toLowerCase())) flags.push(`라이선스 불일치(Commons: ${c.license})`);
      const who = c.artist.split(/[,;(]/)[0].trim();
      if (who && who.length <= 40 && !String(img.credit).toLowerCase().includes(who.toLowerCase())) flags.push(`작가 확인(Commons: ${who})`);
    }
    // 판정: 고칠 것(없는 파일·라이선스) > 먼저 볼 것(먼 촬영 위치 — 넓은 섬·주는 정상일 수 있다) > 눈으로 볼 것(위치 없음·작가) > 맞음
    const level = flags.some((f) => /없는 파일|라이선스/.test(f)) ? '고칠 것' : flags.some((f) => /떨어짐/.test(f)) ? '먼저 볼 것' : flags.length ? '눈으로 볼 것' : '맞음';
    return { item: `${String(id).padStart(3, '0')}-${slug}`, file: stripQuery(img.url), level, km: dist === null ? null : Number(dist.toFixed(1)), flags, commons: c ?? null };
  });
  if (opts.json) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    for (const x of report) {
      console.log(`[${x.level}] ${x.item} ${x.file}${x.km === null ? '' : ` · ${x.km}km`}${x.flags.length ? ` · ${x.flags.join(' · ')}` : ''}`);
      if (x.flags.length && x.commons) console.log(`        설명: ${x.commons.description || '(없음)'} | 분류: ${x.commons.categories.join(', ') || '(없음)'}`);
    }
  }
  const n = (level) => report.filter((x) => x.level === level).length;
  console.error(`\n사진 ${report.length}장 — 고칠 것 ${n('고칠 것')} · 먼저 볼 것 ${n('먼저 볼 것')}(${limitKm}km 넘게 떨어져 찍음) · 눈으로 볼 것 ${n('눈으로 볼 것')} · 맞음 ${n('맞음')}`);
  if (n('고칠 것')) process.exit(1);
}

// ───────────── 명령 ─────────────

function fail(message) {
  console.error(message);
  process.exit(1);
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
  const dir = resolve(opts.dir ?? rest[0] ?? '_site/v2');
  if (command === 'stamp') stamp(rest[0] ?? opts.file);
  else if (command === 'check') check(dir);
  else if (command === 'images') await images(dir, opts);
  else {
    console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').slice(1, 9).map((l) => l.replace(/^\/\/ ?/, '')).join('\n'));
    if (command && command !== 'help') process.exit(1);
  }
}
