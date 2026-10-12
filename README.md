# Goodreads Reading Infographic

Turn your Goodreads library into one infographic of everything you've read: where your authors come from, who wrote your books, which languages you read in, and what you rate highest.

![Example infographic](output/reading_infographic.png)

The example above is drawn from my own library (479 books), included as `data/goodreads_cleaned.csv`.

## What the infographic shows

| Panel | What it shows |
| --- | --- |
| Headline numbers | Books read, different authors, countries of origin, reading languages |
| World map | Every country your authors come from, plus how many new countries are waiting on your to-read list |
| Who wrote them | Share of books by men and by women |
| Women's share by year | How the share of books by women changed over time |
| Top 10 countries | Books read per author country |
| Reading languages | Books per language you actually read them in |
| Most-read authors | Your six most-read authors |
| Ratings by country | Your average star rating per author country (8+ rated books) |

## How it works

The raw Goodreads export can't be charted directly. It doesn't record an author's gender or country, the same book often appears several times, and the edition you logged often isn't the language you read. So there are two stages:

1. **Clean the data with Claude.** Claude tags every author, removes duplicates, and checks the reading language of every book with you, one book at a time. It asks you whenever it isn't sure. The result is `goodreads_cleaned.csv`.
2. **Draw the infographic in R.** `goodreads_infographic.R` reads the cleaned CSV and draws `output/reading_infographic.png`.

If you'd rather not use R, Claude can draw the infographic too: see [Path A](prompts/path_a_full_infographic.md).

## Repository layout

```
goodreads-reading-infographic/
├── README.md
├── goodreads_infographic.R            # draws the infographic from the cleaned CSV
├── data/
│   └── goodreads_cleaned.csv          # the cleaned library (yours goes here)
├── output/
│   └── reading_infographic.png        # the script writes here
└── prompts/
    ├── path_a_full_infographic.md     # Claude cleans the data and draws the infographic
    └── path_b_cleaned_data_only.md    # Claude cleans the data; you run the R script
```

## Step 1: Export your Goodreads library

1. Sign in at [goodreads.com](https://www.goodreads.com) on a computer; the export isn't in the mobile app.
2. Go to **My Books**, then **Import and export** in the left sidebar under Tools.
3. Click **Export Library** and wait for the download link. This can take a few minutes for large libraries.
4. Download `goodreads_library_export.csv`.

To find the file afterwards, look in your browser's Downloads folder (on Windows and Mac, usually the **Downloads** folder in your user folder), or search your computer for `goodreads_library_export`. If you've exported before, the newest copy may be named `goodreads_library_export (1).csv`; use the most recent one.

## Step 2: Clean it with Claude

Start a new chat with Claude, attach the export, and paste the [Path B prompt](prompts/path_b_cleaned_data_only.md). Fill in your name, the languages you read in, and any extra country rules. Expect these decisions along the way:

| Stage | What Claude does | What you'll be asked |
| --- | --- | --- |
| Author tagging | Adds gender and country of origin to every author. Country = where the author was born or grew up, in today's borders. Merges one author written in two scripts or under a pen name. | A table of authors it isn't sure about. Correct only the wrong ones. |
| Duplicates | Removes separate volumes when the full work is on the shelf, titles contained in a collection you also logged, second copies or translations, retellings of originals you read, and to-read copies of books already read. | The list of removals with a reason for each, before anything is dropped. |
| Reading language | Guesses a language per book, then builds a page that shows your read books one at a time. | Pick the language you read each book in (Enter keeps the guess). Mark books you never read as "Not read". |

The language check matters most. In my library, 110 of 482 books turned out to be in a different language from the one Goodreads implied, mostly books read in Armenian but logged as English editions.

Everything removed goes into `removed_books.csv` with its reason, so nothing disappears silently. Plan on about an hour, most of it spent on the language check.

### Cleaned data format

`goodreads_cleaned.csv` keeps all the original Goodreads columns and adds five more. The script matches column names and values literally, so keep them exactly as shown.

| Column | Values | Used for |
| --- | --- | --- |
| `Author_Clean` | One spelling per author, e.g. "Raffi" for both `Րաֆֆի` and "Raffi (Hagop Melik-Hagopian)" | Different authors, most-read authors |
| `Author_Gender` | `Female`, `Male`, `Non-binary`, `Mixed (anthology)`, `Unknown` | Who wrote them, women's share by year |
| `Author_Country` | English country name in today's borders, or `Unknown` | Map, top 10 countries, ratings by country, countries waiting |
| `Tag_Note` | Free text, e.g. "born in Japan" | Your own checking only |
| `Reading_Language` | e.g. `English` or `Armenian; English`; blank outside the read shelf | Reading languages |

The script also uses these original Goodreads columns: `Exclusive Shelf`, `Date Read` and `My Rating`. Save the file as UTF-8.

## Step 3: Draw the infographic in R

1. Install R 4.1 or newer from [cran.r-project.org](https://cran.r-project.org). [RStudio](https://posit.co/download/rstudio-desktop/) is optional.
2. Install the packages once:

   ```r
   install.packages(c("readr", "dplyr", "tidyr", "ggplot2", "maps", "patchwork", "ggtext", "ragg"))
   ```

3. Optional: install the fonts [Fraunces](https://fonts.google.com/specimen/Fraunces) and [Inter](https://fonts.google.com/specimen/Inter) for the intended look. Without them the script falls back to your system's serif and sans fonts and prints a tip.
4. Clone or download this repository and put your `goodreads_cleaned.csv` in `data/`.
5. Open `goodreads_infographic.R` and edit the settings at the top (see below). At minimum, set `NAME`.
6. Run it from the repository root:

   ```sh
   Rscript goodreads_infographic.R
   ```

   In RStudio, open the script, choose **Session → Set Working Directory → To Source File Location**, then click **Source**.

7. Open `output/reading_infographic.png`. The console prints a summary such as `Saved output/reading_infographic.png (479 books, 56 countries, 6 languages).`

### Settings

| Setting | Default | What it does |
| --- | --- | --- |
| `NAME` | `"Byurakn"` | Your first name for the title; `""` gives "My Reading Life" |
| `INPUT` | `"data/goodreads_cleaned.csv"` | Path to the cleaned CSV |
| `OUTPUT` | `"output/reading_infographic.png"` | Where the PNG is written |
| `FIRST_YEAR` | `2011` | First year in the women's-share chart; `NULL` = earliest date read |
| `SPLIT_YEAR` | `2018` | Year for the "before / since" comparison; `NULL` = middle of the range |
| `MIN_RATED` | `8` | Minimum rated books for a country to appear in ratings by country |
| `TOP_AUTHORS` | `6` | Number of most-read authors |
| `COUNTRY_NOTE` | My country rule | The sentence printed under the map; describe your own rules here |
| `COL` | Warm off-white, red and blue | All colours |

To drop a panel, remove it from the `final <-` line near the end of the script, and give the `heights` list one value per remaining row.

## Country rules

"Where the author was born or grew up, in today's borders" is a choice, not a fact. Without an extra rule, a Western Armenian writer born in Istanbul lands under Turkey.

My data uses one extra rule: Armenian writers born in present-day Turkey or present-day Azerbaijan (historic Western Armenia, Constantinople, Shamakhi, Shushi, Baku) count as Armenia. All other Armenian-heritage writers keep their actual country, for example Saroyan (United States) and Nar-Dos (Georgia).

Decide what you want your map to say before you start, give that rule to Claude in the prompt, and describe it in `COUNTRY_NOTE`.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `Can't find data/goodreads_cleaned.csv` | Put the file in `data/`, or change `INPUT`. Run the script from the repository root. |
| `Missing columns in …` | The CSV isn't the cleaned file. Ask Claude for the five added columns named exactly as in "Cleaned data format". |
| Warning `Not drawn on the map` | A country name doesn't match R's world map. Rename it in the CSV, or add it to the `to_map` list in the script. |
| Letters show as boxes or `<U+0531>` | The CSV isn't UTF-8. Re-save it as UTF-8. |
| The fonts look plain | Install Fraunces and Inter, restart R, and run again. |
| A panel looks squashed | Increase that row's value in the `heights` list, or the overall height `h`, near the end of the script. |
| The language-check page says "Not connected" | Your answers aren't being saved. Reload the page, or ask Claude to republish it. |

## Privacy

Your cleaned CSV includes your ratings, reading dates and reviews from Goodreads. If you publish your data, check the `My Review` and `Private Notes` columns first and blank them if you want them private.
