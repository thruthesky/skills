#!/usr/bin/env node
// 콘텐츠 도구 — 정보 API(ph-travel-api 와 같은 형태)의 콘텐츠를 가공한 뒤, 배포하기 전에 쓴다.
// 규격은 ../references/pipeline.md. 외부 패키지 없음 (Node 22+).
//
//   node content.mjs stamp <meta.json>                 meta.json 의 data_version 을 지금 UTC 시각으로 쓴다 (가공·수정 커밋 직전)
//   node content.mjs check --dir <빌드 폴더> [--allow-few-images]
//                                                      배포 규격 검사 — 8개 언어·data_version·version 일치·항목마다 사진 10장 이상·credit·source
//   node content.mjs images --dir <빌드 폴더> [--ids 1,2] [--km 15] [--json]
//                                                      사진마다 Wikimedia Commons 정보(촬영 위치·라이선스·작가·설명)를 항목과 대조
//   node content.mjs photos --dir <빌드 폴더> --id 30 [--km 3] [--limit 40] [--json]
//                                                      항목에 더할 사진 후보를 Commons 에서 찾는다 (분류·이름 검색·좌표 주변, 이미 쓴 사진은 뺀다)
//   node content.mjs fetch --title "File:….jpg" --out data/images/030-vigan-4.webp [--alt 비간]
//                                                      Commons 사진을 가로 1080px WebP 로 받고 image 노드(credit·source)를 출력한다
//
// 모듈로도 쓴다 — r2.mjs 가 import 한다: checkBuild · REQUIRED_LANGS · MIN_IMAGES · DATA_VERSION_RE · utcNow
import { execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

/** 배포에 반드시 있어야 하는 8개 언어. 하나라도 없으면 배포하지 않는다. */
export const REQUIRED_LANGS = ['ar', 'en', 'ja', 'ko', 'ru', 'th', 'vi', 'zh'];
/**
 * 항목마다 있어야 하는 사진 수 — 대표 사진 1장 + gallery 9장 이상.
 * 사진 3장으로는 그곳의 전경·명소·활동·계절을 다 보여 주지 못해서 2026-10-02 에 3장에서 10장으로 올렸다.
 */
export const MIN_IMAGES = 10;
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

/** 항목의 사진 — 대표 사진(image)과 gallery 의 사진. 본문 안의 사진은 세지 않는다. 같은 파일은 한 번만 센다. */
export function placePhotos(item) {
  const nodes = [item?.image, ...(Array.isArray(item?.gallery?.items) ? item.gallery.items : [])];
  const seen = new Set();
  return nodes.filter((n) => n?.type === 'image' && n.url && !seen.has(stripQuery(n.url)) && seen.add(stripQuery(n.url)));
}

/**
 * 빌드 폴더(_site/v2 등)를 배포 규격으로 검사한다. 오류가 하나라도 있으면 배포하지 않는다.
 *
 * 사진이 [MIN_IMAGES] 장보다 적은 항목은 오류다. 옛 항목의 사진을 채우는 중에 다른 고침을 내보내야 하면
 * `allowFewImages` 로 알림으로 낮춘다 — 그때도 모자란 항목 수는 알린다.
 * 돌려주는 값: { errors, warnings, manifest, meta, itemsKey, items: { <lang>: 항목 배열 }, images: [사진 경로], fewImages: [{ id, slug, count }] }
 */
export function checkBuild(dir, { minImages = MIN_IMAGES, allowFewImages = false } = {}) {
  const errors = [];
  const warnings = [];
  const result = { errors, warnings, manifest: null, meta: null, itemsKey: null, items: {}, images: [], fewImages: [] };
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
      if (lang === manifest.source_language) {
        const count = placePhotos(item).length;
        if (count < minImages) result.fewImages.push({ id: item.id, slug: item.slug, count });
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
  const few = result.fewImages;
  if (few.length) {
    const short = few.reduce((sum, x) => sum + (minImages - x.count), 0);
    const list = few.slice(0, 12).map((x) => `${String(x.id).padStart(3, '0')}-${x.slug}(${x.count}장)`).join(', ');
    const message = `사진 ${minImages}장(대표 1 + gallery ${minImages - 1}) 미만 ${few.length}곳 — 모자란 사진 ${short}장: ${list}${few.length > 12 ? ` … 외 ${few.length - 12}곳` : ''}. `
      + 'content.mjs photos --id <번호> 로 후보를 찾아 채운다 (pipeline.md §4)';
    if (allowFewImages) warnings.push(`${message} — --allow-few-images 로 이번만 통과`);
    else errors.push(`${message}. 옛 항목을 채우는 중에 다른 고침을 내보내야 하면 --allow-few-images`);
  }
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

function check(dir, opts) {
  const r = checkBuild(dir, { allowFewImages: Boolean(opts['allow-few-images']) });
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
  const r = checkBuild(dir, { allowFewImages: true });
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

// ───────────── 사진 모으기 — 후보 찾기·받기 ─────────────

/** 쓸 수 있는 라이선스 — CC BY·CC BY-SA·CC0·퍼블릭 도메인. NC·ND 와 「출처 불명」은 쓰지 않는다. */
const FREE_LICENSE = /^(cc[ -]by(-sa)?[ -][\d.]+|cc[ -]by(-sa)?$|cc0|public domain|pd\b|pdm)/i;

async function commonsQuery(params) {
  const res = await fetch(`${COMMONS_API}?${new URLSearchParams({ format: 'json', formatversion: '2', ...params })}`, { headers: { 'user-agent': UA } });
  if (!res.ok) fail(`Commons API HTTP ${res.status}`);
  return res.json();
}

/** 파일 제목 → 크기·형식·라이선스·작가·설명·촬영 위치 (50개씩). */
async function commonsFiles(titles) {
  const out = new Map();
  for (let i = 0; i < titles.length; i += 50) {
    const data = await commonsQuery({
      action: 'query', prop: 'imageinfo|coordinates', iiprop: 'size|mime|extmetadata', colimit: 'max', coprimary: 'all',
      iiextmetadatafilter: 'LicenseShortName|Artist|ImageDescription|GPSLatitude|GPSLongitude|DateTimeOriginal', titles: titles.slice(i, i + 50).join('|'),
    });
    for (const page of data.query?.pages ?? []) {
      const ii = page.imageinfo?.[0];
      if (!ii) continue;
      const em = ii.extmetadata ?? {};
      const co = page.coordinates?.[0];
      const lat = co?.lat ?? (em.GPSLatitude ? Number(em.GPSLatitude.value) : null);
      const lng = co?.lon ?? (em.GPSLongitude ? Number(em.GPSLongitude.value) : null);
      out.set(page.title, {
        title: page.title, width: ii.width, height: ii.height, mime: ii.mime,
        license: plain(em.LicenseShortName?.value), artist: plain(em.Artist?.value).split(/[,;(]/)[0].trim().slice(0, 60),
        description: plain(em.ImageDescription?.value).slice(0, 140), date: plain(em.DateTimeOriginal?.value).slice(0, 10),
        lat: Number.isFinite(lat) ? lat : null, lng: Number.isFinite(lng) ? lng : null,
      });
    }
    if (i + 50 < titles.length) await new Promise((r) => setTimeout(r, 300));
  }
  return out;
}

/**
 * 항목에 더할 사진 후보를 Commons 에서 찾는다 — 그곳 이름의 분류(Category:<영문 이름>), 이름 검색, 좌표 주변(--km).
 * 이미 쓴 사진·작은 사진(가로 1080px 미만)·쓸 수 없는 라이선스는 뺀다. 분류·이름에 걸린 사진이 앞이다.
 * 도구는 후보를 줄일 뿐이다 — 고른 사진은 fetch 로 받아 직접 열어 보고 §4.3 기준으로 판단한다.
 */
async function photos(dir, opts) {
  const r = checkBuild(dir, { allowFewImages: true });
  if (!r.manifest || !r.itemsKey) fail(r.errors.join('\n'));
  const items = r.items[r.manifest.source_language] ?? Object.values(r.items)[0];
  const item = items?.find((x) => String(x.id) === String(opts.id) || x.slug === opts.id);
  if (!item) fail(`항목을 찾지 못했다 — --id <번호|slug> (${opts.id ?? '없음'})`);
  const name = item.title_en?.text ?? item.slug;
  const lat = item.latitude?.value;
  const lng = item.longitude?.value;
  const radius = Math.min(10, Number(opts.km ?? 3));
  const limit = Number(opts.limit ?? 40);
  const used = new Set(placePhotos(item).map((n) => fileTitle(n.source)).filter(Boolean));
  const hits = new Map(); // 제목 → 걸린 곳 (분류·이름·좌표)
  const add = (title, how) => hits.set(title, new Set([...(hits.get(title) ?? []), how]));
  const SCORE = { 분류: 3, 이름: 2, 좌표: 1 };

  const category = await commonsQuery({ action: 'query', list: 'categorymembers', cmtitle: `Category:${name}`, cmtype: 'file', cmlimit: '200' });
  for (const m of category.query?.categorymembers ?? []) add(m.title, '분류');
  const search = await commonsQuery({ action: 'query', list: 'search', srnamespace: '6', srsearch: `"${name}"`, srlimit: '100' });
  for (const s of search.query?.search ?? []) add(s.title, '이름');
  if (Number.isFinite(lat) && Number.isFinite(lng)) {
    const near = await commonsQuery({ action: 'query', list: 'geosearch', gsnamespace: '6', gscoord: `${lat}|${lng}`, gsradius: String(radius * 1000), gslimit: '200' });
    for (const g of near.query?.geosearch ?? []) add(g.title, '좌표');
  }
  const info = await commonsFiles([...hits.keys()].filter((t) => !used.has(t)));
  const rows = [...info.values()]
    .filter((f) => /^image\/(jpeg|png|webp)$/.test(f.mime ?? '') && f.width >= 1080 && FREE_LICENSE.test(f.license))
    .map((f) => ({ ...f, how: [...(hits.get(f.title) ?? [])], score: [...(hits.get(f.title) ?? [])].reduce((sum, h) => sum + SCORE[h], 0), km: f.lat !== null && Number.isFinite(lat) ? Number(km(lat, lng, f.lat, f.lng).toFixed(1)) : null, source: `https://commons.wikimedia.org/wiki/${encodeURI(f.title.replace(/ /g, '_'))}` }))
    .sort((a, b) => b.score - a.score || (a.km ?? 99) - (b.km ?? 99) || b.width - a.width)
    .slice(0, limit);
  const have = placePhotos(item).length;
  if (opts.json) {
    console.log(JSON.stringify({ id: item.id, slug: item.slug, name, have, need: Math.max(0, MIN_IMAGES - have), candidates: rows }, null, 2));
    return;
  }
  console.log(`${String(item.id).padStart(3, '0')}-${item.slug} (${name}) — 지금 ${have}장, ${MIN_IMAGES}장까지 ${Math.max(0, MIN_IMAGES - have)}장 더. 후보 ${rows.length}개 (분류·이름·좌표 ${radius}km)`);
  for (const f of rows) {
    console.log(`- ${f.title} · ${f.width}×${f.height} · ${f.license} · ${f.artist || '작가 미상'}${f.km === null ? ' · 위치 없음' : ` · ${f.km}km`} · ${f.how.join('+')}`);
    if (f.description) console.log(`    ${f.description}`);
  }
  console.log('\n다음: 고른 사진을 fetch 로 받아 열어 본다 — 같은 장소인지(§4.3), 이미 있는 사진과 다른 모습(전경·명소·활동·계절)인지 확인한다.');
}

/** Commons 사진 한 장을 가로 1080px WebP 로 받아 저장하고, 데이터에 넣을 image 노드를 출력한다. 미리보기 JPEG 경로도 알린다. */
async function fetchPhoto(opts) {
  const title = String(opts.title ?? '').replace(/^(?!File:)/, 'File:').replace(/_/g, ' ');
  const out = opts.out;
  if (title === 'File:' || !out) fail('사용: node content.mjs fetch --title "File:….jpg" --out data/images/<id>-<slug>-<n>.webp [--alt 이름]');
  if (!/\/images\/[a-z0-9-]+\.webp$/.test(resolve(out))) fail(`--out 은 images/<소문자·숫자·-> .webp 이다 — ${out}`);
  if (existsSync(out) && !opts.force) fail(`이미 있다 — ${out} (바꾸려면 --force)`);
  const width = Number(opts.width ?? 1080);
  const data = await commonsQuery({ action: 'query', prop: 'imageinfo', iiprop: 'url|size|mime|extmetadata', iiurlwidth: String(width), iiextmetadatafilter: 'LicenseShortName|Artist', titles: title });
  const page = data.query?.pages?.[0];
  const ii = page?.imageinfo?.[0];
  if (!ii) fail(`Commons 에 없는 파일 — ${title}`);
  const license = plain(ii.extmetadata?.LicenseShortName?.value);
  if (!FREE_LICENSE.test(license)) fail(`쓸 수 없는 라이선스 — ${license || '없음'} (CC BY·CC BY-SA·CC0·퍼블릭 도메인만)`);
  if (ii.width < width) console.error(`(알림) 원본 가로 ${ii.width}px — ${width}px 보다 작다 (§4.3 품질 기준)`);
  const res = await fetch(ii.thumburl ?? ii.url, { headers: { 'user-agent': UA } });
  if (!res.ok) fail(`사진을 받지 못했다 — HTTP ${res.status}`);
  const tmp = mkdtempSync(join(tmpdir(), 'api-skill-photo-'));
  const original = join(tmp, `original${/png/.test(ii.mime) ? '.png' : '.jpg'}`);
  writeFileSync(original, Buffer.from(await res.arrayBuffer()));
  try {
    execFileSync('cwebp', ['-quiet', '-q', '80', '-resize', String(Math.min(width, ii.thumbwidth ?? width)), '0', original, '-o', out]);
  } catch {
    try {
      execFileSync('magick', [original, '-resize', `${width}x>`, '-quality', '80', `webp:${out}`]);
    } catch {
      fail('cwebp 도 magick 도 없다 — brew install webp');
    }
  }
  const artist = plain(ii.extmetadata?.Artist?.value).split(/[,;(]/)[0].trim() || '작가 미상';
  const node = {
    type: 'image',
    url: `images/${out.split('/').pop()}`,
    alt: opts.alt ?? '',
    credit: `${artist} / ${license} / Wikimedia Commons`,
    source: `https://commons.wikimedia.org/wiki/${encodeURI(page.title.replace(/ /g, '_'))}`,
  };
  console.log(JSON.stringify(node));
  console.error(`저장 ${out} — 미리보기(직접 열어 확인): ${original}`);
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
  else if (command === 'check') check(dir, opts);
  else if (command === 'images') await images(dir, opts);
  else if (command === 'photos') await photos(dir, opts);
  else if (command === 'fetch') await fetchPhoto(opts);
  else {
    console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').slice(1, 14).map((l) => l.replace(/^\/\/ ?/, '')).join('\n'));
    if (command && command !== 'help') process.exit(1);
  }
}
