# San Vicente Choir — Claude Project Knowledge File

> This file is the single source of truth for the SVC choir portal project.
> Upload this to your Claude project so any conversation starts with full context.
> Last updated: 2026-06-16

---

## 1. About the Organization

**San Vicente Choir** is a 54-year-old liturgical choir ministry based in the Philippines, serving at San Vicente Parish. The choir sings at weekly masses, feast days, and solemnities.

**Facebook Page:** https://www.facebook.com/share/1c9an5AWnS/

### Officer Roster 2026–2027

| Position | Name | Facebook |
|---|---|---|
| President | Mervin John Tampus (MJ) | https://www.facebook.com/tampus.mervin/ |
| Vice President & Internal Coordinator | Aravila Dionson | https://www.facebook.com/aravila.dionson |
| Choir Adviser | Jan Dacillo | https://www.facebook.com/fordyyyyyy |
| Music Director & Liturgical Lead | Vince Raymund Rojas | https://www.facebook.com/Porkandbinz |
| External Coordinator | Gabriella Amor Lopez | https://www.facebook.com/Gabriellalopez006 |
| Secretary | Gezd Seloterio | https://www.facebook.com/gezd.seloterio |
| Treasurer | Mary Love Lopez | https://www.facebook.com/lopez.marylove |

**The user (MJ) is the President and the developer of this portal.** He manages all code, design decisions, and feature planning. He communicates casually; treat him as a senior developer who knows the codebase well.

---

## 2. Project Overview

A full-featured choir management web portal built on top of a static public website.

| Layer | Technology |
|---|---|
| Frontend | Vanilla HTML5, CSS3, JavaScript (ES6+) — no frameworks |
| Auth / Database | Supabase (free tier) |
| File storage | Google Drive links (no file uploads to Supabase) |
| Form handling | Netlify Forms (sponsor contact form only) |
| Markdown rendering | marked.js (CDN) |
| Fonts | Google Fonts: Cinzel, Cormorant Garamond, Inter |
| Hosting | Netlify |
| Shared CSS | `css/design-system.css` — dark luxury palette, design tokens, WCAG AA compliant |

**Design system rules (apply to every page under `pages/`):**
- `<html lang="en" class="dark">` — required to prevent OS light-mode flash before JS loads
- First stylesheet: `<link rel="stylesheet" href="/css/design-system.css">`
- Use only CSS variables from `design-system.css` — never hardcode colors, spacing, or typography
- Component classes: `.btn`, `.btn-gold`, `.badge-*`, `.alert-*`, `.data-table`, `.table-wrap`, `.portal-header`, `.portal-sidebar`, `.portal-main`, `.modal`, `.stat-card`
- Add `.skip-link` as the first `<body>` element pointing to `<main id="main-content">`
- All interactive elements: 44px minimum touch target (`--touch-min`)
- Never override `:focus-visible` — gold focus ring is handled by the design system

---

## 3. Repository Structure

```
sanvicente-choir/
├── assets/
│   └── images/
│       ├── gallery/          # Gallery and performance images
│       └── officers/         # Officer profile photos and SVC_Logo.png
├── css/
│   └── design-system.css     # Shared design tokens + component classes
├── docs/                     # Official choir documents (Markdown)
│   ├── constitution.md
│   ├── handbook.md
│   ├── calendar.md
│   ├── budget.md
│   ├── commitments.md
│   └── tbd-summary.md
├── js/
│   ├── supabase-client.js    # Supabase initialization
│   ├── auth.js               # Auth utilities and role guards
│   └── utils.js              # Shared helpers (dates, liturgical season, theme toggle)
├── pages/
│   ├── login.html
│   ├── register.html
│   ├── forgot-password.html
│   ├── reset-password.html
│   ├── members/
│   │   ├── dashboard.html
│   │   ├── attendance.html
│   │   ├── songs.html
│   │   └── profile.html
│   ├── secretary/
│   │   ├── tracker.html
│   │   └── absences.html
│   └── admin/
│       ├── members.html
│       ├── attendance-summary.html
│       ├── events.html
│       ├── songs.html
│       ├── fields.html
│       └── leadership-plan.html
├── supabase/
│   └── schema.sql
├── index.html                # Public landing page
├── documents.html            # Documents hub (role-gated)
├── netlify.toml
├── PRD.md                    # Full product requirements
└── SESSIONS.md               # Build session log
```

---

## 4. User Roles & Access Control

**Role hierarchy (lowest → highest):** `member` < `secretary` < `admin` < `super_admin`

| Role | Description |
|---|---|
| `member` | Approved choir member |
| `secretary` | Member + attendance management access |
| `admin` | Full access — officers / webmaster |
| `super_admin` | President account only — all admin + permanent member deletion |

**Member statuses:** `pending` → `active` / `associate` / `honorary` / `inactive`

- `pending`: awaiting admin approval after self-registration
- `active`: full choir member
- `associate`: participating but not full member
- `honorary`: honorary membership
- `inactive`: soft-removed — data retained, portal access blocked, reversible

**Auth guard rule:** `requireAuth()` and `requireRole()` both check for `inactive` status and redirect to `login.html?inactive=1` if triggered.

**Sidebar role-gating rule:** Member pages include hidden `#secretary-section` and `#admin-section` nav divs revealed by JS after profile load. Admin pages always show both sections statically.

---

## 5. Access Control Matrix

| Feature | public | member | secretary | admin | super_admin |
|---|:---:|:---:|:---:|:---:|:---:|
| Landing page | ✓ | ✓ | ✓ | ✓ | ✓ |
| Constitution & By-Laws | ✓ | ✓ | ✓ | ✓ | ✓ |
| Member Handbook | | ✓ | ✓ | ✓ | ✓ |
| Calendar 2026–2027 | | ✓ | ✓ | ✓ | ✓ |
| Commitments 2026–2027 | | ✓ | ✓ | ✓ | ✓ |
| Budget Plan | | | | ✓ | ✓ |
| TBD Summary | | | | ✓ | ✓ |
| Dashboard | | ✓ | ✓ | ✓ | ✓ |
| Song Library (search + filter) | | ✓ | ✓ | ✓ | ✓ |
| My Attendance (own record) | | ✓ | ✓ | ✓ | ✓ |
| Submit Absence Request | | ✓ | ✓ | ✓ | ✓ |
| My Profile (read-only) | | ✓ | ✓ | ✓ | ✓ |
| Attendance Tracker (live marking) | | | ✓ | ✓ | ✓ |
| Approve/Reject Absence Request | | | ✓ | ✓ | ✓ |
| Attendance Summary (leaderboard) | | | ✓ | ✓ | ✓ |
| Member Management (list/approve/edit) | | | | ✓ | ✓ |
| View Full Member Profile | | | | ✓ | ✓ |
| Event Management | | | | ✓ | ✓ |
| Song Management (add/edit/delete) | | | | ✓ | ✓ |
| Custom Field Management | | | | ✓ | ✓ |
| Permanently Delete Member | | | | | ✓ |

---

## 6. Current Features (Live as of 2026-06-16)

### Public Pages
- **Landing page** (`index.html`) — choir story, gallery, officers, Join Us CTA → Facebook, Sponsor section with Netlify contact form (3 tiers: Supporter ₱500, Partner ₱1,000, Patron ₱2,000+)
- **Documents hub** (`documents.html`) — role-gated; shows/hides documents based on auth state
- **Login / Register / Forgot Password / Reset Password**

### Registration Flow
1. Visitor opens `pages/register.html`
2. Full-screen ToS modal shows Constitution + Member Handbook (via `marked.js`) — must check acknowledgement box before proceeding
3. Registration form: full name, email, password, contact number (required), birthday (required), school/occupation (optional), voice part (required), profile photo URL (optional, Google Drive link), plus any admin-defined custom fields
4. Age is **never collected** — always auto-calculated from birthday
5. Account created in Supabase Auth; profile row inserted with `status: pending`, `role: member`, `tos_accepted_at` timestamp
6. Admin approves → member gains full access

### Member Portal
- **Dashboard** — welcome greeting, liturgical season badge (e.g., "Ordinary Time · Week 12"), quick stat cards (voice part, status, role), pending approval banner if applicable, light/dark mode toggle
- **My Attendance** — own attendance history table, per-tier rates (Core / Major / Special), On Track (≥80%) / At Risk (<80%) status badge, ability to submit advance or retroactive absence requests
- **Song Library** — full-text search (title + lyrics), filter by language / liturgical use / season, auto pre-filters to current liturgical season on load, expandable song cards with full lyrics + Google Drive PDF link + YouTube link
- **My Profile** — read-only display of all profile fields (name, email, voice part, role, status, contact, birthday/age, school/occupation, joined date, approved date, custom fields); profile photo shown as circular avatar if set

### Secretary Portal (inherits all member features)
- **Attendance Tracker** (`pages/secretary/tracker.html`) — select event from dropdown → live table of all active + associate members → mark each Present / Absent / Excused → real-time summary counts → save to database; editable after save
- **Absence Requests** (`pages/secretary/absences.html`) — Pending tab (approve / reject with optional note) + History tab (approved/rejected log)
- **Attendance Summary** (read access, same leaderboard as admin)

### Admin Portal (inherits all member + secretary features)
- **Member Management** (`pages/admin/members.html`) — pending registrations queue (approve/reject), all members table (search, view, edit role/status, soft-remove), Create Account button for members who can't self-register, View Profile modal (full read-only record), Delete Member (super_admin only — hard delete)
- **Event Management** (`pages/admin/events.html`) — add/edit/delete events (title, date, type: Core/Major/Special, description)
- **Song Management** (`pages/admin/songs.html`) — add/edit/delete songs with all metadata (title, lyrics, language tags, liturgical use tags, season tags, PDF link, YouTube link)
- **Custom Field Management** (`pages/admin/fields.html`) — add/edit/delete/reorder fields (types: text, number, date, dropdown); date-type fields show years-of-service counter in admin view
- **Attendance Summary** (`pages/admin/attendance-summary.html`) — aggregate leaderboard ranked by attendance rate, sortable columns, color-coded progress bars (green ≥80%, gold 50–79%, red <50%), filters by voice part / event type / name search, top stat cards

### Super Admin (inherits everything above)
- Permanent (hard) deletion of member accounts — removes auth user + all associated data (profile, attendance, absence requests)

---

## 7. Database Schema

### `profiles`
| Column | Type | Notes |
|---|---|---|
| id | uuid | FK → auth.users |
| full_name | text | |
| email | text | copied from auth at registration |
| contact_number | text | NOT NULL |
| birthday | date | NOT NULL; age is always calculated, never stored |
| school_occupation | text | |
| voice_part | text | soprano / alto / tenor / bass |
| role | text | member / secretary / admin / super_admin |
| status | text | pending / active / associate / honorary / inactive |
| profile_photo_url | text | nullable — Google Drive link |
| custom_fields | jsonb | admin-defined extra fields |
| tos_accepted_at | timestamptz | set on registration |
| created_at | timestamptz | |
| approved_at | timestamptz | |
| approved_by | uuid | FK → profiles |

### `custom_field_definitions`
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| field_name | text | |
| field_type | text | text / number / date / dropdown |
| field_options | jsonb | options array for dropdown type |
| is_required | boolean | |
| sort_order | int | |
| created_at | timestamptz | |

### `events`
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| title | text | |
| event_date | date | |
| event_type | text | core / major / special |
| description | text | |
| created_by | uuid | FK → profiles |
| created_at | timestamptz | |

### `attendance`
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| event_id | uuid | FK → events |
| member_id | uuid | FK → profiles |
| status | text | present / absent / excused |
| marked_by | uuid | FK → profiles |
| marked_at | timestamptz | |

### `absence_requests`
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| member_id | uuid | FK → profiles |
| event_id | uuid | FK → events |
| request_type | text | advance / retroactive |
| reason | text | |
| status | text | pending / approved / rejected |
| reviewer_note | text | optional |
| reviewed_by | uuid | FK → profiles |
| reviewed_at | timestamptz | |
| created_at | timestamptz | |

### `songs`
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| title | text | |
| lyrics | text | |
| language_tags | text[] | bisaya / filipino / english / latin |
| liturgical_use_tags | text[] | entrance / offertory / communion / recessional / responsorial_psalm / gloria / sanctus / agnus_dei / other |
| season_tags | text[] | advent / christmas / lent / easter / ordinary_time / marian / patron_saint_feast / other |
| gdrive_url | text | nullable |
| youtube_url | text | nullable |
| created_by | uuid | FK → profiles |
| created_at | timestamptz | |
| updated_at | timestamptz | |

---

## 8. Shared JavaScript Modules

### `js/supabase-client.js`
Initializes and exports the Supabase client.

### `js/auth.js`
- `signIn(email, password)`
- `signOut()`
- `getSession()` — returns current session or null
- `getProfile()` — fetches profile row for current user
- `requireAuth(redirectTo)` — redirects to login if not authenticated; also checks for `inactive` status
- `requireRole(role, redirectTo)` — redirects if user lacks required role (hierarchy: member < secretary < admin < super_admin)

### `js/utils.js`
- `getLiturgicalSeason(date)` — returns current Roman Catholic liturgical season + week number (client-side algorithm, no DB dependency)
- `initThemeToggle()` — reads `localStorage`, applies `data-theme` to `<html>`, wires toggle button
- Date formatting helpers
- Google Drive image URL converter

---

## 9. Upcoming Features (Not Yet Built)

### v2 — Next Priority Sessions

**Session 11: Admin CMS — Gallery & Officer Profiles**
- New Supabase tables: `gallery_images`, `officer_profiles`
- New page: `pages/admin/cms.html` with tabs for Gallery and Officer Profiles management
- `index.html` gallery + officers section rendered dynamically from Supabase instead of hardcoded HTML
- Public read / admin write RLS

**Session 12: In-App Notifications**
- New Supabase table: `notifications` (member_id, type, message, is_read)
- Notification bell with unread count badge on all portal pages
- Triggered by: absence approved, absence rejected, award generated
- New module: `js/notifications.js`

**Session 13: Semester Awards + Certificate Generation**
- New Supabase table: `awards` (member_id, semester, attendance_rate, events_attended, events_total)
- Semester definition: S1 = June 20 – Oct 31; S2 = Nov 1 – May 31
- Admin triggers "Close Semester & Generate Awards" — computes top attendance rate, all tied members win
- PDF certificate generated client-side using `jsPDF` + `html2canvas`
- Awards visible in member dashboard with "Download Certificate" button
- Depends on Session 12 (notifications) being complete first

### v3 — Future

**Session 14: Liturgical Season Timeline**
- Parse gcatholic.org Philippine calendar HTML into `assets/data/liturgical-YYYY.json` (one-time per year)
- Dashboard: horizontal timeline bar with colored season segments + "today" dot marker
- Upcoming feasts list (next 14 days, Solemnities/Feasts/Memorials only)
- Upgrade `getLiturgicalSeason()` to use JSON data when available, fall back to algorithm

**Session 15: Constitution & Handbook Admin Editor**
- Allow admin to edit `docs/constitution.md` and `docs/handbook.md` from within the admin panel
- Store content in Supabase (text rows) instead of static files

### Permanently Deferred (decided — do not re-raise)
- Online voting system
- Audio file uploads for practice tracks
- Automated email/SMS notifications (replaced by in-app notifications in v2)
- Mobile app

---

## 10. Liturgical Season Logic

The `getLiturgicalSeason(date)` function in `utils.js` computes the Roman Catholic liturgical season client-side using a calendar algorithm. Seasons returned:

| Season | Color (for future UI use) |
|---|---|
| Advent | violet `#5B2D8E` |
| Christmas | white/gold `#F5F2EB` |
| Ordinary Time | green `#3A6B35` |
| Lent | purple `#6B3A6B` |
| Easter | gold `#C9A86A` |

Song library auto-filters to the current season on load. The badge on the member dashboard shows "Season · Week N".

---

## 11. Attendance System Rules

- **Event types:**
  - Core — weekly masses (counts toward primary rate)
  - Major — feasts and solemnities
  - Special — voluntary events
- **Statuses:** present / absent / excused
- **Excused absences** do not reduce attendance rate
- **At-risk threshold:** <80% Core attendance rate
- **Attendance tracking excludes `super_admin`** service account
- **Semester anchor:** tracking begins June 20 (first General Assembly)

---

## 12. Performance Constraints

- All pages must load usably on slow 3G mobile data
- Supabase JS loaded via CDN — not bundled
- Images lazy-loaded
- Song lyrics and member lists fetched on demand, filtered server-side
- Paginate or limit results wherever lists could grow large
- No heavy JS frameworks

---

## 13. Key Decisions & Conventions (Do Not Re-Litigate)

- Age is never collected or stored — always calculated from birthday
- `super_admin` role is reserved for the President account only
- `inactive` status is the soft-remove path; hard delete is super_admin only
- The secretary (Gezd Seloterio) handles all attendance marking and absence approvals
- Netlify Forms handles the sponsor contact form — no backend needed
- `email` is stored in `profiles` table (not just in `auth.users`) for admin query convenience
- ToS acknowledgement (`tos_accepted_at`) is stored in profiles at registration time
- Constitution and Handbook are currently static Markdown files — editing via admin panel is deferred to v3
