import { test, expect } from "./support/fixtures";
import { signIn, users } from "./support/auth";

test.describe("Activity feed", () => {
  test("member sees a followed moderator's reading activity in their feed", async ({ page, pageAs }) => {
    // fresh context instead of reusing the member's page, since navigating a signed-in
    // page to /sign_in just redirects it away rather than showing the form
    const moderatorPage = await pageAs(users.moderator);
    await moderatorPage.goto("/readings/new");
    await moderatorPage.getByLabel("Book").selectOption({ label: "1984" });
    await moderatorPage.getByLabel("Status").selectOption({ label: "Want to read" });
    await moderatorPage.getByRole("button", { name: "Create Reading" }).click();
    await expect(moderatorPage).toHaveURL(/\/readings\/\d+$/);
    const moderatorReadingUrl = moderatorPage.url();

    await signIn(page, users.member);
    await page.goto("/books");
    await page.getByRole("link", { name: "1984" }).click();
    await page.getByRole("link", { name: users.moderator.email }).click(); // moderator's row in Community Readings
    await expect(page).toHaveURL(/\/users\/\d+$/);
    const moderatorProfileUrl = page.url();
    await page.getByRole("button", { name: "Follow" }).click();

    await page.goto("/feed");
    await expect(page.getByRole("link", { name: users.moderator.email })).toBeVisible();
    await expect(page.getByText("added 1984 to their shelf")).toBeVisible();

    // revert the follow and the created reading so the fixture users stay stable for other specs/runs
    await page.goto(moderatorProfileUrl);
    await page.getByRole("button", { name: "Following" }).click();

    await moderatorPage.goto(moderatorReadingUrl);
    moderatorPage.once("dialog", (dialog) => dialog.accept());
    await moderatorPage.getByRole("button", { name: "Delete" }).click();
  });
});
