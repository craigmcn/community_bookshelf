# Moderator Guide

Moderators have every member permission, plus content-management powers over
books, series, and readings across the whole community. This guide covers
what's added on top of the [Member Guide](member-guide.md) — read that first
for the base reading/list/browsing features.

## Managing books

Unlike regular members, you can:

- **Edit any book** — including ones you didn't add — from its page's
  **Edit** button.
- **Delete any book** from its page's **Delete** button. Deleting a book is
  permanent (not a soft delete) and removes it from the catalog entirely.

## Managing series

Series creation and editing is moderator+ only:

- **Create a series** from `/series/new`.
- **Edit or delete a series** from its page.
- Assign a book to a series (and its position in the reading order) via the
  book's edit form.

## Managing readings

You can see and act on every member's reading, not just your own:

- On any book's page, the Community Readings table shows every reader's
  review text even when it's marked private — private reviews are hidden
  only from other members, never from moderators/admins.
- You can **edit** or **delete** any member's reading the same way you would
  your own, from the reading's show/edit page.
- Deleting someone else's reading is a soft delete, same as a member
  deleting their own — the record is hidden but recoverable.

## Moderating social features

- You can view any reading page regardless of its privacy setting or
  deletion state (members can only view a reading if it's their own or has a
  public, non-blank review) — same as the existing private-review exception
  above, extended to the page itself, not just the Community Readings table.
- You can **delete any comment** on a review, or **any post** in a book
  club, not just your own — the delete control appears on every
  comment/post when you're signed in as a moderator or admin.
- You always see club posts flagged as spoilers, regardless of your own
  reading progress on that club's book.
- Buddy reads are the one social feature moderators have no special access
  to — they're private between their two participants, with no
  moderator-visibility exception (there's nothing to moderate; report abuse
  the same way you would anything else in the app).

## Reviewed Readings queue

`/admin/readings` lists every reading that has review text, most recently
updated first — across all members, including soft-deleted ones (marked with
a red "deleted" badge). This is the moderation queue: use it to find and
review member feedback without having to browse every book individually.
From here you can jump to a reading's page, edit it, or delete it.

## What moderators can't do

- Access the admin dashboard (`/admin`) or the most-read-books leaderboard —
  admin only.
- Manage user accounts or assign roles — admin only.
- See another member's private lists ("shelves") — those stay private to
  their owner even from moderators.
