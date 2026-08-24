# Playwright Demo

This project contains a tiny browser automation example that opens the W3Schools HTML forms page and fills its visible example form.

## Files
- `meta-data.json` - values used by the automation
- `fill-form.js` - headed Playwright script that fills the form
- `package.json` - project config and scripts

## Run it
```bash
npm install
npx playwright install chromium
npm start
```

The browser opens visibly, fills `#fname` with `username` and `#lname` with `date`, then stays open until you press Enter in the terminal.

If PowerShell blocks scripts, use:
```powershell
$env:PATH += ';C:\Program Files\nodejs'
& "C:\Program Files\nodejs\npm.cmd" install
& "C:\Program Files\nodejs\npx.cmd" playwright install chromium
& "C:\Program Files\nodejs\npm.cmd" start
```
