// Shared fixture credentials — same rows across community_bookshelf, bookshelf-islands,
// bookshelf-api and bookshelf-spa (see test/fixtures/users.yml in each Rails repo).
export const users = {
  member: { email: "member@example.com", password: "correct-horse-shelf" },
  moderator: { email: "moderator@example.com", password: "correct-horse-shelf" },
  admin: { email: "admin@example.com", password: "correct-horse-shelf" },
};

export async function submitSignInForm(page, user) {
  await page.goto("/sign_in");
  await page.getByLabel("Email").fill(user.email);
  await page.getByLabel("Password").fill(user.password);
  await page.getByRole("button", { name: "Sign In" }).click();
}

export async function signIn(page, user) {
  await submitSignInForm(page, user);
  // The click only waits for the click event, not for the sign-in redirect chain
  // (POST /session -> 302 -> GET) to actually settle the auth cookie. Callers that
  // immediately page.goto() elsewhere can otherwise race an unauthenticated request.
  await page.waitForURL((url) => !url.pathname.startsWith("/sign_in") && !url.pathname.startsWith("/session"));
}
