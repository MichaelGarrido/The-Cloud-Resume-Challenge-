const { defineConfig } = require("cypress");

module.exports = defineConfig({
  e2e: {
    baseUrl: process.env.CYPRESS_BASE_URL || "https://michaelgarridoresume.com",
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
});
