import { test as base, expect } from "@playwright/test";
import { signIn } from "./auth";

// pageAs(user) opens a second signed-in browser context for multi-user scenarios.
// Contexts are closed at teardown even when the test fails, since the suite runs
// serially in one worker and leaked contexts would pile up until the browser exits.
export const test = base.extend({
  pageAs: async ({ browser }, use) => {
    const contexts = [];
    await use(async (user) => {
      const context = await browser.newContext();
      contexts.push(context);
      const page = await context.newPage();
      await signIn(page, user);
      return page;
    });
    await Promise.all(contexts.map((context) => context.close()));
  },
});

export { expect };
