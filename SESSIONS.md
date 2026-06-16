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

---

## Session 1: Repo Restructure + Supabase Schema

**Status:** [x] Complete

**Goal:** Clean the repository layout and create the Supabase project with all tables and RLS policies. No visible changes to users — foundation only.

**Context to provide Claude:**
- "We are restructuring the repo and setting up Supabase. Read PRD.md Section 9 for the target structure and Section 8 for the schema."

**Tasks:**

*Repo restructure:*
- Create `assets/images/gallery/` and move gallery images (1.jpg–8.jpg, easter_vigil_2025.jpg, novena_birhen.jpg)
- Create `assets/images/officers/` and move officer images (president-pp.jpg, vicepresident-pp.jpg, SVC_Logo.png)
- Create `docs/` and move + rename MD files:
  - `SanVicenteChoir_Constitution_2026.md` → `docs/constitution.md`
  - `SanVicenteChoir_MemberHandbook_2026.md` → `docs/handbook.md`
  - `SanVicenteChoir_Calendar_2026-2027.md` → `docs/calendar.md`
  - `SanVicenteChoir_BudgetPlan_2026-2027.md` → `docs/budget.md`
  - `Commitments_2026-27.md` → `docs/commitments.md`
  - `SanVicenteChoir_TBD_Summary.md` → `docs/tbd-summary.md`
- Delete `CHANGES_PROPOSED.md`
- Move `leadership-plan-2026-27.html` → `pages/admin/leadership-plan.html`
- Create `js/supabase-client.js` (stub — just the import and init)
- Create `js/auth.js` (stub — empty functions)
- Create `js/utils.js` (stub — empty)
- Create all empty HTML stubs under `pages/`
- Update all `src` / `href` / `fetch` paths in `index.html` and `documents.html` to match new locations
- Create `supabase/schema.sql` with the full schema from PRD.md Section 8

*Supabase (manual steps in dashboard, instruct Claude to write the SQL):*
- Create Supabase project at supabase.com
- Run `supabase/schema.sql` in the SQL Editor
- Enable Row Level Security on all tables
- Apply RLS policies (Claude writes these as SQL in schema.sql):
  - `profiles`: user reads own row; secretary/admin read all; admin updates any
  - `events`: authenticated users read all; admin writes
  - `attendance`: secretary/admin read/write all; member reads own rows
  - `absence_requests`: member inserts + reads own; secretary/admin reads + updates all
  - `songs`: authenticated users read all; admin writes
- Copy Supabase project URL + anon key into `js/supabase-client.js`

**Acceptance criteria:**
- [ ] No broken image or document links in index.html and documents.html
- [ ] All pages still render correctly after path changes
- [ ] schema.sql covers all 6 tables with correct columns and types
- [ ] CHANGES_PROPOSED.md is deleted from repo

---

## Session 2: Login, Register & Auth Guards

**Status:** [x] Complete

**Goal:** Implement login and registration pages. Wire auth state into navigation. Protect member-only pages with auth guards.

**Context to provide Claude:**
- "Session 1 is done. Supabase is set up. Now build auth: login.html, register.html, auth.js, and add nav login state to index.html and documents.html."

**Tasks:**
- `js/supabase-client.js` — initialize Supabase client with project URL and anon key
- `js/auth.js` — implement:
  - `signIn(email, password)`
  - `signOut()`
  - `getSession()` — returns current session or null
  - `getProfile()` — fetches profile row for current user
  - `requireAuth(redirectTo)` — redirects to login if not authenticated
  - `requireRole(role, redirectTo)` — redirects if user lacks required role
- `pages/login.html` — email + password form; link to register; error display
- `pages/register.html`:
  - Core fields: full name, email, password, contact number, birthday, age, school/occupation, voice part
  - Dynamic custom fields: fetch `custom_field_definitions` from Supabase and render dynamically
  - On submit: create Supabase auth user + insert profile row (`status: pending`, `role: member`)
  - Success message: "Your registration is pending approval."
- `pages/members/dashboard.html` — stub page with auth guard (redirects to login if not authenticated)
- Update `index.html` nav — add "Member Login" link (or "Dashboard" if logged in)
- Update `documents.html` nav — show user name + logout button if logged in

**Acceptance criteria:**
- [ ] Register form submits; profile row appears in Supabase with status: pending
- [ ] Login works; session persists on page refresh (localStorage)
- [ ] Logout clears session and redirects to index.html
- [ ] Visiting pages/members/dashboard.html while logged out redirects to login

---

## Session 3: Admin — Member Management & Custom Fields

**Status:** [x] Complete

**Goal:** Build admin tools for approving registrations, managing member roles/status, and defining custom profile fields.

**Context to provide Claude:**
- "Sessions 1–2 are done. Auth is working. Now build pages/admin/members.html and pages/admin/fields.html. Also build pages/members/profile.html."

**Tasks:**
- `pages/admin/members.html`:
  - Section 1 — Pending Registrations: table of members with `status: pending`; Approve button (opens modal to set status + confirm role); Reject button (deletes auth user + profile)
  - Section 2 — All Members: searchable table with name, voice part, role, status; Edit button to change role or status; View Profile link
  - "Create Account" button: form to create a member account directly (bypasses self-register)
  - Auth guard: redirect to index.html if not admin
- `pages/admin/fields.html`:
  - List all `custom_field_definitions` with name, type, required flag, sort order
  - Add Field form: field name, type (text/number/date/dropdown), dropdown options (if dropdown), required checkbox
  - Reorder fields (up/down buttons)
  - Delete field (with warning: "Existing member data for this field will be hidden but not deleted")
  - Auth guard: admin only
- `pages/members/profile.html`:
  - Displays logged-in member's profile (all core fields + custom fields)
  - Edit mode: allows member to update their own non-sensitive fields
  - Auth guard: member+

**Acceptance criteria:**
- [ ] Admin approves a pending member; their status updates in Supabase
- [ ] Admin promotes a member to secretary; they gain secretary-level access
- [ ] Admin creates a custom field; it appears on register.html and profile.html
- [ ] Non-admin visiting admin pages is redirected

---

## Session 4: Attendance Tracker

**Status:** [x] Complete

**Goal:** Build event management for admin, attendance marking for secretary, and attendance record view for members.

**Context to provide Claude:**
- "Sessions 1–3 done. Now build the attendance system: pages/admin/events.html, pages/secretary/tracker.html, and pages/members/attendance.html."

**Tasks:**
- `pages/admin/events.html`:
  - List all events (title, date, type, actions)
  - Add Event form: title, date, event type (core/major/special), description
  - Edit / Delete event
  - Auth guard: admin only
- `pages/secretary/tracker.html`:
  - Event selector: shows recent + upcoming events from Supabase
  - On event select: load all active + associate members
  - Toggle each member: Present / Absent (visual toggle, not a dropdown)
  - Save button: upserts attendance rows for that event
  - Shows a summary row: X present / Y absent / Z total
  - Auth guard: secretary+
- `pages/members/attendance.html`:
  - Attendance history table: event name, date, type, status (Present / Absent / Excused)
  - Attendance rate per tier: Core X/Y (Z%), Major X/Y (Z%), Special X/Y (Z%)
  - Status badge: On Track (≥80% Core) / At Risk (<80% Core)
  - Auth guard: member+

**Acceptance criteria:**
- [ ] Admin creates an event; it appears in secretary's event selector
- [ ] Secretary marks attendance; rows appear in `attendance` table in Supabase
- [ ] Member's attendance page shows correct history and per-tier rates
- [ ] At-risk status shows correctly for members below 80%

---

## Session 5: Absence Request System

**Status:** [x] Complete

**Goal:** Build the member absence request flow and the secretary review queue. Integrate with attendance records.

**Context to provide Claude:**
- "Session 4 is done. Attendance marking works. Now build the absence request system on top of it."

**Tasks:**
- Update `pages/members/attendance.html`:
  - Add "Request Excuse" button next to each Absent row
  - Add "Request Advance Absence" button for upcoming events (show upcoming events list)
  - Clicking either opens a form: event (pre-filled if from Absent row), reason textarea, submit button
  - On submit: insert row into `absence_requests` (status: pending)
  - Show "Pending" badge on rows that have a pending request
- `pages/secretary/absences.html`:
  - Pending queue: member name, event, event date, request type (advance/retroactive), reason, submitted date
  - Approve button: updates `absence_requests.status` to approved; updates `attendance.status` to excused (insert row if advance request)
  - Reject button: updates status to rejected; optional note
  - Separate tabs or sections: Pending / Approved / Rejected history
  - Auth guard: secretary+
- Update `pages/members/attendance.html`:
  - Excused absences shown with "Excused" badge instead of "Absent"
  - Excused absences excluded from rate calculation
- Update `pages/secretary/tracker.html`:
  - Excused members shown with a distinct indicator (not counted as unexcused absent)

**Acceptance criteria:**
- [ ] Member submits advance request; row appears in absence_requests (pending)
- [ ] Secretary approves; attendance record shows Excused
- [ ] Excused absences do not reduce the member's attendance rate
- [ ] Secretary can see and filter the full request history

---

## Session 6: Song Library

**Status:** [x] Complete

**Goal:** Build the member-facing song library and admin song management. Can be developed in parallel with Sessions 4–5.

**Context to provide Claude:**
- "Sessions 1–2 are done (auth works). Now build the song library: pages/members/songs.html and pages/admin/songs.html."

**Tasks:**
- `pages/admin/songs.html`:
  - Song list with title, language tags, liturgical use, actions (Edit / Delete)
  - Add Song form: title, lyrics (textarea), language tags (checkbox: Bisaya/Filipino/English/Latin), liturgical use tags (checkbox multi-select), season tags (checkbox multi-select), GDrive URL, YouTube URL
  - Edit Song: same form pre-populated
  - Auth guard: admin only
- `pages/members/songs.html`:
  - Search bar: searches song title and lyrics (uses Supabase `ilike` — fetches only matching results)
  - Filter panel: Language (checkboxes), Liturgical Use (checkboxes), Season (checkboxes)
  - Song list: title + tag chips; click to expand
  - Expanded view: full lyrics, GDrive PDF button (if available), YouTube button (if available)
  - Default state: show 20 most recently added songs; user searches/filters to find more
  - Auth guard: member+

**Supabase queries to use:**
- Search: `songs.select('*').ilike('title', '%query%').or('lyrics.ilike.%query%')`
- Filter by tag: `songs.select('*').contains('language_tags', ['bisaya'])`

**Acceptance criteria:**
- [ ] Admin adds a song with all metadata; it appears in member song library
- [ ] Search for a word found in lyrics returns that song
- [ ] Filter by "Bisaya" shows only Bisaya-tagged songs
- [ ] GDrive and YouTube links open in new tab
- [ ] Page loads quickly — only matching songs fetched, not the full library

---

## Session 7: Landing Page + Documents Access Control

**Status:** [x] Complete

**Goal:** Update the public landing page for better marketing, and wire role-based visibility into documents.html.

**Context to provide Claude:**
- "Sessions 1–2 are done (auth works). Now update index.html for sponsor marketing, and update documents.html to show/hide content based on auth role."

**Tasks:**
- `index.html` — Join Us section:
  - Replace individual officer Facebook links with one clear CTA: "Join Our Community on Facebook" → links to choir Facebook page
  - Keep officer Facebook links only in the Contact/Officers section
- `index.html` — Add Sponsor section (before footer or after Support section):
  - Section heading: "Partner With Our Ministry"
  - Three sponsorship tiers displayed as cards: Supporter ₱500 (uniforms), Partner ₱1,000 (sound equipment), Patron ₱2,000+ (multiple needs)
  - Contact form with `data-netlify="true"`: fields — Name, Organization, Contact Number, Message, Submit
  - Style consistent with existing design system (dark luxury palette)
- `documents.html` — role-based sidebar:
  - On page load: check Supabase session and fetch profile role
  - Hide/show sidebar items and document sections based on role (use PRD Section 5 access matrix)
  - Unauthenticated: show Constitution only; all other items hidden with "Login to access" message
  - Member: show Constitution + Handbook + Calendar + Commitments
  - Admin: show all including Budget and TBD Summary
  - Remove Excuse Letter and Leave Request Letter from sidebar entirely (add HTML comment: retired, replaced by absence request system)
  - Add link to absence request system for logged-in members

**Acceptance criteria:**
- [ ] Sponsor form submits and appears in Netlify Forms dashboard
- [ ] Join CTA links to Facebook page
- [ ] Unauthenticated user visiting documents.html sees Constitution only
- [ ] Member sees correct subset of documents
- [ ] Admin sees all documents

---

## Session 8: Netlify Migration + Final QA

**Status:** [x] Complete

**Goal:** Migrate from GitHub Pages to Netlify, do final link audit, remove retired files, and verify all features work on the deployed site.

**Context to provide Claude:**
- "All previous sessions are done. Now migrate to Netlify and do final QA. Check the acceptance criteria for all previous sessions."

**Tasks:**
- Create `netlify.toml` in repo root:
  ```toml
  [[redirects]]
    from = "/documents"
    to = "/pages/documents.html"
    status = 200
  ```
  (Add any other clean URL redirects desired)
- Connect repo to Netlify (done in Netlify UI — no code change; instruct user)
- Set publish directory to `.` (root) in Netlify settings
- Add Netlify form notification: go to Netlify dashboard → Forms → set email for sponsor form
- Test all pages in Netlify preview URL before going live
- Remove retired MD files from repo:
  - `SanVicenteChoir_ExcuseLetter_Template.md`
  - `SanVicenteChoir_LeaveRequest_Template.md`
- Run full link audit: check every internal `href` and `src` for 404s
- Mobile check: test all new pages at 375px width
- Slow network check: use browser DevTools → throttle to Slow 3G → verify pages load usably

**Acceptance criteria:**
- [ ] Site live on Netlify URL (*.netlify.app or custom domain)
- [ ] Sponsor form submission received in Netlify dashboard + email
- [ ] No 404s on any internal link or image
- [ ] Login, register, dashboard, attendance, songs all work on deployed site
- [ ] Letter template MD files removed from repo
- [ ] All new pages are usable on Slow 3G simulation

---

---

## Session 9: Dark Mode Toggle + Liturgical Season Badge

**Status:** [x] Complete

**Goal:** Add light/dark mode toggle to all member and admin dashboard pages. Add a liturgical season badge computed client-side and shown on the member dashboard. Wire the season to auto-filter the song library.

**Context to provide Claude:**
- "Sessions 1–8 are done. Now build Session 9: dark mode toggle and liturgical season badge. Read PRD.md Section 10.4 and 10.5."

**Tasks:**
- `css/design-system.css`:
  - Add light mode CSS variable overrides under a `[data-theme="light"]` attribute selector (current defaults are dark)
  - Toggle button component styles
- `js/utils.js`:
  - `getLiturgicalSeason(date)` — returns current Roman Catholic liturgical season and week number based on the given date
  - `initThemeToggle()` — reads `localStorage` for saved theme, applies `data-theme` to `<html>`, wires toggle button
- All pages under `pages/members/` and `pages/admin/`:
  - Add theme toggle button to portal header (sun/moon icon)
  - Call `initThemeToggle()` on page load
- `pages/members/dashboard.html`:
  - Add liturgical season badge (e.g., "Ordinary Time · Week 12") using `getLiturgicalSeason(new Date())`
- `pages/members/songs.html`:
  - On page load, call `getLiturgicalSeason()` and pre-set the season filter to the current season
  - Show a chip: "Showing songs for: Ordinary Time" with an "×" to clear the filter

**Acceptance criteria:**
- [ ] Toggle switches between dark and light mode on all dashboard pages
- [ ] Theme persists on page refresh (localStorage)
- [ ] Season badge on dashboard shows correct current season
- [ ] Song library defaults to current season filter on load
- [ ] Filter can be cleared manually

---

## Session 10: Registration ToS Modal + Member Profile Picture

**Status:** [x] Complete

**Goal:** Add a Terms of Service modal showing the Constitution and Member Handbook before registration. Add profile picture field to registration and member profile pages.

**Context to provide Claude:**
- "Sessions 1–8 are done. Now build Session 10: ToS modal and profile picture. Read PRD.md Section 10.2 and 10.3."

**Tasks:**
- `pages/register.html`:
  - On page load, before showing the registration form: render a full-screen modal
  - Modal content: render `docs/constitution.md` and `docs/handbook.md` using `marked.js` (fetch both files, render sequentially with a divider)
  - Modal footer: checkbox "I have read and agree to the Constitution & By-Laws and Member Handbook" + "Proceed to Register" button (disabled until checkbox checked)
  - On proceed: close modal, show registration form
  - Add optional field: **Profile Photo URL** (Google Drive direct link) — shown after voice part field
  - On submit: store `tos_accepted_at: new Date().toISOString()` and `profile_photo_url` in profiles row
- `pages/members/profile.html`:
  - Display profile photo (if set) as a circular avatar at top of profile
  - Allow member to update `profile_photo_url` in edit mode
- `pages/admin/members.html`:
  - Show small profile photo thumbnail in member list table (if available)

**Database changes (run in Supabase SQL editor):**
```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_photo_url text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS tos_accepted_at timestamptz;
```

**Acceptance criteria:**
- [ ] Visiting register.html shows the ToS modal first; form is hidden
- [ ] Proceed button disabled until checkbox checked
- [ ] Registration with a photo URL shows the photo on profile.html
- [ ] `tos_accepted_at` is set in the profiles row on successful registration
- [ ] Admin member list shows thumbnails for members with photos

---

## Session 10.5: Registration Hardening + Member Lifecycle

**Status:** [x] Complete

**Goal:** Tighten registration field requirements, remove redundant Age input (auto-calculate from birthday), introduce `super_admin` role for the President account, add soft-removal via `inactive` status, and add permanent member deletion restricted to super_admin.

**Changes made:**

*Registration (`pages/register.html`):*
- Contact Number and Birthday made required
- Age field removed — calculated from birthday wherever displayed
- School / Occupation moved next to Birthday in the layout
- `email` saved to `profiles` row at sign-up

*Profile page (`pages/members/profile.html`):*
- Age field in edit mode replaced with a read-only auto-calculated display
- Birthday input live-updates the age display

*Admin members page (`pages/admin/members.html`):*
- Create Account modal aligned with registration: Contact Number and Birthday required, Age removed
- Email shown under member name in the members table and in the View Profile modal
- Custom field labels in View modal now show field name instead of UUID
- Date-type custom fields show a years-of-service counter (e.g. "10 yrs of service")
- Age in View modal calculated from birthday
- **Delete Member** button added to View modal (super_admin only) — hard deletes auth user + cascades all data
- Edit Member status dropdown includes `inactive`

*Auth (`js/auth.js`):*
- `super_admin` added to role hierarchy (rank 4, above `admin`)
- `requireAuth` and `requireRole` both check for `inactive` status — signs out the user and redirects to `/pages/login.html?inactive=1`

*Login page (`pages/login.html`):*
- Shows a "Your account has been deactivated" banner when redirected with `?inactive=1`

*Design system (`css/design-system.css`):*
- `.badge-inactive` — muted grey
- `.badge-super-admin` — soft purple

**Database migrations (run in Supabase SQL Editor):**
- `supabase/migration_contact_birthday_required.sql` — makes contact_number and birthday NOT NULL, drops age column
- `supabase/migration_super_admin.sql` — adds super_admin to role constraint, grants it to admin@svc.com, updates all RLS policies, creates `delete_member` RPC
- `supabase/migration_inactive_status.sql` — adds inactive to status constraint
- `supabase/migration_profile_email.sql` — adds email column to profiles, backfills from auth.users

---

## Session 11: Admin CMS — Gallery & Officer Profiles

**Status:** [ ] Not Started

**Goal:** Make gallery images and officer profiles manageable from the admin panel, replacing hardcoded HTML in index.html.

**Context to provide Claude:**
- "Sessions 1–8 are done. Now build Session 11: admin CMS for gallery and officer profiles. Read PRD.md Section 10.1."

**Tasks:**
- Supabase — create two new tables (run in SQL editor):
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
- `pages/admin/cms.html`:
  - Tab 1 — Gallery: list current images (thumbnail + caption + sort order); Add image form (GDrive URL, caption, sort order); Edit / Delete
  - Tab 2 — Officer Profiles: list officers (photo, name, role, voice part, sort order); Add / Edit / Delete
  - Auth guard: admin only
- `index.html`:
  - Gallery section: replace hardcoded `<img>` tags — fetch `gallery_images` from Supabase on page load and render dynamically
  - Officers section: replace hardcoded officer cards — fetch `officer_profiles` from Supabase and render dynamically
  - Unauthenticated visitors still see the gallery and officers (public read RLS)
- Add "Content Management" link to admin sidebar

**Acceptance criteria:**
- [ ] Admin adds a gallery image via CMS; it appears on the landing page without a code deploy
- [ ] Admin reorders gallery images; new order reflected on landing page
- [ ] Admin updates an officer profile photo; new photo appears on landing page
- [ ] Landing page gallery and officers section render correctly for unauthenticated visitors

---

## Session 12: In-App Notifications

**Status:** [ ] Not Started

**Goal:** Build the notifications system. Trigger notifications for award certificates and absence request outcomes.

**Context to provide Claude:**
- "Sessions 1–8 are done. Now build Session 12: in-app notifications. Read PRD.md Section 10.7."

**Tasks:**
- Supabase — create notifications table (run in SQL editor):
```sql
CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  type text NOT NULL, -- award / absence_approved / absence_rejected
  message text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
-- Member reads own; secretary/admin insert; member updates own (mark read)
```
- `js/notifications.js` (new shared module):
  - `getUnreadCount(memberId)` — returns count of unread notifications
  - `getNotifications(memberId)` — returns recent notifications (latest 20)
  - `markAllRead(memberId)` — sets is_read = true for all
  - `createNotification(memberId, type, message)` — inserts a new row (called server-side or by secretary/admin action)
- All pages under `pages/members/` and `pages/admin/`:
  - Add notification bell icon with unread count badge to portal header
  - Click opens a dropdown panel: list of notifications with message, type icon, timestamp
  - Mark all as read on panel open
- `pages/secretary/absences.html`:
  - On approve: call `createNotification(memberId, 'absence_approved', message)`
  - On reject: call `createNotification(memberId, 'absence_rejected', message)`

**Acceptance criteria:**
- [ ] Secretary approves an absence; member sees a notification badge on next page load
- [ ] Member opens notifications panel; badge clears
- [ ] Rejection notification includes the reviewer note (if provided)
- [ ] Notification panel shows correct type icon per notification type

---

## Session 13: Semester Awards + Certificate Generation

**Status:** [ ] Not Started

**Goal:** Build the semester awards system — auto-compute top member(s) by attendance, generate a PDF certificate with stats, store the award, and notify the winner(s).

**Context to provide Claude:**
- "Sessions 1–8 and Session 12 (notifications) are done. Now build Session 13: semester awards. Read PRD.md Section 10.6."

**Tasks:**
- Supabase — create awards table (run in SQL editor):
```sql
CREATE TABLE awards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  semester text NOT NULL, -- e.g. "2026-S1"
  attendance_rate numeric NOT NULL,
  events_attended int NOT NULL,
  events_total int NOT NULL,
  generated_by uuid REFERENCES profiles(id),
  generated_at timestamptz DEFAULT now()
);
ALTER TABLE awards ENABLE ROW LEVEL SECURITY;
-- Member reads own; admin reads/writes all
```
- `js/awards.js` (new module):
  - `getSemesters()` — returns list of semester periods based on June 20 anchor:
    - S1: June 20 – October 31
    - S2: November 1 – May 31
  - `computeAwardWinners(semester)` — queries attendance table for the semester window, computes rate per active member, returns all members tied at the top rate
  - `generateCertificatePDF(member, award)` — uses `jsPDF` + `html2canvas` to render and download a certificate PDF with: member name, award title, semester, SVC logo, attendance stats, signing officer name
- `pages/admin/awards.html` (new page):
  - Semester selector dropdown
  - "Preview Winners" button: shows computed winner(s) with their stats
  - "Generate & Save Awards" button: inserts rows into `awards` table + triggers certificate download for each winner + creates notifications
  - Past awards table: all previous semester awards with winner names and stats
  - Auth guard: admin only
- `pages/members/dashboard.html`:
  - Add "Awards" section: list of certificates received (semester, rate, date)
  - Each row has a "Download Certificate" button (regenerates PDF from stored data)
- Add "Awards" link to admin sidebar

**Certificate contents:**
- SVC Logo (top center)
- "Certificate of Recognition" heading
- "This certifies that [Full Name] has been awarded Most Consistent Member"
- Semester period (e.g., "First Semester 2026–2027")
- Stats line: "Attended [X] of [Y] events with a [Z]% attendance rate"
- Signing line: officer name + role (pulled from current admin's profile)
- SVC name + date at bottom

**Acceptance criteria:**
- [ ] Admin selects a semester and previews computed winners with correct stats
- [ ] Generating awards saves rows to `awards` table
- [ ] PDF certificate downloads with correct member name and stats
- [ ] Winner sees the award in their member dashboard
- [ ] Winner receives an in-app notification
- [ ] If two members tie, both receive the award and certificate

---

## Session Order Summary

| # | Session | Depends On |
|---|---------|-----------|
| 1 | Repo Restructure + Supabase Schema | — |
| 2 | Login, Register & Auth Guards | 1 |
| 3 | Admin — Member Management | 2 |
| 4 | Attendance Tracker | 3 |
| 5 | Absence Request System | 4 |
| 6 | Song Library | 2 (can run parallel with 4–5) |
| 7 | Landing Page + Documents Access | 2 (can run parallel with 4–6) |
| 8 | Netlify Migration + Final QA | All |
| 9 | Dark Mode Toggle + Liturgical Season Badge | 8 |
| 10 | Registration ToS Modal + Member Profile Picture | 8 |
| 11 | Admin CMS — Gallery & Officer Profiles | 8 |
| 12 | In-App Notifications | 8 |
| 13 | Semester Awards + Certificate Generation | 12 |
