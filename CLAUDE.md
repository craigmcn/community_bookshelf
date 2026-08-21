# Community Bookshelf

A Rails 8 community reading-list app where members track books, log readings, and write reviews. Moderators/admins manage content via a scoped admin dashboard.

## Tech Stack

- **Ruby** 4.0.5 / **Rails** 8.1.3
- **Database**: PostgreSQL
- **Authentication**: Clearance gem
- **Authorization**: Pundit (policy classes)
- **Frontend**: Hotwire (Turbo + Stimulus), Bootstrap 5, esbuild + Sass via propshaft
- **External API**: Open Library (book search + cover images via Faraday)
- **Background jobs / Cache**: solid_queue, solid_cache (DB-backed)
- **File uploads**: Active Storage, local disk service (`config/storage.yml`) in every environment
- **Mailers**: `ApplicationMailer`/`UserMailer` via Action Mailer; `letter_opener` in development, `:test` delivery in test
- **Pagination**: Pagy (`~> 9.4` — pinned below the unrelated v43 API rewrite), Bootstrap nav extra
- **Testing**: Minitest + Capybara (system tests); Playwright for cross-app e2e parity checks (see below)
- **CI**: GitHub Actions (Brakeman, bundler-audit, StandardRB, full test suite vs PostgreSQL, Playwright e2e)
- **Deployment**: Docker + Kamal + Thruster

## Setup

```sh
bin/setup          # install deps, create/migrate DB, seed
bin/dev            # start web + esbuild watch + CSS watch (via Procfile.dev)
```

## Common Commands

```sh
bin/rails test                          # full test suite
bin/rails test test/models/user_test.rb # single file
bin/rails test:system                   # Capybara system tests

bin/rails routes                        # list all routes
bin/rails db:migrate                    # run pending migrations
bin/rails db:rollback                   # undo last migration
bin/rails db:seed                       # seed roles + users

bin/rubocop                             # lint (StandardRB via standard + standard-rails)
bin/rubocop -a                          # auto-correct safe offenses
bin/rubocop -A                          # auto-correct all offenses (includes unsafe)
bundle exec brakeman                    # security scan

yarn build                              # compile JS
yarn build:css                          # compile Sass

yarn test:e2e                           # Playwright e2e (starts its own server, see below)
```

## Domain Model

### Core Tables
- **books** — `title`, `author`, `cover_url`, `added_by_id` (FK → users)
- **readings** — `user_id`, `book_id`, `status` (enum), `rating` (enum), `review`, `deleted_at` (soft delete)
- **users** — Clearance authentication (email, encrypted_password, tokens), plus `name`/`bio` (self-service profile), `avatar` (Active Storage attachment), `email_confirmed_at`/`email_confirmation_token` (informational-only confirmation, not enforced)
- **roles** — `name`: `member | moderator | admin`
- **role_assignments** — join table users ↔ roles (users can hold multiple roles)
- **tags** — `name` (globally unique), `category` (`genre | mood | pace`, default `genre`)
- **taggings** — join table books ↔ tags (unique per book/tag pair)

### Enums
```ruby
# Reading#status
want_to_read: 0, reading: 1, finished: 2

# Reading#rating
one: 1, two: 2, three: 3, four: 4, five: 5
```

### Soft Deletes
Readings use `deleted_at` for soft deletes. Default scopes exclude deleted records; use `Reading.unscoped` or `with_deleted` if you need them.

## Authentication & Authorization

### Clearance
- `ApplicationController` includes `Clearance::Controller`
- Use `require_login` before_action to protect routes
- `current_user` is always available (nil if signed out)
- Test helper: `sign_in_as(user)` (defined in test_helper.rb)
- Test fixture password: `"correct-horse-shelf"` (all fixture users)

### Pundit
- `ApplicationController` includes `Pundit::Authorization`; `authorize` is called explicitly per action (not enforced via a `verify_authorized` after_action) — controllers that only ever act on `current_user` directly (e.g. `AccountsController`) skip Pundit entirely and rely on `require_login`
- One policy per model in `app/policies/` — all default to `false`
- Roles checked via `current_user.member?`, `.moderator?`, `.admin?`, `.moderator_or_above?`
- Pundit errors are rescued in ApplicationController (renders 403)

### Role Hierarchy
```
admin > moderator > member (default for new users)
```
Users can hold multiple roles simultaneously. Helper methods on User:
- `member?` / `moderator?` / `admin?` — checks for that specific role
- `moderator_or_above?` — moderator OR admin

## Routes

```
GET  /books              BooksController#index       (public)
GET  /books/:id          BooksController#show        (public)
POST /books              BooksController#create      (member+)
PATCH /books/:id         BooksController#update      (moderator+)
DELETE /books/:id        BooksController#destroy     (moderator+)

resources :readings      ReadingsController           (owner or moderator+)

GET  /book_search        BookSearchController#index   (Turbo Frame search)

resource :account        AccountsController           (signed-in only; always acts on current_user)
resource :email_confirmation, only: [:create]         (resend, signed-in only)
GET  /confirm_email/:token  EmailConfirmationsController#confirm  (public)

namespace :admin
  /admin/dashboard       AdminDashboardController     (moderator+)
  /admin/readings        AdminReadingsController      (moderator+)
  /admin/users           AdminUsersController         (admin only)
```

## Testing Conventions

- **Framework**: Minitest (test/unit style, not RSpec)
- **Fixtures** over factories — all fixtures in `test/fixtures/`
- **Parallel** test execution (parallel workers = CPU count)
- Controller tests use `sign_in_as(users(:member))` / `sign_in_as(users(:admin))`
- Always test the three permission tiers: unauthenticated, member, moderator/admin
- System tests use Capybara + Selenium

### Fixture Users
| Fixture | Role | Password |
|---|---|---|
| `users(:member)` | member | correct-horse-shelf |
| `users(:moderator)` | moderator | correct-horse-shelf |
| `users(:admin)` | admin | correct-horse-shelf |

## Key Patterns

### Adding a new policy check
1. Add method to `app/policies/<model>_policy.rb`
2. Call `authorize @record` (or `authorize @record, :custom_action?`) in controller
3. Add fixture-based tests in `test/controllers/<model>s_controller_test.rb`

### Admin-only features
Inherit from `Admin::BaseController` — it enforces `moderator_or_above?` and provides `require_admin!`.

### Open Library integration
`OpenLibraryService.search(query)` returns an array of hashes with `:title`, `:author`, `:cover_url`. The `BookSearchController` serves results into a Turbo Frame (`#book-search-results`). The Stimulus controller (`book_search_controller.js`) debounces input at 300ms.

### Asset builds
Changes to JS or CSS require `yarn build` / `yarn build:css` (or keep `bin/dev` running). Compiled output lands in `app/assets/builds/`.

### Discovery & search (catalog + "My Shelf")
- `BooksController#index` / `ReadingsController#index` each support `q` (ILIKE title/author search), `sort` (see each controller's `SORT_OPTIONS` constant), and pagination via `pagy` (`ApplicationController` includes `Pagy::Backend`, `ApplicationHelper` includes `Pagy::Frontend`; views render `pagy_bootstrap_nav`).
- `ReadingsController#index` additionally filters by `status`, `rating`, and `tag` (via the reading's book).
- Tags have a `category` (genre/mood/pace, see Domain Model above); `Book#tag_list` / `#mood_list` / `#pace_list` are per-category virtual attributes on the book form — each only touches taggings for its own category when assigned, so partial updates leave the other categories alone.
- `Book#similar_books` and `Book.recommended_for(user)` rank by shared-tag count (no ML/vector infra) — the former excludes the book itself, the latter excludes books already on the user's shelf and seeds from books the user finished or rated 4-5 stars.

### Account & profile
- `User#display_name` (`name.presence || email`) is used wherever a user's contributions are attributed publicly (book "Added by", Community Readings) — admin-only views (`admin/users`, `admin/readings`) still show the real `email` since admins need it for account management.
- Email confirmation is informational-only, not enforced: `User#send_email_confirmation` (also an `after_create` callback) generates a token and delivers `UserMailer#email_confirmation` via `deliver_later`; nothing blocks an unconfirmed user from signing in or using any feature. New accounts created programmatically without a real inbox (the deleted-user placeholder, seeded demo accounts) set `skip_confirmation_email = true` before saving.
- Self-service account deletion (`AccountsController#destroy`) requires re-entering the current password (`current_user.authenticated?`), then calls `User#delete_account!`: reassigns the user's contributed catalog books to `User.deleted_placeholder` (a lazily-created system account, email `deleted-user@community-bookshelf.invalid`) in a transaction, then destroys the user, cascading to their own readings/shelves/role_assignments via existing `dependent: :destroy`. `sign_out` must run *before* `delete_account!` — Clearance's `sign_out` writes a fresh `remember_token` to the current user, which raises `FrozenError` against an already-destroyed record if the order is reversed.
- Avatar upload validates content type (PNG/JPEG/WEBP) and a 5MB size cap in `User`'s own `validate` callback rather than a gem (no `image_processing`/libvips dependency) — avatars render at their original resolution, constrained by CSS, not an Active Storage variant.

## Playwright e2e (cross-app parity)

`yarn test:e2e` runs the Playwright suite in `e2e/`. `playwright.config.js`'s `webServer`
boots `bin/e2e_server`, which builds JS/CSS, resets the test DB (`db:test:prepare
db:fixtures:load`), backfills `remember_token` for fixture users (fixtures skip AR
callbacks, so Clearance's `before_create` token generator never runs — without this,
a real browser sign-in can never authenticate), and starts Rails on port 3000 in
`RAILS_ENV=test` with `OPEN_LIBRARY_STUB=1`. That env var makes
`config/initializers/open_library_stub.rb` register a WebMock stub for
`openlibrary.org/search.json` so book search doesn't depend on the live API.

These specs are one half of a shared parity contract also implemented in
`bookshelf-islands` (same scenarios, React-island UI instead of Turbo Frames/native
selects) and, against a real backend, in `bookshelf-spa`/`bookshelf-api`. Same fixture
data across all four repos (`member@example.com` / `moderator@example.com` /
`admin@example.com`, password `correct-horse-shelf`, books "The Great Gatsby"/"1984") —
keep spec *outcomes* aligned across repos when adding new scenarios here.

Runs single-worker/serial (`e2e` tests mutate a shared Postgres DB, unlike Minitest's
per-test fixtures — there's no transaction rollback between Playwright tests). Tests
that change fixture-owned state revert it before finishing (see the role-edit test in
`e2e/admin.spec.js`) so re-running the suite against the same DB stays idempotent.
