# API Guide

A JSON API for the book catalog and reading logs, for anyone who wants to
script against their own data or build an external tool against this
instance. It covers the same books/readings functionality as the website —
see the [Member Guide](member-guide.md), [Moderator Guide](moderator-guide.md),
and [Admin Guide](admin-guide.md) for the equivalent web features and who can
do what.

This guide is prose; for a machine-readable contract (client codegen,
Postman/Insomnia import, or just poking at endpoints interactively) see the
[OpenAPI spec](openapi.yaml), also served live at `/api/docs/openapi.yaml`.
An interactive Swagger UI explorer is at `/api/docs`.

## Getting a token

Tokens are created from `/api_tokens` (linked from **API Access** on
`/account/edit`). You can hold multiple tokens at once — one per script or
integration — each independently revocable:

- Give it a name, pick which **scopes** it needs (`read:books`,
  `write:books`, `read:readings`, `write:readings`, `read:shelves`,
  `write:shelves`, `write:follows`, `read:reading_challenges`,
  `write:reading_challenges`, `read:stats`, `read:buddy_reads`,
  `write:buddy_reads`), and optionally an expiration (30 days, 90 days,
  1 year, or never).
- The full value is shown exactly once, right after creation — copy it
  immediately. The list afterward only ever shows a short prefix
  (`cb_a1b2c3d4…`), enough to tell your tokens apart, never the full secret.
- Click **Revoke** on any token to kill it immediately — this only affects
  that one token, not any others you've created.

Treat every token like a password: anyone who has it can act as you, within
whatever scopes it was granted (and, if you're a moderator or admin, with
those permissions too).

### Scopes

| Scope | Grants |
|---|---|
| `read:books` | `GET` requests to `/api/v1/books` |
| `write:books` | `POST`/`PATCH`/`DELETE` on `/api/v1/books` |
| `read:readings` | `GET` requests to `/api/v1/readings` |
| `write:readings` | `POST`/`PATCH`/`DELETE` on `/api/v1/readings` (including `/bulk`) |
| `read:shelves` | `GET` requests to `/api/v1/shelves` |
| `write:shelves` | `POST`/`PATCH`/`DELETE` on `/api/v1/shelves` and its nested `/books` (add/remove) |
| `write:follows` | `POST`/`DELETE` on `/api/v1/users/:user_id/follow` |
| `read:reading_challenges` | `GET` requests to `/api/v1/reading_challenges` |
| `write:reading_challenges` | `POST`/`PATCH` on `/api/v1/reading_challenges` |
| `read:stats` | `GET` requests to `/api/v1/stats` |
| `read:buddy_reads` | `GET` requests to `/api/v1/buddy_reads` |
| `write:buddy_reads` | `POST`/`PATCH` on `/api/v1/buddy_reads` and `POST` on its nested `/messages` |

A request with a token missing the required scope gets a `403` — the same
status a Pundit permission failure returns, but with a distinct message
(`"Token missing required scope: ..."`) so you can tell the two apart.
Scope checks and Pundit's role/ownership checks are independent: a token
needs both the right scope *and* the signed-in user needs the right
role/ownership to succeed.

## Making a request

Every request needs the token in an `Authorization` header:

```sh
curl -H "Authorization: Bearer <your-token>" https://<host>/api/v1/books
```

There's no anonymous access — even endpoints that are public on the website
(browsing the book catalog) require a valid token when called through the
API. A missing or invalid token gets a `401`.

## Base URL and versioning

All endpoints live under `/api/v1/`. There's only one version right now; a
future breaking change would arrive as `/api/v2/` rather than changing `v1`
in place.

## Response shape

Every response is JSON. A single resource looks like:

```json
{
  "id": 42,
  "title": "1984",
  "author": "George Orwell",
  ...
}
```

A list response wraps the array and adds pagination metadata:

```json
{
  "books": [ { "id": 42, "title": "1984", ... }, ... ],
  "pagination": { "page": 1, "pages": 3, "count": 52 }
}
```

### Errors

| Status | Shape | When |
|---|---|---|
| 401 | `{"error": "..."}` | Missing or invalid token |
| 403 | `{"error": "..."}` | Token is valid, but you're not allowed to do this |
| 404 | `{"error": "..."}` | Resource doesn't exist |
| 422 | `{"errors": ["...", "..."]}` | Validation failed on create/update — one message per problem |

## Endpoints

Permissions mirror the website exactly — the same rules described in the
Member/Moderator/Admin guides apply here, just enforced against your token
instead of a signed-in session.

### Books

| Method | Path | Who |
|---|---|---|
| GET | `/api/v1/books` | Anyone with a token |
| GET | `/api/v1/books/:id` | Anyone with a token |
| POST | `/api/v1/books` | Anyone with a token |
| PATCH | `/api/v1/books/:id` | Moderator or admin |
| DELETE | `/api/v1/books/:id` | Moderator or admin |

`GET /api/v1/books` accepts an optional `q` param to search by title/author
(same as the website's catalog search), and paginates 20 at a time.

Creating a book accepts the same fields as the website's add-book form:
`title`, `author`, `cover_url`, `isbn`, `page_count`, `published_on`,
`series_id`, `series_position`, `tag_list`, `mood_list`, `pace_list`
(the last three are comma-separated strings, same as the form). Pass
`open_library_key` to auto-fill description and subjects from Open Library,
same as the website.

```sh
curl -X POST https://<host>/api/v1/books \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"book": {"title": "1984", "author": "George Orwell"}}'
```

### Readings

| Method | Path | Who |
|---|---|---|
| GET | `/api/v1/readings` | Anyone with a token — see your own; moderators/admins see everyone's |
| GET | `/api/v1/readings/:id` | The owner, a moderator/admin, or anyone if the review is public |
| POST | `/api/v1/readings` | Anyone with a token |
| PATCH | `/api/v1/readings/:id` | The owner, or a moderator/admin |
| DELETE | `/api/v1/readings/:id` | Moderator or admin only — this is a soft delete, same as the website |

`GET /api/v1/readings` accepts an optional `status` param
(`want_to_read`/`reading`/`finished`/`dnf`) and paginates 20 at a time. A
reading's `show` response nests its book; the index response doesn't (to
avoid repeating book data across every row of a paginated list) — fetch
`GET /api/v1/books/:id` separately if you need it there.

Creating or updating a reading accepts the same fields as the website's
reading form: `book_id`, `status`, `rating`, `review`, `is_review_public`,
`started_on`, `finished_on`, `progress_percent`, `format`.

```sh
curl -X POST https://<host>/api/v1/readings \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"reading": {"book_id": 42, "status": "reading"}}'
```

#### Bulk create

`POST /api/v1/readings/bulk` creates several readings in one request — for
importing a batch of already-read books without burning a rate-limit slot
per row. Accepts up to 100 readings per request; each one is created (or
rejected) independently, so one bad row doesn't fail the rest.

```sh
curl -X POST https://<host>/api/v1/readings/bulk \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"readings": [{"book_id": 42, "status": "finished"}, {"book_id": 7, "status": "want_to_read"}]}'
```

The response is always `200` (even if every row failed — check each row's
own `status`) and lists a result per row, in the same order as the request:

```json
{
  "results": [
    {"index": 0, "status": "created", "reading": {"id": 101, "book_id": 42, ...}},
    {"index": 1, "status": "error", "errors": ["Book must exist"]}
  ]
}
```

### Shelves

| Method | Path | Who |
|---|---|---|
| GET | `/api/v1/shelves` | Anyone with a token — always your own lists only, same as the website |
| GET | `/api/v1/shelves/:id` | The owner only |
| POST | `/api/v1/shelves` | Anyone with a token |
| PATCH | `/api/v1/shelves/:id` | The owner only |
| DELETE | `/api/v1/shelves/:id` | The owner only |
| POST | `/api/v1/shelves/:shelf_id/books` | The owner only — adds a book, pass `book_id` |
| DELETE | `/api/v1/shelves/:shelf_id/books/:id` | The owner only — `:id` is the shelf/book pairing's id |

Shelves are personal book-collection lists — there's no moderator override,
unlike books/readings. A shelf id that isn't yours gets a `404`, not a `403`
(same as the website — you can't tell another user's shelf exists). `GET
/api/v1/shelves/:id` nests the shelf's books; the index response doesn't
(same reasoning as readings' index above). A shelf's book list isn't
paginated, so each nested book is a *summary* — the same fields as
`GET /api/v1/books/:id` minus `tag_list`/`mood_list`/`pace_list` (each of
those runs its own query; omitting them here avoids a per-book query
fan-out on a large shelf). Fetch `GET /api/v1/books/:id` separately if you
need those.

```sh
curl -X POST https://<host>/api/v1/shelves \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"shelf": {"name": "Beach reads"}}'

curl -X POST https://<host>/api/v1/shelves/1/books \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"book_id": 42}'
```

Adding a book already on the shelf is a no-op (`201`, not a duplicate row) —
the same idempotent behavior as the website's add-to-shelf button.

### Follows

| Method | Path | Who |
|---|---|---|
| POST | `/api/v1/users/:user_id/follow` | Anyone with a token — can't follow yourself |
| DELETE | `/api/v1/users/:user_id/follow` | Anyone with a token — unfollows your own relationship |

Following someone you already follow returns `422` — unlike the website,
which treats a duplicate follow as a silent no-op with no user-facing
error, the API surfaces it explicitly so a script doesn't mistake a failed
follow for a successful one. Unfollowing is idempotent, though: calling it
when you're not following that user is still a `204`, not a `404`.

```sh
curl -X POST https://<host>/api/v1/users/42/follow \
  -H "Authorization: Bearer <your-token>"

curl -X DELETE https://<host>/api/v1/users/42/follow \
  -H "Authorization: Bearer <your-token>"
```

There's no `GET` endpoint here for a user's followers/following lists yet —
that's likely to land alongside a future `/api/v1/users/:id` profile
endpoint rather than under `/follow` itself.

### Reading Challenges

| Method | Path | Who |
|---|---|---|
| GET | `/api/v1/reading_challenges` | Anyone with a token — always your own challenges only |
| POST | `/api/v1/reading_challenges` | Anyone with a token — one per calendar year |
| PATCH | `/api/v1/reading_challenges/:id` | The owner only |

There's no `show` or `destroy` — same action set as the website. Each
challenge includes computed progress fields alongside the raw `year`/`goal`
columns: `books_finished_count`, `progress_percent` (capped at 100), and
`completed`.

`year` is only accepted on create — a challenge's year is part of its
identity (one per user per calendar year) and can't be changed afterward,
so `PATCH` only accepts `goal`; a `year` in the request body is silently
ignored, same as the website's edit form disabling the field.

```sh
curl -X POST https://<host>/api/v1/reading_challenges \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"reading_challenge": {"year": 2027, "goal": 24}}'
```

### Stats

| Method | Path | Who |
|---|---|---|
| GET | `/api/v1/stats` | Anyone with a token — always your own stats |

Returns the same three datasets as the website's `/stats` page, each as an
array rather than the website's chart-library-shaped hash:

- `genre_breakdown`: one entry per genre tag across your finished books, e.g. `{"genre": "Fantasy", "count": 5}`.
- `books_finished_by_month` / `pages_read_by_month`: always exactly 12 entries (the trailing 12 calendar months, zero-filled for months with no activity — same `groupdate` backfill behavior as the website), e.g. `{"month": "2026-08-01", "count": 3}` / `{"month": "2026-08-01", "pages": 840}`.

Unlike the website, there's no separate "have you finished anything yet"
flag — `books_finished_by_month`/`pages_read_by_month` are zero-filled
either way, so a client can just check whether every `count`/`pages` value
is zero.

```sh
curl https://<host>/api/v1/stats -H "Authorization: Bearer <your-token>"
```

### Buddy Reads

| Method | Path | Who |
|---|---|---|
| GET | `/api/v1/buddy_reads` | Anyone with a token — always your own (as initiator or partner) |
| GET | `/api/v1/buddy_reads/:id` | Either participant only |
| POST | `/api/v1/buddy_reads` | Anyone with a token — can't invite yourself |
| PATCH | `/api/v1/buddy_reads/:id` | Either participant, depending on the transition (see below) |
| POST | `/api/v1/buddy_reads/:buddy_read_id/messages` | Either participant, while the pairing is still active |

A buddy read is a private two-person space — there's no moderator
override, unlike clubs/reviews. `index`/`show` nest `book` (`id`, `title`)
and both `initiator`/`partner` (`id`, `display_name`) — a client always
gets both sides, matching the website.

`PATCH` drives a small fixed state machine via a `status` param, not a
general update:

| From | `status` | Who | To |
|---|---|---|---|
| `pending` | `accepted` / `declined` | The partner only | `accepted` / `declined` |
| `pending` or `accepted` | `cancelled` | Either participant | `cancelled` |
| `accepted` | `completed` | Either participant | `completed` |

Unlike the website (which silently ignores an invalid transition), an
invalid or unrecognized `status` returns `422` with an explanatory error —
useful for a script to know its request didn't do anything.

```sh
curl -X POST https://<host>/api/v1/buddy_reads \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"buddy_read": {"book_id": 42, "partner_id": 7}}'

curl -X PATCH https://<host>/api/v1/buddy_reads/1 \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"status": "accepted"}'
```

`POST .../messages` accepts `{"buddy_read_message": {"body": "..."}}` and
is blocked once the pairing is `declined`/`cancelled` (`completed` and
`accepted` can both still be messaged).

## Rate limits

To keep the API usable for everyone, requests are throttled:

- **120 requests/minute** per token.
- **30 requests/minute** per IP address for requests with no valid token —
  this only affects scripts hammering the API with a missing or bad token;
  it doesn't apply once you're sending a real one.

Exceeding a limit gets a `429` with `{"error": "Rate limit exceeded"}`.
There's no higher limit for moderator/admin tokens — a runaway script is
equally disruptive regardless of whose token it's using.
