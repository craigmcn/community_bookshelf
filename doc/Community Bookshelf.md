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
* Moderator: edit/delete any book entry, remove reviews
* Admin: full access including user management

Authorized views:

* Public: book listing, individual book pages with aggregate ratings
* Member-only: personal shelf, add/edit/delete own readings
* Moderator+: edit any book, delete any review
* Admin-only: admin dashboard

Admin dashboard:

* User list with role assignment
* Site stats (total books, total readings, most popular books)
* Moderation queue (flagged reviews)

Why this works well for the exercise

* Simple enough to build twice without burnout
* Touches real-world auth/authz patterns (role enum, policy-based view toggling)
* Has a clear public/private split so authorization has meaningful consequences
* The admin dashboard gives you a distinct UI surface to compare between plain Rails and the framework
* No complex domain logic -- the complexity is in the access control layer, which is exactly what you're studying

Rails implementation path (when you get there)

1. `devise` for authentication
2. `pundit` for authorization
3. Namespaced `/admin` routes with a base controller that enforces admin role
4. Enum-based role checking in policies
