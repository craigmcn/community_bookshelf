import { signIn, users } from "./auth";

// Profile URLs are /users/:id, and nothing in the UI a member can reach
// exposes another member's numeric id directly — so each caller looks it up
// via a throwaway admin context first (admin/users links to it), then
// proceeds with the real member-facing interaction under test.
export async function lookUpUserId(browser, email) {
  const adminContext = await browser.newContext();
  const adminPage = await adminContext.newPage();
  await signIn(adminPage, users.admin);
  await adminPage.goto("/admin/users");

  const href = await adminPage
    .getByRole("row", { name: new RegExp(email) })
    .getByRole("link", { name: "Edit Roles" })
    .getAttribute("href");
  await adminContext.close();

  const match = /\/admin\/users\/(\d+)\/edit/.exec(href ?? "");
  if (!match) throw new Error(`Could not find a user id for ${email}`);
  return match[1];
}
