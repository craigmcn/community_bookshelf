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
  `write:books`, `read:readings`, `write:readings`), and optionally an
  expiration (30 days, 90 days, 1 year, or never).
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

## Rate limits

To keep the API usable for everyone, requests are throttled:

- **120 requests/minute** per token.
- **30 requests/minute** per IP address for requests with no valid token —
  this only affects scripts hammering the API with a missing or bad token;
  it doesn't apply once you're sending a real one.

Exceeding a limit gets a `429` with `{"error": "Rate limit exceeded"}`.
There's no higher limit for moderator/admin tokens — a runaway script is
equally disruptive regardless of whose token it's using.
