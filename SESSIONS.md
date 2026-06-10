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

**Status:** [ ] Complete

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

**Status:** [ ] Complete

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

**Status:** [ ] Complete

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

**Status:** [ ] Complete

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

**Status:** [ ] Complete

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
