import { test, expect } from "@playwright/test";
import { signIn, users } from "./support/auth";

test.describe("Admin access control", () => {
  test("unauthenticated user is redirected to sign-in", async ({ page }) => {
    await page.goto("/admin");
    await expect(page).toHaveURL(/\/sign_in$/);
  });

  test("member (non-moderator) is denied", async ({ page }) => {
    await signIn(page, users.member);
    const response = await page.goto("/admin/readings");
    expect(response.status()).toBe(403);
  });

  test("moderator can reach Reviewed Readings but not the Dashboard or Users", async ({ page }) => {
    await signIn(page, users.moderator);

    await page.goto("/admin/readings");
    await expect(page.getByRole("heading", { name: "Reviewed Readings" })).toBeVisible();

    const dashboard = await page.goto("/admin");
    expect(dashboard.status()).toBe(403);

    const usersPage = await page.goto("/admin/users");
    expect(usersPage.status()).toBe(403);
  });

  test("admin can reach the Dashboard and edit user roles", async ({ page }) => {
    await signIn(page, users.admin);

    await page.goto("/admin");
    await expect(page.getByRole("heading", { name: "Admin Dashboard" })).toBeVisible();

    await page.goto("/admin/users");
    await page.getByRole("row", { name: /member@example.com/ }).getByRole("link", { name: "Edit Roles" }).click();

    await page.getByLabel("Moderator").check();
    await page.getByRole("button", { name: "Update Roles" }).click();

    await expect(page).toHaveURL(/\/admin\/users$/);
    await expect(
      page.getByRole("row", { name: /member@example.com/ }).getByText("Moderator")
    ).toBeVisible();

    // revert so the fixture user's role stays stable for other specs/runs
    await page.getByRole("row", { name: /member@example.com/ }).getByRole("link", { name: "Edit Roles" }).click();
    await page.getByLabel("Moderator").uncheck();
    await page.getByRole("button", { name: "Update Roles" }).click();
  });
});
