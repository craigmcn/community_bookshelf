# Community Bookshelf — Build Log

A running record of steps taken to build this app, in order.

---

## Step 1 — Generate Rails app (2026-06-03)

Generated a new Rails 8.1 app with PostgreSQL, Hotwire (Turbo + Stimulus), and CSS/JS bundling via Propshaft + jsbundling + cssbundling.

```bash
rails new community_bookshelf -d postgresql -j esbuild --css bootstrap --skip-active-storage --skip-action-cable
```

Key gems included out of the box:
- `rails ~> 8.1.3`
- `pg ~> 1.1` — PostgreSQL adapter
- `turbo-rails` + `stimulus-rails` — Hotwire
- `solid_cache` + `solid_queue` — DB-backed cache and job queue
- `kamal` — Docker-based deployment
- `dotenv-rails` (development) — environment variable management
- `brakeman` + `bundler-audit` — security tooling
- `rubocop-rails-omakase` — linting

---

## Step 2 — Create core models and migrations (2026-06-03)

Generated three models with their migrations:

### Users
```bash
rails generate model User email:string password_digest:string role:integer
```
- `email` — unique index
- `password_digest` — for `has_secure_password`
- `role` — integer enum (admin/member/etc.)

### Books
```bash
rails generate model Book title:string author:string cover_url:string added_by:references
```
- `added_by` — foreign key to `users` (tracks who added the book to the shelf)

### Readings
```bash
rails generate model Reading user:references book:references status:integer rating:integer review:text
```
- Join model between users and books
- `status` — integer enum (e.g. want_to_read / reading / finished)
- `rating` — numeric rating
- `review` — free-text review

Ran migrations:
```bash
rails db:create db:migrate
```

---

## Step 3 — Wire up model associations and enums (2026-06-03)

Added associations, enums, validations, and `has_secure_password` to models.

**Fixes made during migration:**
- `t.references :added_by` in the Books migration inferred a target table of `added_bies`, which doesn't exist. Fixed by specifying `foreign_key: { to_table: :users }` explicitly.
- `role` column on Users set to `default: 0, null: false` so every user starts as a member.
- Uncommented `gem "bcrypt"` in Gemfile and ran `bundle install` (required by `has_secure_password`).

**User** (`app/models/user.rb`)
- `has_secure_password`
- `has_many :readings, dependent: :destroy`
- `has_many :books, foreign_key: :added_by_id`
- `enum :role, { member: 0, moderator: 1, admin: 2 }, default: :member`
- Validates email presence and uniqueness

**Book** (`app/models/book.rb`)
- `belongs_to :added_by, class_name: "User"`
- `has_many :readings, dependent: :destroy`
- Validates title and author presence

**Reading** (`app/models/reading.rb`)
- `belongs_to :user`
- `belongs_to :book`
- `enum :status, { want_to_read: 0, reading: 1, finished: 2 }`
- `enum :rating, { one: 1, two: 2, three: 3, four: 4, five: 5 }`
- Validates status presence

Smoke-tested all associations and enums in `rails console` — all passing.

---

## Step 4 — Authentication, authorization, controllers, and views (2026-06-03)

### Authentication — Clearance

Added `clearance` gem. Replaced `has_secure_password` on User with `include Clearance::User`. Clearance manages sessions, password resets, and mailer views.

Routes added:
```ruby
resources :passwords, controller: "clearance/passwords", only: [:new, :create, :edit, :update]
resource  :session,   controller: "clearance/sessions",  only: [:new, :create, :destroy]
resources :users,     controller: "clearance/users",     only: [:new, :create]
```

`ApplicationController` includes `Clearance::Controller` and enforces `before_action :require_login` globally.

### Authorization — Pundit

Added `pundit` gem. `ApplicationController` includes `Pundit::Authorization` and rescues `Pundit::NotAuthorizedError` with a flash redirect.

Policies created:

**`ApplicationPolicy`** — default deny on all actions (Pundit generator default).

**`BookPolicy`**
- `index?` / `show?` — public
- `create?` — any signed-in user
- `update?` / `destroy?` — moderator or admin only
- `Scope#resolve` — returns all books

**`ReadingPolicy`**
- `create?` — any signed-in user
- `update?` / `destroy?` — record owner or admin
- `Scope#resolve` — scoped to current user's readings only

> **Note:** The original plan intended moderators to be able to remove any review. `ReadingPolicy#destroy?` is currently `record.user == user || user&.admin?` — moderators are not included and can only delete their own readings. To implement the original intent, add `user&.moderator?` to the condition.

### Controllers

Generated scaffold controllers for `Books` and `Readings`, then customized:
- `ReadingsController#index` scopes to `current_user.readings`
- `ReadingsController#reading_params` whitelists `user_id, book_id, status, rating, review`

Admin namespace:
- `Admin::BaseController < ApplicationController` — `before_action :require_admin` (renders 403 if not admin)
- `Admin::DashboardController` — renders the admin dashboard
- `Admin::UsersController` — lists all users, allows role editing

### Routes

```ruby
root "readings#index"

namespace :admin do
  root "dashboard#index"
  resources :users, only: [:index, :edit, :update]
end
```

### Views

Built Bootstrap-styled views for sign-in, sign-up, books (index/show/new/edit), readings (index/show/new/edit), and admin (dashboard, user list/edit). Password reset views copied from Clearance defaults and restyled.

---

## Step 5 — Role-based redirect after sign-in (2026-06-03)

Overrode Clearance's sessions controller to redirect users based on role after login.

Created `app/controllers/sessions_controller.rb`:
```ruby
class SessionsController < Clearance::SessionsController
  private

  def url_after_create
    current_user.admin? ? admin_root_path : root_path
  end
end
```

Updated routes to point `:session` at the custom controller:
```ruby
resource :session, controller: "sessions", only: [:new, :create, :destroy]
```

Admins land on `/admin` after sign-in; all other roles land on `/`.

---

## Step 6 — letter_opener + Forgot Password styling (2026-06-03)

### letter_opener

Added `gem "letter_opener"` to the development group. Configured `development.rb`:
```ruby
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
```

Password reset emails now open automatically in the browser during development instead of requiring an SMTP server.

### Forgot Password page

Restyled `app/views/passwords/new.html.erb` to match the sign-in card layout — Bootstrap card shell, `form-control` inputs, `btn btn-primary` submit button, and a "Back to Sign In" link.

---

## Step 7 — Change Password styling + mailer port fix (2026-06-03)

### Change Password page

Restyled `app/views/passwords/edit.html.erb` to match the Forgot Password card layout — Bootstrap card shell, `form-control` password input, `btn btn-primary` submit, and a "Back to Sign In" link.

### Mailer port fix

`development.rb` had the mailer URL port hardcoded to `3000`. Fixed to read from the environment:
```ruby
config.action_mailer.default_url_options = { host: "localhost", port: ENV.fetch("PORT", 3000) }
```
The app runs on `PORT=3020` (set in `.env`), so password reset links now use the correct port.

---

## Step 8 — "Add to shelf" / "View on shelf" on books#show (2026-06-03)

Added a contextual shelf button to `app/views/books/show.html.erb`:

- **Signed in, book already on shelf** — "View on shelf" (green) links to the user's existing `readings#show`
- **Signed in, book not on shelf** — "Add to shelf" (blue) links to `readings#new?book_id=<id>`
- **Not signed in** — no button shown

`BooksController#show` sets `@user_reading = current_user&.readings&.find_by(book: @book)`. The safe navigation handles the unauthenticated case since `books#show` allows public access (`skip_before_action :require_login`).

`ReadingsController#new` initializes `@reading = Reading.new(book_id: params[:book_id])` so the book dropdown is pre-selected when arriving from the button.
