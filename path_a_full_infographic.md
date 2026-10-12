# Path A prompt: Claude cleans the data and draws the infographic

Start a new chat with Claude (with file uploads and Artifacts enabled) and attach your `goodreads_library_export.csv`. Fill in the three lines in square brackets, then paste everything inside the box.

```text
My name: [your first name]
Languages I read in: [e.g. English, Spanish, Portuguese]
Extra country rules (optional): [e.g. "Armenian writers born in present-day Turkey or Azerbaijan count as Armenia"]

I've attached my raw Goodreads library export. Clean it, tag it, check reading languages with me, and make one infographic of the books I've read. Follow these steps in order. Never skip a step where you ask me to confirm, and ask me whenever you're unsure instead of guessing silently.

STEP 1 – LOAD
- Read the CSV and report the row count and the Exclusive Shelf counts.
- Read shelf = Exclusive Shelf "read". To-read + currently-reading are used only to count countries still waiting. Ignore did-not-finish.

STEP 2 – TAG AUTHORS
- Add Author_Clean (one spelling per author: merge the same author written in different scripts, reversed names and pen names to the real author), Author_Gender (Male, Female, Non-binary, Mixed (anthology) for multi-author anthologies, Unknown for anonymous or institutional authors), Author_Country and Tag_Note.
- Country of origin = where the author was born and/or grew up, in today's borders. When birth and upbringing differ, upbringing wins; put the other angle in Tag_Note (e.g. "born in Japan").
- Apply my extra country rules above, if any.
- Use English country names and check each one matches a region in R's maps::map_data("world") after recoding United States -> USA, United Kingdom -> UK, Czechia -> Czech Republic.
- CONFIRM: show me a table of every author whose gender or country you're unsure of (author, one title, shelf, your guess). Apply my corrections; anything I don't mention keeps your guess.

STEP 3 – REMOVE DUPLICATES
Remove:
1. separate volumes when the full work is on the shelf (keep the full work);
2. titles contained in a collection or combined edition that is also on the shelf;
3. second copies, editions or translations of the same book (keep the one in the language I read, if you can tell);
4. retellings or adaptations of an original I've also read;
5. to-read copies of books already on the read shelf, and duplicate to-read entries.
Keep separate parts when no full edition exists.
- CONFIRM: write every removal to removed_books.csv with a Removal_Reason column and show me the list before continuing.

STEP 4 – READING-LANGUAGE CHECK (book by book)
Goodreads editions don't say which language I read a book in, so don't trust edition-based guesses alone.
1. Guess a language for every read book from the title's script, title language and publisher; otherwise English.
2. Publish an interactive page (Artifact with the db capability) showing my read books one at a time, sorted by author: title, author, position ("Book 12 of 480") and your guess pre-selected. Give it one button per language I read in (keyboard shortcuts 1–9; picking one saves and moves on), Enter to keep the highlighted choice, left/right arrows, a "Read in more than one language" checkbox, an "Other" text box (I'll type "Not read" there for books I never read), a progress bar, "Next unchecked", and a searchable list of all books. Save each answer to collection "languages", doc id = Book Id, as {title, author, langs, guess, at}, and resume at the first unchecked book.
3. Wait until I say I'm done. Read every answer back, check every read book has one, and tell me how many changed from your guess.
4. Store the result as Reading_Language; join several languages with "; ".
5. Drop books I marked "Not read" from the read shelf and add them to removed_books.csv.

STEP 5 – FIGURES (read shelf, after steps 2–4)
- Headline: books read; different authors (unique Author_Clean); countries of origin (excluding Unknown); reading languages.
- Map: countries with at least one read book filled red (#C0392B) on white, Antarctica removed. Note how many countries on to-read + currently-reading aren't on the read shelf yet.
- Who wrote them: count and % of all read books by men and by women; a note naming how many books are left out and why.
- Women's share by year: share of Female among books read each year (from Date Read), dot size = books that year, lowest and highest years labelled, a note comparing before vs since the middle year, and the current year flagged as partial.
- Top 10 countries by books read.
- Reading languages: books per language (a book read in two languages counts in each), count and % per language, % not in English; a note if the bars add up to more than the number of books.
- Most-read authors: top 6 by books read (using Author_Clean).
- Ratings by country: average My Rating (ratings > 0) for countries with 8+ rated books, on a 1–5 scale, a tick at my overall average, n per country, panel titled after the top country.

STEP 6 – INFOGRAPHIC
One static page, 1000 px wide, rendered to PNG at 2x. Background #FBF8F3, ink #1F1B16 / #5C554C / #8E867B, rules #E7E0D6, red #C0392B for most bars and the map, blue #2E6A9E for male, light red #D9A39C for the English bar. Fonts: Fraunces for headings and big numbers, Inter for text. Thin bars, no chart junk, a short heading, a one-line description and a small muted note per panel.
Layout top to bottom: title "[my name]'s Reading Life" ("Reading" in red) with subtitle "Everything on the Goodreads “read” shelf, by the numbers"; four headline numbers between a heavy top rule and a light bottom rule; the map with its note; then a two-column grid: Who wrote them | Women's share by year; Top 10 countries | Reading languages; Most-read authors | Ratings by country; footer with the source and the month.
Look at the rendered PNG once, fix clipped labels and overlaps, and check every number against the data.

DELIVER: reading_infographic.png, goodreads_cleaned.csv (all shelves, with the added columns), removed_books.csv. Keep your final message short.
```

What happens next: Claude reports your shelves, shows a table of uncertain authors, then a list of removals. After you confirm, it publishes the language-check page. Tell Claude when you've finished it, and the infographic follows.
