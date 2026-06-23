import { formatRole } from './utils.js';

/**
 * Replaces the #portal-header-user element with a circular avatar.
 * Shows profile photo if available, otherwise initials.
 * Clicking the avatar opens a dropdown with My Profile + Sign Out.
 *
 * @param {object} profile  - The member profile object
 * @param {Function} onSignOut - Called when Sign Out is clicked
 */
export function initPortalHeader(profile, onSignOut) {
  const container = document.getElementById('portal-header-user');
  if (!container) return;

  const name = profile.full_name || '';
  const initials = name
    .split(' ')
    .filter(Boolean)
    .map(w => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase() || '?';

  const roleLabel = formatRole(profile.role);

  container.innerHTML = `
    <button class="nav-avatar" id="nav-avatar"
            aria-label="User menu — ${name} (${roleLabel})"
            aria-haspopup="true" aria-expanded="false">
      <span class="nav-avatar-initials" id="nav-avatar-initials">${initials}</span>
    </button>
    <div class="nav-avatar-dropdown" id="nav-avatar-dropdown"
         role="menu" aria-hidden="true">
      <a href="/pages/members/profile.html" class="nav-avatar-item" role="menuitem">◎ My Profile</a>
      <button class="nav-avatar-item" id="nav-avatar-signout" role="menuitem">← Sign Out</button>
    </div>
  `;

  if (profile.profile_photo_url) {
    const initialsEl = document.getElementById('nav-avatar-initials');
    const img = document.createElement('img');
    img.src = profile.profile_photo_url;
    img.alt = '';
    img.onerror = () => img.remove();
    initialsEl.replaceWith(img);
  }

  const avatarBtn = document.getElementById('nav-avatar');
  const dropdown  = document.getElementById('nav-avatar-dropdown');

  function openDropdown() {
    dropdown.classList.add('open');
    avatarBtn.setAttribute('aria-expanded', 'true');
    dropdown.setAttribute('aria-hidden', 'false');
  }
  function closeDropdown() {
    dropdown.classList.remove('open');
    avatarBtn.setAttribute('aria-expanded', 'false');
    dropdown.setAttribute('aria-hidden', 'true');
  }
  function toggleDropdown() {
    dropdown.classList.contains('open') ? closeDropdown() : openDropdown();
  }

  avatarBtn.addEventListener('click', e => { e.stopPropagation(); toggleDropdown(); });
  avatarBtn.addEventListener('keydown', e => {
    if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggleDropdown(); }
    if (e.key === 'Escape') closeDropdown();
  });
  document.addEventListener('click', closeDropdown);

  document.getElementById('nav-avatar-signout').addEventListener('click', onSignOut);
}
