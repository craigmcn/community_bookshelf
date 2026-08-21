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

After signing up, check your inbox for a confirmation email — but this is a
nudge, not a requirement. You can sign in and use every feature of the app
before confirming; a reminder banner on your account page just offers a
resend link until you do.

## Your account

`/account/edit` is where you manage your own account:

- **Display name and bio** — your display name (if set) replaces your email
  everywhere your contributions are shown to others, like "Added by" on a
  book you added or your name in a book's Community Readings table. Leaving
  it blank falls back to showing your email, same as before this existed.
- **Avatar** — upload a PNG, JPEG, or WEBP image up to 5MB. Shows next to
  your name in the navigation bar; remove it with the checkbox next to your
  current avatar.
- **Email confirmation** — if you haven't confirmed yet, a banner here lets
  you resend the confirmation email.
- **Deleting your account** — the "Danger Zone" at the bottom permanently
  deletes your account: your readings, reviews, and lists are gone for good.
  Books you added to the catalog stay (the catalog is shared, community
  content), but show "Deleted user" as the contributor instead of your name.
  This can't be undone, and requires re-entering your password to confirm.

## Browsing books

- **Books** (`/books`) lists every book in the catalog, 20 at a time with
  pagination at the bottom.
- **Search** the catalog by title or author with the search box, and
  **sort** by title, author, recently added, or publication date.
- **Tags** come in three flavors: genre (e.g. "fantasy"), mood (e.g. "dark"),
  and pace (e.g. "fast-paced"). Each has its own "Browse by..." row of
  badges on the catalog page — click one to filter, or filter the URL with
  `?tag=<name>` directly (works for any tag regardless of category, since
  tag names are unique across categories).
- Each book's page shows its cover, author, ISBN, page count, publish date,
  series (with your place in the reading order), description, subjects, and
  its genre/mood/pace tags. A **Similar Books** section lists other books
  that share the most tags with it.
- **Series** (`/series`) lists book series; a series page shows every book in
  it in reading order.
- **Adding a book**: any signed-in member can add a new book to the catalog.
  Search Open Library from the add-book form to pull in the title, author,
  cover, and description automatically, or enter details by hand. Genre,
  mood, and pace tags are each entered as their own comma-separated field.

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

**Searching, filtering, and sorting your shelf**: search by book title or
author, filter by status, rating, or genre tag, and sort by recently
updated, book title, or rating — all from the controls above the table.
Your shelf paginates 20 readings at a time once it grows past that.

**Recommended for You**: if you've finished a book or rated one 4-5 stars,
your shelf page shows a "Recommended for You" row of books that share tags
with it and aren't already on your shelf.

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
