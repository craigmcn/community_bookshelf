import { test, expect } from "./support/fixtures";
import { signIn, users } from "./support/auth";

test.describe("Book clubs", () => {
  test("member starts a club, moderator joins and posts, spoiler posts are flagged", async ({ page, pageAs }) => {
    await signIn(page, users.member);
    await page.goto("/clubs/new");
    await page.getByLabel("Name").fill("1984 Discussion Club");
    await page.getByLabel("Book").selectOption({ label: "1984" });
    await page.getByLabel("Description").fill("A club for discussing 1984.");
    await page.getByRole("button", { name: "Create Club" }).click();

    await expect(page).toHaveURL(/\/clubs\/\d+$/);
    await expect(page.getByText("1 member")).toBeVisible();
    const clubUrl = page.url();

    // fresh context instead of reusing the member's page, since navigating a signed-in
    // page to /sign_in just redirects it away rather than showing the form
    const moderatorPage = await pageAs(users.moderator);
    await moderatorPage.goto(clubUrl);
    await moderatorPage.getByRole("button", { name: "Join Club" }).click();
    await expect(moderatorPage.getByText("2 members")).toBeVisible();

    await moderatorPage.getByLabel("Add a post").fill("Just started chapter 1!");
    await moderatorPage.getByRole("button", { name: "Post" }).click();
    await expect(moderatorPage.getByText("Just started chapter 1!")).toBeVisible();

    await page.goto(clubUrl);
    await page.getByLabel("Add a post").fill("Winston's fate at the end is heartbreaking.");
    await page.getByLabel("Contains spoilers").check();
    await page.getByRole("button", { name: "Post" }).click();
    await expect(page.getByText("Winston's fate at the end is heartbreaking.")).toBeVisible();
    await expect(page.getByText("Spoiler", { exact: true })).toBeVisible();

    await page.getByRole("button", { name: "Leave Club" }).click();
    await expect(page.getByText("1 member")).toBeVisible();
  });
});
