# Path B prompt: Claude cleans the data, you draw the infographic in R

Use the [Path A prompt](path_a_full_infographic.md) with one change: delete everything from `STEP 5 – FIGURES` to the end, and paste this block in its place.

```text
STEP 5 – DELIVER THE CLEANED DATA (no infographic)
Don't compute figures or draw anything. Deliver:
- goodreads_cleaned.csv: every remaining row from all shelves, all original Goodreads columns unchanged, plus the columns Author_Clean, Author_Gender, Author_Country, Tag_Note and Reading_Language exactly as named here. Fill Reading_Language for the read shelf only. Save as UTF-8.
- removed_books.csv: every removed row with its Removal_Reason.
Then tell me how many books are on each shelf and list any country name that doesn't match a region in maps::map_data("world").
```

When Claude hands you `goodreads_cleaned.csv`, put it in this repository's `data/` folder and follow "Draw the infographic in R" in the [README](../README.md).
