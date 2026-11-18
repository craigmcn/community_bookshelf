import { test, expect } from "@playwright/test";
import { signIn, users } from "./support/auth";

test.describe("Books", () => {
  test("index and show are visible signed out", async ({ page }) => {
    await page.goto("/books");
    await expect(page.getByRole("heading", { name: "Books" })).toBeVisible();
    await page.getByRole("link", { name: "The Great Gatsby" }).click();
    await expect(page.getByRole("heading", { name: "The Great Gatsby" })).toBeVisible();
  });

  test("anyone can search and sort the catalog", async ({ page }) => {
    await page.goto("/books");
    await expect(page.getByRole("link", { name: "1984" })).toBeVisible();
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toBeVisible();

    await page.getByLabel("Search").fill("1984");
    await page.getByLabel("Search").press("Enter");
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toHaveCount(0);
    await expect(page.getByRole("link", { name: "1984" })).toBeVisible();

    // Clear reloads the results frame (including the sort select), so wait for it to land first
    await page.getByRole("link", { name: "Clear" }).click();
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toBeVisible();
    await page.getByLabel("Sort by").selectOption("author");
    const titles = page.locator(".card-title");
    await expect(titles.first()).toHaveText("The Great Gatsby"); // F. Scott Fitzgerald sorts before George Orwell
  });

  test("anyone can browse the catalog by genre tag", async ({ page }) => {
    await page.goto("/books");
    await page.getByRole("link", { name: "fantasy", exact: true }).click();

    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toBeVisible();
    await expect(page.getByRole("link", { name: "1984" })).toHaveCount(0);

    await page.getByRole("link", { name: "Clear tag filter" }).click();
    await expect(page.getByRole("link", { name: "1984" })).toBeVisible();
  });

  test("member can tag a book with genres when adding it", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/books/new");

    await page.getByLabel("Search for a Book").fill("hobbit");
    await page.getByRole("button", { name: /The Hobbit/ }).click();

    await page.getByLabel("Genres").fill("adventure");

    await page.getByRole("button", { name: "Create Book" }).click();
    await expect(page).toHaveURL(/\/books\/\d+$/);
    await expect(page.getByRole("link", { name: "adventure" })).toBeVisible();
  });

  test("member can tag a book with moods and pace, and browse the catalog by them", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/books/new");

    await page.getByLabel("Search for a Book").fill("chamber of secrets");
    await page.getByRole("button", { name: /Chamber of Secrets/ }).click();

    await page.getByLabel("Moods").fill("cozy");
    await page.getByLabel("Pace").fill("fast-paced");

    await page.getByRole("button", { name: "Create Book" }).click();
    await expect(page).toHaveURL(/\/books\/\d+$/);
    await expect(page.getByRole("link", { name: "cozy" })).toBeVisible();
    await expect(page.getByRole("link", { name: "fast-paced" })).toBeVisible();

    await page.goto("/books");
    await page.getByRole("link", { name: "cozy", exact: true }).click();
    await expect(page.getByRole("link", { name: /Chamber of Secrets/ })).toBeVisible();
    await expect(page.getByRole("link", { name: "The Great Gatsby" })).toHaveCount(0);
  });

  test("book page lists similar books sharing a genre tag", async ({ page }) => {
    await signIn(page, users.moderator);
    await page.goto("/books/new");
    await page.getByLabel("Search for a Book").fill("silmarillion");
    await page.getByRole("button", { name: /The Silmarillion/ }).click();
    await page.getByLabel("Genres").fill("fantasy");
    await page.getByRole("button", { name: "Create Book" }).click();

    await page.goto("/books");
    await page.getByRole("link", { name: "The Great Gatsby" }).click();
    await expect(page.getByRole("heading", { name: "Similar Books" })).toBeVisible();
    await expect(page.getByRole("link", { name: "The Silmarillion" })).toBeVisible();
  });

  test("moderator can set ISBN, page count, and publish date on a book", async ({ page }) => {
    await signIn(page, users.moderator);
    await page.goto("/books/new");
    await page.getByLabel("Search for a Book").fill("chamber of secrets");
    await page.getByRole("button", { name: /Chamber of Secrets/ }).click();
    await page.getByLabel("ISBN").fill("978-0451524935");
    await page.getByLabel("Page Count").fill("328");
    await page.getByLabel("Publish Date").fill("1949-06-08");
    await page.getByRole("button", { name: "Create Book" }).click();

    await expect(page).toHaveURL(/\/books\/\d+$/);
    await expect(page.getByText("ISBN: 978-0451524935")).toBeVisible();
    await expect(page.getByText("328 pages")).toBeVisible();
    await expect(page.getByText("Published June 8, 1949")).toBeVisible();
  });

  test("moderator can create a series and assign a book to it", async ({ page }) => {
    await signIn(page, users.moderator);
    await page.goto("/series/new");
    await page.getByLabel("Name").fill("The Riverbend Chronicles");
    await page.getByRole("button", { name: "Create Series" }).click();
    await expect(page.getByRole("heading", { name: "The Riverbend Chronicles" })).toBeVisible();

    await page.goto("/books/new");
    await page.getByLabel("Search for a Book").fill("hobbit");
    await page.getByRole("button", { name: /The Hobbit/ }).click();
    await page.getByLabel("Series", { exact: true }).selectOption({ label: "The Riverbend Chronicles" });
    await page.getByLabel("Position in Series").fill("1");
    await page.getByRole("button", { name: "Create Book" }).click();

    await expect(page).toHaveURL(/\/books\/\d+$/);
    await expect(page.getByRole("link", { name: "The Riverbend Chronicles" })).toBeVisible();
    await expect(page.getByText("Book 1")).toBeVisible();

    await page.getByRole("link", { name: "The Riverbend Chronicles" }).click();
    await expect(page.getByRole("link", { name: "The Hobbit" })).toBeVisible();
  });

  test("book search announces result count via a live region for screen readers", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/books/new");

    const liveRegion = page.locator('[aria-live="polite"]');
    await page.getByLabel("Search for a Book").fill("hobbit");
    await expect(liveRegion).toHaveText("Showing 1 result.");

    await page.getByLabel("Search for a Book").fill("there is no such book");
    await expect(liveRegion).toHaveText("No results found.");
  });

  test("member can search Open Library and add a book", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/books/new");

    await page.getByLabel("Search for a Book").fill("hobbit");
    await page.getByRole("button", { name: /The Hobbit/ }).click();
    await page.getByRole("button", { name: "Create Book" }).click();

    await expect(page).toHaveURL(/\/books\/\d+$/);
    await expect(page.getByRole("heading", { name: "The Hobbit" })).toBeVisible();
    await expect(page.getByText("J.R.R. Tolkien")).toBeVisible();
  });

  test("member does not see edit or delete controls on a book", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/books");
    await page.getByRole("link", { name: "The Great Gatsby" }).click();
    await expect(page.getByRole("link", { name: "Edit" })).toHaveCount(0);
    await expect(page.getByRole("button", { name: "Delete" })).toHaveCount(0);
  });

  test("moderator can edit and delete a book", async ({ page }) => {
    await signIn(page, users.moderator);
    await page.goto("/books/new");
    await page.getByLabel("Search for a Book").fill("1984");
    await page.getByRole("button", { name: /1984/ }).click();
    await page.getByRole("button", { name: "Create Book" }).click();

    await page.getByRole("link", { name: "Edit" }).click();
    await expect(page.getByRole("heading", { name: /Edit/ })).toBeVisible();

    await page.goBack();
    page.once("dialog", (dialog) => dialog.accept());
    await page.getByRole("button", { name: "Delete" }).click();
    await expect(page).toHaveURL(/\/books$/);
  });
});
