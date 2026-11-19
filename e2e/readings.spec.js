import { test, expect } from "./support/fixtures";
import { signIn, users } from "./support/auth";

test.describe("Readings", () => {
  test("member sees their own shelf, including the seeded reading", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/readings");
    const row = page.locator("tr", { has: page.getByRole("link", { name: "The Great Gatsby" }) });
    await expect(row).toBeVisible();
    await expect(row.locator("i.fa-star")).toHaveCount(4);
  });

  test("member can search and filter their shelf", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/readings");
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toBeVisible();

    // each submit reloads the results frame (and the search box with it), so wait
    // for the URL to reflect it before typing the next query
    await page.getByLabel("Search").fill("gatsby");
    await page.getByLabel("Search").press("Enter");
    await expect(page).toHaveURL(/q=gatsby/);
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toBeVisible();

    await page.getByLabel("Search").fill("nonexistent title");
    await page.getByLabel("Search").press("Enter");
    await expect(page).toHaveURL(/q=nonexistent/);
    await expect(page.getByText("No readings match those filters.")).toBeVisible();

    // Clear reloads the results frame, so wait for it before changing the next filter
    await page.getByRole("link", { name: "Clear" }).click();
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toBeVisible();
    await page.getByLabel("Status").selectOption("finished");
    await expect(page.getByText("No readings match those filters.")).toBeVisible();

    await page.getByLabel("Status").selectOption("");
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toBeVisible();
  });

  test("member can browse their shelf by genre tag", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/readings");
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toBeVisible();

    // The Great Gatsby is tagged "fantasy" via the taggings fixture.
    await page.getByRole("link", { name: "fantasy", exact: true }).click();
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toBeVisible();

    await page.getByRole("link", { name: "Clear" }).click();
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toBeVisible();
  });

  test("member sees a Recommended for You section based on a highly-rated book's genre", async ({ page, pageAs }) => {
    await signIn(page, users.moderator);
    await page.goto("/books/new");
    await page.getByLabel("Search for a Book").fill("chamber of secrets");
    await page.getByRole("button", { name: /Chamber of Secrets/ }).click();
    await page.getByLabel("Genres").fill("fantasy"); // matches the tag on the member's 4-star Gatsby reading
    await page.getByRole("button", { name: "Create Book" }).click();

    // fresh context instead of reusing the moderator's page, since navigating a signed-in
    // page to /sign_in just redirects it away rather than showing the form
    const memberPage = await pageAs(users.member);
    await memberPage.goto("/readings");
    await expect(memberPage.getByRole("heading", { name: "Recommended for You" })).toBeVisible();
    await expect(memberPage.getByRole("link", { name: /Chamber of Secrets/ })).toBeVisible();
  });

  test("member can log a reading with a status, rating, review, format, dates, and progress", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/readings/new");

    await page.getByLabel("Book").selectOption({ label: "1984" });
    await page.getByLabel("Status").selectOption("finished");
    await page.getByLabel("Format").selectOption("ebook");
    await page.getByLabel("Started").fill("2026-01-05");
    await page.getByLabel("Finished").fill("2026-01-20");
    await page.getByLabel("Progress (%)").fill("100");
    await page.getByLabel("Rating").selectOption("five");
    await page.getByLabel("Review", { exact: true }).fill("Chillingly good.");
    await page.getByLabel("Visible to other members").uncheck();
    await page.getByRole("button", { name: "Create Reading" }).click();

    await expect(page.getByText("Chillingly good.")).toBeVisible();
    await expect(page.locator("dd i.fa-star")).toHaveCount(5);
    await expect(page.getByText("Ebook")).toBeVisible();
    await expect(page.getByText("100%")).toBeVisible();
    await expect(page.getByText("Private", { exact: true })).toBeVisible();
  });

  test("member can mark their Gatsby reading as DNF", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/readings");
    const row = page.locator("tr", { has: page.getByRole("link", { name: "The Great Gatsby" }) });
    await row.getByRole("link", { name: "Edit reading" }).click();
    // Turbo's link prefetch can race a same-URL navigation and morph the just-rendered
    // form back to its original state if we interact before it settles — wait it out.
    await page.waitForLoadState("networkidle");

    await page.getByLabel("Status").selectOption("dnf");
    await page.getByRole("button", { name: "Update Reading" }).click();

    await expect(page.locator(".badge-status-dnf")).toBeVisible();
  });

  test("editing a reading updates the displayed rating", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/readings");
    const row = page.locator("tr", { has: page.getByRole("link", { name: "1984" }) }).first();
    await row.getByRole("link", { name: "Edit reading" }).click();
    await page.waitForLoadState("networkidle"); // see the DNF test above

    await page.getByLabel("Rating").selectOption("one");
    await page.getByRole("button", { name: "Update Reading" }).click();

    await expect(page.locator("dd i.fa-star")).toHaveCount(1);
  });

  test("member can start a re-read from a finished book", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/readings");
    const rows = page.locator("tr", { has: page.getByRole("link", { name: "1984" }) });
    await expect(rows.first()).toBeVisible();
    const wantToRead = rows.filter({ hasText: "Want to read" });
    const before = await rows.count();
    const wantToReadBefore = await wantToRead.count();

    await rows.getByRole("button", { name: "Start a re-read" }).first().click();

    await expect(rows).toHaveCount(before + 1);
    await expect(wantToRead).toHaveCount(wantToReadBefore + 1);
  });

  test("member can remove a reading from their shelf", async ({ page }) => {
    // logs its own Want-to-read reading to remove, so it runs alone and leaves no extra row
    await signIn(page, users.member);
    await page.goto("/readings");
    await expect(page.getByRole("heading", { name: "My Shelf" })).toBeVisible();
    const rows = page.locator("tr", { has: page.getByRole("link", { name: "1984" }) });
    const before = await rows.count();

    await page.goto("/readings/new");
    await page.getByLabel("Book").selectOption({ label: "1984" });
    await page.getByLabel("Status").selectOption("want_to_read");
    await page.getByRole("button", { name: "Create Reading" }).click();
    await expect(page).toHaveURL(/\/readings\/\d+$/);

    await page.goto("/readings");
    await expect(rows).toHaveCount(before + 1);
    page.once("dialog", (dialog) => dialog.accept());
    await rows.filter({ hasText: "Want to read" }).first().getByRole("button", { name: "Remove reading" }).click();

    await expect(page.getByRole("alert")).toContainText("Reading was removed.");
    await expect(rows).toHaveCount(before);
  });

  test("moderator soft-deleting a reading removes it from the owner's shelf", async ({ page, pageAs }) => {
    await signIn(page, users.moderator);
    await page.goto("/admin/readings");

    const row = page.locator("tr", { has: page.getByRole("link", { name: "The Great Gatsby" }) });
    page.once("dialog", (dialog) => dialog.accept());
    await row.getByRole("button", { name: "Delete" }).click();

    // a Turbo Stream swaps the row in place, so the moderator stays on /admin/readings
    await expect(row).toHaveClass(/opacity-50/);
    await expect(row.getByText("Deleted")).toBeVisible();
    await expect(page).toHaveURL(/\/admin\/readings$/);

    // fresh context instead of UI sign-out, to avoid racing the moderator's sign-out redirect
    const memberPage = await pageAs(users.member);
    await memberPage.goto("/readings");
    await expect(memberPage.getByRole("link", { name: "The Great Gatsby" })).toHaveCount(0);
  });
});
