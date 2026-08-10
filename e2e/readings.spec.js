import { test, expect } from "@playwright/test";
import { signIn, users } from "./support/auth";

test.describe("Readings", () => {
  test("member sees their own shelf, including the seeded reading", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/readings");
    const row = page.locator("tr", { has: page.getByRole("link", { name: "The Great Gatsby" }) });
    await expect(row).toBeVisible();
    await expect(row.locator("i.fa-star")).toHaveCount(4);
  });

  test("member can log a reading with a status, rating, and review", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/readings/new");

    await page.getByLabel("Book").selectOption({ label: "1984" });
    await page.getByLabel("Status").selectOption("finished");
    await page.getByLabel("Rating").selectOption("five");
    await page.getByLabel("Review").fill("Chillingly good.");
    await page.getByRole("button", { name: "Create Reading" }).click();

    await expect(page.getByText("Chillingly good.")).toBeVisible();
    await expect(page.locator("dd i.fa-star")).toHaveCount(5);
  });

  test("editing a reading updates the displayed rating", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/readings");
    const row = page.locator("tr", { has: page.getByRole("link", { name: "1984" }) });
    await row.getByRole("link").last().click();

    await page.getByLabel("Rating").selectOption("one");
    await page.getByRole("button", { name: "Update Reading" }).click();

    await expect(page.locator("dd i.fa-star")).toHaveCount(1);
  });

  test("moderator soft-deleting a reading removes it from the owner's shelf", async ({ page, browser }) => {
    await signIn(page, users.moderator);
    await page.goto("/admin/readings");

    const row = page.locator("tr", { has: page.getByRole("link", { name: "The Great Gatsby" }) });
    page.once("dialog", (dialog) => dialog.accept());
    await row.getByRole("button", { name: "Delete" }).click();

    // destroy redirects to the moderator's own shelf; go back to confirm the "deleted" badge
    await page.goto("/admin/readings");
    await expect(
      page.locator("tr", { has: page.getByRole("link", { name: "The Great Gatsby" }) }).getByText("deleted")
    ).toBeVisible();

    // fresh context instead of UI sign-out, to avoid racing the moderator's sign-out redirect
    const memberPage = await (await browser.newContext()).newPage();
    await signIn(memberPage, users.member);
    await memberPage.goto("/readings");
    await expect(memberPage.getByRole("link", { name: "The Great Gatsby" })).toHaveCount(0);
  });
});
