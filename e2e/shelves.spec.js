import { test, expect } from "@playwright/test";
import { signIn, users } from "./support/auth";

test.describe("Shelves (Lists)", () => {
  test("member sees their seeded list", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/shelves");
    await expect(page.getByRole("link", { name: "Favorites", exact: true })).toBeVisible();
  });

  test("member can create a list and save a book to it from the book page", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/shelves/new");
    await page.getByLabel("Name").fill("2026 TBR");
    await page.getByRole("button", { name: "Create List" }).click();
    await expect(page.getByRole("heading", { name: "2026 TBR" })).toBeVisible();

    await page.goto("/books");
    await page.getByRole("link", { name: "1984" }).click();
    await page.getByRole("button", { name: "Save to a List" }).click();
    await page.getByRole("button", { name: "2026 TBR" }).click();
    await expect(page.getByRole("alert")).toContainText('Added "1984" to 2026 TBR.');

    await page.getByRole("button", { name: "Save to a List" }).click();
    await expect(page.getByRole("button", { name: "2026 TBR" }).locator(".fa-check")).toBeVisible();

    await page.goto("/shelves");
    await page.getByRole("link", { name: "2026 TBR" }).click();
    await expect(page.getByRole("link", { name: "1984" })).toBeVisible();
  });

  test("member can remove a book from a list", async ({ page }) => {
    // The Great Gatsby starts on the member's Favorites list via the shelf_books fixture.
    await signIn(page, users.member);
    await page.goto("/books");
    await page.getByRole("link", { name: "The Great Gatsby" }).click();
    await page.getByRole("button", { name: "Save to a List" }).click();
    await expect(page.getByRole("button", { name: "Favorites" }).locator(".fa-check")).toBeVisible();

    await page.getByRole("button", { name: "Favorites" }).click();
    await expect(page.getByRole("alert")).toContainText('Removed "The Great Gatsby" from Favorites.');
    await page.getByRole("button", { name: "Save to a List" }).click();
    await expect(page.getByRole("button", { name: "Favorites" }).locator(".fa-check")).toHaveCount(0);

    // put it back so the fixture list stays stable for other specs/runs
    await page.getByRole("button", { name: "Favorites" }).click();
    await expect(page.getByRole("alert")).toContainText('Added "The Great Gatsby" to Favorites.');
  });
});
