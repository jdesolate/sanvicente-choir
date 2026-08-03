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

**Status:** [x] Done

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
- [x] Admin creates a "Practice" event; it appears in tracker with Practice badge
- [x] Member's attendance page shows separate service rate (with badge) and practice count (no badge)
- [x] Attendance summary filter by "Service" recalculates correctly
- [x] Practice attendance never triggers At Risk badge

---

## Session 14: Liturgical Calendar

**Status:** [x] Done

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

**Status:** [x] Done

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

**Status:** [x] Done

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

---

## Session 17.5: Joined Choir Date + Dashboard UX Audit + Mobile Fixes

**Status:** [x] Complete

**Goal:** Prevent new members from being penalised with absences for events before they joined, audit and reorder the member dashboard for mobile-first priority, and fix mobile UI regressions.

**What was done:**

*Joined choir date (`supabase/migration_joined_choir_date.sql`, `pages/admin/members.html`, `pages/members/profile.html`, `pages/admin/attendance-summary.html`):*
- Added `joined_choir_date date` column to `profiles`
- Migration backfill priority: (1) existing "Date of Joining Choir" custom field value, (2) `approved_at::date`, (3) `created_at::date`
- Attendance summary excludes events dated before `joined_choir_date` per member; also checks the custom field at runtime as a fallback for members not yet backfilled
- Admin members page: shows "Joined Choir" in the view panel; edit modal has a date picker to set it
- Member profile page: "Joined" display field shows `joined_choir_date` (fallback: registration date); members can edit it in the edit form

*Dashboard reorder (`pages/members/dashboard.html`):*
- New section order: stat cards → quick-action cards → liturgical calendar
- Replaced Voice Part / Status / Role stat cards with **Attendance Rate** (colour-coded green/gold/red), **Unpaid Fines** (red when balance > 0), and **Voice Part** (smaller font via `.stat-num-text`)
- Attendance rate respects `joined_choir_date` — only counts events after join date
- Liturgical calendar rank legend (S/F/M) now injected by JS only when upcoming feasts exist; hidden when "no feasts in 14 days"
- Added missing `import { supabase }` to dashboard script

*Mobile fixes (`css/design-system.css`, `pages/members/dashboard.html`):*
- Dashboard avatar: added `min-width:64px; min-height:64px` to prevent flexbox squashing the circle on narrow screens
- Notification dropdown: switched from `position:absolute` with `right:-8px` to `position:fixed; left:16px; right:16px` on mobile — dropdown now always stays within the viewport regardless of bell button position

---

## Session 19: Dashboard Polish

**Status:** [ ] Not Started

**Goal:** Fix minor UX issues on the member dashboard identified during a UX audit — redundant sub-text, dead-end stat cards, emoji inconsistency, inline style, missing date context, and weak quick-action hover affordance.

**Note:** Session 17.5 already replaced the stat cards with Attendance Rate + Unpaid Fines + Voice Part, and reordered the dashboard. The remaining tasks from this session are: date sub-text, stat cards as links, quick-action CSS class, and calendar icon swap.

**Context to provide Claude:**
- "Sessions 1–17.5 are done. Now build Session 19: dashboard polish. Read SESSIONS.md Session 19 only."

**Tasks:**

*`pages/members/dashboard.html`:*
1. **Welcome sub-text** — replace the static `"San Vicente Choir Member Portal"` sub-line with today's date (e.g., `"Wednesday, 25 June 2026"`) formatted using `toLocaleDateString('en-PH', { weekday:'long', year:'numeric', month:'long', day:'numeric' })`.
2. **Stat cards as links** — wrap each `.stat-card` in an `<a href="profile.html">` so clicking Voice Part, Status, or Role takes the member to their profile. Add a small `"View profile →"` text link below the stat grid (font-size xs, gold, right-aligned).
3. **Calendar of Activities icon** — replace the `🗓` emoji with `◷` to match the Unicode-only icon set used across the other quick-action cards.
4. **Quick-action card hover** — add `transform: translateY(-2px)` and `box-shadow: 0 4px 16px rgba(0,0,0,0.35)` to `.card:hover` in the design system, or scope it to the quick-action cards via an added class if the global card hover change would affect other pages.

*`css/design-system.css`:*
5. **Quick-action grid class** — add `.quick-action-grid` utility class:
   ```css
   .quick-action-grid {
     display: grid;
     grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
     gap: 12px;
     margin-top: var(--space-6);
   }
   ```
   Replace the inline `style=""` block on the quick-action wrapper `<div>` in `dashboard.html` with `class="quick-action-grid"`.

**Acceptance criteria:**
- [ ] Welcome sub-text shows today's date in en-PH locale
- [ ] Clicking any stat card navigates to `profile.html`
- [ ] "View profile →" link appears below stat grid
- [ ] Calendar of Activities card uses `◷` icon, not 🗓
- [ ] Quick-action cards have a visible lift on hover (no inline styles remain)

---

## Session 20: Attendance Page UX

**Status:** [ ] Not Started

**Goal:** Fix a colour-variable bug on the history filter, improve the practice attendance section, and make the absence request button more discoverable.

**Context to provide Claude:**
- "Sessions 1–14 are done. Now build Session 20: attendance UX. Read SESSIONS.md Session 20 only."

**Tasks:**

*`pages/members/attendance.html`:*

1. **Bug fix — filter button active colour** — the page-scoped style `.hist-cat-btn.active-filter` sets `color: var(--bg-base)`, which does not exist in the design system. Replace with `color: #0A0A0A` (dark text on the gold background). While here, change the active background to use `var(--gold)` for consistency with the design system's existing `.filter-chip.active` pattern.

2. **Practice attendance — richer display** — replace the single prose line (`X of Y practices attended`) with a small stat card identical in structure to the Service Rate card:
   - Stat number: `X%` rate (or `—` if no records), calculated as `practicePresent / practiceTotal`
   - Stat label: "Practice Rate"
   - Below it: muted sub-line `"X of Y practices attended"` as supporting text
   - No On Track / At Risk badge (practice is informational only per PRD)

3. **Absence request button — secondary placement** — add a second `"+ Request Advance Absence"` button directly above the History table heading (inside `#att-history`), right-aligned in the same flex row as the "Attendance History" heading. Both buttons must call the same `openModal('advance')` handler.

4. **Action column — hide when empty** — in `renderHistory()`, check whether any row in the current filtered set has an actionable absent record. If none do, add a `no-actions` class to the table and hide the Action `<th>` and each Action `<td>` via CSS:
   ```css
   .data-table.no-actions .actions-col { display: none; }
   ```
   This avoids the empty column when all records are Present or Excused.

**Acceptance criteria:**
- [ ] Active filter button shows dark text on gold background (not the browser default)
- [ ] Practice section shows a stat card with percentage and supporting count text
- [ ] Second "Request Advance Absence" button appears above the history table
- [ ] Both buttons open the same modal
- [ ] Action column is hidden when no row in the current view has an actionable absent record

---

## Session 21: Profile Page Improvements

**Status:** [ ] Not Started

**Goal:** Fix an accessibility bug on the Age field, add a password change flow, and style the raw file input for profile photo.

**Context to provide Claude:**
- "Sessions 1–14 are done. Now build Session 21: profile improvements. Read SESSIONS.md Session 21 only."

**Tasks:**

*`pages/members/profile.html`:*

1. **Age field a11y fix** — in edit mode the Age row has a `<label>Age</label>` with no associated control (age is computed and displayed as a `<p>`, not an `<input>`). Replace the `<label>` with a `<p class="profile-label">Age</p>` styled identically, so no unassociated label exists. The computed age display (`<p id="e-age-display">`) remains unchanged.

2. **Password change section** — add a "Change Password" section below the edit form (always visible in view mode, not inside the edit form):
   - A collapsible panel toggled by a `"Change Password"` button (`.btn-ghost` style)
   - Inside: single email field pre-filled with the member's email, read-only, and a `"Send Reset Link"` button
   - On click: call `supabase.auth.resetPasswordForEmail(email, { redirectTo: window.location.origin + '/pages/reset-password.html' })`
   - Show success alert: `"A password reset link has been sent to your email."`
   - Show error alert if the call fails
   - This keeps the flow simple: no current-password entry, no inline new-password form — just the Supabase email reset flow

3. **File input styling** — replace the raw `<input type="file" id="e-photo">` with a styled upload trigger:
   - Hide the native input with `display:none`
   - Add a `<label for="e-photo" class="btn btn-ghost btn-sm" style="cursor:pointer">Choose Photo</label>` as the visible trigger
   - After file selection, show the filename in a small muted `<span>` next to the button
   - The existing `change` event listener on `#e-photo` (which shows the preview) remains unchanged

**Acceptance criteria:**
- [ ] No `<label>` elements in edit mode are missing a `for` / associated control
- [ ] "Change Password" button appears on the profile page in view mode
- [ ] Clicking it reveals the reset panel; submitting sends the Supabase reset email
- [ ] Profile photo file picker shows a styled button, not the raw browser input
- [ ] Selected filename is displayed next to the choose button

---

## Session 22: Weekend Songs on Dashboard

**Status:** [ ] Not Started

**Goal:** Surface the "Songs for this Weekend" data directly on the dashboard as a mini-widget, so members see upcoming song assignments without navigating away.

**Context to provide Claude:**
- "Session 12 (song assignments) is done. Now build Session 22: weekend songs on dashboard. Read SESSIONS.md Session 22 only."

**Depends on:** Session 12 (song_assignments table)

**Tasks:**

*`pages/members/dashboard.html`:*

1. **Weekend songs widget** — add a new card between the stat grid and the quick-action grid:
   ```html
   <div class="card" id="weekend-songs-card" style="margin-top:var(--space-6)">
     <div class="card-header">
       <h3 class="card-title">Songs for this Weekend</h3>
       <a href="songs.html" class="btn btn-ghost btn-sm">See all →</a>
     </div>
     <div id="weekend-songs-body">
       <div class="loading-text"><div class="spinner"></div> Loading…</div>
     </div>
   </div>
   ```

2. **Data fetch** — reuse the same query pattern from `songs.html` `loadWeekendSongs()`:
   - Query `events` where `event_date >= today AND event_date <= today + 7` and `event_category = 'service'`
   - Query `song_assignments` for those event IDs, join `songs(title)`
   - Group by event; render a compact list:
     - Event title + formatted date as a sub-heading
     - Bulleted song titles (plain text, no expand/collapse needed)
   - If no assignments: render `<p class="litcal-empty">No songs assigned for this weekend yet.</p>`
   - If Supabase query fails: hide the card silently (don't block dashboard load)

3. **Performance** — fetch in parallel with the liturgical calendar data; do not block `hidePageLoader()`.

**Acceptance criteria:**
- [ ] Widget appears on dashboard between stat grid and quick-action cards
- [ ] Shows correct songs for events in the next 7 days (service events only)
- [ ] "See all →" link goes to `songs.html`
- [ ] Empty state shows when no assignments exist
- [ ] Card does not appear / shows empty state gracefully if the fetch fails

---

## Session 23: Cross-Portal Infrastructure

**Status:** [ ] Not Started

**Goal:** Extract the duplicated sidebar HTML and mobile-toggle JS into a shared module, and add Escape-key support to close the mobile drawer.

**Context to provide Claude:**
- "Sessions 1–14 are done. Now build Session 23: cross-portal infrastructure. Read SESSIONS.md Session 23 only."

**Why:** Every portal page currently contains a full copy of the sidebar HTML (~40 lines) and mobile open/close JS (~10 lines). Adding a new nav link requires editing 5–8 files. This session centralises both.

**Tasks:**

*`js/sidebar.js` (new module):*
- Export `renderSidebar(activeLink)` — returns the complete sidebar `<nav>` HTML string as a template literal
- `activeLink` is one of: `'dashboard'`, `'attendance'`, `'songs'`, `'profile'`, `'documents'`, `'tracker'`, `'absences'`, `'officer-songs'`, `'officer-events'`, `'fines'`, `'ledger'`, `'admin-members'`, `'admin-summary'`, `'admin-events'`, `'admin-songs'`, `'admin-fields'`
- The function marks the matching `sidebar-link` as `active` by comparing against `activeLink`
- Role-gated sections (`#secretary-section`, `#officer-section`, `#treasurer-section`, `#admin-section`) remain hidden by default; JS still reveals them after profile loads
- Export `initMobileSidebar()` — sets up the hamburger button, backdrop click, and Escape key listeners; call once after the sidebar is inserted into the DOM

*All portal pages (update):*
- Remove the inline `<nav class="portal-sidebar">` block and mobile sidebar JS
- Replace with:
  ```js
  import { renderSidebar, initMobileSidebar } from '../../js/sidebar.js';
  document.getElementById('sidebar-placeholder').outerHTML = renderSidebar('dashboard');
  initMobileSidebar();
  ```
- Add `<div id="sidebar-placeholder"></div>` in the HTML where the sidebar was

*Escape key support (in `initMobileSidebar`):*
```js
document.addEventListener('keydown', e => {
  if (e.key === 'Escape' && sidebar.classList.contains('open')) closeSidebar();
});
```

**Pages to update:** `pages/members/dashboard.html`, `attendance.html`, `songs.html`, `profile.html`, `pages/secretary/tracker.html`, `pages/secretary/absences.html`, `pages/officer/songs.html`, `pages/officer/events.html` (if exists), `pages/treasurer/fines.html`, `pages/treasurer/ledger.html`, `pages/admin/members.html`, `pages/admin/attendance-summary.html`, `pages/admin/events.html`, `pages/admin/songs.html`, `pages/admin/fields.html`

**Acceptance criteria:**
- [ ] Sidebar renders identically across all pages (compare side by side)
- [ ] Active link is highlighted correctly on each page
- [ ] Role-gated sections still appear correctly after profile loads
- [ ] Pressing Escape on mobile closes the sidebar drawer
- [ ] Backdrop click still closes the sidebar
- [ ] Adding a new sidebar link requires editing only `js/sidebar.js`

---

## Session 24: Logistics & Property — Inventory + Borrowing Log

**Status:** [x] Complete

**Goal:** Give the Logistics & Property head (per the July 26, 2026 assembly) portal tools for equipment inventory and the borrowing log. Read PRD.md Section 6.10.

**What was done:**

*Database (`supabase/migration_logistics.sql` — run in Supabase SQL editor):*
- `logistics` role added to `profiles_role_check` and to the officer-tier profiles read policy
- `inventory_items` table: name, category, quantity, condition, storage location, acquired date, photo URL, notes, retired flag
- `borrow_records` table: item FK, member borrower FK or free-text non-member name, borrowed/returned dates, return condition, notes
- RLS: officer-tier and up read both tables; logistics/admin/super_admin write

*`js/auth.js`:*
- `logistics` added at level 2 (parallel with secretary/officer/treasurer)

*`pages/logistics/inventory.html` (new page):*
- Guard: `requireRole('logistics')` — any officer-tier role can view; write buttons and a view-only banner gated by `canWrite = logistics/admin/super_admin`
- Inventory table with category filter chips, condition/status badges, Add/Edit/Delete item modals
- Lend modal (member dropdown or non-member name) and Mark Returned modal; a degraded return condition also updates the item's condition
- Borrowing log table with Still Out / All Records filter; stat cards for items, borrowed, needs attention

*All portal pages:*
- Hidden `#logistics-section` sidebar div (Inventory & Borrowing link) revealed for all officer-tier roles and up
- `pages/admin/members.html`: `logistics` added to approve/edit role dropdowns and role badge map; badge map also updated in `pages/members/profile.html`

**Acceptance criteria:**
- [ ] Admin can assign the `logistics` role from member edit
- [ ] Logistics head can add items, lend, and mark returns; changes persist
- [ ] Secretary/officer/treasurer see the page read-only (no write buttons; RLS blocks writes)
- [ ] Plain member cannot access the page or see the sidebar link
- [ ] Deleting an item removes its borrow history (cascade)

---

## Session 25: Commitment Reconciliation (Google Forms → Fines)

**Status:** [ ] Not Started

**Goal:** Replace the treasurer's manual cross-check of Google Forms commitment responses against attendance. Import Form names for a service event, match them to members, reconcile against attendance, and generate fines in one click. The Google Forms workflow itself is unchanged.

**Context to provide Claude:**
- "Sessions 15–16 and 24 are done. Now build Session 25: commitment reconciliation. Read PRD.md Sections 6.4, 6.11, and 8."

**Depends on:** Session 15 (fines table), Session 16 (notifications)

**Test data:** a real export lives at `~/Downloads/SVC Weekend Attendance (Responses) - Form Responses 1.csv` (do not commit it — reasons contain personal details). Provide it to the build session for parser validation.

**Tasks:**

*Database (`supabase/migration_commitments.sql` — run in Supabase SQL editor):*
```sql
create table if not exists commitments (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references profiles(id) on delete cascade,
  event_id uuid not null references events(id) on delete cascade,
  source text not null default 'google_form',
  status text not null default 'committed' check (status in ('committed','cant_attend')),
  reason text,
  raw_name text,
  reconciled_at timestamptz,
  imported_by uuid references profiles(id),
  created_at timestamptz default now(),
  unique(member_id, event_id)
);
alter table commitments enable row level security;

create table if not exists member_aliases (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references profiles(id) on delete cascade,
  alias text not null unique,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);
alter table member_aliases enable row level security;

-- RLS: member reads own commitments; treasurer/admin/super_admin full access on both tables
```

*`pages/treasurer/commitments.html` (new page):*
- Auth guard: same pattern as `fines.html` — `requireRole('treasurer')` plus explicit `['treasurer','admin','super_admin']` allowlist
- **Step 1 — weekend picker:** pick a weekend; the panel lists that week's events (masses, practices, specials)
- **Step 2 — CSV import:** file input (or paste of the raw CSV) for the Form responses export. Current header format:
  `Timestamp,Which weekend is this for,Name,Voice Section,Which masses can you serve this weekend? (Multi-select),Reason if you can't attend`
  Parse against the real export (sample: June–Aug 2026). Rules, in order:
  - Use a proper CSV parser (quoted cells contain commas — both in the multi-select and in reasons); locate columns by header keyword (timestamp / name / mass / reason), trimming stray header whitespace
  - Filter rows to the selected weekend via the "Which weekend" column — values like `"June 28–29, 2026"` with an en-dash; show non-matching rows unchecked
  - Duplicate names within the weekend: keep the latest Timestamp (format M/D/YYYY H:MM:SS) — members do resubmit to change their answer
  - Split the multi-select cell on commas; collect the distinct option labels across all filtered rows and show a mapping UI: each label → one of that week's portal events (any category — options include practices like "Wednesday 8pm Practice" and specials like "Sunday 8pm General Assembly") or "Ignore". Pre-select by day/time keyword match; option labels change every week, so mapping is per-import
  - The literal option `I can't serve this weekend` is NOT an event: it yields `status='cant_attend'` rows (with the reason text) for every **service** event of the weekend the member did not explicitly select. It can coexist with real selections in the same response (e.g. practices committed + weekend masses declined, or Sunday committed + Saturday declined) — explicit selections still become commitments
  - The reason column is free text and often filled by committed members too ("N/A", ".", partial notes) — never treat it as a can't-attend signal; store it on the member's rows for reference
- **Step 3 — match review table:** one row per response → matched member. The Form's Name field is a dropdown that should mirror portal `full_name` values, so most rows auto-match. The Form collects no emails (intentional — no login friction for members); matching is name-based only:
  - Exact `full_name` match (case/whitespace-insensitive) → auto-matched
  - `member_aliases` lookup on the normalized name → auto-matched
  - An unmatched name likely means the Form dropdown drifted from the roster — show a hint to update the Form
  - The Voice Section column is not used by the import (it exists for humans reading the sheet)
  - Otherwise: dropdown of fuzzy suggestions (token overlap against full names) + full member list fallback; a "skip" option per row
  - Manual match confirm offers "Remember this spelling" checkbox → inserts into `member_aliases`
  - "Save Commitments" upserts matched rows into `commitments` — one row per member per weekend event (re-import updates, not duplicates)
- **Step 4 — reconcile panel:** per **service** event of the weekend (tab or section per mass; practice/special commitments are stored but informational — no fines, per working rules), join commitments × attendance:
  - present or excused → OK row (muted)
  - `cant_attend` → listed separately with reason, never proposed for a fine
  - committed + absent or no attendance record → proposed fine row with checkbox (checked by default)
  - members with an existing fine for that event → shown as already fined, no checkbox
  - "Create N Fines" button: inserts into `fines` (amount 20, notes "Committed via Google Form but absent", recorded_by = current user), fires `fine_added` notification per member (reuse the message pattern from `fines.html`), sets `reconciled_at` on that event's commitments
- Empty states for: no attendance marked yet for the event (warn and block reconcile), no commitments imported

*`pages/members/attendance.html` (small update):*
- In the "My Fines" section, fines created this way already appear — no change needed. Optionally show "Committed" badge in history rows where a commitment exists for that event (nice-to-have, skip if time is short).

*Sidebar (`treasurer` section, all portal pages — or `js/sidebar.js` if Session 23 has landed):*
- Add "Commitments" link to `#treasurer-section` → `../treasurer/commitments.html`

**Acceptance criteria (test against the real CSV export):**
- [ ] Importing the real Form CSV maps each multi-select option to the right event, including practices and specials
- [ ] "I can't serve this weekend" rows never appear in proposed fines and show their reason
- [ ] A mixed response (e.g. "Sunday 7pm, I can't serve this weekend") commits Sunday and marks the other service events cant_attend
- [ ] A practices-only + can't-serve response records practice commitments and no mass fines
- [ ] A member who committed to Saturday only is not proposed for a fine on Sunday
- [ ] Duplicate responses keep only the latest timestamp
- [ ] A filled reason on a committed response does not affect reconciliation
- [ ] Exact and alias name matches auto-resolve
- [ ] Confirming a fuzzy match with "remember" saves an alias; re-importing the same spelling auto-matches
- [ ] Reconcile proposes fines only for committed + absent/unmarked members; excused members are excluded
- [ ] "Create Fines" inserts fines, notifies members, and marks commitments reconciled
- [ ] Re-running reconcile on the same event shows already-fined members and creates no duplicates
- [ ] Secretary/officer/logistics cannot access the page; member cannot read others' commitments

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
| 11 | Role System Overhaul + UI Bug Fixes | 10.5 | ✅ Complete |
| 12 | Song Enhancements | 11 | ✅ Complete |
| 13 | Attendance Split (Practice vs. Service) | 11 | ✅ Complete |
| 14 | Liturgical Calendar | 11 | ✅ Complete |
| 15 | Treasurer Features | 11 | ✅ Complete |
| 16 | In-App Notifications | 15 | ✅ Complete |
| 17 | Admin CMS — Gallery & Officer Profiles | 11 | ⏳ Planned |
| 17.5 | Joined Choir Date + Dashboard UX Audit + Mobile Fixes | 16 | ✅ Complete |
| 18 | Semester Awards + Certificate Generation | 16 | ⏳ Planned |
| 19 | Dashboard Polish | 14 | ⏳ Planned |
| 20 | Attendance Page UX | 13 | ⏳ Planned |
| 21 | Profile Page Improvements | 10 | ⏳ Planned |
| 22 | Weekend Songs on Dashboard | 12 | ⏳ Planned |
| 23 | Cross-Portal Infrastructure | Any complete | ⏳ Planned |
| 24 | Logistics & Property — Inventory + Borrowing Log | 11 | ✅ Complete |
| 25 | Commitment Reconciliation (Google Forms → Fines) | 15, 16 | ⏳ Planned |
