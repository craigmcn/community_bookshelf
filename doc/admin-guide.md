# Admin Guide

Admins have every moderator permission, plus the admin dashboard and user
role management. This guide covers what's added on top of the
[Moderator Guide](moderator-guide.md) — read that (and the
[Member Guide](member-guide.md) before it) for the rest of the app's
features.

## Admin Dashboard

`/admin` (also linked as "Admin Dashboard" once you're signed in as an
admin) shows community-wide stats:

- Total users, total books, and total readings logged. The "Users" total
  excludes the internal "Deleted user" placeholder account (see below).
- **Most-Read Books** — the top 5 books ranked by number of readings logged
  against them, linked through to each book's page.
- **Trends** — line charts of new users, books added, and readings logged
  per month, over the last 12 months, so you can see growth over time rather
  than just the current totals above.

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

### The "Deleted user" placeholder

When a member deletes their own account (see the Member Guide's Account
section), any books they'd added to the catalog are reassigned to a shared
"Deleted user" placeholder account rather than being removed — the catalog
is shared, community content, so it stays. That placeholder is a real row
in the users table, but it's deliberately excluded from this list (and from
the dashboard's user count) and can't be opened directly, even by URL —
it's not a real account and shouldn't be assigned roles or otherwise
managed.

### Deleting your own admin account

Self-service account deletion (from `/account/edit`) refuses to go through
if you're the only admin — otherwise the entire `/admin` area would become
permanently unreachable with no way back in short of a console. Promote
another member to admin first if you want to delete your own account.

## Everything else

Book/series management and the reviewed-readings moderation queue
(`/admin/readings`) work exactly as described in the
[Moderator Guide](moderator-guide.md) — admins have the same access there as
moderators, nothing extra.

The admin dashboard and user role management are website-only — there's no
API equivalent for either. Everything else (books, readings, moderator
actions) is available through the [API Guide](api-guide.md).
