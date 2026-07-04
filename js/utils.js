import { supabase } from './supabase-client.js';

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

// Canonical mass parts in liturgical order — drives the ordered lineup and
// full-lyrics copy. Shared so the assign UI and library render never drift.
export const MASS_PARTS = [
  { value: 'entrance',            label: 'Entrance' },
  { value: 'kyrie',              label: 'Kyrie' },
  { value: 'gloria',             label: 'Gloria' },
  { value: 'responsorial_psalm', label: 'Responsorial Psalm' },
  { value: 'gospel_acclamation', label: 'Gospel Acclamation' },
  { value: 'offertory',          label: 'Offertory' },
  { value: 'sanctus',            label: 'Sanctus' },
  { value: 'mysterium_fidei',    label: 'Mysterium Fidei' },
  { value: 'great_amen',         label: 'Amen' },
  { value: 'our_father',         label: 'Amahan Namo' },
  { value: 'agnus_dei',          label: 'Agnus Dei' },
  { value: 'communion',          label: 'Communion' },
  { value: 'recessional',        label: 'Recessional' },
];

export function massPartLabel(value) {
  return MASS_PARTS.find(p => p.value === value)?.label || '';
}

// Sort index for a mass part; unknown/blank parts sort to the end.
export function massPartOrder(value) {
  const i = MASS_PARTS.findIndex(p => p.value === value);
  return i === -1 ? MASS_PARTS.length : i;
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

// Ordinary Time week number, computed the way the liturgical calendar does it:
// forward from the Baptism of the Lord before Lent, and backward from Christ the
// King (the 34th Sunday, the Sunday before Advent) after Pentecost — so the weeks
// skipped by Lent and Easter are accounted for.
function _ordinaryTimeWeek(date) {
  const MS = 86400000;
  const y = date.getFullYear();
  const t = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const add = (d, n) => new Date(d.getTime() + n * MS);

  // The Sunday on or before the date labels its week.
  const curSun = add(new Date(y, date.getMonth(), date.getDate()), -date.getDay());
  const ashWed = add(computeEaster(y), -46);

  if (t(curSun) < t(ashWed)) {
    // Before Lent: week containing the Baptism of the Lord is week 1.
    return Math.round((t(curSun) - t(baptismOfLord(y))) / (7 * MS)) + 1;
  }
  // After Pentecost: count back from Christ the King = week 34.
  const christKing = add(firstSundayOfAdvent(y), -7);
  return 34 - Math.round((t(christKing) - t(curSun)) / (7 * MS));
}

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
    const week = _ordinaryTimeWeek(date);
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
    const week = _ordinaryTimeWeek(date);
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
      // The JSON's week is unreliable for Ordinary Time after Pentecost, so
      // compute that ourselves; other seasons count simply and are trustworthy.
      const week = e.season === 'ordinary_time' ? _ordinaryTimeWeek(date) : e.week;
      const label = week ? `${season} · Week ${week}` : season;
      return { season, seasonKey: e.season, week, label };
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


// ── Finance proof uploads (private bucket) ───────────────────────────────────

const PROOF_BUCKET = 'finance-proofs';
const PROOF_MAX_BYTES = 5 * 1024 * 1024;
const PROOF_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

// Uploads an optional proof file for a finance record and returns its storage
// path. Throws with a user-facing message on validation or upload failure.
export async function uploadProof(folder, id, file) {
  if (file.size > PROOF_MAX_BYTES) throw new Error('Proof file must be under 5 MB.');
  if (!PROOF_TYPES.includes(file.type)) throw new Error('Proof must be a JPG, PNG, WebP, or PDF.');
  const ext = file.type === 'application/pdf' ? 'pdf' : (file.type.split('/')[1] || 'jpg').replace('jpeg', 'jpg');
  const path = `${folder}/${id}/proof-${Date.now()}.${ext}`;
  const { error } = await supabase.storage.from(PROOF_BUCKET).upload(path, file, { upsert: true });
  if (error) throw new Error(`Proof upload failed: ${error.message}`);
  return path;
}

// Opens a stored proof in a new tab via a short-lived signed URL.
export async function openProof(path) {
  const { data, error } = await supabase.storage.from(PROOF_BUCKET).createSignedUrl(path, 60);
  if (error) { alert(`Could not open proof: ${error.message}`); return; }
  window.open(data.signedUrl, '_blank', 'noopener');
}

// Removes a proof file when its record is deleted; failures are non-fatal.
export async function removeProof(path) {
  if (!path) return;
  try { await supabase.storage.from(PROOF_BUCKET).remove([path]); } catch (_) {}
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
