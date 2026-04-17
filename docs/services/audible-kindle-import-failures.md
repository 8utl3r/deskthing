# Audible/Kindle → LazyLibrarian Import Failures

Analysis of failures from the import log: what you're missing and how to fix initials.

## Organizations (What You're Missing)

These are **not** individual authors; they're publishers/labels. LazyLibrarian uses Goodreads for author lookups; Goodreads doesn't list most orgs as "authors."

| Org | Book(s) | Notes |
|-----|---------|-------|
| **Alcoholics Anonymous World Services Inc.** | *Alcoholics Anonymous, Fourth Edition* (Big Book) | The org is the publisher. The book is the AA Big Book. |
| **Audible Originals** | *Strong Ending* (Mary-Louise Parker) | Audible Originals is the label; the **author** is Mary-Louise Parker. She's already in your library if you imported her separately. |
| **Civic Ventures** | *Pitchfork Economics with Nick Hanauer* | Civic Ventures is the publisher; Nick Hanauer is the host/author. |

**Bottom line:** You're only missing 3 titles, and 2 of them have real authors you can add manually:
- **Big Book** → Add as standalone book entry or skip (org-published)
- **Strong Ending** → Add **Mary-Louise Parker** if not already in library
- **Pitchfork Economics** → Add **Nick Hanauer** if not already in library

---

## Initials (Were They the Issue?)

**Yes.** LazyLibrarian's Goodreads lookup is sensitive to how initials are formatted.

| Audible name | Result | Goodreads format |
|--------------|--------|------------------|
| C.J. Thompson | ❌ Failed | `C.J. Thompson` (works on Goodreads) |
| JF Brink | ❌ Failed | `J.F. Brink` (periods required) |
| B. V. Larson | ✓ Worked | Space after initials |
| C.B. Titus | ✓ Worked | No space |
| J. R. R. Tolkien | ✓ Worked | Space after each initial |

**Root cause:**
- **JF Brink** – Goodreads expects `J.F. Brink` (periods), not `JF Brink`
- **C.J. Thompson** – May need `C. J. Thompson` (space after C.) or Goodreads search ambiguity

**Fix:** The dashboard now retries with alternate initials formats when the first attempt fails (see `add-authors-dashboard.py`).

---

## Fix: Add by Goodreads ID (addAuthorID)

When `addAuthor` name lookup fails, use **addAuthorID** to add by Goodreads author ID. This bypasses name matching.

### Authors with known Goodreads IDs

| Audible name | Goodreads ID | Series |
|--------------|--------------|--------|
| C.J. Thompson | 1435922 | Rune Seeker (with J.M. Clarke) |
| JF Brink | 50669198 | Defiance of the Fall (with TheFirstDefier) |
| Cixin Liu | 5780686 | Three-Body Problem / Remembrance of Earth's Past |
| Erick Thiemke | 48423774 | A Soldier's Life (with Always RollsAOne) |

### Auto-fix (dashboard + by-ID script)

1. **Dashboard fallback:** The add-authors dashboard now tries `addAuthorID` for these authors when name lookup fails.
2. **One-off add by ID:**

```bash
cd /Users/pete/dotfiles/scripts/servarr
source .env
python3 add-authors-by-id.py --api "http://192.168.0.136:5299/api?apikey=$LAZYLIBRARIAN_API_KEY"
```

### Joseph L. Hoffmann & Michael Lennington

These are co-authors of the *revised* edition of *The Design of Everyday Things*. Goodreads only lists **Donald A. Norman** as the author. Hoffmann and Lennington do not have separate Goodreads author pages. **Fix:** Add **Donald A. Norman** if you want that book; the co-authors cannot be added separately.

---

## Manual Fixes (Other)

1. **Mary-Louise Parker** – Add for *Strong Ending* (Audible Originals)
2. **Nick Hanauer** – Add for *Pitchfork Economics* (Civic Ventures)

---

## Re-run Import

Use the **Rich dashboard** by default (no `--plain`); use `--plain` only for nohup/tail -f logging:

```bash
./scripts/servarr/audible-kindle-to-lazylibrarian.sh
```
