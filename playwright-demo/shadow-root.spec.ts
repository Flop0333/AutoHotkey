import { test, expect } from '@playwright/test';

test('updates the MDN Tools label', async ({ page }) => {
  await page.goto(
    'https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_shadow_DOM'
  );

  const toolsButton = page
    .locator('button.menu__tab-button')
    .filter({ hasText: 'Tools' });

  await toolsButton.waitFor({ state: 'visible' });

  const toolsLabel = page.locator('span.menu__tab-label').first();
  await toolsLabel.evaluate((element) => {
    element.textContent = 'Automation';
  });


  await expect(toolsLabel).toHaveText('Automation');
});