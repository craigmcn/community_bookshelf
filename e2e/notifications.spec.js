import { test, expect } from "./support/fixtures";
import { signIn, users } from "./support/auth";
import { lookUpUserId } from "./support/admin";

// Other specs (buddy reads, book clubs) leave unrelated notifications behind
// as a side effect of actions they don't revert, so the unread count here
// can't be asserted as an absolute — only as a delta around this test's own
// follow/unfollow.
async function unreadCount(page) {
  const label = await page.getByRole("link", { name: /^Notifications/ }).getAttribute("aria-label");
  const match = /\((\d+)\+? unread\)/.exec(label ?? "");
  return match ? Number(match[1]) : 0;
}

test.describe("Notifications", () => {
  test("bell badge, dropdown preview, and inbox mark-as-read reflect a new follower", async ({ page, browser, pageAs }) => {
    const memberId = await lookUpUserId(browser, users.member.email);

    // fresh context instead of reusing the member's page, since navigating a signed-in
    // page to /sign_in just redirects it away rather than showing the form
    const moderatorPage = await pageAs(users.moderator);
    await moderatorPage.goto("/");
    const before = await unreadCount(moderatorPage);

    // member follows moderator, so moderator gets a new_follower notification
    await signIn(page, users.member);
    const moderatorId = await lookUpUserId(browser, users.moderator.email);
    await page.goto(`/users/${moderatorId}`);
    await page.getByRole("button", { name: "Follow" }).click();
    await expect(page.getByRole("button", { name: "Following" })).toBeVisible();

    await moderatorPage.goto("/");
    await expect(moderatorPage.getByRole("link", { name: /^Notifications/ })).toHaveAttribute(
      "aria-label",
      new RegExp(`\\(${before + 1} unread\\)`),
    );
    await moderatorPage.getByRole("link", { name: /^Notifications/ }).click();
    const followNotification = moderatorPage.getByRole("button", { name: /started following you/ }).first();
    await expect(followNotification).toBeVisible();

    await followNotification.click();
    await expect(moderatorPage).toHaveURL(new RegExp(`/users/${memberId}$`));

    await moderatorPage.goto("/");
    await expect(moderatorPage.getByRole("link", { name: /^Notifications/ })).toHaveAttribute(
      "aria-label",
      new RegExp(`\\(${before} unread\\)|^Notifications$`),
    );

    await moderatorPage.goto("/notifications");
    const main = moderatorPage.locator("#main-content");
    await expect(main.getByText("You don't have any notifications yet.")).not.toBeVisible();
    await expect(main.getByText("started following you")).toBeVisible();

    // revert so the fixture users stay stable for other specs/runs
    await page.goto(`/users/${moderatorId}`);
    await page.getByRole("button", { name: "Following" }).click();
    await expect(page.getByRole("button", { name: "Follow" })).toBeVisible();
  });
});
