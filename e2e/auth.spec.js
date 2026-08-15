import { test, expect } from "@playwright/test";
import { signIn, submitSignInForm, users } from "./support/auth";

test.describe("Auth", () => {
  test("signed-out user hitting a protected page is redirected to sign-in", async ({ page }) => {
    await page.goto("/readings");
    await expect(page).toHaveURL(/\/sign_in$/);
  });

  test("member can sign in and lands on My Shelf", async ({ page }) => {
    await signIn(page, users.member);
    await expect(page).toHaveURL("/");
    await expect(page.getByRole("heading", { name: "My Shelf" })).toBeVisible();
  });

  test("wrong password shows an error and stays on the sign-in form", async ({ page }) => {
    await submitSignInForm(page, { email: users.member.email, password: "wrong-password" });
    await expect(page.getByRole("alert")).toBeVisible();
    await expect(page.getByLabel("Email")).toBeVisible();
  });
});
