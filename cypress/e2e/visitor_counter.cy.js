describe("Resume site visitor counter", () => {
  it("increments the visitor count after reload", () => {
    cy.visit("/");

    cy.get("#visitor-count", { timeout: 10000 })
      .should(($el) => {
        const text = $el.text().trim();
        expect(text).to.match(/^\d+$/);
      })
      .invoke("text")
      .then((firstText) => {
        const firstCount = parseInt(firstText.trim(), 10);

        cy.wait(1500);
        cy.reload();

        cy.get("#visitor-count", { timeout: 10000 })
          .should(($el) => {
            const text = $el.text().trim();
            expect(text).to.match(/^\d+$/);
          })
          .invoke("text")
          .then((secondText) => {
            const secondCount = parseInt(secondText.trim(), 10);
            expect(secondCount).to.be.greaterThan(firstCount);
          });
      });
  });
});
