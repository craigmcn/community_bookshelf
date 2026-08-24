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
  you resend the confirmation email. You can resend once a minute; if you've
  already confirmed, the option disappears.
- **Deleting your account** — the "Danger Zone" at the bottom permanently
  deletes your account: your readings, reviews, and lists are gone for good.
  Books you added to the catalog stay (the catalog is shared, community
  content), but show "Deleted user" as the contributor instead of your name.
  This can't be undone, and requires re-entering your password to confirm.
  If you're the app's only admin, deletion is blocked until you promote
  someone else to admin first — see the Admin Guide.

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

## Social

- **Profiles** — every member has a public profile at `/users/:id`: avatar,
  bio, favorite genres, finished/currently-reading counts, and their public
  reviews. Any signed-in member can view any profile. Set your own favorite
  genres (comma-separated, like the genre tags on a book) from
  `/account/edit`. Names throughout the app — Community Readings, "Added
  by", comments — link to the person's profile.
- **Following** — follow another member from their profile page to see their
  reading activity in your feed. `/users/:id/followers` and
  `/users/:id/following` list who follows whom. You can't follow yourself.
- **Feed** (`/feed`) is a chronological feed of updates from people you
  follow: books added to their shelf, started, finished, and reviewed
  (public reviews only). Nothing shows here until you follow someone.
- **Likes and comments** — a public review (the default privacy setting) can
  be liked and commented on by any member from the reading's page — click
  the review text in a book's Community Readings table to open it. You can
  delete your own comments; a moderator can delete anyone's.
- **Buddy reads** (`/buddy_reads`) let you pair up with one other member to
  read a book together: invite them, they accept or decline, and you get a
  private shared discussion thread for the two of you. Either of you can
  cancel it or mark it completed once accepted. It's separate from your own
  reading log — your own status/progress/rating for the book still lives on
  your own shelf as normal.
- **Book clubs** (`/clubs`) are open discussion groups built around one
  book. Anyone can browse a club's discussion, but you need to join to post.
  Starting a club joins you automatically. Flag a post as containing
  spoilers and it's hidden from other members — including in the club
  you're reading together — until they've logged that book as **Finished**;
  you and moderators can still see it either way.
- **Notifications** — the bell icon in the nav bar shows how many
  notifications you haven't seen yet. You get one when someone follows you,
  comments on one of your public reviews, or posts in a club you belong to
  (your own comments and posts don't notify you). Opening a notification
  from `/notifications` marks it read and takes you straight to the
  follower's profile, the reading, or the club post. If you have unread
  notifications, you'll also get a daily email digest summarizing them —
  each notification is only emailed once, even if you haven't opened the
  app since.

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

## Gamification

- **Reading challenges** (`/reading_challenges`) let you set a book-count
  goal for a calendar year — e.g. "read 20 books in 2026" — and track your
  progress against it. You can set one challenge per year, and edit the goal
  at any time. Your current year's progress also shows on your account page
  and your public profile.
- **Reading streaks** count how many books you've finished in a row without
  more than a 30-day gap between finishes. Your current streak shows on your
  account page and your public profile.
- **Badges** are earned automatically as you finish books, write reviews,
  build a streak, or complete a reading challenge — there are several tiers
  for each. Once earned, a badge is yours for good. See what you've earned
  (and what's still open) on your account page; your public profile shows
  the badges you've earned to other members.

## My Stats

`/stats` ("My Stats" in the nav) shows charts built from your own finished
readings:

- **Genre Breakdown** — a pie chart of the genre tags on the books you've
  finished (a book tagged with multiple genres counts toward each).
- **Reading Pace** — a bar chart of how many books you finished per month,
  over the last 12 months.
- **Pages Read Over Time** — a line chart of pages read per month (summed
  from each finished book's page count), over the last 12 months.

Each chart shows a short prompt instead of an empty chart until you have
matching data (e.g. a finished book with a genre tag).

## What members can't do

- Edit or delete a book, even one you added yourself (moderator+ only).
- Edit or delete another member's reading (moderator+ only).
- Create, edit, or delete a series (moderator+ only).
- Access the admin area (`/admin`).
