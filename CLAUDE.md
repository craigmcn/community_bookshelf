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
- **Mailers**: `ApplicationMailer`/`UserMailer`/`NotificationsMailer` via Action Mailer; `letter_opener` in development, `:test` delivery in test; shared `layouts/mailer.html.erb` carries inline-CSS branding used by every transactional email
- **Pagination**: Pagy (`~> 9.4` — pinned below the unrelated v43 API rewrite), Bootstrap nav extra
- **Charts**: Chartkick (view helpers) + Chart.js (JS renderer, bundled via esbuild — `import "chartkick/chart.js"` in `app/javascript/application.js`), `groupdate` gem for month-bucketed trend queries
- **Import/export**: `csv` gem (removed from Ruby's default gems since 3.4, so it's an explicit Gemfile dependency) backs shelf CSV export and Goodreads CSV import
- **JSON API**: `jbuilder` (views) + `rack-attack` (rate limiting) back `/api/v1/*` — see JSON API section below
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
- **books** — `title`, `author`, `cover_url`, `added_by_id` (FK → users), `series_id`/`series_position` (optional FK → series)
- **series** — `name` (globally unique)
- **readings** — `user_id`, `book_id`, `status` (enum), `rating` (enum), `review`, `deleted_at` (soft delete)
- **users** — Clearance authentication (email, encrypted_password, tokens), plus `name`/`bio` (self-service profile), `avatar` (Active Storage attachment), `email_confirmed_at`/`email_confirmation_token` (informational-only confirmation, not enforced)
- **roles** — `name`: `member | moderator | admin`
- **role_assignments** — join table users ↔ roles (users can hold multiple roles)
- **tags** — `name` (globally unique), `category` (`genre | mood | pace`, default `genre`)
- **taggings** — join table books ↔ tags (unique per book/tag pair)
- **favorite_genres** — join table users ↔ tags (unique per user/tag pair); user-declared favorite genres, distinct from `taggings` which is book-scoped
- **shelves** — `user_id`, `name` (unique per user/name)
- **shelf_books** — join table shelves ↔ books (unique per shelf/book pair)
- **reading_challenges** — `user_id`, `year`, `goal` (unique per user/year, `goal > 0` check constraint)
- **user_badges** — `user_id`, `badge_key`, `awarded_at` (unique per user/badge_key); `badge_key` is validated against the hardcoded `Badge::DEFINITIONS` registry, not a database-backed `badges` table
- **follows** — `follower_id`/`followed_id` (both FK → users, unique per pair); DB check constraint blocks self-follows
- **activities** — `user_id`, `reading_id`, `action` (`added_book | started_reading | finished_reading | reviewed`); feeds `/feed`
- **review_likes** — `user_id`, `reading_id` (unique per pair); likes on a reading's public review
- **review_comments** — `user_id`, `reading_id`, `body`; comments on a reading's public review
- **buddy_reads** — `book_id`, `initiator_id`/`partner_id` (both FK → users), `status` (`pending | accepted | declined | cancelled | completed`, default `pending`); DB check constraint blocks self-pairing
- **buddy_read_messages** — `buddy_read_id`, `user_id`, `body`; flat per-pair discussion thread
- **clubs** — `book_id`, `created_by_id` (FK → users), `name`, `description`
- **club_memberships** — join table clubs ↔ users (unique per pair)
- **club_posts** — `club_id`, `user_id`, `body`, `spoiler` (boolean, default `false`)
- **notifications** — `recipient_id`/`actor_id` (both FK → users), `notifiable` (polymorphic: `Follow` | `ReviewComment` | `ClubPost`), `notification_type`, `read_at`, `digested_at`

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
- `ApplicationController` includes `Pundit::Authorization`; `authorize` is called explicitly per action (not enforced via a `verify_authorized` after_action) — every controller that acts on a model, including ones that only ever touch `current_user` directly rather than a `params[:id]` (`AccountsController`, `EmailConfirmationsController#create`), calls `authorize` via a matching policy, so a missing check anywhere raises `Pundit::NotAuthorizedError` instead of failing silently
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
POST /account/regenerate_api_token  AccountsController#regenerate_api_token  (signed-in only)
resource :email_confirmation, only: [:create]         (resend, signed-in only)
GET  /confirm_email/:token  EmailConfirmationsController#confirm  (public)
GET  /users/:id          ProfilesController#show       (any signed-in user)
GET  /users/:id/followers, /users/:id/following  ProfilesController#followers/#following
resource :follow, nested under /users/:user_id  FollowsController#create/#destroy
GET  /feed                ActivitiesController#index    (signed-in only)
resource :review_like, resources :review_comments, nested under /readings/:reading_id
resources :buddy_reads      BuddyReadsController         (participant-only; index/new/create/show/update)
resources :messages, nested under /buddy_reads/:buddy_read_id  BuddyReadMessagesController#create
resources :clubs             ClubsController               (any signed-in user can view; creator/moderator can edit/delete)
resource :membership, resources :posts, nested under /clubs/:club_id  ClubMembershipsController, ClubPostsController
resources :reading_challenges, only: [:index, :new, :create, :edit, :update]  ReadingChallengesController  (scoped to current_user, like AccountsController)
GET  /stats               StatsController#show           (signed-in only; scoped to current_user, like /feed)
GET  /notifications, PATCH /notifications/:id, PATCH /notifications/mark_all_read  NotificationsController  (signed-in only; scoped to current_user, like /feed)
GET  /readings/export     ReadingsController#export      (signed-in only; scoped to current_user, like /feed)
resource :goodreads_import, only: [:new, :create]  GoodreadsImportsController  (signed-in only; scoped to current_user, like /feed)

namespace :admin
  /admin/dashboard       AdminDashboardController     (moderator+)
  /admin/readings        AdminReadingsController      (moderator+)
  /admin/users           AdminUsersController         (admin only)

namespace :api do namespace :v1
  resources :books       Api::V1::BooksController     (token-authenticated; policy tiers same as HTML BooksController)
  resources :readings    Api::V1::ReadingsController  (token-authenticated; policy tiers same as HTML ReadingsController)
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
- `AccountsController` (edit/update/destroy on `current_user`) and `EmailConfirmationsController#create` are backed by `UserPolicy` (`record == user`) even though neither ever takes a `params[:id]` — the policy pins that invariant with the same authorization layer every other model uses, rather than leaving it as an unenforced assumption in the controller body. `EmailConfirmationsController#confirm` has no policy (public, token-authenticated, not ownership-based).
- Email confirmation is informational-only, not enforced: `User#send_email_confirmation` (also an `after_create` callback) generates a token, stamps `email_confirmation_sent_at`, and delivers `UserMailer#email_confirmation` via `deliver_later`; nothing blocks an unconfirmed user from signing in or using any feature. `EmailConfirmationsController#create` (resend) refuses if already confirmed or if `User#email_confirmation_on_cooldown?` (`RESEND_COOLDOWN`, 1 minute) is true — otherwise the route itself had no limit on regenerating tokens/re-sending mail, independent of the UI hiding the resend button once confirmed. New accounts created programmatically without a real inbox (the deleted-user placeholder, seeded demo accounts) set `skip_confirmation_email = true` before saving.
- Self-service account deletion (`AccountsController#destroy`) requires re-entering the current password (`current_user.authenticated?`) and refuses if `User#sole_admin?` is true (raises `User::SoleAdminError` if called directly) — otherwise it would permanently lock every `/admin` route with no recovery path short of a console. Otherwise calls `User#delete_account!`: reassigns the user's contributed catalog books to `User.deleted_placeholder` (a lazily-created system account, email `deleted-user@community-bookshelf.invalid`, excluded from admin listings/counts via the `excluding_deleted_placeholder` scope and from direct `admin/users/:id` access) in a transaction, explicitly destroys the user's readings via `Reading.unscoped` (readings' default scope hides soft-deleted rows from the `dependent: :destroy` association, so a soft-deleted one left behind would otherwise still reference the user's id and fail the final `destroy!` on its FK), then destroys the user, cascading to shelves/role_assignments via existing `dependent: :destroy`. `sign_out` must run *before* `delete_account!` — Clearance's `sign_out` writes a fresh `remember_token` to the current user, which raises `FrozenError` against an already-destroyed record if the order is reversed.
- `User.deleted_placeholder`'s `find_by || create!` rescues both `ActiveRecord::RecordNotUnique` and `ActiveRecord::RecordInvalid` and retries via `find_by!` — concurrent first-time calls can lose the race either at the DB's unique index or at the `uniqueness: true` validation depending on exact timing (verified both are reachable), unlike a plain `rescue RecordNotUnique` which only covers one of the two.
- Avatar upload validates content type (PNG/JPEG/WEBP) and a 5MB size cap in `User`'s own `validate` callback rather than a gem (no `image_processing`/libvips dependency) — avatars render at their original resolution, constrained by CSS, not an Active Storage variant. `AccountsController#update` only purges an existing avatar when `remove_avatar=1` *and* no new avatar was submitted in the same request — otherwise a stale checked checkbox would silently discard an avatar just uploaded in that same submit.
- `User#favorite_genre_list` is a comma-separated virtual attribute mirroring `Book#tag_list` — same `find_or_create_by`/`RecordNotUnique` reuse pattern, but always creates tags as `category: "genre"` and is backed by its own join model (`FavoriteGenre`), not `Tagging` (which is book-scoped). Edited on `/account/edit`, shown on the public profile.
- `ProfilesController#show` (`/users/:id`) is any member's public profile page — `UserPolicy#show?` allows any signed-in user (unlike `edit?`/`update?`/`destroy?`, which stay pinned to `record == user` for `AccountsController`). Excludes the deleted-user placeholder via `excluding_deleted_placeholder` (404s if requested directly). Shows finished/currently-reading counts and up to 5 recent reviews where `is_review_public?` — private reviews never appear here even to the profile's own readings list, since this view has no owner-only branch.

### Social — follows
- `Follow` (`follower_id`/`followed_id`, both FK to `users`) backs `User#following`/`#followers` (`has_many :through`) and `User#following?`. A DB check constraint (`follower_id <> followed_id`) plus a model validation both block self-follows — the constraint is the real guard (defense at the DB layer, consistent with the uniqueness index also being DB-enforced), the validation exists so a self-follow attempt renders a normal `unprocessable_content`/error path instead of a raw `ActiveRecord::StatementInvalid`.
- `FollowsController` (`POST`/`DELETE /users/:user_id/follow`, nested under the profile route) always resolves `@followed_user` from `params[:user_id]`, never a `Follow` id — `destroy` looks it up via `current_user.active_follows.find_by!`, so a user can only ever unfollow their own follow relationship. `FollowPolicy#create?` additionally blocks following yourself at the authorization layer (belt-and-suspenders with the DB constraint above).

### Social — activity feed
- `Activity` (`user_id`, `reading_id`, `action` — `added_book`/`started_reading`/`finished_reading`/`reviewed`) is written by `Reading` callbacks, not created directly: `after_create` always logs `added_book`; `after_update` logs `started_reading`/`finished_reading` on `saved_change_to_status?`; `reviewed` only fires when a *blank* review becomes present *and* `is_review_public?` — editing existing review text, or making a review public without changing its text, does not re-fire it, so the feed doesn't spam on every edit.
- `Reading#soft_delete` explicitly destroys its `activities` before setting `deleted_at` — soft delete doesn't run `dependent: :destroy` (that only fires on a real `destroy`), so without this a soft-deleted reading's activity would keep showing in followers' feeds pointing at a reading the owner believes they removed.
- `/feed` (`ActivitiesController#index`) queries `Activity.where(user: current_user.following)` — no policy class; it's inherently scoped to the signed-in user's own follow list, not a specific authorizable record. Activity entries link to the book, not the reading itself — `ReadingPolicy#show?` doesn't grant followers access to someone else's reading page.

### Social — likes & comments on reviews
- `ReadingPolicy#show?` was widened from owner-or-moderator to also allow any signed-in user when the reading has a public, non-blank review (`is_review_public? && review.present?`) — a blank review with the (default-true) `is_review_public` flag stays owner/moderator-only, since opening the page on that flag alone would leak dates/progress/format for readings the user never intended to share. The moderator branch is a separate `||` term, not gated by the deleted/public checks, so moderators keep the pre-existing ability to view a soft-deleted reading's show page (e.g. from `admin/readings`).
- `ReviewLike`/`ReviewComment` both belong to `reading` (not `book`) — likes/comments are on a specific member's review, not the book. `ReviewLikePolicy#create?`/`ReviewCommentPolicy#create?` re-check `is_review_public? && review.present?` independently of `ReadingPolicy#show?` (a moderator can view a private review's page but still shouldn't be able to like/comment on it as if it were public). Comment deletion allows the author or `moderator_or_above?`, matching the moderation pattern used elsewhere; likes only the liker (no moderator override — a like isn't abuse-prone the way a comment body is).
- `Reading#soft_delete` also destroys `review_likes`/`review_comments` (same reasoning as `activities` above — soft delete skips `dependent: :destroy`).

### Social — buddy reads
- `BuddyRead` (`book_id`, `initiator_id`/`partner_id`, `status`: `pending`/`accepted`/`declined`/`cancelled`/`completed`, default `"pending"`) is a private pairing between two members reading one book together — MVP scope, not full progress-sync: each participant's own `Reading` still tracks their own status/progress as normal. A DB check constraint blocks `initiator_id == partner_id`, mirroring `Follow`'s no-self pattern.
- `BuddyReadPolicy` gates everything on `record.participant?(user)` (true if `user` is either `initiator` or `partner`) — there's no moderator override, since this is a private two-person space, unlike reviews/clubs which are public-by-default. `BuddyReadsController#update` doesn't blindly apply `params[:status]`: only the *partner* can move `pending` → `accepted`/`declined` (the initiator can't accept their own invite), either participant can `cancel` from `pending` or `accepted`, and only `accepted` → `completed` is allowed — invalid combinations are silently no-ops (redirects without changing state) rather than raising, since this is a small fixed state machine, not a full workflow gem.
- `BuddyReadMessage` is a flat per-pair discussion thread (`buddy_read_messages`, ordered by `created_at`) — no threading/replies, matching the "MVP: paired reading + shared thread" scope decision over full synced-progress milestones. `BuddyRead#messageable?` (`!declined? && !cancelled?`) gates both `BuddyReadMessagePolicy#create?` and the message form — a declined or cancelled pairing stops accepting new messages, but `pending`/`accepted`/`completed` can still be messaged (invites and post-completion remarks are both legitimate).
- The buddy-reads index view always renders both `initiator.display_name` and `partner.display_name` (not a conditional "other participant" helper) — Bullet's N+1 detector flags an eager-loaded association that a request path never touches, and a per-row conditional (`other_participant(current_user)`) only ever touches one side of the `includes(:initiator, :partner)`, tripping it. `BuddyRead#other_participant` is still used on the show page, where only one side is displayed per request.
- `BuddyReadsController#show` re-queries with `.includes(:book, :initiator, :partner)` *after* `authorize` succeeds, rather than eager-loading in `set_buddy_read` up front — `set_buddy_read` is shared with `#update`, which never renders those associations, and an unauthorized `#show` request redirects before rendering too; eager-loading in either of those paths would be genuinely unused and Bullet correctly flags it. The extra query on a successful show is the tradeoff for keeping `set_buddy_read` shared and simple.
- `Book has_many :buddy_reads, dependent: :destroy` (added alongside `readings`/`taggings`/`shelf_books`, which all follow the same pattern) — without it, deleting a book that's ever had a buddy read created for it (in any status; buddy reads are never cleaned up on decline/cancel/complete) would raise an unhandled `ActiveRecord::InvalidForeignKey`, since `BooksController#destroy` calls `@book.destroy!` unrescued.

### Social — book clubs
- `Club` centers on one `book` (not a general standing group) — creating one auto-joins the creator via an `after_create` callback (`ClubMembership`), so `club.members` is never empty. `ClubPolicy#index?`/`#show?` are open to any signed-in member (clubs are discoverable/joinable by anyone, unlike `BuddyRead`); `#update?`/`#destroy?` are creator-or-moderator, the same pattern as comment/post moderation elsewhere.
- Spoiler gating on `ClubPost#visible_to?(user)` is **status-based**, not page/chapter-based — a post flagged `spoiler` stays hidden from a member until they have a `Reading` with `status: finished` for the club's book (checked live via `Reading.exists?`, not cached on the membership). This was a deliberate scope decision: `Reading` only has a status enum, no page/percent-threshold field fine-grained enough to gate per-chapter, so a real "you've read past this point" mechanic was out of scope. The post's own author and moderators always see it regardless of their reading status.
- `ClubPostPolicy#create?` requires `record.club.member?(user)` — posting is membership-gated even though *viewing* the club (and its non-spoiler posts) isn't, matching the "join to participate, browse to preview" pattern implied by the club index/show being open to all signed-in users.
- `User#delete_account!` reassigns `created_clubs` to the deleted-user placeholder, the same treatment as `books` — without it, `destroy!` hit `ActiveRecord::InvalidForeignKey` via `clubs.created_by_id` for anyone who'd ever created a club (reproduced directly before fixing). `User has_many :club_posts, dependent: :destroy` similarly closes the same failure mode via `club_posts.user_id` for anyone who'd ever posted in one — neither had a caught test until both were added here.
- `ClubsController#index` computes member counts with one grouped `ClubMembership.where(club_id: ...).group(:club_id).count` query rather than `club.members.count` per row in the view. `ClubsController#show` precomputes `@viewer_has_finished_book` once and passes it into `ClubPost#visible_to?(user, viewer_has_finished_book:)` — every spoiler post on the same club/viewer would otherwise run an identical `Reading.exists?` query.
- `ClubMembershipsController#create`/`#destroy` follow the same result-checking/idempotent pattern as `FollowsController` and `ReviewLikesController` — but note `ClubMembershipPolicy#create?` already blocks a same-request double-join (`!record.club.member?(user)`), so the `save` check there is defense against a concurrent-request race, not a reachable UI double-click path the way it is for `Follow`.

### Gamification
- `ReadingChallenge` (`user_id`, `year`, `goal`) is one member-set book-count goal per calendar year (unique per user/year). `#books_finished_count` queries `user.readings.finished.where(finished_on: ...)` for that year live rather than caching a counter — the same "compute on read" tradeoff `Book#similar_books`/`User#current_streak` make elsewhere, and cheap at this scale. `ReadingChallengePolicy` pins ownership (`record.user == user`) the same way `ShelfPolicy` does; `ReadingChallengesController` is scoped to `current_user.reading_challenges` like `ShelvesController`, so a non-owner id 404s before `authorize` is ever reached.
- `User::STREAK_GAP_DAYS` (30) is the max gap between two consecutive finished books for `User#current_streak` to still count them as one streak — deliberately book-based, not calendar-day-based (no "did you read today" tracking exists, only finish dates), so tiers read as "N books in a row" rather than "N-day streak". A most-recent finish older than the gap window itself resets the streak to zero, even though it was once part of one.
- `Badge` is a plain-Ruby registry (`Badge::DEFINITIONS`), not a database table — there's no admin UI to manage badges, and each definition is just a name/description plus a `criteria` lambda checked against a `User`. `UserBadge` (`user_id`, `badge_key`, `awarded_at`, unique per user/badge_key) is the only DB-backed piece; its `badge_key` is validated against `Badge::DEFINITIONS` so a typo'd or removed key can't be persisted.
- Badges are awarded by `User#award_badges!`, which only ever adds rows — once earned, a badge is never revoked (e.g. editing a challenge's goal upward after completion doesn't strip the `challenge_completed` badge). It's called from `Reading`'s `after_save` (`saved_change_to_status? || saved_change_to_review?` — covers finishing a book, DNF, and adding a review) and from `ReadingChallenge`'s `after_save` (covers a challenge becoming completed on creation/edit without a new reading event, e.g. lowering the goal below an already-met count).
- Streak, badges, and the current year's challenge progress render in two places: privately on `/account/edit` (via `AccountsController#edit`'s `@user`) and publicly on `/users/:id` (`ProfilesController#show` sets `@current_streak`/`@badges`/`@current_year_challenge` off `@profile_user`) — mirroring how favorite genres and finished/reading counts are already shown in both places.

### Stats & analytics
- `/stats` (`StatsController#show`) is the personal stats page — no policy class, inherently scoped to `current_user` like `ActivitiesController`'s `/feed`. Its three chart datasets are computed on `User`: `#genre_breakdown` (finished-book genre tag counts, via `Tag.genre.joins(books: :readings).merge(Reading.finished)`), `#books_finished_by_month` and `#pages_read_by_month` (both `group_by_month(:finished_on, last: 12)` off `readings.finished`, the latter summing `books.page_count`).
- `groupdate`'s `group_by_month(..., last: 12)` always backfills every month in the range with a zero count, so a hash's presence/size can't be used to detect "no data yet" — `books_finished_by_month`/`pages_read_by_month` are always non-empty even for a user with zero finished readings. `StatsController#show` computes a separate `@has_finished_readings` (`readings.finished.where.not(finished_on: nil).exists?`) for the view's empty-state checks on those two charts; `genre_breakdown`'s hash is genuinely empty with no matching tags, so it doesn't need the same treatment.
- Charts render via Chartkick + Chart.js (`pie_chart`/`column_chart`/`line_chart` view helpers) — the JS side is wired with a single `import "chartkick/chart.js"` in `app/javascript/application.js` (this subpath import self-registers the Chart.js adapter and sets up the global `Chartkick` object; importing `chartkick` and `chart.js/auto` separately does not wire them together and silently renders nothing).
- The admin dashboard (`Admin::DashboardController#index`) adds three site-wide trend line charts (new users, books added, readings logged) alongside its existing totals/leaderboard, each a `group_by_month(:created_at, last: 12)` count — same backfill-zeros behavior as above, but there's no empty-state branch needed since admin trend charts are always shown regardless of whether any given month has data.

### Notifications
- `Notification` (`recipient_id`, `actor_id`, polymorphic `notifiable`, `notification_type`: `new_follower`/`review_comment`/`club_post`, `read_at`, `digested_at`) is created by `after_create` callbacks on the source model, not directly: `Follow` notifies the followed user, `ReviewComment` notifies the reading's owner (skipped when you comment on your own review), `ClubPost` notifies every other club member (skipped for the poster). Each source model declares the reverse polymorphic association (`has_one`/`has_many :notification(s), as: :notifiable, dependent: :destroy`) so unfollowing, deleting a comment, or deleting a post also removes the notification it generated — including via `User#delete_account!`'s existing cascades through `active_follows`/`review_comments`/`club_posts`, with no extra cleanup code needed there. `User has_many :notifications, foreign_key: :recipient_id, dependent: :destroy` separately cleans up a deleted user's own inbox.
- `read_at` (viewed in-app) and `digested_at` (already included in a digest email) are tracked independently — reading a notification on the site doesn't stop it from being mailed in that day's digest, and vice versa, since a user might check email before ever opening the app.
- `/notifications` (`NotificationsController`) — no policy class, same `current_user`-scoped pattern as `/feed` and `/stats`. `#index` lists them newest-first; `#update` (the link each row points to) marks one read and redirects straight to the underlying resource (`NotificationsHelper#notification_path_for`/`#notification_url_for` map `notification_type` to the follower's profile, the reading, or the club — two variants because Rails mailer views need `_url` helpers, not `_path`); `#mark_all_read` bulk-clears everything unread. The navbar bell (`layouts/application.html.erb`) shows `current_user.notifications.unread.count`, capped at "9+".
- `Notification#message` only dereferences `notifiable` for `review_comment`/`club_post`, not `new_follower` — Bullet's unused-eager-load heuristic flags `NotificationsController#index`'s `includes(:notifiable)` on a page that happens to be all-follower notifications even though the include is needed once the other types are mixed in, so it's safelisted in `config/initializers/bullet.rb` alongside the existing `Series`/`Shelf` entries.
- `SendNotificationDigestsJob` (recurring via `solid_queue`'s `config/recurring.yml`, daily) finds users with `not_yet_digested` notifications, sends each one `NotificationsMailer#digest`, and marks those specific notifications' `digested_at` — a user who reads everything in-app before the job runs still gets skipped, since the query is on `digested_at`, not `read_at`.

### Import & export
- `ReadingsController#export` (`GET /readings/export.csv`) streams `current_user.readings` as CSV via `send_data` — no policy class, same `current_user`-scoped pattern as `/feed`/`/stats`/`/notifications`. Requires `gem "csv"` in the Gemfile; Ruby removed `csv` from the default gems bundled with Rails/Ruby itself as of 3.4, so `require "csv"` alone raises a `LoadError` without it.
- `GoodreadsImportsController#new`/`#create` (`/goodreads_import`, a singular resource) parses an uploaded Goodreads "Export Library" CSV via the `GoodreadsImport` service object — no policy class either, same scoping. Rejects a missing file and anything over `MAX_FILE_BYTES` (5MB) before parsing.
- `GoodreadsImport` matches each row to an existing catalog `Book` by ISBN (`ISBN13` preferred over `ISBN`) first, then by case-insensitive title+author, before creating a new one — same "shared catalog" model `BookSearchController`/the manual add-book form use. Rows missing a title or author are skipped. Goodreads exports wrap ISBNs in Excel's `="..."` literal-string quoting, which trips a strict CSV parser ("Illegal quoting") — `CSV.parse(..., liberal_parsing: true)` is required to read the file at all, and `clean_isbn` strips the `="` `"` characters back out afterward.
- A row is matched to an existing **active** `Reading` (default scope — soft-deleted ones don't count) by `user` and `book` before being applied — if one already exists the row is skipped rather than overwritten, so re-uploading the same export is a no-op instead of piling up duplicate readings. A book the member soft-deleted from their shelf isn't "already on it", so re-importing it creates a fresh `Reading` rather than being silently skipped (a real bug in an earlier version of this feature, caught in Copilot PR review — matching via `Reading.with_deleted` treated a soft-deleted row as blocking, contradicting the "skip only if already on your shelf" behavior).
- This lookup is `Reading.find_or_initialize_by(user: user, book: book)` called on the class, **not** `user.readings.find_or_initialize_by(...)` through the association if `.with_deleted`/`.unscoped` is ever reintroduced here — chaining `.with_deleted` (`scope :with_deleted, -> { unscoped }`) off an association proxy calls `unscoped` on that relation, which drops the association's own `user_id` scoping along with the default scope, silently building a reading with `user_id: nil` that then fails to save. Reproduced directly while building this feature; do not reintroduce the association-chained form.
- `Exclusive Shelf` maps `read`/`currently-reading`/`to-read` to `finished`/`reading`/`want_to_read`; anything else (a custom Goodreads shelf) defaults to `want_to_read` rather than raising, since a `Reading` always requires a status.
- `Reading#skip_activity_logging` (transient `attr_accessor`, not persisted) is set by `GoodreadsImport#apply_row` before every save — without it, each imported reading's `after_create` would fire `record_added_book_activity` same as a normal manual add, so importing dozens of already-read books would blast every follower's `/feed` at once. Badges still award normally (`award_badges` isn't gated by the flag) since a badge reflects genuine reading history regardless of how it was logged.
- Uploaded CSV content typically arrives ASCII-8BIT (binary) via Rack's multipart parser — comparing/stripping a UTF-8 BOM literal against it directly raises `Encoding::CompatibilityError` for any file containing non-ASCII bytes (e.g. an author name like "José"). `GoodreadsImport#normalize_encoding` strips the BOM at the byte level first, then force-encodes to UTF-8 and `scrub`s invalid byte sequences rather than raising.

### JSON API
- `/api/v1/books`, `/api/v1/readings` (full CRUD) are backed by `Api::V1::BaseController`, which does **not** inherit `ApplicationController` — it skips Clearance/session auth entirely in favor of a bearer token (`Authorization: Bearer <token>`) resolved against `User#api_token` (`has_secure_token`, plaintext, not hashed — unlike a password, it's meant to be used directly as a credential, auto-generated `before_create` for every new user). `current_user` on this controller tree is the token-resolved user, not Clearance's session-based one — same method name deliberately, so the existing `BookPolicy`/`ReadingPolicy`/`policy_scope` classes work unmodified for both the HTML and API controllers with zero policy-layer changes. `Api::V1::BaseController` forces `request.format = :json` on every request regardless of `Accept` header, since this controller tree only ever renders jbuilder JSON.
- Every `/api/v1/*` action requires a valid token, including `Book`'s nominally-public `index?`/`show?` — there is no anonymous API access, even though the HTML `BooksController` allows it. Pundit failures render `{"error": "..."}` with 403 (not the HTML flow's flash+redirect); a missing/invalid token renders the same shape with 401.
- Error shape: `{"error": "message"}` for single-cause failures (401/403/404), `{"errors": ["msg", ...]}` for `ActiveModel::Errors#full_messages` on 422 validation failures — the two keys are the entire contract, chosen because Pundit/auth/not-found failures are always one categorical reason while model validation is inherently a list.
- `Api::V1::BooksController#create` reuses the same `OpenLibraryService.work_detail(@book.open_library_key)` enrichment as the HTML `BooksController#create`, for behavioral parity. `Api::V1::ReadingsController#destroy` calls `@reading.soft_delete` (matching the HTML controller), not `destroy!`.
- Index actions (`Api::V1::BooksController#index`/`Api::V1::ReadingsController#index`) deliberately don't eager-load `added_by`/`book` — the index jbuilder views only serialize foreign-key ids, not nested associations (to avoid duplicating data across a paginated list), so an eager-load there would be genuinely unused and Bullet correctly flags it. `Api::V1::ReadingsController#show` does render a nested book, loaded per-request there.
- `User#regenerate_api_token` (from `has_secure_token :api_token`) is self-service via `POST /account/regenerate_api_token` (`AccountsController#regenerate_api_token`, `UserPolicy#update?`) — regenerating immediately invalidates the prior token (no grace period/rotation overlap). The full token is only ever shown once, via `flash[:api_token]`, immediately after regeneration; `/account/edit` otherwise shows only a masked prefix.
- Rate limiting via `rack-attack` (`config/initializers/rack_attack.rb`) throttles `/api/*` per-token (120 req/min), not per-IP, since every successfully-authenticated request already carries a token — plus a secondary per-IP throttle (30 req/min) on unauthenticated `/api/*` hits, guarding the token check itself from brute-forcing. No exemption for moderator/admin tokens — a runaway script is equally disruptive regardless of the token owner's role. `rack-attack`'s Railtie auto-registers its middleware; no explicit `config.middleware.use` needed.
- No API versioning beyond `v1` exists yet — `Api::V1::BaseController` is the only version; a breaking change would need a new `Api::V2` namespace rather than mutating `v1` in place.
- Fixtures bypass AR callbacks, so `has_secure_token`'s `before_create` never runs for fixture users — `test_helper.rb`'s `auth_headers(user)` calls `user.regenerate_api_token` lazily if blank, mirroring `sign_in_as`'s existing fixture-callback workaround for `remember_token`.

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
