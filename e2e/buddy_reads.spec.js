import { test, expect } from "@playwright/test";
import { signIn, users } from "./support/auth";

test.describe("Buddy reads", () => {
  test("member invites a buddy, buddy accepts, and they exchange messages", async ({ page, browser }) => {
    await signIn(page, users.member);
    await page.goto("/buddy_reads/new");
    await page.getByLabel("Book").selectOption({ label: "1984" });
    await page.getByLabel("Buddy").selectOption({ label: users.moderator.email });
    await page.getByRole("button", { name: "Send Invite" }).click();

    await expect(page).toHaveURL(/\/buddy_reads\/\d+$/);
    await expect(page.getByText("Pending")).toBeVisible();
    const buddyReadUrl = page.url();

    // fresh context instead of reusing the member's page, since navigating a signed-in
    // page to /sign_in just redirects it away rather than showing the form
    const moderatorPage = await (await browser.newContext()).newPage();
    await signIn(moderatorPage, users.moderator);
    await moderatorPage.goto(buddyReadUrl);
    await moderatorPage.getByRole("button", { name: "Accept" }).click();
    await expect(moderatorPage.getByText("Accepted")).toBeVisible();

    await moderatorPage.getByLabel("Add a message").fill("Just started chapter 1!");
    await moderatorPage.getByRole("button", { name: "Post Message" }).click();
    await expect(moderatorPage.getByText("Just started chapter 1!")).toBeVisible();

    await page.goto(buddyReadUrl);
    await expect(page.getByText("Just started chapter 1!")).toBeVisible();
    await page.getByLabel("Add a message").fill("Me too, loving it so far.");
    await page.getByRole("button", { name: "Post Message" }).click();
    await expect(page.getByText("Me too, loving it so far.")).toBeVisible();

    await page.getByRole("button", { name: "Mark Completed" }).click();
    await expect(page.getByText("Completed")).toBeVisible();
    // messaging stays open after completion (only declining/cancelling closes it)
    await expect(page.getByLabel("Add a message")).toBeVisible();
  });
});
