# San Vicente Choir — Product Requirements Document

## 1. Overview

San Vicente Choir is a 54-year-old liturgical choir ministry. This document defines requirements for a full-featured choir management web application built on top of the existing static website.

**Current state:** Static HTML/CSS/JS site hosted on GitHub Pages  
**Target state:** Supabase-backed member portal with auth, attendance tracking, song library, and sponsor contact — hosted on Netlify

## 2. Goals

1. Provide members a self-service portal for their choir obligations
2. Give the secretary tools to manage attendance without paper
3. Give the admin tools to manage membership and content
4. Market the choir effectively to prospective members and sponsors
5. Keep the site lightweight and fast for users on slow mobile data

## 3. Non-Goals (Deferred to v2)

- Online voting system
- Audio file uploads for practice tracks
- Automated email/SMS notifications (replaced by in-app notifications in v2)
- Mobile app

## 3.1 Non-Goals (Deferred to v3)

- Constitution & by-laws admin editor (content currently managed as a static Markdown file)
- Liturgical season timeline & upcoming feasts view (see spec below)

## 4. User Roles

| Role | Description |
|------|-------------|
| `public` | Unauthenticated visitor |
| `member` | Approved choir member |
| `secretary` | Member with attendance management access |
| `admin` | Full access — officers / webmaster |

## 5. Access Control Matrix

| Feature | public | member | secretary | admin |
|---------|:------:|:------:|:---------:|:-----:|
| Landing page | ✓ | ✓ | ✓ | ✓ |
| Constitution | ✓ | ✓ | ✓ | ✓ |
| Member Handbook | | ✓ | ✓ | ✓ |
| Calendar | | ✓ | ✓ | ✓ |
| Commitments | | ✓ | ✓ | ✓ |
| Budget Plan | | | | ✓ |
| TBD Summary | | | | ✓ |
| Song Library | | ✓ | ✓ | ✓ |
| Own Attendance Record | | ✓ | ✓ | ✓ |
| Full Attendance Tracker | | | ✓ | ✓ |
| Submit Absence Request | | ✓ | ✓ | ✓ |
| Approve Absence Request | | | ✓ | ✓ |
| Member Approval & Roles | | | | ✓ |
| Event Management | | | | ✓ |
| Song Management | | | | ✓ |
| Custom Field Management | | | | ✓ |

## 6. Features

### 6.1 Authentication & Member Registration

**Registration Flow:**
1. Visitor fills the registration form at `/pages/register.html`
2. Account created in Supabase Auth with email + password
3. Profile entry created with `status: pending`, `role: member`
4. Admin reviews pending registrations and sets status (active / associate / honorary)
5. On approval, member gains access to member-only content

**Registration Form Fields (core):**
- Full name
- Email address
- Password
- Contact number
- Birthday
- Age
- School / Occupation
- Voice part (Soprano / Alto / Tenor / Bass)

**Custom Fields:**
- Admin defines additional fields (text, number, date, dropdown) via admin panel
- Stored as JSONB in `profiles.custom_fields`
- New registrants see all active custom fields in the form

**Admin fallback:** Admin can create accounts directly for members unable to self-register.

---

### 6.2 Attendance Tracker

**Event Management (admin):**
- Create events: title, date, event type, description
- Event types: Core (weekly masses), Major (feasts/solemnities), Special (voluntary)

**Attendance Marking (secretary):**
- Secretary selects an event after it occurs
- Sees full list of active + associate members
- Marks each member: Present / Absent
- Can update marks after initial save

**Secretary / Admin Dashboard:**
- Per-event view: all members with present/absent/excused status
- Per-member view: full attendance history + rate per tier
- At-risk flags: members below configurable threshold (default 80%)

**Member's Own View:**
- Own attendance history table
- Attendance rate per tier (Core / Major / Special)
- Status indicator: On Track (≥80%) / At Risk (<80%)

---

### 6.3 Absence Request System

**Submission (member):**
- Advance request: select an upcoming event, provide reason
- Retroactive request: select a past missed event, provide reason

**Review (secretary):**
- Queue of pending requests with member name, event, type, reason
- Approve → attendance marked as Excused (not counted against rate)
- Reject → leave as Unexcused; optional rejection note

**Dashboard integration:**
- Excused absences displayed separately from Unexcused in all views

**Replaces:** Excuse Letter Template and Leave Request Letter Template MD files (to be removed once system is live)

---

### 6.4 Song Library

**Song fields:**
- Title (required)
- Lyrics (full text, required)
- Language tags: Bisaya, Filipino, English, Latin
- Liturgical use tags: Entrance, Offertory, Communion, Recessional, Responsorial Psalm, Gloria, Sanctus, Agnus Dei, Other
- Liturgical season tags: Advent, Christmas, Lent, Easter, Ordinary Time, Marian, Patron Saint Feast, Other
- Google Drive PDF link (optional)
- YouTube reference link (optional)

**Member view:**
- Search by title or lyrics keyword
- Filter by language, liturgical use, liturgical season
- Song detail view: full lyrics, GDrive PDF link, YouTube link
- Results fetched on demand (not the entire library at once)

**Admin management:**
- Add, edit, delete songs and all metadata

---

### 6.5 Landing Page Updates

**Prospective Members:**
- "Join Us" section: clear CTA button linking to the choir's official Facebook page
- Remove per-officer Facebook links from the join flow (keep in the contact section)

**Sponsors:**
- New "Become a Sponsor" section with three tiers:
  - Supporter: ₱500 (uniforms)
  - Partner: ₱1,000 (sound equipment)
  - Patron: ₱2,000+ (multiple needs)
- Netlify Form: Name, Organization, Contact Number, Message
- No backend required — Netlify handles delivery and email notification

---

### 6.6 Documents Access Control

Documents hub (`documents.html`) updated to show/hide content based on auth state:

| Document | Access |
|----------|--------|
| Constitution & By-Laws | Public |
| Member Handbook | Member+ |
| Calendar 2026–2027 | Member+ |
| Commitments 2026–2027 | Member+ |
| Budget Plan | Admin only |
| TBD Summary | Admin only |
| Excuse Letter Template | Retired |
| Leave Request Template | Retired |

---

## 7. Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Vanilla HTML5, CSS3, JavaScript (ES6+) |
| Auth / Database | Supabase (free tier) |
| File storage | Google Drive links (no file uploads to Supabase) |
| Form handling | Netlify Forms (sponsor contact form) |
| Markdown rendering | marked.js (CDN) |
| Fonts | Google Fonts: Cinzel, Cormorant Garamond, Inter |
| Shared CSS | `css/design-system.css` — design tokens, WCAG-compliant base styles, and reusable portal components (buttons, forms, badges, tables, sidebar layout, modals). Every page under `pages/` must import this file. |
| Hosting | Netlify (migrated from GitHub Pages) |

---

## 8. Database Schema

### `profiles`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | FK → auth.users |
| full_name | text | |
| contact_number | text | |
| birthday | date | |
| age | int | |
| school_occupation | text | |
| voice_part | text | soprano / alto / tenor / bass |
| role | text | member / secretary / admin |
| status | text | pending / active / associate / honorary |
| custom_fields | jsonb | admin-defined extra fields |
| created_at | timestamptz | |
| approved_at | timestamptz | |
| approved_by | uuid | FK → profiles |

### `custom_field_definitions`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| field_name | text | |
| field_type | text | text / number / date / dropdown |
| field_options | jsonb | options array for dropdown type |
| is_required | boolean | |
| sort_order | int | display order |
| created_at | timestamptz | |

### `events`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| title | text | |
| event_date | date | |
| event_type | text | core / major / special |
| description | text | |
| created_by | uuid | FK → profiles |
| created_at | timestamptz | |

### `attendance`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| event_id | uuid | FK → events |
| member_id | uuid | FK → profiles |
| status | text | present / absent / excused |
| marked_by | uuid | FK → profiles |
| marked_at | timestamptz | |

### `absence_requests`
| Column | Type | Notes |
|--------|------|-------|
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
|--------|------|-------|
| id | uuid | |
| title | text | |
| lyrics | text | |
| language_tags | text[] | bisaya / filipino / english / latin |
| liturgical_use_tags | text[] | entrance / offertory / communion / etc. |
| season_tags | text[] | advent / lent / easter / etc. |
| gdrive_url | text | nullable |
| youtube_url | text | nullable |
| created_by | uuid | FK → profiles |
| created_at | timestamptz | |
| updated_at | timestamptz | |

---

## 9. Repository Structure

```
sanvicente-choir/
├── assets/
│   └── images/
│       ├── gallery/          # Gallery and performance images
│       └── officers/         # Officer profile photos and SVC_Logo.png
├── docs/                     # Official choir documents (Markdown)
│   ├── constitution.md
│   ├── handbook.md
│   ├── calendar.md
│   ├── budget.md
│   ├── commitments.md
│   └── tbd-summary.md
├── js/                       # Shared JavaScript modules
│   ├── supabase-client.js    # Supabase initialization
│   ├── auth.js               # Auth utilities and role guards
│   └── utils.js              # Shared helpers
├── pages/
│   ├── documents.html        # Documents hub (role-gated)
│   ├── login.html
│   ├── register.html
│   ├── members/              # Member-only pages
│   │   ├── dashboard.html
│   │   ├── attendance.html
│   │   ├── songs.html
│   │   └── profile.html
│   ├── secretary/            # Secretary-only pages
│   │   ├── tracker.html
│   │   └── absences.html
│   └── admin/                # Admin-only pages
│       ├── members.html
│       ├── events.html
│       ├── songs.html
│       └── fields.html
├── supabase/
│   └── schema.sql            # Full database schema for reference
├── index.html                # Public landing page
├── SVC_Logo.ico
├── PRD.md
├── SESSIONS.md
└── README.md
```

## 10. v2 Features

### 10.1 Admin Content Management (CMS)

**Gallery management (admin):**
- Add/remove gallery images via admin panel
- Each entry: Google Drive image link + caption + display order
- Replaces hardcoded gallery HTML — rendered dynamically from Supabase

**Officer profiles management (admin):**
- Add/edit/remove officer entries: name, role, voice part, profile photo (Google Drive link)
- Replaces hardcoded officer section in `index.html`

---

### 10.2 Member Profile Picture

**Registration:**
- New optional field: profile photo (Google Drive link)
- Displayed on member profile page and member list in admin panel

---

### 10.3 Constitution & Handbook Terms of Service Modal

**Registration flow addition:**
- Before the registration form renders, a modal displays the full text of the Constitution & By-Laws and Member Handbook (rendered from the existing Markdown files)
- Member must scroll through and check an acknowledgement checkbox to proceed
- Acknowledgement timestamp stored in `profiles` table (`tos_accepted_at`)

---

### 10.4 Liturgical Season Badge

**Implementation:**
- Current liturgical season computed client-side in `utils.js` using the Roman Catholic calendar algorithm (no database dependency)
- Displayed as a badge on the member and admin dashboards (e.g., "Ordinary Time · Week 12")
- Song library default filter pre-set to the current season on page load

**Seasons covered:** Advent, Christmas, Ordinary Time (pre-Lent), Lent, Easter, Ordinary Time (post-Easter)

---

### 10.5 Light / Dark Mode Toggle

- Toggle button available on all member and admin dashboard pages
- Preference stored in `localStorage` — persists across sessions
- Implemented via CSS custom properties already defined in `design-system.css`

---

### 10.6 Semester Awards System

**Semester definition:**
- Semester 1: June 20 – October 31
- Semester 2: November 1 – May 31
- Attendance data counted from June 20 (official start of attendance tracking and first General Assembly)

**Award computation (admin-triggered):**
- Admin clicks "Close Semester & Generate Awards" in the admin panel
- System computes attendance rate for all active members over the semester window
- Winner(s): member(s) with the highest attendance rate
- Tie-breaking: if two or more members share the top rate, **all tied members receive the award** — no further tie-breaking

**Certificate generation:**
- Generated client-side as a PDF using `jsPDF` + `html2canvas`
- Certificate contents: member name, award title ("Most Consistent Member"), semester period, SVC logo, attendance stats (e.g., "Attended 45 of 50 Core events — 90% rate"), signing officer name + role
- Admin downloads the PDF; certificate record also stored in Supabase and visible to the awardee in their member dashboard

**Award history:**
- `awards` table stores: member_id, semester, attendance_rate, events_attended, events_total, generated_by, generated_at
- Member dashboard shows an "Awards" section listing all certificates received

---

### 10.7 In-App Notifications

**Trigger events:**
- Award generated → notify awardee
- Absence request approved → notify requesting member
- Absence request rejected → notify requesting member (with reviewer note if provided)

**Implementation:**
- `notifications` table: id, member_id, type, message, is_read, created_at
- Unread count badge on dashboard nav
- Notifications dropdown/panel: list of unread + recent read notifications
- Mark as read on open

**Database additions for v2:**

### `awards`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| member_id | uuid | FK → profiles |
| semester | text | e.g., "2026-S1" |
| attendance_rate | numeric | percentage |
| events_attended | int | |
| events_total | int | |
| generated_by | uuid | FK → profiles |
| generated_at | timestamptz | |

### `notifications`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| member_id | uuid | FK → profiles |
| type | text | award / absence_approved / absence_rejected |
| message | text | |
| is_read | boolean | default false |
| created_at | timestamptz | |

**`profiles` additions:**
| Column | Type | Notes |
|--------|------|-------|
| profile_photo_url | text | nullable — Google Drive link |
| tos_accepted_at | timestamptz | nullable — set on registration acknowledgement |

---

## 11. v3 Features

### 11.1 Liturgical Season Timeline

**Data source:** gcatholic.org Philippine calendar (e.g., `https://gcatholic.org/calendar/2026/PH-en`).
The choir director references this page each year. The downloaded HTML is kept in `assets/references/` as a parse source.

**Data preparation (offline, one-time per year):**
- Parse the gcatholic.org HTML into a compact JSON file: `assets/data/liturgical-YYYY.json`
- Each entry: `{ "date": "YYYY-MM-DD", "season": "ordinary_time", "week": 10, "feast": "...", "rank": "S|F|M|m|" }`
- Rank codes: `S` = Solemnity, `F` = Feast, `M` = Memorial, `m` = Optional Memorial
- Season values match existing song tag keys: `advent`, `christmas`, `ordinary_time`, `lent`, `easter`
- A new JSON file must be added each year before the new liturgical year starts (first Sunday of Advent)

**Dashboard display — season timeline bar:**
- A horizontal bar spanning the liturgical year, divided into colored season segments:
  - Advent: violet `#5B2D8E`
  - Christmas: white/gold `#F5F2EB`
  - Ordinary Time: green `#3A6B35`
  - Lent: purple `#6B3A6B`
  - Easter: gold `#C9A86A`
- A "today" dot marker on the bar at the current date's proportional position
- Replaces the simple `.season-badge` text badge added in Session 9

**Dashboard display — upcoming feasts list:**
- Below the timeline bar: a short list of the next 14 days' feasts/solemnities (rank `S`, `F`, or `M` only — skip empty days and optional memorials)
- Format: date · feast name · rank badge
- Purpose: helps the choir anticipate upcoming song needs

**Upgrade to `getLiturgicalSeason()`:**
- When the JSON data file for the current year is present, load it and look up today's entry instead of computing algorithmically
- Fall back to the existing algorithm if the JSON file is absent (graceful degradation)
- The JSON lookup also provides the correct lectionary week number and feast name

**Song library integration:**
- The season pre-filter (added in Session 9) continues to use `getLiturgicalSeason()` — no change needed there

**Constitution & by-laws admin editor:**
- Allow admin to edit `docs/constitution.md` and `docs/handbook.md` content directly from the admin panel
- Changes saved back to Supabase (store as text rows) rather than static files
- Replaces the current static Markdown file approach

---

## 12. Performance Constraints

- All pages must load usably on slow 3G mobile data
- Supabase JS loaded via CDN — not bundled
- Images are lazy-loaded
- No heavy JS frameworks
- Song lyrics and member lists fetched on demand, filtered server-side
- Paginate or limit results wherever lists could grow large
