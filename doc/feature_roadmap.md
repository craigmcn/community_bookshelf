# Feature Roadmap: Toward a Fully-Featured Reading List App

_Last updated: 2026-08-15_

This is a gap analysis, not a commitment or a sprint plan. It compares
community_bookshelf's current feature set against established reading-tracker apps —
Goodreads, The StoryGraph, LibraryThing, Fable, Hardcover, and BookWyrm — and lists
what a "fully-featured" version of this app could add. Treat it as a menu to pull
prioritized work from, not a backlog that all needs building.

**What already exists today**, so it isn't re-listed below: a public book catalog
(title/author/cover URL) with Open Library live search on the add-book form; a
personal reading log with a 3-state status (want to read / reading / finished), a
1–5 star rating, a free-text review, and soft delete; a "Community Readings" table on
each book's page showing everyone's status/rating/review for that book; Clearance-based
auth (sign up/in/out, forgot/reset password); Pundit RBAC with member/moderator/admin
roles; and an admin dashboard (user/book/reading counts, top-5 most-read leaderboard)
plus a moderator review-moderation queue.

## Parity context

community_bookshelf is one of four parallel implementations of the same product
(alongside `bookshelf-islands`, `bookshelf-spa`, `bookshelf-api`) built to compare
architectures, sharing a Playwright e2e parity contract with matching fixture data and
scenarios. Each feature below is tagged:

- **`[parity: coordinated]`** — touches core flows already covered by the shared e2e
  suite (reading tracking, discovery/search). Adding this here without a matching
  change in the sibling repos would break parity or require the e2e scenarios to
  diverge.
- **`[parity: solo]`** — a net-new surface with no existing parity tests. Safe to
  prototype in this repo alone first.

## Cataloging & metadata

- [ ] Genres/tags on books, with tag-based browsing `[parity: coordinated]`
- [ ] ISBN field `[parity: solo]`
- [ ] Page count `[parity: solo]`
- [ ] Publish date / edition metadata `[parity: solo]`
- [ ] Series tracking (link books into a series, show reading order) `[parity: solo]`
- [ ] Support multiple editions per book (LibraryThing-style precise cataloging) `[parity: solo]`
- [ ] Pull richer detail from Open Library (description, subjects) into the book page `[parity: solo]`

## Reading tracking

- [ ] Start date / finish date on a reading `[parity: coordinated]`
- [ ] Progress tracking (current page or %) `[parity: coordinated]`
- [ ] Re-read tracking (multiple reading records per user/book) `[parity: coordinated]`
- [ ] "Did Not Finish" (DNF) status, alongside want-to-read/reading/finished `[parity: coordinated]`
- [ ] Format field: physical / ebook / audiobook `[parity: solo]`
- [x] Custom shelves/collections beyond the single implicit list (e.g. "Favorites", "2026 TBR") `[parity: coordinated]`
- [ ] Private/public toggle on individual reviews `[parity: solo]`

## Discovery & search

- [ ] Search box + filter + sort on the book catalog `[parity: coordinated]`
- [ ] Search/filter/sort on "My Shelf" (by status, rating, genre) `[parity: coordinated]`
- [ ] Pagination on catalog and shelf indexes `[parity: coordinated]`
- [ ] Browse books by genre/tag `[parity: coordinated]`
- [ ] Mood & pace tags on books (StoryGraph-style: "dark", "fast-paced") with filtering `[parity: solo]`
- [ ] Recommendation engine based on reading history `[parity: solo]`
- [ ] "Similar books" on a book's detail page `[parity: solo]`

## Social

- [ ] Follow other readers `[parity: solo]`
- [ ] Activity feed of followed users' reading updates `[parity: solo]`
- [ ] Likes/comments on reviews `[parity: solo]`
- [ ] Buddy reads (shared reading sessions between two users) `[parity: solo]`
- [ ] Book clubs with discussion threads (Fable-style, spoiler-gated by reading progress) `[parity: solo]`
- [ ] User profiles: avatar, bio, favorite genres `[parity: solo]`

## Gamification

- [ ] Annual reading challenge (set a book-count goal, track progress) `[parity: solo]`
- [ ] Reading streaks `[parity: solo]`
- [ ] Badges/achievements (books read, reviews written, challenges completed) `[parity: solo]`

## Stats & insights

- [ ] Personal reading stats page: genre breakdown, pace, pages read over time (charts) `[parity: solo]`
- [ ] Site-wide analytics expansion on the admin dashboard (trends over time, not just current totals) `[parity: solo]`

## Notifications

- [ ] New follower notifications `[parity: solo]`
- [ ] Comment/reply notifications on your reviews `[parity: solo]`
- [ ] Book club activity notifications `[parity: solo]`
- [ ] Digest emails (uses the currently-unused `solid_queue`/`solid_cache` infra for background sending) `[parity: solo]`

## Import/export

- [ ] CSV export of your shelf `[parity: solo]`
- [ ] Goodreads CSV import `[parity: solo]`

## Account & profile

- [ ] Self-service profile edit (name, bio) `[parity: coordinated]` — Clearance currently has no profile-edit views in any sibling repo
- [ ] Avatar upload `[parity: solo]`
- [ ] Email confirmation flow (the `confirmation_token` column exists but is only used for password reset today) `[parity: solo]`
- [ ] Self-service account deletion `[parity: coordinated]`

## API

- [ ] Expose a JSON API for books/readings (the `jbuilder` gem is already a dependency but unused) `[parity: solo — but directly relevant to bookshelf-api, the sibling API-first implementation]`

## Prioritization

Not ranked here by design — this is a comprehensive menu. When picking work, the
`[parity: coordinated]` items are the ones to plan across all four sibling repos
together (or explicitly decide to let the e2e parity contract diverge); the
`[parity: solo]` items — most of social, gamification, notifications, and
import/export — can be prototyped in this repo without touching the others.
