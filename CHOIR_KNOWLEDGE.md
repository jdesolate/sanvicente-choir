# San Vicente Choir — Claude Project Knowledge File

> This file is the single source of truth for the SVC choir portal project.
> Upload this to your Claude project so any conversation starts with full context.
> Last updated: 2026-06-25

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

**The user (MJ) is the President and the sole developer of this portal.** He manages all code, design decisions, and feature planning. He communicates casually; treat him as a senior developer who knows the codebase well.

**Role-to-person mapping (intended — not yet applied in DB):**

| Person | Portal Role |
|---|---|
| MJ (Merv) | `super_admin` |
| VP (Aravila) | `admin` |
| Secretary (Gezd) | `secretary` |
| Music Director & Liturgical Lead (Vince) | `officer` |
| Treasurer (Mary Love) | `treasurer` |
| Other officers | `officer` (as needed) |

---

## 2. Project Overview

A full-featured choir management web portal built on top of a static public website.

| Layer | Technology |
|---|---|
| Frontend | Vanilla HTML5, CSS3, JavaScript (ES6+) — no frameworks |
| Auth / Database | Supabase (free tier) |
| File storage | Google Drive links (no file uploads to Supabase) |
| Form handling | Formspree (sponsor contact form only) |
| Markdown rendering | marked.js (CDN) |
| Fonts | Google Fonts: Cinzel, Cormorant Garamond, Inter |
| Hosting | Vercel |
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
│   ├── data/                     # Liturgical calendar JSON (one file per year)
│   │   └── liturgical-2026.json  # (Session 14)
│   └── images/
│       ├── gallery/
│       └── officers/
├── css/
│   └── design-system.css
├── docs/
│   ├── constitution.md
│   ├── handbook.md
│   ├── calendar.md
│   ├── budget.md
│   ├── commitments.md
│   └── tbd-summary.md
├── js/
│   ├── supabase-client.js
│   ├── auth.js
│   ├── header.js
│   ├── utils.js
│   └── notifications.js          # (Session 16)
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
│   ├── officer/                  # (Session 11)
│   │   ├── songs.html
│   │   └── events.html
│   ├── treasurer/                # (Session 11 stubs — full feature Session 15)
│   │   ├── fines.html
│   │   └── ledger.html
│   └── admin/
│       ├── members.html
│       ├── attendance-summary.html
│       ├── events.html
│       ├── songs.html
│       ├── fields.html
│       ├── leadership-plan.html
│       ├── awards.html           # (Session 18 — not yet built)
│       └── cms.html              # (deferred — not yet built)
├── supabase/
│   └── schema.sql
├── index.html
├── documents.html
├── netlify.toml
├── PRD.md
├── SESSIONS.md
└── README.md
```

---

## 4. User Roles & Access Control

**Role hierarchy:** `member` < `secretary` = `officer` = `treasurer` < `admin` < `super_admin`

Secretary, officer, and treasurer are **parallel roles** — each has distinct access, all sit at the same tier below admin.

| Role | Description |
|---|---|
| `member` | Approved choir member |
| `secretary` | Attendance ops + event management + absence request management |
| `officer` | Song management + event management + absence request management (music committee / liturgical lead) |
| `treasurer` | Fines ledger + income/expense ledger |
| `admin` | Full access — VP / webmaster |
| `super_admin` | President (MJ) — all admin + permanent member deletion |

**Member statuses:** `pending` → `active` / `associate` / `honorary` / `inactive`

- `pending`: awaiting admin approval after self-registration
- `active`: full choir member
- `associate`: participating but not full member
- `honorary`: honorary membership
- `inactive`: soft-removed — data retained, portal access blocked, reversible

**Auth guard rule:** `requireAuth()` and `requireRole()` both check for `inactive` status and redirect to `login.html?inactive=1` if triggered. `super_admin` is exempt from status checks.

**Sidebar role-gating rule:** Member pages include hidden `#secretary-section`, `#officer-section`, `#treasurer-section`, and `#admin-section` nav divs revealed by JS after profile load. Admin pages always show all sections statically.

---

## 5. Access Control Matrix

| Feature | public | member | secretary | officer | treasurer | admin | super_admin |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Landing page | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Constitution | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Member Handbook | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Calendar & Commitments | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Budget Plan | | | | | | ✓ | ✓ |
| TBD Summary | | | | | | ✓ | ✓ |
| Dashboard | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Song Library (search + filter) | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| My Attendance (own record) | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Submit Absence Request | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| My Profile | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Liturgical Calendar | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Attendance Tracker (live marking) | | | ✓ | | | ✓ | ✓ |
| Approve/Reject Absence Request | | | ✓ | ✓ | | ✓ | ✓ |
| Attendance Summary (leaderboard) | | | ✓ | ✓ | | ✓ | ✓ |
| Event Create/Edit | | | ✓ | ✓ | | ✓ | ✓ |
| Song Management (add/edit/delete) | | | | ✓ | | ✓ | ✓ |
| Song Assignments | | | | ✓ | | ✓ | ✓ |
| Toggle is_currently_practicing | | | | ✓ | | ✓ | ✓ |
| Fines Ledger | | | | | ✓ | ✓ | ✓ |
| Income/Expense Ledger | | | | | ✓ | ✓ | ✓ |
| Member Management | | | | | | ✓ | ✓ |
| Event Delete | | | | | | ✓ | ✓ |
| Custom Field Management | | | | | | ✓ | ✓ |
| Permanently Delete Member | | | | | | | ✓ |

---

## 6. Current Features (Live as of 2026-07-04)

### Public Pages
- **Landing page** (`index.html`) — choir story, gallery, officers, Join Us CTA → Facebook, Sponsor section with Formspree contact form (3 tiers: Supporter ₱500, Partner ₱1,000, Patron ₱2,000+)
- **Documents hub** (`documents.html`) — role-gated; shows/hides documents based on auth state
- **Login / Register / Forgot Password / Reset Password**
- **PWA support** — `manifest.json` + home screen icon; installable on mobile

### Registration Flow
1. Full-screen ToS modal — Constitution + Member Handbook — acknowledgement required
2. Registration form: full name, email, password, contact number (required), birthday (required), school/occupation (optional), voice part (required), profile photo URL (optional), custom fields
3. Age never collected — always auto-calculated from birthday
4. Account created with `status: pending`, `role: member`, `tos_accepted_at` timestamp
5. Admin approves → member gains full access

### Member Portal
- **Dashboard** — personalized welcome greeting (first name), liturgical season badge ("Ordinary Time · Week 12"), upcoming feasts timeline, quick stat cards, light/dark mode toggle
- **My Attendance** — own history table, split into service rate (On Track ≥80% / At Risk <80%) and practice rate (informational), submit absence requests
- **Song Library** — full-text search, filter by language / liturgical use / season, auto pre-filters to current season on load, expandable song cards with **Copy Lyrics** button, PDF Sheet URL and Guide URL links
  - **Songs for this Weekend** — assigned songs for upcoming service events, ordered by mass part (Entrance → Recessional). Each song has a **Copy** button for its own lyrics; per mass there's **Copy Lineup** (labeled title list, e.g. `Entrance : Song Title`) and **Copy Full Lyrics** (each part heading followed by its lyrics) — built for the president to paste the weekend lineup into the group chat without opening each song on slow chapel data
- **My Profile** — read-only display of all profile fields including joined choir date; large circular profile avatar (initials fallback); profile photo as circular avatar if set

### Secretary Portal (inherits all member features)
- **Attendance Tracker** — select event → mark each member Present / Absent / Excused → save
- **Absence Requests** — Pending queue (approve / reject) + History tab
- **Attendance Summary** — leaderboard with filters

### Admin Portal (inherits all member + secretary features)
- **Member Management** — pending registrations queue, all members table, Create Account, View Profile modal, Delete Member (super_admin only)
- **Event Management** — add/edit/delete events (title, date, type: Core/Major/Special, description)
- **Song Management** (officer + admin) — add/edit/delete songs with all metadata; instant client-side **search + filters** mirroring the member library (title/tag search, language / liturgical use / season chips, Practicing Now toggle); **Assign** a song to a service event with a required **mass part** so the weekend lineup can be ordered and labeled
- **Custom Field Management** — add/edit/delete/reorder fields
- **Attendance Summary** — aggregate leaderboard

### Super Admin
- Hard delete member accounts (cascades all data)

---

## 7. Database Schema

### `profiles`
| Column | Type | Notes |
|---|---|---|
| id | uuid | FK → auth.users |
| full_name | text | |
| email | text | copied from auth at registration |
| contact_number | text | NOT NULL |
| birthday | date | NOT NULL; age always calculated, never stored |
| school_occupation | text | |
| voice_part | text | soprano / alto / tenor / bass |
| role | text | member / secretary / officer / treasurer / admin / super_admin |
| status | text | pending / active / associate / honorary / inactive |
| profile_photo_url | text | nullable — Google Drive link |
| custom_fields | jsonb | admin-defined extra fields |
| joined_choir_date | date | backfilled from custom field / approved_at / created_at |
| tos_accepted_at | timestamptz | set on registration |
| created_at | timestamptz | |
| approved_at | timestamptz | |
| approved_by | uuid | FK → profiles |

### `events`
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| title | text | |
| event_date | date | |
| event_type | text | core / major / special |
| event_category | text | practice / service *(added Session 11)* |
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
| liturgical_use_tags | text[] | entrance / offertory / communion / etc. |
| season_tags | text[] | advent / christmas / lent / easter / ordinary_time / marian / patron_saint_feast / other |
| is_currently_practicing | boolean | default false *(added Session 12)* |
| gdrive_url | text | nullable — UI label: "PDF Sheet URL" |
| youtube_url | text | nullable — UI label: "Guide URL" (YouTube or Drive) |
| created_by | uuid | FK → profiles |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### `song_assignments` *(Session 12)*
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| song_id | uuid | FK → songs (cascade) |
| event_id | uuid | FK → events (cascade) |
| mass_part | text | nullable — liturgical part the song fills (entrance, kyrie, gloria, …); drives ordered lineup + full-lyrics copy |
| assigned_by | uuid | FK → profiles |
| assigned_at | timestamptz | |

### `fines` *(Session 15)*
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| member_id | uuid | FK → profiles (cascade) |
| event_id | uuid | FK → events (cascade) |
| amount | numeric | default 20 |
| status | text | unpaid / paid / waived |
| notes | text | optional |
| recorded_by | uuid | FK → profiles |
| paid_at | timestamptz | |
| created_at | timestamptz | |

### `ledger` *(Session 15)*
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| type | text | income / expense |
| amount | numeric | |
| category | text | |
| description | text | |
| date | date | |
| recorded_by | uuid | FK → profiles |
| created_at | timestamptz | |

### `notifications` *(Session 16)*
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| member_id | uuid | FK → profiles (cascade) |
| type | text | absence_approved / absence_rejected / fine_added / fine_resolved / songs_assigned / award |
| message | text | |
| is_read | boolean | default false |
| created_at | timestamptz | |

### `awards` *(Session 18)*
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| member_id | uuid | FK → profiles |
| semester | text | e.g. "2026-S1" |
| attendance_rate | numeric | |
| events_attended | int | |
| events_total | int | |
| generated_by | uuid | FK → profiles |
| generated_at | timestamptz | |

### `custom_field_definitions`
| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| field_name | text | |
| field_type | text | text / number / date / dropdown |
| field_options | jsonb | options array for dropdown |
| is_required | boolean | |
| sort_order | int | |
| created_at | timestamptz | |

---

## 8. Shared JavaScript Modules

### `js/supabase-client.js`
Initializes and exports the Supabase client.

### `js/auth.js`
- `signIn(email, password)`
- `signOut()`
- `getSession()` — returns current session or null
- `getProfile()` — fetches profile row for current user
- `requireAuth(redirectTo)` — redirects to login if not authenticated; checks `inactive` status
- `requireRole(role, redirectTo)` — hierarchy: member < secretary = officer = treasurer < admin < super_admin

### `js/utils.js`
- `getLiturgicalSeason(date)` — returns current liturgical season + week number; uses `assets/data/liturgical-YYYY.json` when present, falls back to algorithm. The JSON's `week` field is unreliable for Ordinary Time, so the week is computed via `_ordinaryTimeWeek()` for that season (see §11)
- `MASS_PARTS` — canonical mass parts in liturgical order (Entrance → Recessional); single source of truth shared by the song assign UI and the library weekend render. Helpers: `massPartLabel(value)`, `massPartOrder(value)`
- `initThemeToggle()` — reads `localStorage`, applies `data-theme` to `<html>`, wires toggle button
- Date formatting helpers
- Google Drive image URL converter

### `js/header.js`
- `initPortalHeader(profile, onSignOut)` — renders the circular avatar in `#portal-header-user`; shows profile photo or initials fallback; avatar click opens dropdown with My Profile + Sign Out links

### `js/notifications.js` *(Session 16)*
- `getUnreadCount(memberId)`
- `getNotifications(memberId, limit)`
- `markAllRead(memberId)`
- `createNotification(memberId, type, message)`

---

## 9. Upcoming Features (Planned Sessions)

| Session | Title | Status |
|---|---|---|
| 11 | Role System Overhaul + UI Bug Fixes | ✅ Done |
| 12 | Song Enhancements (practicing flag, event assignments) | ✅ Done |
| 13 | Attendance Split (practice vs. service rates) | ✅ Done |
| 14 | Liturgical Calendar (timeline bar + upcoming feasts on dashboard) | ✅ Done |
| 15 | Treasurer Features (fines ledger + income/expense ledger) | ✅ Done |
| 16 | In-App Notifications | ✅ Done |
| 17 | Profile avatar, dashboard greeting + joined choir date, mobile fixes | ✅ Done |
| 18 | Semester Awards + Certificate Generation | ⏳ Planned |

---

## 10. Attendance System Rules

- **Event categories:** practice (informational rate, no threshold) / service (mandatory, On Track ≥80% / At Risk <80%)
- **Event types:** core / major / special — independent of category; both columns exist on every event
- **Statuses:** present / absent / excused
- **Excused absences** do not reduce attendance rate
- **At-risk threshold:** <80% service attendance rate (not practice)
- **Practice rate:** informational only — shown as raw count, no badge
- **Attendance tracking excludes `super_admin`** service account
- **Semester anchor:** tracking begins June 20 (first General Assembly)

---

## 11. Liturgical Season Logic

Seasons and display colors:

| Season | Color |
|---|---|
| Advent | violet `#5B2D8E` |
| Christmas | white/gold `#F5F2EB` |
| Ordinary Time | green `#3A6B35` |
| Lent | purple `#6B3A6B` |
| Easter | gold `#C9A86A` |

Song library auto-filters to the current season on load. Dashboard shows timeline bar + upcoming feasts (Session 14).

**Ordinary Time week numbering:** the Church numbers resumed Ordinary Time (after Pentecost) *backward* from Christ the King, the 34th and final Sunday before Advent — so the weeks consumed by Lent and Easter are skipped. Counting forward from Pentecost undercounts (it was off by 2). `_ordinaryTimeWeek(date)` in `js/utils.js` does this correctly: forward from the Baptism of the Lord before Lent, backward from week 34 after Pentecost. Both the prebuilt `liturgical-YYYY.json` `week` field and the old fallback had this bug, so the week is now always computed for Ordinary Time and the JSON `week` is used only for the other seasons.

---

## 12. Treasurer / Financial Rules

- **Commitment fines:** ₱20 default per missed commitment; manually logged by treasurer
- **Commitment declarations:** collected via Google Forms (Thursday before service weekend) — not in the portal
- **Fine statuses:** unpaid / paid / waived
- **No online payment** — treasurer marks paid/waived manually
- **Ledger:** income / expense transactions with category and running balance
- Semesters: S1 = June 20 – Oct 31; S2 = Nov 1 – May 31

---

## 13. Performance Constraints

- All pages must load usably on slow 3G mobile data
- Supabase JS loaded via CDN — not bundled
- Images lazy-loaded
- Song lyrics and member lists fetched on demand, filtered server-side
- Paginate or limit results wherever lists could grow large
- No heavy JS frameworks

---

## 14. Key Decisions & Conventions (Do Not Re-Litigate)

- Age is never collected or stored — always calculated from birthday
- `super_admin` role is reserved for the President (MJ) only
- `inactive` status is the soft-remove path; hard delete is super_admin only
- Secretary and officer are **parallel roles** — neither satisfies the other's role check
- Commitment fines are manually entered by treasurer — Google Forms workflow is kept; in-portal commitment form is deferred
- Netlify Forms handles the sponsor contact form — no backend needed
- `email` is stored in `profiles` table (not just `auth.users`) for admin query convenience
- `tos_accepted_at` is stored in profiles at registration time
- Constitution and Handbook are currently static Markdown files — admin editor deferred indefinitely
- Initials avatar (gold on charcoal) is the fallback when no profile photo is set
- Sign Out is accessible via the avatar dropdown AND the sidebar — not the top navbar as a standalone button
