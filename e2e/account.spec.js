import path from "node:path";
import { test, expect } from "@playwright/test";
import { signIn, users } from "./support/auth";

const avatarPath = path.join(process.cwd(), "test/fixtures/files/avatar.png");

test.describe("Account", () => {
  test("member can update their display name and bio, visible elsewhere in the app", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/account/edit");

    await page.getByLabel("Display Name").fill("Sam Reader");
    await page.getByLabel("Bio").fill("I like fantasy novels.");
    await page.getByRole("button", { name: "Save Changes" }).click();
    await expect(page.getByRole("alert")).toContainText("Profile updated");

    await page.goto("/books/new");
    await page.getByLabel("Search for a Book").fill("hobbit");
    await page.getByRole("button", { name: /The Hobbit/ }).click();
    await page.getByRole("button", { name: "Create Book" }).click();
    await expect(page.getByText("Added by Sam Reader")).toBeVisible();

    // revert so the fixture user stays stable for other specs/runs
    await page.goto("/account/edit");
    await page.getByLabel("Display Name").fill("");
    await page.getByLabel("Bio").fill("");
    await page.getByRole("button", { name: "Save Changes" }).click();
  });

  test("member can upload and then remove an avatar", async ({ page }) => {
    await signIn(page, users.member);
    await page.goto("/account/edit");

    await page.locator('input[type="file"]').setInputFiles(avatarPath);
    await page.getByRole("button", { name: "Save Changes" }).click();
    await expect(page.getByRole("alert")).toContainText("Profile updated");
    await expect(page.getByAltText("Current avatar")).toBeVisible();

    await page.getByLabel("Remove avatar").check();
    await page.getByRole("button", { name: "Save Changes" }).click();
    await expect(page.getByAltText("Current avatar")).toHaveCount(0);
  });
});
