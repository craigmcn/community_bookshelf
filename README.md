# Community Bookshelf

A shared reading list app built in Rails 8. Users log books they've read, rate them, and see what others are reading. Moderators and admins manage content.

Built as a learning exercise to explore Rails auth/authz patterns before rebuilding in Niiwin. See [`doc/Community Bookshelf.md`](doc/Community%20Bookshelf.md) for the full spec and [`doc/build_log.md`](doc/build_log.md) for a step-by-step build history.

## Stack

- **Ruby** 4.0.5 / **Rails** 8.1
- **PostgreSQL**
- **Bootstrap** 5 (via cssbundling-rails + esbuild)
- **Hotwire** (Turbo + Stimulus)
- **Clearance** — authentication
- **Pundit** — authorization
- **Faraday** — Open Library API integration
- **Chartkick** + **Chart.js** — stats/analytics charts

## Setup

```bash
bundle install
yarn install

cp .env.example .env        # or create .env with PORT=3020
rails db:create db:migrate db:seed
bin/dev
```

Visit `http://localhost:3000`. (Or PORT defined in `.env`)

### Seed accounts

All seed accounts use the password `correct-horse-shelf`.

| Email | Roles |
|-------|-------|
| `admin@communitybookshelf.org` | Admin, Moderator |
| `moderator@communitybookshelf.org` | Moderator |
| `alice@example.com` | Member |
| `bob@example.com` | Member |
| `carol@example.com` | Member |

## Roles

Roles are stored in a `roles` table with a `role_assignments` join table — users can hold multiple roles simultaneously. Admins and moderators always have member-level permissions without needing an explicit member role assignment.

| Role | Can do |
|------|--------|
| Member | Log and edit their own readings; view all books and community shelves |
| Moderator | All member permissions, plus edit/delete any book or reading; access the review moderation view at `/admin/readings` |
| Admin | Everything, including user role assignment and the admin dashboard |

Assign a role in the console:

```ruby
user = User.find_by(email: "you@example.com")
user.roles << Role.find_by(name: "admin")
```

Or via the admin dashboard at `/admin/users`.

## Auth

Clearance handles sign-up, sign-in, sign-out, and password reset. `ApplicationController` includes `Clearance::Controller` and enforces `before_action :require_login` globally. Public actions (books index/show) use `skip_before_action :require_login`.

`SessionsController < Clearance::SessionsController` overrides `url_after_create` to redirect admins to `/admin` and everyone else to `/`.

## Authorization

Pundit policies live in `app/policies/`. Role checks use `admin?`, `moderator?`, and `moderator_or_above?` on `User`, which query the roles association:

- `BookPolicy` — index/show public; create for any signed-in user; update/destroy for moderator+
- `ReadingPolicy` — create/show for any signed-in user; update for owner or moderator+; destroy (soft delete) for moderator+ only; edit blocked on already-deleted records

`ReadingPolicy::Scope` returns all readings for moderator+, own readings only for members.

`Pundit::NotAuthorizedError` is rescued in `ApplicationController` and surfaces as a flash alert.

## Admin

`Admin::BaseController` enforces `require_moderator_or_above` for all routes under `/admin`. Individual controllers add `require_admin` where full admin access is needed.

| Route | Access |
|-------|--------|
| `/admin` — dashboard with site stats, most-read books, and monthly trend charts | Admin only |
| `/admin/users` — user list with role assignment | Admin only |
| `/admin/readings` — reviewed readings with edit/delete actions | Moderator+ |

## Open Library integration

The book search at `/book_search` queries the Open Library API via `OpenLibraryService` and returns matching titles, authors, and cover images. Results populate the new-book form without a page reload (Stimulus + Turbo Frame).

## Discovery & search

- `/books` and `/readings` ("My Shelf") both support text search, sort, and pagination (via [Pagy](https://ddnexus.github.io/pagy/)).
- Books carry three kinds of tags — genre, mood (e.g. "dark"), and pace (e.g. "fast-paced") — each filterable via `?tag=<name>`, and each editable as its own comma-separated field on the book form.
- A book's page lists "Similar Books" (ranked by shared tags); My Shelf shows "Recommended for You" (tag overlap with books you've finished or rated highly, excluding your own shelf).

## Account & profile

- `/account/edit` lets a signed-in user set a display name, bio, favorite genres, and avatar (Active Storage, local disk service — see `config/storage.yml`), and is where the "Danger Zone" self-service account deletion lives (requires re-entering your password; permanently destroys your readings/reviews/lists — including soft-deleted ones, since a stray one left behind would otherwise block the deletion on a foreign-key constraint — but books you added to the catalog stay, reattributed to a "Deleted user" placeholder account). Blocked for the sole admin, to avoid locking the whole `/admin` area.
- `/users/:id` is a member's public profile: avatar, bio, favorite genres, finished/currently-reading counts, follower/following counts, and their public reviews. Any signed-in member can view any profile — the app has no anonymous browsing, so "public" means visible to the community, not the internet. Names throughout the app (Community Readings, "Added by") link here.
- Members can follow each other from a profile page (`/users/:id/followers` and `/users/:id/following` list who follows whom); a member can't follow themselves.
- `/feed` shows a chronological feed of reading updates (added to shelf, started, finished, reviewed) from people you follow.
- Public reviews (the default) can be liked and commented on by any member from the reading's page, which any member can now view when the review is public — comments can be deleted by their author or a moderator.
- `/buddy_reads` lets two members pair up to read a book together: invite, accept/decline, a shared discussion thread, and cancel/mark-completed. Private to the two participants.
- `/clubs` are open discussion groups centered on one book — any member can browse and join; creating a club auto-joins you. Posts can be flagged as spoilers, which hides them (except from their author or a moderator) until you have a `finished` reading logged for the club's book.
- New sign-ups get a confirmation email (`UserMailer`, viewable via `letter_opener` in development) with a link to confirm their address. Confirmation is informational only — an unconfirmed account can still sign in and use every feature; the account page just shows a reminder with a resend option (capped at once a minute, and hidden once confirmed).
- `UserPolicy` backs `AccountsController` even though it only ever acts on `current_user` — it's there to pin that invariant with the same authorization layer every other model in this app uses, not because the controller branches on ownership today.

## Gamification

- `/reading_challenges` lets a member set an annual book-count goal (one per calendar year) and tracks progress against readings finished with a `finished_on` date in that year; editable at any time, with a progress bar shown there, on the account page, and (for the current year) on the member's public profile.
- Reading streaks count consecutive finished books where no two consecutive finishes are more than 30 days apart (`User::STREAK_GAP_DAYS`) — a most-recent finish older than that resets the streak to zero. Shown on the account page and public profile.
- Badges are a fixed, hardcoded set (`Badge::DEFINITIONS`) covering books finished, reviews written, streak length, and completing a reading challenge, at several tiers each. They're awarded permanently (never revoked) by `User#award_badges!`, called after a reading's status or review changes and after a reading challenge is saved. Shown on the account page and public profile.

## Notifications

- A bell icon in the navbar (visible when signed in) shows an unread count and links to `/notifications`. Notifications are created for a new follower, a comment on your review, or a new post in a club you belong to (not for your own comments/posts).
- Opening a notification marks it read and redirects straight to the thing it's about (the follower's profile, the reading, or the club).
- `SendNotificationDigestsJob` (scheduled daily via `config/recurring.yml`, `solid_queue`) emails each user with unread notifications a summary since their last digest, then marks those notifications as digested so they aren't re-sent tomorrow — independent of whether they've since been read in-app.

## Stats & analytics

- `/stats` ("My Stats") shows a signed-in member's own reading charts: genre breakdown of finished books, books finished per month (last 12), and pages read per month (last 12) — rendered with [Chartkick](https://chartkick.com/) + Chart.js.
- The admin dashboard (`/admin`) adds monthly trend line charts for new users, books added, and readings logged, alongside its existing totals and leaderboard.
