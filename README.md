# San Vicente Choir

Official website and member portal for the San Vicente Choir — a liturgical choir ministry serving San Vicente Ferrer Chapel (Duljo) and the Archdiocesan Shrine of San Nicolas de Tolentino Parish, Cebu City, Philippines. Founded 1972.

## Features

**Public**
- Landing page: choir history, gallery, performances, join CTA, sponsor contact
- Constitution & By-Laws (English and Bisaya)

**Members (login required)**
- Member Handbook, Calendar, Commitments
- Personal attendance record and rate per event tier
- Song library with full lyrics, search, filters, and external sheet music links
- Absence request submission (advance and retroactive)

**Secretary**
- Event attendance marking
- Absence request review and approval queue
- At-risk member dashboard

**Admin**
- Member registration approval and role management
- Event creation and management
- Song library management
- Custom profile field management

## Tech Stack

- **Frontend:** Vanilla HTML5, CSS3, JavaScript (ES6+) — no framework
- **Backend / Auth / Database:** [Supabase](https://supabase.com) free tier
- **Form handling:** Netlify Forms (sponsor contact)
- **Hosting:** [Netlify](https://netlify.com) free tier
- **Markdown rendering:** marked.js (CDN)
- **Fonts:** Google Fonts — Cinzel, Cormorant Garamond, Inter

## Project Structure

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
├── js/                       # Shared JavaScript
│   ├── supabase-client.js    # Supabase client initialization
│   ├── auth.js               # Auth helpers and role guards
│   └── utils.js              # Shared utilities
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
│       ├── fields.html
│       └── leadership-plan.html
├── supabase/
│   └── schema.sql            # Full database schema
├── index.html                # Public landing page
├── SVC_Logo.ico
├── PRD.md                    # Product Requirements Document
├── SESSIONS.md               # Build session plan for Claude Code
└── README.md
```

## Local Development

No build tools required. Serve from a local HTTP server (required for Supabase JS and module imports):

```bash
# Python 3
python -m http.server 8080

# Node.js
npx serve .
```

Then open `http://localhost:8080` in your browser.

## Supabase Setup

1. Create a project at [supabase.com](https://supabase.com)
2. Go to the SQL Editor and run `supabase/schema.sql`
3. Copy your project URL and anon key into `js/supabase-client.js`
4. Under Authentication → Providers, ensure Email is enabled

## Netlify Deployment

1. Push this repository to GitHub
2. Connect the repo to [Netlify](https://netlify.com) (New site → Import from Git)
3. Build command: *(leave empty)*
4. Publish directory: `.`
5. Go to Forms in the Netlify dashboard and set up email notifications for the sponsor contact form

## Documents

Official documents live in `docs/` as Markdown files, rendered client-side via marked.js. To update a document, edit the `.md` file and commit. Documents are access-controlled by auth role — see `PRD.md` Section 5 for the full access matrix.

## Contributing

This project is maintained by the officers of San Vicente Choir. For changes to governance documents (Constitution, Handbook), obtain officer approval before committing. For website changes, open a pull request or contact the webmaster (admin).

---

*"Sing to the Lord a new song." — Psalm 96:1*
