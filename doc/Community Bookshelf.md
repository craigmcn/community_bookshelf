# Community Bookshelf
A shared reading list app where users can log books they've read, rate them, and see what others are reading. Admins can manage users and moderate content.


## Core models

1. User (email, password, role)
2. Book (title, author, cover_url, added_by)
3. Reading (user, book, status: want_to_read/reading/finished, rating, review)

## Features by concern

Authentication:

* Sign up with email/password
* Log in / log out
* Password reset

Roles (store as an enum on User: `member`, `moderator`, `admin`):

* Member: manage their own readings, view everyone's shelves
* Moderator: edit/delete any book entry *(review removal not yet implemented — only admins can delete other users' readings)*
* Admin: full access including user management

Authorized views:

* Public: book listing, individual book pages with aggregate ratings
* Member-only: personal shelf, add/edit/delete own readings
* Moderator+: edit any book, delete any review
* Admin-only: admin dashboard

Admin dashboard:

* User list with role assignment
* Site stats (total books, total readings, most popular books)

Why this works well for the exercise

* Simple enough to build twice without burnout
* Touches real-world auth/authz patterns (role enum, policy-based view toggling)
* Has a clear public/private split so authorization has meaningful consequences
* The admin dashboard gives you a distinct UI surface to compare between plain Rails and the framework
* No complex domain logic -- the complexity is in the access control layer, which is exactly what you're studying

Rails implementation (completed)

1. `clearance` — authentication (sessions, password reset, sign-up/sign-out)
2. `pundit` — authorization (role-based policies, `Pundit::NotAuthorizedError` rescue in `ApplicationController`)
3. Namespaced `/admin` routes with `Admin::BaseController` enforcing `require_admin`
4. Enum-based role checking in `BookPolicy` and `ReadingPolicy`
5. Custom `SessionsController < Clearance::SessionsController` for role-based redirect after sign-in (admins → `/admin`, everyone else → `/`)
