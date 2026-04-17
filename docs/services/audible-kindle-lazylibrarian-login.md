# Audible + Kindle → LazyLibrarian: Login Guide

How to log in so the import script can export your libraries.

---

## Quick checklist (what you need to do)

1. **Audible:** Run `audible quickstart` once → use external login (paste redirect URL)
2. **Kindle:** Open read.amazon.com/kindle-library → run `scripts/servarr/kindle-export-console.js` in Console → save CSV to `scripts/servarr/kindle-library.csv`
3. **LazyLibrarian API key:** Add `LAZYLIBRARIAN_API_KEY=...` to `scripts/servarr/.env` (from LazyLibrarian Config → Interface)
4. **Run:** `./scripts/servarr/audible-kindle-to-lazylibrarian.sh`

---

## Audible login (audible-cli)

### 1. Install audible-cli

```bash
pip install -r ~/dotfiles/scripts/servarr/requirements.txt
# or
pip install audible-cli
# or
uv tool install audible-cli
```

### 2. Run quickstart (one-time)

```bash
audible quickstart
```

### 3. Choose login method

**Option A: External login (recommended)**

- Select your locale (e.g. `us` for US Audible)
- The CLI will print a URL or open your browser
- Log in to Amazon/Audible in the browser (including 2FA/CAPTCHA if prompted)
- Copy the redirect URL from the browser address bar (after login)
- Paste it back into the terminal when prompted
- Auth is saved to `~/.audible/` (or `$AUDIBLE_CONFIG_DIR`)

**Option B: Username + password**

- Enter your Audible/Amazon email and password
- If CAPTCHA or 2FA is required, you may need to use external login instead

### 4. Verify

```bash
audible library list
```

If you see your books, you're logged in.

---

## Kindle export (manual, one-time)

1. Go to https://read.amazon.com/kindle-library
2. Sign in if needed
3. Open DevTools (F12 or Cmd+Option+I) → Console tab
4. Paste the contents of `scripts/servarr/kindle-export-console.js` (or the script below) and press Enter:

```javascript
// Copy from scripts/servarr/kindle-export-console.js or use:
let xhr = new XMLHttpRequest();
let items = [];
let csvData = "ASIN,Title,Author,Read%\n";
function getItemsList(paginationToken = null) {
  let url = 'https://read.amazon.com/kindle-library/search?query=&libraryType=BOOKS' + (paginationToken ? '&paginationToken=' + paginationToken : '') + '&sortType=acquisition_desc&querySize=50';
  xhr.open('GET', url, false);
  xhr.send();
}
xhr.onreadystatechange = function() {
  if (xhr.readyState === 4 && xhr.status === 200) {
    let data = JSON.parse(xhr.responseText);
    if (data.itemsList) items.push(...data.itemsList);
    if (data.paginationToken) getItemsList(data.paginationToken);
  }
};
getItemsList();
items.forEach(item => {
  csvData += '"' + (item.asin||'') + '","' + (item.title||'').replace(/"/g,'""') + '","' + (item.authors?.[0]||'') + '","' + (item.percentageRead||'') + '"\n';
});
let a = document.createElement('a');
a.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvData);
a.download = 'kindle-library.csv';
a.click();
console.log('Exported ' + items.length + ' books');
```

5. Save the downloaded `kindle-library.csv` to:

   ```
   ~/dotfiles/scripts/servarr/kindle-library.csv
   ```

---

## Run the import script

```bash
cd ~/dotfiles
./scripts/servarr/audible-kindle-to-lazylibrarian.sh
```

Use `--fresh` to re-export from Audible:

```bash
./scripts/servarr/audible-kindle-to-lazylibrarian.sh --fresh
```

For background runs (e.g. nohup), use `--plain` for append-friendly log lines you can tail:

```bash
nohup ./scripts/servarr/audible-kindle-to-lazylibrarian.sh --plain > import.log 2>&1 &
```

```bash
tail -f import.log
```

---

## Troubleshooting

**Audible: "Export failed"**
- Run `audible quickstart` again
- Use external login if password login fails

**Audible: "Authentication expired"**
- Run `audible quickstart` again to re-auth

**Kindle: Script does nothing**
- Make sure you're on the Books tab at read.amazon.com/kindle-library
- Check the Console for errors

**LazyLibrarian: "No API key"**
- Set `LAZYLIBRARIAN_API_KEY` in `scripts/servarr/.env`
