# San Vicente Choir — Build Sessions

Each session is a self-contained Claude Code conversation. Start each session by telling Claude: **"Read PRD.md and SESSIONS.md, then we're working on Session N."**

Mark sessions complete as you finish them. Sessions are ordered by dependency — do not skip ahead.

---

## Standing Instruction — Apply to Every Session

Every HTML page created under `pages/` must import the shared design system as the **first stylesheet**:

```html
<html lang="en" class="dark">
...
<link rel="stylesheet" href="/css/design-system.css">
```

- The `class="dark"` on `<html>` is required — it prevents the OS light-mode media query from auto-applying before the JS theme toggle loads.
- Use CSS variables from `design-system.css` for all colors, spacing, and typography — never hardcode values.
- Use the component classes already defined there: `.btn`, `.btn-gold`, `.badge-*`, `.alert-*`, `.data-table`, `.table-wrap`, `.portal-header`, `.portal-sidebar`, `.portal-main`, `.modal`, `.stat-card`, etc.
- Add a `.skip-link` as the first element in `<body>` pointing to `<main id="main-content">`.
- All interactive elements must meet the 44px minimum touch target (`--touch-min`).
- Never override `:focus-visible` — the gold focus ring is already handled by the design system.

---

## Session 1: Repo Restructure + Supabase Schema

**Status:** [x] Complete

---

## Session 2: Login, Register & Auth Guards

**Status:** [x] Complete

---

## Session 3: Admin — Member Management & Custom Fields

**Status:** [x] Complete

---

## Session 4: Attendance Tracker

**Status:** [x] Complete

---

## Session 5: Absence Request System

**Status:** [x] Complete

---

## Session 6: Song Library

**Status:** [x] Complete

---

## Session 7: Landing Page + Documents Access Control

**Status:** [x] Complete

---

## Session 8: Netlify Migration + Final QA

**Status:** [x] Complete

---

## Session 9: Dark Mode Toggle + Liturgical Season Badge

**Status:** [x] Complete

---

## Session 10: Registration ToS Modal + Member Profile Picture

**Status:** [x] Complete

---

## Session 10.5: Registration Hardening + Member Lifecycle

**Status:** [x] Complete

**Changes made:**
- Contact Number and Birthday made required; Age field removed (calculated from birthday)
- `super_admin` role added to hierarchy and RLS policies
- `inactive` status added — soft-remove with reversibility
- Hard delete (super_admin only) via `delete_member` RPC
- `email` column added to `profiles` table and backfilled
- Inactive users are signed out and redirected to `login.html?inactive=1`

---

## Session 11: Role System Overhaul + UI Bug Fixes

**Status:** [x] Done

**Goal:** Add `officer` and `treasurer` roles to the system. Extend secretary and officer access. Fix all known UI bugs. Replace the Sign Out button in the navbar with an initials avatar.

**Context to provide Claude:**
- "Sessions 1–10.5 are done. Now build Session 11: role system overhaul and UI fixes. Read PRD.md Sections 4, 5, 6.7, and 8."

**Tasks:**

*Database (run in Supabase SQL editor):*
```sql
-- Add new roles to profiles check constraint
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('member','secretary','officer','treasurer','admin','super_admin'));

-- Add event_category to events table
ALTER TABLE events ADD COLUMN IF NOT EXISTS event_category text
  CHECK (event_category IN ('practice','service')) NOT NULL DEFAULT 'service';
```

*RLS policy updates:*
- `events` insert/update: extend to secretary and officer (currently admin only)
- `absence_requests` update: extend to officer (currently secretary/admin only)
- `songs` insert/update/delete: extend to officer (currently admin only)
- New `song_assignments` table: officer/admin write; all authenticated read

*`js/auth.js`:*
- Add `officer` and `treasurer` to role hierarchy
- `requireRole('officer')` — passes for officer, admin, super_admin
- `requireRole('treasurer')` — passes for treasurer, admin, super_admin
- Secretary and officer are parallel — neither satisfies the other's `requireRole` check; both satisfy `admin`

*Sidebar navigation updates (all portal pages):*
- Add hidden `#officer-section` and `#treasurer-section` nav divs to all member pages
- Reveal the correct sections after profile loads based on role
- Officer sidebar: Song Management link + Absence Requests link + Event Management link
- Treasurer sidebar: Fines Ledger link + Income/Expense Ledger link

*Top navbar — initials avatar (all portal pages):*
- Replace "Sign Out" button in `.portal-header` with a circular avatar
- Avatar shows profile photo if `profile_photo_url` is set; otherwise shows initials (first letter of first name + first letter of last name), gold text on charcoal background
- Clicking avatar opens a small dropdown: "My Profile" → `/pages/members/profile.html` and "Sign Out"
- Remove the standalone Sign Out button; keep Sign Out in sidebar as well

*UI bug fixes:*
1. `.badge-super-admin` — add `white-space: nowrap` or reduce font size so text fits the badge
2. Song library filter panel — change `display: flex` to `flex-wrap: wrap` so filter buttons wrap on narrow screens
3. Registration page — increase font size / line height for the ToS modal document text on mobile (min `font-size: 15px`, `line-height: 1.7`)
4. Documents page — remove the burger nav from the header; make the SVC logo and "San Vicente Choir" text a link back to `index.html` (styled same as the existing `← Website` button)

**Acceptance criteria:**
- [ ] `officer` and `treasurer` roles appear in the role dropdown on admin member edit
- [ ] Officer can access song management page; member cannot
- [ ] Treasurer can access fines and ledger pages (stubs OK at this stage); secretary cannot
- [ ] Secretary can create events; plain member cannot
- [ ] Initials avatar appears in top navbar on all portal pages
- [ ] Clicking avatar shows dropdown with My Profile + Sign Out
- [ ] `super_admin` badge no longer overflows
- [ ] Song library filter buttons wrap on mobile
- [ ] Documents page burger nav replaced by logo-as-link

**Note:** The `event_category` SQL above is a prerequisite for Session 12's and Session 13's `event_category = 'service'` filters to take effect. Run it before starting Session 13.

---

## Session 12: Song Enhancements

**Status:** [x] Done

**Goal:** Add "Practicing Now" flag to songs, build song assignment to service events, and add "Songs for this Weekend" view on the member song library.

**Context to provide Claude:**
- "Session 11 is done. Now build Session 12: song enhancements. Read PRD.md Sections 6.3 and 8."

**Tasks:**

*Database (run in Supabase SQL editor):*
```sql
-- Add is_currently_practicing to songs
ALTER TABLE songs ADD COLUMN IF NOT EXISTS is_currently_practicing boolean DEFAULT false;

-- Create song_assignments table
CREATE TABLE IF NOT EXISTS song_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  song_id uuid REFERENCES songs(id) ON DELETE CASCADE,
  event_id uuid REFERENCES events(id) ON DELETE CASCADE,
  assigned_by uuid REFERENCES profiles(id),
  assigned_at timestamptz DEFAULT now(),
  UNIQUE(song_id, event_id)
);
ALTER TABLE song_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "song_assignments_select" ON song_assignments FOR SELECT TO authenticated USING (true);
CREATE POLICY "song_assignments_insert" ON song_assignments FOR INSERT TO authenticated
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('officer','admin','super_admin'));
CREATE POLICY "song_assignments_delete" ON song_assignments FOR DELETE TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('officer','admin','super_admin'));
```

*`pages/officer/songs.html` (new page):*
- Auth guard: officer+
- Song table: Title + tags, Practicing toggle, Actions (Assign / Edit / Delete)
- Practicing toggle: inline button per row; optimistic UI update on click
- "Assign" opens a modal showing current assignments (with remove button) and a dropdown of all upcoming events (next 60 days) not yet assigned to that song
- Add Song / Edit Song / Delete Song modal (same form fields as before)

*`pages/admin/songs.html` (update):*
- Full rewrite matching officer page — same Practicing toggle and Assign modal, auth guard stays `requireRole('admin')`

*`pages/members/songs.html` (update):*
- Add "Practicing Now" filter chip next to the Filters button — filters to `is_currently_practicing = true`; cleared by "Clear Filters"
- Songs marked practicing show a small "● Practicing" badge on the card title
- Add "Songs for this Weekend" section at top of page:
  - Queries events where `event_date >= today AND event_date <= today + 7 days`
  - Then queries `song_assignments` for those event IDs, groups songs by event
  - Shows event title + date with bulleted song list per event
  - If no assignments found: shows muted "No songs assigned yet for this weekend"
  - Section auto-clears as event dates pass (query-driven)

*`pages/members/dashboard.html` (update):*
- Added "Songs for this Weekend" quick-action card linking to `songs.html`

**Implementation note — `event_category` filter:**
The assignment modal and member weekend section currently query **all upcoming events** without filtering by `event_category`. This is intentional: Session 11's SQL adding `event_category` to `events` may not have been run yet, and Session 13 hasn't built the UI to mark events as practice vs. service. Once Session 11 SQL is applied and Session 13 is complete, restore the filter:
- Assignment modal: add `.eq('event_category', 'service')` to the events query in `refreshAssignModal()`
- Member weekend section: add `.eq('event_category', 'service')` to the events query in `loadWeekendSongs()`

**Acceptance criteria:**
- [x] Officer toggles `is_currently_practicing` on a song; member sees it under "Practicing Now" filter
- [x] Officer assigns a song to a Sunday service event; it appears in "Songs for this Weekend" on member song library
- [x] After the event date passes, the song no longer appears in the weekend section
- [x] Member cannot access `pages/officer/songs.html`

---

## Session 13: Attendance Split (Practice vs. Service)

**Status:** [ ] Not Started

**Goal:** Surface the `event_category` column in the UI — event management, attendance tracker, member attendance page, and attendance summary.

**Context to provide Claude:**
- "Session 11 is done (event_category column exists). Now build Session 13: attendance split. Read PRD.md Section 6.2."

**Tasks:**

*`pages/admin/events.html` and `pages/secretary/tracker.html` (update — officer can also create events):*
- Add "Event Category" field to Add/Edit Event form: radio or select — Practice / Service (default: Service)
- Event list table: show category as a badge (Practice in blue, Service in gold)
- Attendance tracker event selector: show category badge next to event name

*`pages/members/attendance.html` (update):*
- Split attendance display into two sections:
  1. **Service Attendance** — rate calculation + On Track / At Risk badge (unchanged logic, now filtered to `event_category = 'service'`)
  2. **Practice Attendance** — informational only; show "X of Y practices attended" with no threshold badge
- History table: add a "Category" column (Practice / Service)
- Filter: allow member to filter history by category

*`pages/admin/attendance-summary.html` (update):*
- Add "Category" filter dropdown: All / Practice / Service
- When filtered to a category, the rate column recalculates for only that category's events
- On Track / At Risk colors still based on service rate only

**Acceptance criteria:**
- [ ] Admin creates a "Practice" event; it appears in tracker with Practice badge
- [ ] Member's attendance page shows separate service rate (with badge) and practice count (no badge)
- [ ] Attendance summary filter by "Service" recalculates correctly
- [ ] Practice attendance never triggers At Risk badge

---

## Session 14: Liturgical Calendar

**Status:** [ ] Not Started

**Goal:** Parse the Philippine gcatholic.org calendar into a JSON file and display a liturgical timeline bar + upcoming feasts list on the member dashboard.

**Context to provide Claude:**
- "Sessions 1–11 are done. Now build Session 14: liturgical calendar. Read PRD.md Section 6.5."

**Tasks:**

*Data preparation (offline — done by Merv manually):*
- Download gcatholic.org PH calendar HTML for the current liturgical year
- Parse into `assets/data/liturgical-2026.json`
- Format: `[{ "date": "YYYY-MM-DD", "season": "ordinary_time", "week": 10, "feast": "...", "rank": "S|F|M|m|" }]`
- Rank codes: S = Solemnity, F = Feast, M = Memorial, m = Optional Memorial, empty = ordinary day

*`js/utils.js` (update):*
- Update `getLiturgicalSeason(date)` to first try loading `assets/data/liturgical-YYYY.json` for the current year
- If JSON is present and has a matching date entry: use its season, week, and feast data
- If JSON is absent or date not found: fall back to existing algorithm (graceful degradation)

*`pages/members/dashboard.html` (update):*
- Replace the simple season text badge with a full liturgical timeline bar:
  - Horizontal bar spanning the liturgical year (Advent start to next Advent eve)
  - Colored season segments (see PRD Section 6.5 for colors)
  - "Today" dot marker at proportional position
- Below the bar: upcoming feasts list (next 14 days, ranks S/F/M only)
  - Format: date · feast name · rank badge (Solemnity / Feast / Memorial)
  - If no feasts in next 14 days: show "No major feasts in the next 14 days"

*Visible to:* All authenticated users (member, secretary, officer, treasurer, admin, super_admin)

**Acceptance criteria:**
- [ ] Timeline bar renders on dashboard with correct season colors
- [ ] "Today" dot is positioned correctly on the bar
- [ ] Upcoming feasts list shows correct entries for the next 14 days
- [ ] Optional memorials (rank `m`) and empty days are excluded from the list
- [ ] If JSON file is removed, the season badge falls back gracefully to the algorithm

---

## Session 15: Treasurer Features

**Status:** [ ] Not Started

**Goal:** Build the treasurer portal with fines ledger and income/expense ledger.

**Context to provide Claude:**
- "Session 11 is done (treasurer role exists). Now build Session 15: treasurer features. Read PRD.md Sections 6.4 and 8."

**Tasks:**

*Database (run in Supabase SQL editor):*
```sql
CREATE TABLE IF NOT EXISTS fines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  event_id uuid REFERENCES events(id) ON DELETE CASCADE,
  amount numeric NOT NULL DEFAULT 20,
  status text NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid','paid','waived')),
  notes text,
  recorded_by uuid REFERENCES profiles(id),
  paid_at timestamptz,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE fines ENABLE ROW LEVEL SECURITY;
-- Member reads own; treasurer/admin reads all, inserts, updates

CREATE TABLE IF NOT EXISTS ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type IN ('income','expense')),
  amount numeric NOT NULL,
  category text NOT NULL,
  description text,
  date date NOT NULL,
  recorded_by uuid REFERENCES profiles(id),
  created_at timestamptz DEFAULT now()
);
ALTER TABLE ledger ENABLE ROW LEVEL SECURITY;
-- Treasurer/admin reads all, inserts; admin can delete
```

*`pages/treasurer/fines.html` (new page):*
- Auth guard: treasurer+
- "Add Fine" button: opens modal — select member (dropdown of active members), select event (dropdown), amount (default 20, editable), notes (optional)
- Outstanding fines table: member name, event, event date, amount, status badge, actions
- "Mark Paid" button → sets status to `paid`, records `paid_at`
- "Waive" button → sets status to `waived`, records `paid_at`
- Filter: All / Unpaid / Paid / Waived
- Total outstanding amount shown as a stat card
- On fine added: create notification for member (`fine_added`)
- On fine paid/waived: create notification for member (`fine_resolved`)

*`pages/treasurer/ledger.html` (new page):*
- Auth guard: treasurer+
- "Add Entry" button: type (income/expense), amount, category, description, date
- Transaction list: date, type badge (Income/Expense), category, description, amount
- Running balance stat card (total income − total expenses)
- Filter by type (income / expense) and date range

*`pages/members/attendance.html` (update):*
- Add "My Fines" section at bottom: list of fines (event, amount, status); visible to member for their own record

*Sidebar:*
- Treasurer sidebar: Fines Ledger link + Income/Expense Ledger link (add to all portal pages)

**Acceptance criteria:**
- [ ] Treasurer adds a fine; it appears in fines table
- [ ] Member sees their own fine in "My Fines" section on attendance page
- [ ] Member receives notification when fine is added
- [ ] Treasurer marks fine paid; member receives notification
- [ ] Ledger running balance updates correctly on each entry
- [ ] Secretary cannot access fines or ledger pages

---

## Session 16: In-App Notifications

**Status:** [ ] Not Started

**Goal:** Build the notification system with a bell icon and unread badge on all portal pages.

**Context to provide Claude:**
- "Session 15 is done. Now build Session 16: in-app notifications. Read PRD.md Section 6.6."

**Tasks:**

*Database (run in Supabase SQL editor):*
```sql
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN (
    'absence_approved','absence_rejected',
    'fine_added','fine_resolved',
    'songs_assigned','award'
  )),
  message text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
-- Member reads/updates own; secretary/officer/treasurer/admin insert
```

*`js/notifications.js` (new module):*
- `getUnreadCount(memberId)` — count of unread notifications
- `getNotifications(memberId, limit = 20)` — latest N notifications
- `markAllRead(memberId)` — sets is_read = true for all
- `createNotification(memberId, type, message)` — inserts row

*All portal pages (update):*
- Add notification bell icon to `.portal-header` (next to avatar)
- Unread count badge on bell (hidden when 0)
- Click opens dropdown panel: list with type icon, message, timestamp
- Mark all read on panel open; badge clears

*Trigger points (update existing pages):*
- `pages/secretary/absences.html`: on approve → `createNotification(memberId, 'absence_approved', ...)`; on reject → `createNotification(memberId, 'absence_rejected', ...)`
- `pages/officer/songs.html` + `pages/admin/songs.html`: on saving song assignments → `createNotification` for all active members (`songs_assigned`, "Songs for this weekend have been updated")
- `pages/treasurer/fines.html`: on add fine → `createNotification(memberId, 'fine_added', ...)`; on mark paid/waive → `createNotification(memberId, 'fine_resolved', ...)`

**Acceptance criteria:**
- [ ] Bell icon appears on all portal pages
- [ ] Unread count badge shows correct number
- [ ] Absence approval triggers notification; member sees it on next page load
- [ ] Song assignment triggers notification to all active members
- [ ] Fine added/resolved triggers notification to that member
- [ ] Opening notification panel clears the badge

---

## Session 17: Admin CMS — Gallery & Officer Profiles

**Status:** [ ] Not Started

**Goal:** Make gallery images and officer profiles manageable from the admin panel, replacing hardcoded HTML in index.html.

**Context to provide Claude:**
- "Sessions 1–11 are done. Now build Session 17: admin CMS. Read PRD.md Section 6.8."

**Tasks:**

*Database (run in Supabase SQL editor):*
```sql
CREATE TABLE gallery_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gdrive_url text NOT NULL,
  caption text,
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE officer_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  role_title text NOT NULL,
  voice_part text,
  photo_url text,
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE gallery_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE officer_profiles ENABLE ROW LEVEL SECURITY;
-- Public read, admin write for both tables
```

*`pages/admin/cms.html` (new page):*
- Tab 1 — Gallery: list images (thumbnail + caption + order); Add / Edit / Delete
- Tab 2 — Officers: list officers (photo, name, role, voice part, order); Add / Edit / Delete
- Auth guard: admin only

*`index.html` (update):*
- Gallery section: fetch `gallery_images` from Supabase on load; render dynamically
- Officers section: fetch `officer_profiles` from Supabase on load; render dynamically
- Public RLS ensures unauthenticated visitors still see both sections

**Acceptance criteria:**
- [ ] Admin adds a gallery image; it appears on the landing page without a code deploy
- [ ] Admin updates an officer profile; landing page reflects the change
- [ ] Unauthenticated visitors still see gallery and officers

---

## Session 18: Semester Awards + Certificate Generation

**Status:** [ ] Not Started

**Goal:** Build the semester awards system — compute top attendance member(s), generate a PDF certificate, store the award, and notify the winner(s).

**Context to provide Claude:**
- "Session 16 (notifications) is done. Now build Session 18: semester awards. Read PRD.md Section 6.9."

**Tasks:**

*Database (run in Supabase SQL editor):*
```sql
CREATE TABLE awards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  semester text NOT NULL,
  attendance_rate numeric NOT NULL,
  events_attended int NOT NULL,
  events_total int NOT NULL,
  generated_by uuid REFERENCES profiles(id),
  generated_at timestamptz DEFAULT now()
);
ALTER TABLE awards ENABLE ROW LEVEL SECURITY;
-- Member reads own; admin reads/writes all
```

*`js/awards.js` (new module):*
- `getSemesterWindow(semester)` — returns date range (S1: June 20 – Oct 31; S2: Nov 1 – May 31)
- `computeAwardWinners(semester)` — queries **service** attendance for the semester window; computes rate per active member; returns all members tied at the top rate
- `generateCertificatePDF(member, award)` — `jsPDF` + `html2canvas` certificate

*`pages/admin/awards.html` (new page):*
- Semester selector dropdown
- "Preview Winners" button — shows computed winner(s) with their stats
- "Generate & Save Awards" button — inserts rows into `awards`, downloads PDFs, creates notifications
- Past awards table
- Auth guard: admin only

*`pages/members/dashboard.html` (update):*
- Add "Awards" section: list certificates received (semester, rate, date) with "Download Certificate" button

**Certificate contents:**
- SVC Logo (top center)
- "Certificate of Recognition"
- "Most Consistent Member" award title
- Semester period
- Attendance stats (X of Y events, Z%)
- Signing officer name + role
- SVC name + date

**Acceptance criteria:**
- [ ] Admin previews semester winners with correct stats (service events only)
- [ ] Generating awards saves rows and downloads PDFs
- [ ] Winner sees award in dashboard
- [ ] Winner receives in-app notification
- [ ] Tied members all receive the award

---

## Session Order Summary

| # | Session | Depends On | Status |
|---|---------|-----------|--------|
| 1 | Repo Restructure + Supabase Schema | — | ✅ Complete |
| 2 | Login, Register & Auth Guards | 1 | ✅ Complete |
| 3 | Admin — Member Management | 2 | ✅ Complete |
| 4 | Attendance Tracker | 3 | ✅ Complete |
| 5 | Absence Request System | 4 | ✅ Complete |
| 6 | Song Library | 2 | ✅ Complete |
| 7 | Landing Page + Documents Access | 2 | ✅ Complete |
| 8 | Netlify Migration + Final QA | All | ✅ Complete |
| 9 | Dark Mode Toggle + Liturgical Season Badge | 8 | ✅ Complete |
| 10 | Registration ToS Modal + Profile Picture | 8 | ✅ Complete |
| 10.5 | Registration Hardening + Member Lifecycle | 10 | ✅ Complete |
| 11 | Role System Overhaul + UI Bug Fixes | 10.5 | ⏳ Next |
| 12 | Song Enhancements | 11 | ⏳ Planned |
| 13 | Attendance Split (Practice vs. Service) | 11 | ⏳ Planned |
| 14 | Liturgical Calendar | 11 | ⏳ Planned |
| 15 | Treasurer Features | 11 | ⏳ Planned |
| 16 | In-App Notifications | 15 | ⏳ Planned |
| 17 | Admin CMS — Gallery & Officer Profiles | 11 | ⏳ Planned |
| 18 | Semester Awards + Certificate Generation | 16 | ⏳ Planned |
