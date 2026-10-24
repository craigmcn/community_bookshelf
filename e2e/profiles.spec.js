import { test, expect } from "@playwright/test";
import { signIn, users } from "./support/auth";
import { lookUpUserId } from "./support/admin";

test.describe("Profiles", () => {
  test("member's profile shows their favorite genres and public reviews", async ({ page, browser }) => {
    await signIn(page, users.member);
    await page.goto("/account/edit");
    await page.getByLabel("Favorite Genres").fill("fantasy");
    await page.getByRole("button", { name: "Save Changes" }).click();

    const memberId = await lookUpUserId(browser, users.member.email);
    await page.goto(`/users/${memberId}`);
    await expect(page.getByRole("link", { name: "fantasy" })).toBeVisible();
    await expect(page.getByText("A great read.")).toBeVisible();

    // revert so the fixture user stays stable for other specs/runs
    await page.goto("/account/edit");
    await page.getByLabel("Favorite Genres").fill("");
    await page.getByRole("button", { name: "Save Changes" }).click();
  });

  test("member can follow and unfollow another member from their profile", async ({ page, browser }) => {
    const moderatorId = await lookUpUserId(browser, users.moderator.email);

    await signIn(page, users.member);
    await page.goto(`/users/${moderatorId}`);

    await page.getByRole("button", { name: "Follow" }).click();
    await expect(page.getByRole("button", { name: "Following" })).toBeVisible();

    await page.getByRole("link", { name: "Followers" }).click();
    await expect(page.getByRole("heading", { name: /Followers/ })).toBeVisible();
    await expect(page.locator("#main-content").getByRole("link", { name: users.member.email })).toBeVisible();

    await page.goBack();
    await page.getByRole("button", { name: "Following" }).click();
    await expect(page.getByRole("button", { name: "Follow" })).toBeVisible();
  });
});
