import { test, expect } from "@playwright/test";
import { signIn, users } from "./support/auth";

test.describe("Books", () => {
  test("index and show are visible signed out", async ({ page }) => {
    await page.goto("/books");
    await expect(page.getByRole("heading", { name: "Books" })).toBeVisible();
    await page.getByRole("link", { name: "The Great Gatsby" }).click();
    await expect(page.getByRole("heading", { name: "The Great Gatsby" })).toBeVisible();
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
