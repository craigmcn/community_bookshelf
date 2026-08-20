# Member Guide

Members are any signed-up reader. This is the default role — everyone gets it
automatically when they sign up, and you keep it even if you're also a
moderator or admin.

## Getting started

- **Sign up** at `/sign_up` with an email and password.
- **Sign in / out** at `/sign_in`.
- **Forgot your password?** Use the "forgot password" link on the sign-in
  page to get a reset email.

You don't need to be signed in to browse the book catalog or read series
pages — signing in is only required to log readings, review books, or build
your own lists.

## Browsing books

- **Books** (`/books`) lists every book in the catalog. Filter by clicking a
  tag badge, or filter the URL with `?tag=<name>`.
- Each book's page shows its cover, author, ISBN, page count, publish date,
  series (with your place in the reading order), description, subjects, and
  tags.
- **Series** (`/series`) lists book series; a series page shows every book in
  it in reading order.
- **Adding a book**: any signed-in member can add a new book to the catalog.
  Search Open Library from the add-book form to pull in the title, author,
  cover, and description automatically, or enter details by hand.

## Logging readings ("My Shelf")

Your reading log lives at `/readings` ("My Shelf"). From a book's page, click
**Add to Shelf** (or **Log a Re-read** if you've already logged it once) to
create a new reading record. Each reading tracks:

- **Status** — Want to Read, Reading, Finished, or DNF (did not finish)
- **Rating** — 1 to 5 stars
- **Review** — free-text
- **Review visibility** — public by default; uncheck "public" to keep a
  review private. A private review only shows to you and to
  moderators/admins — everyone else sees "Review is private" on the book's
  Community Readings table.
- **Started on / Finished on** dates
- **Progress** — a percentage (0–100)
- **Format** — physical, ebook, or audiobook

You can log the same book more than once (for re-reads) — each reading is
its own record with its own status/rating/review.

**Editing and deleting**: you can edit or delete any reading you own at any
time. Deleting is a soft delete — the record is hidden from your shelf and
from other readers, but not permanently erased (a moderator/admin can still
see it).

## Community Readings

Every book's page has a "Community Readings" table showing what everyone has
logged for that book — reader, status, rating, format, and review (subject
to that reader's privacy setting). This is where you see what other members
think of a book before adding it yourself.

## Lists (Shelves)

Beyond your reading log, you can create your own named lists ("shelves") to
organize books however you like — e.g. "Beach Reads" or "To Buy".

- **My Lists** (`/shelves`) shows all your lists.
- Create a new list from the "Save to a List" dropdown on any book's page,
  or from `/shelves/new`.
- Add a book to a list from the same dropdown on the book's page.
- Remove a book from a list, or delete the whole list, from the list's page.

Lists are private to you — no one else, including moderators and admins, can
see another member's lists.

## What members can't do

- Edit or delete a book, even one you added yourself (moderator+ only).
- Edit or delete another member's reading (moderator+ only).
- Create, edit, or delete a series (moderator+ only).
- Access the admin area (`/admin`).
