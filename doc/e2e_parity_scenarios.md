# e2e parity scenarios

The shared Playwright contract for the bookshelf family. Every repo's e2e suite
(community_bookshelf `e2e/*.spec.js`, bookshelf-islands `e2e/*.spec.ts`,
bookshelf-spa `e2e/real-api/*.spec.ts` against bookshelf-api) implements these
scenarios under **these exact `test()` names**, with the same outcomes. Each
repo uses its own UI idiom to get there, so the steps can differ: Turbo
forms here, React islands in bookshelf-islands, the SPA in bookshelf-spa.
Diffing test names across repos shows which scenarios a repo is missing.

When a scenario is added or renamed here, add it to the siblings too (or file
an issue in each).

## account

- member can update their display name and bio, visible elsewhere in the app
- member can upload and then remove an avatar

## activities

- member sees a followed moderator's reading activity in their feed

## admin

- unauthenticated user is redirected to sign-in
- member (non-moderator) is denied
- moderator can reach Reviewed Readings but not the Dashboard or Users
- admin can reach the Dashboard and edit user roles

## auth

- signed-out user hitting a protected page is redirected to sign-in
- member can sign in and lands on My Shelf
- wrong password shows an error and stays on the sign-in form

## book_clubs

- member starts a club, moderator joins and posts, spoiler posts are flagged

## books

- index and show are visible signed out
- anyone can search and sort the catalog
- anyone can browse the catalog by genre tag
- member can tag a book with genres when adding it
- member can tag a book with moods and pace, and browse the catalog by them
- book page lists similar books sharing a genre tag
- moderator can set ISBN, page count, and publish date on a book
- moderator can create a series and assign a book to it
- book search announces result count via a live region for screen readers
- member can search Open Library and add a book
- member does not see edit or delete controls on a book
- moderator can edit and delete a book

## buddy_reads

- member invites a buddy, buddy accepts, and they exchange messages

## notifications

- bell badge, dropdown preview, and inbox mark-as-read reflect a new follower

## profiles

- member's profile shows their favorite genres and public reviews
- member can follow and unfollow another member from their profile

## readings

- member sees their own shelf, including the seeded reading
- member can search and filter their shelf
- member can browse their shelf by genre tag
- member sees a Recommended for You section based on a highly-rated book's genre
- member can log a reading with a status, rating, review, format, dates, and progress
- member can mark their Gatsby reading as DNF
- editing a reading updates the displayed rating
- member can start a re-read from a finished book
- member can remove a reading from their shelf
- moderator soft-deleting a reading removes it from the owner's shelf

## review_social

- member can like and comment on another member's public review

## shelves

- member sees their seeded list
- member can create a list and save a book to it from the book page
- member can remove a book from a list
- member can remove a book from the list's page
