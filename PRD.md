# San Vicente Choir — Product Requirements Document

## 1. Overview

San Vicente Choir is a 54-year-old liturgical choir ministry. This document defines requirements for a full-featured choir management web application built on top of the existing static website.

**Current state:** Supabase-backed member portal hosted on Netlify (v1 complete)
**Target state:** Extended portal with role system overhaul, song enhancements, attendance split, liturgical calendar, treasurer tools, and in-app notifications

## 2. Goals

1. Provide members a self-service portal for their choir obligations
2. Give the secretary tools to manage attendance without paper
3. Give the admin tools to manage membership and content
4. Give the treasurer tools to track commitment fines and the income/expense ledger
5. Give officers (music committee, liturgical lead) tools to manage song assignments
6. Market the choir effectively to prospective members and sponsors
7. Keep the site lightweight and fast for users on slow mobile data

## 3. Non-Goals (Permanently Deferred — Do Not Re-Raise)

- Online voting system
- Audio file uploads for practice tracks
- Automated email/SMS notifications (replaced by in-app notifications)
- Mobile app
- In-portal commitment declaration form (Google Forms workflow is kept; portal form deferred until member adoption grows)

---

## 4. User Roles

| Role | Description |
|------|-------------|
| `public` | Unauthenticated visitor |
| `member` | Approved choir member |
| `secretary` | Member + attendance ops + event management + absence request management |
| `officer` | Music committee / liturgical lead — song management + event management + absence request management |
| `treasurer` | Financial ops — fines ledger + income/expense ledger |
| `admin` | Full access — VP / webmaster |
| `super_admin` | President account only — all admin access plus permanent member deletion |

**Role hierarchy:** `member` < `secretary` = `officer` = `treasurer` < `admin` < `super_admin`

Secretary, officer, and treasurer are **parallel roles** — each has distinct ops access but sits at the same tier below admin.

---

## 5. Access Control Matrix

| Feature | public | member | secretary | officer | treasurer | admin | super_admin |
|---------|:------:|:------:|:---------:|:-------:|:---------:|:-----:|:-----------:|
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
| My Profile (read-only) | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Liturgical Calendar | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Attendance Tracker (live marking) | | | ✓ | | | ✓ | ✓ |
| Approve/Reject Absence Request | | | ✓ | ✓ | | ✓ | ✓ |
| Attendance Summary (leaderboard) | | | ✓ | ✓ | | ✓ | ✓ |
| Event Create/Edit | | | ✓ | ✓ | | ✓ | ✓ |
| Song Management (add/edit/delete) | | | | ✓ | | ✓ | ✓ |
| Song Assignments (assign to events) | | | | ✓ | | ✓ | ✓ |
| Toggle is_currently_practicing | | | | ✓ | | ✓ | ✓ |
| Fines Ledger (view/add/mark paid) | | | | | ✓ | ✓ | ✓ |
| Income/Expense Ledger | | | | | ✓ | ✓ | ✓ |
| Member Management (list/approve/edit) | | | | | | ✓ | ✓ |
| View Full Member Profile | | | | | | ✓ | ✓ |
| Event Delete | | | | | | ✓ | ✓ |
| Custom Field Management | | | | | | ✓ | ✓ |
| Permanently Delete Member | | | | | | | ✓ |

---

## 6. Features

### 6.1 Authentication & Member Registration

**Registration Flow:**
1. Visitor fills the registration form at `/pages/register.html`
2. Full-screen ToS modal shows Constitution + Member Handbook — must acknowledge before proceeding
3. Account created in Supabase Auth with email + password
4. Profile entry created with `status: pending`, `role: member`, `tos_accepted_at` timestamp
5. Admin reviews pending registrations and sets status (active / associate / honorary)
6. On approval, member gains access to member-only content

**Registration Form Fields (core):**
- Full name *(required)*
- Email address *(required)*
- Password *(required)*
- Contact number *(required)*
- Birthday *(required)*
- School / Occupation *(optional)*
- Voice part *(required)*
- Profile photo URL *(optional — Google Drive link)*

> **Age is not collected.** It is auto-calculated from birthday wherever displayed.

**Custom Fields:**
- Admin defines additional fields (text, number, date, dropdown) via admin panel
- Stored as JSONB in `profiles.custom_fields`
- New registrants see all active custom fields in the form
- Date-type custom fields (e.g. "Date of Joining Choir") display a years-of-service counter in the admin view modal

**Admin fallback:** Admin can create accounts directly for members unable to self-register.

**Member statuses:**

| Status | Description |
|--------|-------------|
| `pending` | Awaiting admin approval after self-registration |
| `active` | Full choir member |
| `associate` | Participating but not full member |
| `honorary` | Honorary membership |
| `inactive` | Soft-removed — data retained, portal access blocked; reversible |

---

### 6.2 Attendance System

**Event categories (new):**
- `practice` — choir rehearsals; attendance tracked but rate is informational only, no threshold
- `service` — masses, feasts, solemnities; attendance mandatory; On Track/At Risk badge applies

**Event types (unchanged — independent of category):**
- `core` — weekly masses
- `major` — feasts and solemnities
- `special` — voluntary events

Both `event_category` and `event_type` are stored on every event.

**Two separate attendance rates (member's own view):**
1. **Service rate** — mandatory; On Track (≥80%) / At Risk (<80%) badge displayed prominently
2. **Practice rate** — informational only; shown as a raw count (e.g., "8 of 15 practices attended"); no threshold, no badge

**Attendance Tracker (secretary):**
- Event selector shows category label (Practice / Service)
- All active + associate members listed; mark Present / Absent / Excused
- Editable after save

**Attendance Summary (secretary / officer / admin):**
- Filter by `event_category` (practice / service) recalculates rates for that category only
- Filter by `event_type`, voice part, name search also available

**Absence requests:**
- Members can submit advance or retroactive requests
- Secretary and officer can approve/reject
- Approved → attendance marked Excused (excluded from rate)

---

### 6.3 Song Library

**Song fields:**
- Title *(required)*
- Lyrics *(full text, required)*
- Language tags: Bisaya, Filipino, English, Latin
- Liturgical use tags: Entrance, Offertory, Communion, Recessional, Responsorial Psalm, Gloria, Sanctus, Agnus Dei, Other
- Liturgical season tags: Advent, Christmas, Lent, Easter, Ordinary Time, Marian, Patron Saint Feast, Other
- Google Drive PDF link *(optional)*
- YouTube reference link *(optional)*
- `is_currently_practicing` *(boolean, default false)* — admin/officer toggles this on/off

**Song Assignments:**
- Admin/officer assigns songs to specific service events via `song_assignments` table
- "Songs for this Saturday / Sunday" view on song library auto-clears after the event date passes

**Member view:**
- Search by title or lyrics keyword
- Filter by language, liturgical use, liturgical season
- "Practicing Now" filter chip — shows only songs where `is_currently_practicing = true`
- "Songs for this Sunday / Saturday" section — upcoming service assignments
- Song detail: full lyrics, GDrive PDF button, YouTube button

**Admin / officer management:**
- Add, edit, delete songs and all metadata
- Toggle `is_currently_practicing`
- Assign/unassign songs to events

---

### 6.4 Treasurer Features

**Commitment Fines:**
- Commitment declarations are collected via external Google Forms (Thursday before each service weekend) — not managed in the portal
- Treasurer manually logs fines for members who committed but did not attend
- Fine statuses: `unpaid` | `paid` | `waived`
- Default fine amount: ₱20 (editable per entry in case the amount changes)

**Fines Ledger (treasurer portal page):**
- Add fine entry: member, event, amount (default ₱20), notes (optional)
- View outstanding fines: member name, event, amount, status
- Mark paid / waive with a single button
- Admin can also view the fines ledger

**Member notification:** member receives an in-app notification when a fine is added to their record and when it is marked paid or waived.

**Income/Expense Ledger:**
- Treasurer logs financial transactions: type (income / expense), amount, category, description, date
- View running balance and transaction history
- Admin can also view the ledger

---

### 6.5 Liturgical Calendar

**Data source:** gcatholic.org Philippine calendar (one-time parse per year → `assets/data/liturgical-YYYY.json`)

**Each JSON entry:** `{ "date": "YYYY-MM-DD", "season": "ordinary_time", "week": 10, "feast": "...", "rank": "S|F|M|m|" }`
- Rank: `S` = Solemnity, `F` = Feast, `M` = Memorial, `m` = Optional Memorial

**Dashboard display:**
- Horizontal timeline bar spanning the liturgical year with colored season segments
  - Advent: violet `#5B2D8E`
  - Christmas: white/gold `#F5F2EB`
  - Ordinary Time: green `#3A6B35`
  - Lent: purple `#6B3A6B`
  - Easter: gold `#C9A86A`
- "Today" dot marker at the current date's proportional position
- Upcoming feasts list (next 14 days, rank S/F/M only)

**`getLiturgicalSeason()` upgrade:** uses JSON file when present; falls back to existing algorithm when absent.

---

### 6.6 In-App Notifications

**Trigger events:**
- Absence request approved → notify requesting member
- Absence request rejected → notify requesting member (with reviewer note if provided)
- Fine added to record → notify member
- Fine marked paid or waived → notify member
- Service songs assigned (new `song_assignments` rows saved) → notify all active members

**Implementation:**
- `notifications` table: id, member_id, type, message, is_read, created_at
- Notification bell icon with unread count badge on all portal pages
- Notifications dropdown: list with type icon, message, timestamp; mark all read on open
- New module: `js/notifications.js`

---

### 6.7 UI Improvements (Session 11)

**Top navbar — initials avatar:**
- Replace the "Sign Out" button in the top navbar with a circular initials avatar (gold letters on charcoal background)
- Fallback when no profile photo: member's initials (e.g., "MT")
- Clicking avatar opens a small dropdown: "My Profile" link + "Sign Out" button
- Sign Out also available in the sidebar
- Solves mobile navbar overflow on the documents page

**Documents page mobile fix:**
- Remove the burger nav from the documents page header
- Make the SVC logo / "San Vicente Choir" text the back-to-website link instead

**Known bugs to fix:**
1. `super_admin` role badge text overflowing on dashboard
2. Song library filter buttons overflowing horizontally — wrap them
3. Registration page: ToS/handbook text too compact on mobile
4. Documents page mobile: burger nav overflows off-screen right

---

### 6.8 Admin CMS (Session 17)

**Gallery management (admin):**
- Add/remove gallery images via admin panel
- Each entry: Google Drive image link + caption + display order
- Replaces hardcoded gallery HTML — rendered dynamically from Supabase

**Officer profiles management (admin):**
- Add/edit/remove officer entries: name, role, voice part, profile photo (Google Drive link)
- Replaces hardcoded officer section in `index.html`

---

### 6.9 Semester Awards System (Session 18)

- Semester 1: June 20 – October 31
- Semester 2: November 1 – May 31
- Admin triggers "Close Semester & Generate Awards"
- Winner(s): member(s) with highest attendance rate; all tied members win
- PDF certificate generated client-side via `jsPDF` + `html2canvas`
- Award history stored in `awards` table; visible in member dashboard
- Winner receives in-app notification

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
| Shared CSS | `css/design-system.css` — design tokens, WCAG-compliant base styles, reusable portal components |
| Hosting | Netlify |

**Sidebar role-gating rule:** All member pages must include hidden `#secretary-section`, `#officer-section`, `#treasurer-section`, and `#admin-section` nav divs revealed via JS after profile loads.

---

## 8. Database Schema

### `profiles`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | FK → auth.users |
| full_name | text | |
| email | text | copied from auth at registration |
| contact_number | text | NOT NULL |
| birthday | date | NOT NULL; age is always calculated, never stored |
| school_occupation | text | |
| voice_part | text | soprano / alto / tenor / bass |
| role | text | member / secretary / officer / treasurer / admin / super_admin |
| status | text | pending / active / associate / honorary / inactive |
| profile_photo_url | text | nullable — Google Drive link |
| custom_fields | jsonb | admin-defined extra fields |
| tos_accepted_at | timestamptz | set on registration |
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
| event_category | text | practice / service *(new)* |
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
| is_currently_practicing | boolean | default false *(new)* |
| gdrive_url | text | nullable |
| youtube_url | text | nullable |
| created_by | uuid | FK → profiles |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### `song_assignments` *(new)*
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| song_id | uuid | FK → songs (cascade delete) |
| event_id | uuid | FK → events (cascade delete) |
| assigned_by | uuid | FK → profiles |
| assigned_at | timestamptz | DEFAULT now() |

### `fines` *(new)*
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| member_id | uuid | FK → profiles (cascade delete) |
| event_id | uuid | FK → events (cascade delete) |
| amount | numeric | DEFAULT 20 |
| status | text | unpaid / paid / waived |
| notes | text | optional |
| recorded_by | uuid | FK → profiles |
| paid_at | timestamptz | set when marked paid/waived |
| created_at | timestamptz | |

### `ledger` *(new)*
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| type | text | income / expense |
| amount | numeric | |
| category | text | |
| description | text | |
| date | date | |
| recorded_by | uuid | FK → profiles |
| created_at | timestamptz | |

### `notifications`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| member_id | uuid | FK → profiles (cascade delete) |
| type | text | absence_approved / absence_rejected / fine_added / fine_resolved / songs_assigned / award |
| message | text | |
| is_read | boolean | default false |
| created_at | timestamptz | |

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

---

## 9. Repository Structure

```
sanvicente-choir/
├── assets/
│   ├── data/                     # Liturgical calendar JSON (one file per year)
│   │   └── liturgical-2026.json
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
│   │   └── songs.html            # Song management + assignments
│   ├── treasurer/                # (Session 15)
│   │   ├── fines.html
│   │   └── ledger.html
│   └── admin/
│       ├── members.html
│       ├── attendance-summary.html
│       ├── events.html
│       ├── songs.html
│       ├── fields.html
│       ├── awards.html           # (Session 18)
│       └── cms.html              # (Session 17)
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

## 10. Performance Constraints

- All pages must load usably on slow 3G mobile data
- Supabase JS loaded via CDN — not bundled
- Images are lazy-loaded
- No heavy JS frameworks
- Song lyrics and member lists fetched on demand, filtered server-side
- Paginate or limit results wherever lists could grow large
