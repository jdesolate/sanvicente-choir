export function formatRole(role) {
  if (!role) return '—';
  return role.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

export function formatDate(dateStr) {
  if (!dateStr) return '—';
  return new Date(dateStr).toLocaleDateString('en-PH', {
    year: 'numeric', month: 'short', day: 'numeric',
  });
}

export function escHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function showAlert(message, type = 'info') {}

export function clearAlerts() {}

export function hidePageLoader() {
  const loader = document.getElementById('page-loader');
  if (!loader) return;
  loader.classList.add('fade-out');
  setTimeout(() => loader.remove(), 320);
}


// ── Liturgical Season ────────────────────────────────────────────────────────

function computeEaster(y) {
  const a = y % 19, b = Math.floor(y / 100), c = y % 100;
  const d = Math.floor(b / 4), e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4), k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  const day = ((h + l - 7 * m + 114) % 31) + 1;
  return new Date(y, month - 1, day);
}

function firstSundayOfAdvent(y) {
  // Sunday on or before Dec 3 — ranges Nov 27–Dec 3
  const dec3 = new Date(y, 11, 3);
  return new Date(y, 11, 3 - dec3.getDay());
}

function baptismOfLord(y) {
  // First Sunday strictly after Jan 6; if Jan 6 is Sunday, result is Jan 13
  const jan6 = new Date(y, 0, 6);
  const dow = jan6.getDay();
  return new Date(y, 0, 6 + (dow === 0 ? 7 : 7 - dow));
}

const _SEASON_NAMES = {
  christmas:    'Christmas Season',
  ordinary_time:'Ordinary Time',
  lent:         'Lent',
  easter:       'Easter Season',
  advent:       'Advent',
};

function _computeSeason(date) {
  const MS = 86400000;
  const y = date.getFullYear();
  const t = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const add = (d, n) => new Date(d.getTime() + n * MS);
  const dt = t(date);

  const easter    = computeEaster(y);
  const ashWed    = add(easter, -46);
  const pentecost = add(easter, 49);
  const advent    = firstSundayOfAdvent(y);
  const christmas = new Date(y, 11, 25);
  const baptism   = baptismOfLord(y);

  if (dt <= t(baptism)) {
    return { season: 'Christmas Season', seasonKey: 'christmas', week: null, label: 'Christmas Season' };
  }
  if (dt < t(ashWed)) {
    const week = Math.floor((dt - t(baptism)) / (7 * MS)) + 1;
    return { season: 'Ordinary Time', seasonKey: 'ordinary_time', week, label: `Ordinary Time · Week ${week}` };
  }
  if (dt < t(easter)) {
    const week = Math.floor((dt - t(ashWed)) / (7 * MS)) + 1;
    return { season: 'Lent', seasonKey: 'lent', week, label: `Lent · Week ${week}` };
  }
  if (dt <= t(pentecost)) {
    const week = Math.floor((dt - t(easter)) / (7 * MS)) + 1;
    return { season: 'Easter Season', seasonKey: 'easter', week, label: `Easter Season · Week ${week}` };
  }
  if (dt < t(advent)) {
    const weeksInOTI = Math.floor((t(ashWed) - t(baptism)) / (7 * MS));
    const weeksSinceOTII = Math.floor((dt - t(pentecost)) / (7 * MS));
    const week = weeksInOTI + weeksSinceOTII + 1;
    return { season: 'Ordinary Time', seasonKey: 'ordinary_time', week, label: `Ordinary Time · Week ${week}` };
  }
  if (dt < t(christmas)) {
    const week = Math.floor((dt - t(advent)) / (7 * MS)) + 1;
    return { season: 'Advent', seasonKey: 'advent', week, label: `Advent · Week ${week}` };
  }
  return { season: 'Christmas Season', seasonKey: 'christmas', week: null, label: 'Christmas Season' };
}

// ── JSON-backed liturgical data ───────────────────────────────────────────────

const _litCache = {};

async function _fetchLit(year) {
  if (_litCache[year] !== undefined) return _litCache[year];
  try {
    const r = await fetch(`/assets/data/liturgical-${year}.json`);
    _litCache[year] = r.ok ? await r.json() : null;
  } catch (_) {
    _litCache[year] = null;
  }
  return _litCache[year];
}

export async function loadLiturgicalData(year) {
  return _fetchLit(year);
}

export async function getLiturgicalSeason(date = new Date()) {
  const data = await _fetchLit(date.getFullYear());
  if (data) {
    const ds = `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`;
    const e = data.find(x => x.date === ds);
    if (e) {
      const season = _SEASON_NAMES[e.season] || e.season;
      const label = e.week ? `${season} · Week ${e.week}` : season;
      return { season, seasonKey: e.season, week: e.week, label };
    }
  }
  return _computeSeason(date);
}


// ── Google Drive Image URL ───────────────────────────────────────────────────

export function gdriveImgUrl(url) {
  if (!url) return null;
  // Convert share/view URLs to direct-embed URL
  const m = url.match(/\/file\/d\/([-\w]+)/);
  if (m) return `https://drive.google.com/uc?export=view&id=${m[1]}`;
  const m2 = url.match(/[?&]id=([-\w]+)/);
  if (m2) return `https://drive.google.com/uc?export=view&id=${m2[1]}`;
  return url;
}


// ── Theme Toggle ─────────────────────────────────────────────────────────────

export function initThemeToggle() {
  const html = document.documentElement;
  const btn = document.getElementById('theme-toggle');
  if (!btn) return;

  function updateBtn() {
    const isLight = html.classList.contains('light');
    btn.textContent = isLight ? '☀' : '☾';
    btn.setAttribute('aria-label', isLight ? 'Switch to dark mode' : 'Switch to light mode');
  }

  updateBtn();

  btn.addEventListener('click', () => {
    const isLight = html.classList.contains('light');
    html.classList.toggle('light', !isLight);
    html.classList.toggle('dark', isLight);
    localStorage.setItem('svc-theme', isLight ? 'dark' : 'light');
    updateBtn();
  });
}
