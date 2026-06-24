import { supabase } from './supabase-client.js';

// ── CRUD helpers ──────────────────────────────────────────────────────────────

export async function createNotification(memberId, type, message) {
  if (!memberId) return;
  const { error } = await supabase.from('notifications').insert({ member_id: memberId, type, message });
  if (error) console.warn('createNotification:', error.message);
}

export async function createNotifications(memberIds, type, message) {
  if (!memberIds?.length) return;
  const rows = memberIds.map(id => ({ member_id: id, type, message }));
  const { error } = await supabase.from('notifications').insert(rows);
  if (error) console.warn('createNotifications:', error.message);
}

export async function getUnreadCount(memberId) {
  const { count, error } = await supabase
    .from('notifications')
    .select('id', { count: 'exact', head: true })
    .eq('member_id', memberId)
    .eq('is_read', false);
  if (error) return 0;
  return count ?? 0;
}

export async function getNotifications(memberId, limit = 20) {
  const { data, error } = await supabase
    .from('notifications')
    .select('id, type, message, is_read, created_at')
    .eq('member_id', memberId)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) return [];
  return data || [];
}

export async function markAllRead(memberId) {
  await supabase
    .from('notifications')
    .update({ is_read: true })
    .eq('member_id', memberId)
    .eq('is_read', false);
}

// ── Bell UI ───────────────────────────────────────────────────────────────────

const TYPE_META = {
  absence_approved: { icon: '✓', color: 'var(--success, #5cb85c)' },
  absence_rejected: { icon: '✕', color: 'var(--danger, #d9534f)' },
  fine_added:       { icon: '◈', color: 'var(--warning, #e0a030)' },
  fine_resolved:    { icon: '✓', color: 'var(--success, #5cb85c)' },
  songs_assigned:   { icon: '♪', color: 'var(--ivory-muted, #b0a898)' },
  award:            { icon: '★', color: 'var(--gold, #C9A86A)' },
};

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function timeAgo(dateStr) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1)  return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24)  return `${hrs}h ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

export async function initNotificationBell(memberId) {
  const container = document.getElementById('notification-bell-container');
  if (!container) return;

  container.innerHTML = `
    <div class="notif-wrap">
      <button class="notif-bell" id="notif-bell-btn"
              aria-label="Notifications" aria-haspopup="true" aria-expanded="false">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2"
             stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
          <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
        </svg>
        <span class="notif-badge" id="notif-badge" aria-live="polite" style="display:none"></span>
      </button>
      <div class="notif-dropdown" id="notif-dropdown"
           role="dialog" aria-label="Notifications" aria-hidden="true">
        <div class="notif-dropdown-header">Notifications</div>
        <div class="notif-list" id="notif-list">
          <div class="loading-text" style="padding:var(--space-4) var(--space-5)">
            <div class="spinner"></div>
          </div>
        </div>
      </div>
    </div>
  `;

  const bellBtn  = document.getElementById('notif-bell-btn');
  const badge    = document.getElementById('notif-badge');
  const dropdown = document.getElementById('notif-dropdown');
  const list     = document.getElementById('notif-list');

  async function refreshBadge() {
    const count = await getUnreadCount(memberId);
    if (count > 0) {
      badge.textContent  = count > 99 ? '99+' : String(count);
      badge.style.display = '';
    } else {
      badge.style.display = 'none';
    }
  }

  function renderList(items) {
    if (!items.length) {
      list.innerHTML = `<p class="notif-empty">No notifications yet.</p>`;
      return;
    }
    list.innerHTML = items.map(n => {
      const meta = TYPE_META[n.type] || { icon: '◉', color: 'var(--ivory-muted)' };
      return `
        <div class="notif-item${n.is_read ? '' : ' notif-item-unread'}">
          <span class="notif-icon" style="color:${meta.color}">${meta.icon}</span>
          <div class="notif-body">
            <p class="notif-msg">${esc(n.message)}</p>
            <span class="notif-time">${timeAgo(n.created_at)}</span>
          </div>
        </div>`;
    }).join('');
  }

  async function openDropdown() {
    dropdown.classList.add('open');
    bellBtn.setAttribute('aria-expanded', 'true');
    dropdown.setAttribute('aria-hidden', 'false');
    list.innerHTML = `<div class="loading-text" style="padding:var(--space-4) var(--space-5)">
      <div class="spinner"></div></div>`;

    const items = await getNotifications(memberId);
    renderList(items);

    // Mark read in background; clear badge immediately
    markAllRead(memberId);
    badge.style.display = 'none';
  }

  function closeDropdown() {
    dropdown.classList.remove('open');
    bellBtn.setAttribute('aria-expanded', 'false');
    dropdown.setAttribute('aria-hidden', 'true');
  }

  bellBtn.addEventListener('click', e => {
    e.stopPropagation();
    dropdown.classList.contains('open') ? closeDropdown() : openDropdown();
  });
  document.addEventListener('click', e => {
    if (!container.contains(e.target)) closeDropdown();
  });
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeDropdown();
  });

  await refreshBadge();
}
