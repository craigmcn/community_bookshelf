# Community Bookshelf

A shared reading list app where users log books they've read, rate them, and see what others are reading. Moderators and admins manage content.

## Core models

1. **User** — email, password (via Clearance), role enum (`member: 0`, `moderator: 1`, `admin: 2`)
2. **Book** — title, author, cover_url, added_by (User)
3. **Reading** — user, book, status (`want_to_read` / `reading` / `finished`), rating (1–5), review (text), deleted_at (soft delete timestamp)

## Features by concern

### Authentication

- Sign up with email/password
- Log in / log out
- Password reset
- Implemented via **Clearance**; `SessionsController` overrides `url_after_create` to send admins to `/admin` and everyone else to `/`

### Roles

Stored as an integer enum on `User`. Every new user defaults to `member`. The `moderator_or_above?` helper returns true for both `moderator` and `admin`.

| Role | Permissions |
|------|-------------|
| Member | Log and edit their own readings; view all books and community shelves |
| Moderator | All of the above, plus edit/delete any book or reading; access `/admin/readings` |
| Admin | Full access including user role management and the admin dashboard |

### Authorization (Pundit)

Policies live in `app/policies/`. `ApplicationController` rescues `Pundit::NotAuthorizedError` and redirects with a flash alert.

**BookPolicy**

| Action | Who |
|--------|-----|
| index, show | Everyone (public) |
| create | Any signed-in user |
| update, destroy | Moderator+ |

**ReadingPolicy**

| Action | Who |
|--------|-----|
| show | Owner or moderator+ |
| create | Any signed-in user |
| edit, update | Owner or moderator+; blocked if reading is soft-deleted |
| destroy (soft delete) | Moderator+ only; blocked if already deleted |

`ReadingPolicy::Scope` returns `scope.all` for moderator+, `scope.where(user: user)` for members.

### Soft delete

`Reading#soft_delete` stamps `deleted_at` with the current time. Deleted readings remain in the database and are visible to admins in the review moderation view (with a "deleted" badge), but cannot be edited or deleted again.

### Authorized views

- **Public**: book listing, individual book pages with community readings
- **Member-only**: personal shelf (`/readings`), add/edit own readings
- **Moderator+**: edit any book, soft-delete any reading, review moderation at `/admin/readings`
- **Admin-only**: admin dashboard, user role management

### Open Library integration

`BookSearchController` at `/book_search` delegates to `OpenLibraryService`, which queries the Open Library search API via Faraday and returns up to 10 results (title, author, cover image). A Stimulus controller populates the new-book form from the results without a full page load.

## Admin area

`Admin::BaseController` enforces `require_moderator_or_above`. Actions that need full admin access call `require_admin` additionally.

| Route | Controller | Access |
|-------|-----------|--------|
| `GET /admin` | `Admin::DashboardController#index` | Admin only |
| `GET /admin/users` | `Admin::UsersController#index` | Admin only |
| `GET /admin/users/:id/edit`, `PATCH /admin/users/:id` | `Admin::UsersController` | Admin only |
| `GET /admin/readings` | `Admin::ReadingsController#index` | Moderator+ |

**Dashboard** shows total users, total books, total readings logged, and the five most-read books.

**Users** lists all users with a role-assignment edit form.

**Readings (review moderation)** lists all readings that have a review text, ordered by last updated, with edit and soft-delete actions. Soft-deleted readings are shown with a "deleted" badge; edit/delete buttons are hidden for them.

## Rails implementation

1. `clearance` — authentication (sessions, password reset, sign-up/sign-out)
2. `pundit` — authorization (role-based policies, `Pundit::NotAuthorizedError` rescue in `ApplicationController`)
3. Namespaced `/admin` routes with `Admin::BaseController` enforcing `require_moderator_or_above`; dashboard and users routes additionally enforce `require_admin`
4. Enum-based role checking in `BookPolicy` and `ReadingPolicy`; `moderator_or_above?` helper on `User`
5. Custom `SessionsController < Clearance::SessionsController` for role-based redirect after sign-in
6. Soft delete on `Reading` via `deleted_at` timestamp; policy blocks re-editing or re-deleting soft-deleted records
7. `OpenLibraryService` + `BookSearchController` for live book search via the Open Library API
