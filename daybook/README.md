# Day Book

A tear-off desk calendar for the browser: one hand-picked fun observance for every
day of the year, 366 squares, plus links straight to that date's full listing on
[National Day Calendar](https://nationaldaycalendar.com/) and
[National Today](https://nationaltoday.com/).

## Running it

Open `index.html` in a browser. No build step, no server, no dependencies.

```
open index.html
```

## Using it

| Action | How |
| --- | --- |
| Move a day | `←` / `→` or the arrow buttons |
| Back to today | `T` or **Today** |
| Land somewhere random | `R` or **Any day** |
| Jump to a date | the date picker |
| Keep a day | **Save** — stored in `localStorage`, shown as chips below |
| Share a day | **Copy** — puts the date, name, and blurb on the clipboard |

## Files

| File | What it is |
| --- | --- |
| `index.html` | the page |
| `styles.css` | the whole design: two-ink riso palette, both themes |
| `app.js` | date navigation, saved days, clipboard |
| `observances.js` | the data — 366 entries keyed `"MM-DD"` |
| `build.py` | inlines everything into `artifact.html` for publishing |
| `artifact.html` | generated single-file build; don't edit by hand |

## The data

Each entry is one featured observance plus the runners-up for that date:

```js
"08-28": {
  e: "\u{2328}",                          // the stamp emoji
  name: "Crackers Over The Keyboard Day", // the featured day
  blurb: "Everybody eats over the laptop and nobody admits it...",
  also: ["National Bow Tie Day", "Rainbow Bridge Remembrance Day", ...]
}
```

The observances are curated from the two calendars linked above rather than
scraped from them — neither site publishes an API, and a static page can't fetch
across origins anyway. Both sites list more days per square than fit on a page,
which is what the two source links on every day are for. To change what a day
features, edit its entry in `observances.js` and re-run `python3 build.py`.

Feb 29 has its own square. Landing on it from a saved chip in a non-leap year
jumps to the next leap year so the date stays real.
