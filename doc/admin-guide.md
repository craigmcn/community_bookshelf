# Admin Guide

Admins have every moderator permission, plus the admin dashboard and user
role management. This guide covers what's added on top of the
[Moderator Guide](moderator-guide.md) — read that (and the
[Member Guide](member-guide.md) before it) for the rest of the app's
features.

## Admin Dashboard

`/admin` (also linked as "Admin Dashboard" once you're signed in as an
admin) shows community-wide stats:

- Total users, total books, and total readings logged.
- **Most-Read Books** — the top 5 books ranked by number of readings logged
  against them, linked through to each book's page.

This page is admin-only; moderators are redirected/forbidden if they try to
visit it directly.

## Managing users and roles

`/admin/users` lists every user by email, with their current roles.

- Click **Edit Roles** (or navigate to a user's edit page) to check/uncheck
  the `member`, `moderator`, and `admin` roles for that user.
- A user can hold multiple roles at once — e.g. a user can be both
  `moderator` and `admin` simultaneously. Removing every role from a user
  leaves them without member-level permissions, so be careful clearing all
  checkboxes.
- There's no separate "promote"/"demote" action — role changes are just
  toggling checkboxes and saving.

This screen is admin-only; moderators cannot see or reach it.

## Everything else

Book/series management and the reviewed-readings moderation queue
(`/admin/readings`) work exactly as described in the
[Moderator Guide](moderator-guide.md) — admins have the same access there as
moderators, nothing extra.
