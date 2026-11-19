'use strict';

const manifestUrl = '/dl/towork/latest.json';
const historyUrl = 'changelog.json';

function element(tag, className, content) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (content) node.textContent = content;
  return node;
}

function chevron() {
  const ns = 'http://www.w3.org/2000/svg';
  const icon = document.createElementNS(ns, 'svg');
  icon.setAttribute('class', 'icon');
  icon.setAttribute('aria-hidden', 'true');
  const use = document.createElementNS(ns, 'use');
  use.setAttribute('href', '#chevron');
  icon.append(use);
  return icon;
}

async function readJson(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);
  try {
    const response = await fetch(url, { cache: 'no-store', signal: controller.signal });
    return response.ok ? await response.json() : null;
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

function downloadUrl(value) {
  if (typeof value !== 'string' || !value.trim()) return null;
  try {
    const url = new URL(value, new URL(manifestUrl, location.href));
    if (url.protocol === 'https:' || (url.protocol === 'http:' && url.origin === location.origin)) return url.href;
  } catch {
    return null;
  }
  return null;
}

function setPlatform(name, url, status) {
  const platform = document.querySelector('[data-platform="' + name + '"]');
  platform.querySelector('[data-status]').textContent = status;
  const link = platform.querySelector('[data-link]');
  if (url) {
    link.href = url;
    link.hidden = false;
  }
}

function renderDownloads(manifest) {
  const full = manifest?.android?.full;
  const apk = downloadUrl(full?.url);
  const size = Number(full?.size);
  const sizeLabel = size > 0 ? ' / ' + Math.round(size / 1048576) + ' MiB' : '';
  setPlatform('android', apk, apk ? '基础包 ' + manifest.versionName + sizeLabel : '安装包信息暂不可用');
  const primary = document.querySelector('[data-primary-download]');
  if (apk) {
    primary.href = apk;
    if (/^[0-9a-f]{64}$/i.test(full.sha256 || '')) {
      document.querySelector('[data-hash]').textContent = full.sha256;
      document.querySelector('.hash').hidden = false;
    }
  }

  const mac = downloadUrl(manifest?.macos?.downloadUrl);
  const ios = downloadUrl(manifest?.ios?.storeUrl);
  if (mac) {
    const info = manifest.macos;
    const minOS = info.minimumSystemVersion ? 'macOS ' + info.minimumSystemVersion + '+' : '';
    const universal = info.architectures?.includes('arm64') && info.architectures.includes('x86_64');
    const chips = universal ? 'Apple 芯片与 Intel' : '';
    const signing = info.notarized === false ? '未经 Apple 公证' : '';
    const size = info.size > 0 ? Math.round(info.size / 1048576) + ' MiB' : '';
    setPlatform('macos', mac, [info.versionName, minOS, chips, size, signing].filter(Boolean).join(' / ') || 'DMG');
    const details = document.querySelector('[data-mac-info]');
    if (/^[0-9a-f]{64}$/i.test(info.sha256 || '')) {
      details.querySelector('[data-mac-hash]').textContent = 'SHA-256 ' + info.sha256;
      details.hidden = false;
    }
    if (signing) {
      const note = details.querySelector('[data-mac-signing]');
      note.textContent = '此版本使用本地签名。首次打开如被系统拦截，可在「系统设置 → 隐私与安全性」确认打开 ToWork。';
      note.hidden = false;
      details.hidden = false;
    }
    if (/Mac/.test(navigator.platform) && navigator.maxTouchPoints < 2) {
      primary.href = mac;
      primary.querySelector('span').textContent = '下载 Mac 版';
      document.querySelector('[data-primary-requirements]').textContent = [minOS, chips, signing].filter(Boolean).join(' / ');
    }
  }
  if (ios) setPlatform('ios', ios, 'App Store');
}

function releaseLabel(entry) {
  return entry.version + (entry.patch ? ' P' + entry.patch : '');
}

function releaseEntry(entry, latest) {
  const details = element('details', 'release-entry' + (latest ? ' latest' : ''));
  details.open = latest;
  const summary = element('summary');
  const label = element('span', 'release-title');
  label.append(element('strong', '', releaseLabel(entry)), element('span', '', entry.title));
  const date = element('time', '', entry.date);
  date.dateTime = entry.date;
  summary.append(label, date, chevron());
  const notes = element('ul', 'release-notes');
  for (const note of entry.notes) notes.append(element('li', '', note));
  details.append(summary, notes);
  return details;
}

function validRelease(entry) {
  return entry && Number.isSafeInteger(entry.build) && Number.isSafeInteger(entry.patch) &&
    entry.build > 0 && entry.patch >= 0 && typeof entry.version === 'string' && typeof entry.title === 'string' &&
    typeof entry.date === 'string' && Array.isArray(entry.notes) && entry.notes.every(note => typeof note === 'string');
}

function renderHistory(catalog, manifest) {
  const list = document.querySelector('#release-list');
  const entries = Array.isArray(catalog) ? catalog.filter(validRelease) : [];
  const base = manifest && manifest.releaseNotes;
  if (Array.isArray(base) && base.length && !entries.some(entry => entry.build === manifest.versionCode && entry.patch === 0)) {
    const entry = {
      build: manifest.versionCode, patch: 0, version: manifest.versionName, title: 'Android 基础包',
      date: String(manifest.publishedAt || '').slice(0, 10), notes: base
    };
    if (validRelease(entry)) entries.push(entry);
  }
  entries.sort((a, b) => b.build - a.build || b.patch - a.patch);
  if (!entries.length) {
    list.replaceChildren(element('p', 'muted', '版本日志暂不可用。'));
    return;
  }
  document.querySelector('[data-current]').textContent =
    (Array.isArray(catalog) && catalog.some(validRelease) ? '最新发布 ' : 'Android 基础包 ') + releaseLabel(entries[0]);
  list.replaceChildren(...entries.slice(0, 3).map((entry, i) => releaseEntry(entry, i === 0)));
  if (entries.length > 3) {
    const archive = element('details', 'archive');
    const toggle = element('summary');
    const text = element('span', '', '查看全部 ' + entries.length + ' 个版本');
    toggle.append(text, chevron());
    archive.append(toggle, ...entries.slice(3).map(entry => releaseEntry(entry, false)));
    archive.addEventListener('toggle', () => {
      text.textContent = archive.open ? '收起历史版本' : '查看全部 ' + entries.length + ' 个版本';
    });
    list.append(archive);
  }
}

const views = {
  home: ['assets/product/home.webp', 'ToWork 对话首页，底部可长按声波输入'],
  workspace: ['assets/product/workspace.webp', '侧栏中的 Note 会员标签和六个双字工作入口']
};
const viewSwitch = document.querySelector('.view-switch');
viewSwitch.hidden = false;
for (const button of viewSwitch.querySelectorAll('button')) {
  button.addEventListener('click', () => {
    const screen = document.querySelector('#hero-screen');
    [screen.src, screen.alt] = views[button.dataset.view];
    for (const control of viewSwitch.querySelectorAll('button')) control.setAttribute('aria-pressed', String(control === button));
  });
}

const preview = document.querySelector('#preview');
if (typeof preview.showModal === 'function') {
  for (const trigger of document.querySelectorAll('[data-preview]')) {
    trigger.addEventListener('click', event => {
      if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
      event.preventDefault();
      document.querySelector('#preview-title').textContent = trigger.dataset.preview;
      const image = document.querySelector('#preview-image');
      image.src = trigger.href;
      image.alt = trigger.querySelector('img').alt;
      preview.showModal();
    });
  }
  preview.querySelector('button').addEventListener('click', () => preview.close());
  preview.addEventListener('click', event => {
    const box = preview.getBoundingClientRect();
    if (event.target === preview && (event.clientX < box.left || event.clientX > box.right ||
      event.clientY < box.top || event.clientY > box.bottom)) preview.close();
  });
}

const manifestRequest = readJson(manifestUrl).then(value =>
  value?.schema === 1 && typeof value.versionName === 'string' ? value : null
);
manifestRequest.then(renderDownloads);
Promise.all([readJson(historyUrl), manifestRequest]).then(([catalog, manifest]) => renderHistory(catalog, manifest));
