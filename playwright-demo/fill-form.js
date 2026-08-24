const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { chromium } = require('playwright');

const url = 'https://www.w3schools.com/html/html_forms.asp';
const metadataPath = path.join(__dirname, 'meta-data.json');

async function main() {
  const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.locator('#fname').fill(metadata.username);
  await page.locator('#lname').fill(metadata.date);

  console.log(`Filled #fname with username: ${metadata.username}`);
  console.log(`Filled #lname with date: ${metadata.date}`);
  console.log('Browser is open. Press Enter here to close it.');

  await new Promise((resolve) => {
    const input = readline.createInterface({ input: process.stdin, output: process.stdout });
    input.once('line', () => {
      input.close();
      resolve();
    });
  });

  await browser.close();
}

main().catch((error) => {
  console.error('Playwright script failed:', error);
  process.exit(1);
});
