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

## Setup

```bash
bundle install
yarn install

cp .env.example .env        # or create .env with PORT=3020
rails db:create db:migrate
bin/dev
```

Visit `http://localhost:3000`. (Or PORT defined in `.env`)

## Roles

Roles are stored as an integer enum on `User` (`member: 0`, `moderator: 1`, `admin: 2`). Every new user starts as `member`.

| Role | Can do |
|------|--------|
| Member | Log and edit their own readings; view all books and community shelves |
| Moderator | All of the above, plus edit/delete any book or reading; access the review moderation view at `/admin/readings` |
| Admin | Everything, including user role assignment and the admin dashboard |

Promote a user in the console:

```ruby
User.find_by(email: "you@example.com").admin!
```

Or via the admin dashboard at `/admin`.

## Auth

Clearance handles sign-up, sign-in, sign-out, and password reset. `ApplicationController` includes `Clearance::Controller` and enforces `before_action :require_login` globally. Public actions (books index/show) use `skip_before_action :require_login`.

`SessionsController < Clearance::SessionsController` overrides `url_after_create` to redirect admins to `/admin` and everyone else to `/`.

## Authorization

Pundit policies live in `app/policies/`. The role enum drives all decisions:

- `BookPolicy` — index/show public; create for any signed-in user; update/destroy for moderator+
- `ReadingPolicy` — create/show for any signed-in user; update for owner or moderator+; destroy (soft delete) for moderator+ only; edit blocked on already-deleted records

`ReadingPolicy::Scope` returns all readings for moderator+, own readings only for members.

`Pundit::NotAuthorizedError` is rescued in `ApplicationController` and surfaces as a flash alert.

## Admin

`Admin::BaseController` enforces `require_moderator_or_above` for all routes under `/admin`. Individual controllers add `require_admin` where full admin access is needed.

| Route | Access |
|-------|--------|
| `/admin` — dashboard with site stats and most-read books | Admin only |
| `/admin/users` — user list with role assignment | Admin only |
| `/admin/readings` — reviewed readings with edit/delete actions | Moderator+ |

## Open Library integration

The book search at `/book_search` queries the Open Library API via `OpenLibraryService` and returns matching titles, authors, and cover images. Results populate the new-book form without a page reload (Stimulus + Turbo Frame).
