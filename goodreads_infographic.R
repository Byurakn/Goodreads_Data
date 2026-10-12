# =============================================================================
#  Goodreads "Reading Life" infographic
#  Draws one tall PNG from a CLEANED Goodreads library (see README.md).
#  Run from the repository root:  Rscript goodreads_infographic.R
#
#  Input : data/goodreads_cleaned.csv  -> the raw Goodreads export columns plus
#            Author_Clean      one spelling per author (merges scripts / pen names)
#            Author_Gender     Female | Male | Non-binary | Mixed (anthology) | Unknown
#            Author_Country    country of origin, English name, today's borders
#            Reading_Language  language(s) you read it in, read shelf only,
#                              several joined with "; " (e.g. "Armenian; English")
#  Output: output/reading_infographic.png (2000 px wide)
#
#  Packages: install.packages(c("readr","dplyr","tidyr","ggplot2","maps",
#                               "patchwork","ggtext","ragg"))
#  Fonts (optional): install "Fraunces" and "Inter" from fonts.google.com for
#  the intended look; otherwise the script falls back to serif / sans.
# =============================================================================

# ---- 1. Settings: change these -------------------------------------------------
NAME        <- "Byurakn"   # your first name; "" gives "My Reading Life"
INPUT       <- "data/goodreads_cleaned.csv"
OUTPUT      <- "output/reading_infographic.png"
FIRST_YEAR  <- 2011      # first year in the "women's share" chart (NULL = earliest date read)
SPLIT_YEAR  <- 2018      # year for the "before / since" comparison (NULL = middle of the range)
MIN_RATED   <- 8         # minimum rated books for a country to appear in "ratings by country"
TOP_AUTHORS <- 6
COUNTRY_NOTE <- paste0("Country of origin = where the author was born and/or grew up, ")
                       # describe your own country rules here (the map note prints this)

# Palette (light theme)
COL <- list(bg = "#FBF8F3", ink = "#1F1B16", ink2 = "#5C554C", muted = "#8E867B",
            line = "#E7E0D6", track = "#EFE9E0", red = "#C0392B", blue = "#2E6A9E",
            soft = "#D9A39C")

# ---- 2. Packages and fonts -----------------------------------------------------
if (!isTRUE(l10n_info()$`UTF-8`)) invisible(suppressWarnings(Sys.setlocale("LC_CTYPE", "C.UTF-8")))
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(ggplot2)
  library(maps); library(patchwork); library(ggtext)
})
has_font <- function(f) {
  if (!requireNamespace("systemfonts", quietly = TRUE)) return(FALSE)
  f %in% systemfonts::system_fonts()$family
}
SERIF <- if (has_font("Fraunces")) "Fraunces" else "serif"
SANS  <- if (has_font("Inter")) "Inter" else "sans"
if (SERIF == "serif" || SANS == "sans")
  message("Tip: install the Fraunces and Inter fonts for the intended look (using fallbacks now).")

# ---- 3. Data -------------------------------------------------------------------
if (!file.exists(INPUT)) stop("Can't find ", INPUT, ". Put your cleaned CSV there or change INPUT at the top.")
books <- read_csv(INPUT, show_col_types = FALSE, guess_max = 5000)
need  <- c("Exclusive Shelf", "Author_Gender", "Author_Country", "Reading_Language", "My Rating", "Date Read")
miss  <- setdiff(need, names(books))
if (length(miss)) stop("Missing columns in ", INPUT, ": ", paste(miss, collapse = ", "),
                       ". See \"Cleaned data format\" in README.md.")
if (!"Author_Clean" %in% names(books)) books$Author_Clean <- books$Author
books <- books %>% mutate(Author_Clean = trimws(gsub("\\s+", " ", Author_Clean)))

read_b <- books %>% filter(`Exclusive Shelf` == "read") %>%
  mutate(Year = suppressWarnings(as.integer(substr(as.character(`Date Read`), 1, 4))))
tbr_b  <- books %>% filter(`Exclusive Shelf` %in% c("to-read", "currently-reading"))
n_read <- nrow(read_b)

langs <- read_b %>% filter(!is.na(Reading_Language), Reading_Language != "") %>%
  mutate(L = strsplit(Reading_Language, ";\\s*")) %>% unnest(L) %>%
  mutate(L = trimws(L)) %>% count(L, sort = TRUE, name = "n")
n_multi <- sum(grepl(";", read_b$Reading_Language))

countries_read <- setdiff(unique(read_b$Author_Country), c(NA, "Unknown"))
n_new <- length(setdiff(setdiff(unique(tbr_b$Author_Country), c(NA, "Unknown")), countries_read))

g <- read_b %>% count(Author_Gender)
n_m <- sum(g$n[g$Author_Gender == "Male"]); n_f <- sum(g$n[g$Author_Gender == "Female"])
n_other <- n_read - n_m - n_f
other_txt <- read_b %>% filter(!Author_Gender %in% c("Male", "Female")) %>% count(Author_Gender) %>%
  mutate(t = paste(n, tolower(Author_Gender))) %>% pull(t) %>% paste(collapse = ", ")

# ---- 4. Shared panel theme -----------------------------------------------------
pct <- function(x) ifelse(x > 0 & x < 0.005, "<1%", paste0(round(100 * x), "%"))
theme_panel <- function() {
  theme_void(base_family = SANS) +
    theme(plot.title = element_text(family = SERIF, size = 17, colour = COL$ink, margin = margin(b = 9)),
          plot.subtitle = element_textbox_simple(size = 10.5, colour = COL$ink2, lineheight = 1.25,
                                                 margin = margin(b = 10)),
          plot.caption = element_textbox_simple(size = 8.5, colour = COL$muted, lineheight = 1.2,
                                                margin = margin(t = 8), halign = 0),
          plot.title.position = "plot", plot.caption.position = "plot",
          plot.background = element_rect(fill = COL$bg, colour = NA),
          panel.background = element_rect(fill = COL$bg, colour = NA),
          plot.margin = margin(14, 18, 14, 18))
}

# Horizontal bars with a light track, value and optional extra column on the right
bar_panel <- function(df, title, subtitle, caption = NULL, xmax = max(df$value),
                      fill = COL$red, extra = NULL, label_w = 0.5, min_rows = 10) {
  total <- max(nrow(df), min_rows)
  df <- df %>% mutate(y = total - row_number() + 1)
  x0 <- -label_w * xmax
  p <- ggplot(df) +
    geom_rect(aes(xmin = 0, xmax = xmax, ymin = y - .3, ymax = y + .3), fill = COL$track) +
    geom_rect(aes(xmin = 0, xmax = value, ymin = y - .3, ymax = y + .3, fill = I(bar_fill))) +
    geom_text(aes(x = x0, y = y, label = label), hjust = 0, size = 3.6, colour = COL$ink2, family = SANS) +
    geom_text(aes(x = xmax * 1.03, y = y, label = value_lab), hjust = 0, size = 3.6,
              fontface = "bold", colour = COL$ink, family = SANS)
  if (!is.null(extra))
    p <- p + geom_text(aes(x = xmax * 1.17, y = y, label = extra_lab), hjust = 0, size = 3.1,
                       colour = COL$muted, family = SANS)
  p + scale_x_continuous(limits = c(x0, xmax * 1.3), expand = c(0, 0)) +
    scale_y_continuous(limits = c(.5, total + .5), expand = c(0, 0)) +
    labs(title = title, subtitle = subtitle, caption = caption) + theme_panel()
}

# ---- 5. Panels -----------------------------------------------------------------
# Title
title_p <- ggplot() + theme_void() +
  labs(title = paste0(if (nzchar(NAME)) paste0(NAME, "’s") else "My",
                      " <span style='color:", COL$red, "'>Reading</span> Life"),
       subtitle = "Everything on the Goodreads “read” shelf, by the numbers") +
  theme(plot.title = element_markdown(family = SERIF, face = "bold", size = 40, colour = COL$ink),
        plot.subtitle = element_text(family = SANS, size = 13, colour = COL$ink2, margin = margin(t = 6)),
        plot.background = element_rect(fill = COL$bg, colour = NA), plot.margin = margin(30, 18, 4, 18))

# Headline numbers
kpi <- tibble(x = 0:3, big = prettyNum(c(n_read, n_distinct(read_b$Author_Clean),
                                      length(countries_read), nrow(langs)), big.mark = ",", preserve.width = "none"),
              small = c("BOOKS READ", "DIFFERENT AUTHORS", "COUNTRIES OF ORIGIN", "READING LANGUAGES"))
kpi_p <- ggplot(kpi) +
  annotate("segment", x = -0.05, xend = 3.95, y = 1, yend = 1, linewidth = 1, colour = COL$ink) +
  annotate("segment", x = -0.05, xend = 3.95, y = 0, yend = 0, linewidth = .3, colour = COL$line) +
  annotate("segment", x = 0.92:2.92, xend = 0.92:2.92, y = 0, yend = 1, linewidth = .3, colour = COL$line) +
  geom_text(aes(x = x + ifelse(x == 0, 0, .04), y = .36, label = big), hjust = 0, vjust = 0, family = SERIF,
            fontface = "bold", size = 10, colour = COL$ink) +
  geom_text(aes(x = x + ifelse(x == 0, 0, .04), y = .15, label = small), hjust = 0, family = SANS,
            size = 3.3, colour = COL$ink2) +
  scale_x_continuous(limits = c(-0.05, 3.95), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-.05, 1.05), expand = c(0, 0)) + theme_panel() +
  theme(plot.margin = margin(10, 18, 6, 18))

# Map
to_map <- function(x) recode(x, "United States" = "USA", "United Kingdom" = "UK",
  "Czechia" = "Czech Republic", "Trinidad and Tobago" = "Trinidad", "Côte d'Ivoire" = "Ivory Coast",
  "Eswatini" = "Swaziland", "Congo" = "Republic of Congo", "DR Congo" = "Democratic Republic of the Congo",
  "Hong Kong" = "China", "Macedonia" = "North Macedonia", .default = x)
world <- map_data("world") %>% filter(region != "Antarctica")
unmatched <- setdiff(to_map(countries_read), unique(world$region))
if (length(unmatched)) warning("Not drawn on the map (name not recognised): ", paste(unmatched, collapse = ", "))
world$hit <- world$region %in% to_map(countries_read)
map_p <- ggplot(world, aes(long, lat, group = group)) +
  geom_polygon(aes(fill = hit), colour = "#D9D4CC", linewidth = .1) +
  scale_fill_manual(values = c(`TRUE` = COL$red, `FALSE` = "white"), guide = "none") +
  coord_quickmap(ylim = c(-56, 84), expand = FALSE) +
  labs(title = "Where the authors come from",
       caption = paste0(COUNTRY_NOTE, " <b style='color:", COL$blue, "'>", n_new,
                        " more countries</b> are waiting on the to-read list.")) + theme_panel()

# Who wrote them
gen_p <- ggplot() +
  annotate("rect", xmin = 0, xmax = n_m - .004 * (n_m + n_f), ymin = .2, ymax = .85, fill = COL$blue) +
  annotate("rect", xmin = n_m + .004 * (n_m + n_f), xmax = n_m + n_f, ymin = .2, ymax = .85, fill = COL$red) +
  annotate("text", x = 0, y = 2.15, label = pct(n_m / n_read), hjust = 0, family = SERIF,
           fontface = "bold", size = 9, colour = COL$blue) +
  annotate("text", x = n_m + n_f, y = 2.15, label = pct(n_f / n_read), hjust = 1, family = SERIF,
           fontface = "bold", size = 9, colour = COL$red) +
  annotate("text", x = 0, y = 1.45, label = paste0("Male · ", n_m), hjust = 0, size = 3.7,
           colour = COL$ink, family = SANS) +
  annotate("text", x = n_m + n_f, y = 1.45, label = paste0("Female · ", n_f), hjust = 1,
           size = 3.7, colour = COL$ink, family = SANS) +
  scale_y_continuous(limits = c(-.2, 2.7)) +
  labs(title = "Who wrote them", subtitle = "All books read, by author gender.",
       caption = if (n_other > 0) paste0(n_other, " books not shown: ", other_txt, ".") else NULL) +
  theme_panel()

# Women's share by year
wy <- read_b %>% filter(!is.na(Year)) %>%
  { if (!is.null(FIRST_YEAR)) filter(., Year >= FIRST_YEAR) else . } %>%
  group_by(Year) %>% summarise(Books = n(), Women = mean(Author_Gender == "Female"), .groups = "drop")
split <- if (is.null(SPLIT_YEAR)) ceiling(mean(range(wy$Year))) else SPLIT_YEAR
pre  <- mean(read_b$Author_Gender[!is.na(read_b$Year) & read_b$Year <  split] == "Female")
post <- mean(read_b$Author_Gender[!is.na(read_b$Year) & read_b$Year >= split] == "Female")
lo <- wy[which.min(wy$Women), ]; hi <- wy[which.max(wy$Women), ]
this_year <- as.integer(format(Sys.Date(), "%Y"))
part_note <- if (max(wy$Year) == this_year)
  paste0(" ", this_year, " covers only ", wy$Books[wy$Year == this_year], " books so far.") else ""
women_p <- ggplot(wy, aes(Year, Women)) +
  geom_hline(yintercept = c(0, .25, .75, 1), colour = COL$line, linewidth = .3) +
  geom_hline(yintercept = .5, colour = "#B9B0A3", linewidth = .3, linetype = "22") +
  geom_line(colour = COL$red, linewidth = .9) +
  geom_point(aes(size = Books), colour = COL$red, stroke = 0) +
  annotate("text", x = lo$Year, y = lo$Women - .09, label = paste0(round(100 * lo$Women), "% in ", lo$Year),
           size = 3.4, fontface = "bold", colour = COL$ink, family = SANS) +
  annotate("text", x = hi$Year, y = min(hi$Women + .09, 1.06), label = paste0(round(100 * hi$Women), "% in ", hi$Year),
           size = 3.4, fontface = "bold", colour = COL$ink, family = SANS, hjust = .8) +
  scale_size_continuous(range = c(1.5, 4.5), guide = "none") +
  scale_y_continuous(limits = c(-.12, 1.1), breaks = c(0, .25, .5, .75, 1),
                     labels = function(x) paste0(x * 100, "%")) +
  scale_x_continuous(breaks = function(l) unique(round(seq(min(wy$Year), max(wy$Year), length.out = 6)))) +
  labs(title = "Women’s share by year",
       subtitle = "Share of books finished each year that were written by women. Dot size = books read that year.",
       caption = paste0("Before ", split, " women wrote ", round(100 * pre), "% of what I read; since ",
                        split, ", ", round(100 * post), "%.", part_note)) +
  theme_panel() +
  theme(axis.text = element_text(size = 8.5, colour = COL$muted, family = SANS),
        axis.text.y = element_text(hjust = 1, margin = margin(r = 4)))

# Top 10 countries
cc <- read_b %>% filter(!is.na(Author_Country), Author_Country != "Unknown") %>%
  count(Author_Country, sort = TRUE) %>% slice_head(n = 10) %>%
  transmute(label = Author_Country, value = n, value_lab = n, bar_fill = COL$red)
countries_p <- bar_panel(cc, "Top 10 countries", "Books read, by author’s country of origin.")

# Reading languages
en_share <- 1 - sum(langs$n[langs$L == "English"]) / sum(langs$n)
lp <- langs %>% transmute(label = L, value = n, value_lab = n, extra_lab = pct(n / sum(n)),
                          bar_fill = ifelse(L == "English", COL$soft, COL$red))
lang_p <- bar_panel(lp, paste(nrow(langs), "reading languages"),
                    paste0("Books read, by the language I read them in. <b>", round(100 * en_share),
                           "% were not in English.</b>"),
                    caption = if (n_multi > 0) paste0(n_multi, " books read in two languages count once in each, ",
                                                      "so the bars add up to ", sum(langs$n), ", not ", n_read, ".") else NULL,
                    extra = TRUE)

# Most-read authors
ta <- read_b %>% count(Author_Clean, sort = TRUE) %>% slice_head(n = TOP_AUTHORS) %>%
  mutate(y = rev(seq_len(n())))
authors_p <- ggplot(ta) +
  geom_segment(aes(x = 0, xend = 1, y = y - .5, yend = y - .5), colour = COL$line, linewidth = .3) +
  geom_text(aes(x = 0, y = y, label = Author_Clean), hjust = 0, size = 4.2, colour = COL$ink, family = SANS) +
  geom_text(aes(x = 1, y = y, label = n), hjust = 1, size = 4.2, fontface = "bold", colour = COL$ink, family = SERIF) +
  scale_x_continuous(limits = c(0, 1)) +
  labs(title = "Most-read authors", subtitle = "Authors with the most books on the read shelf.") + theme_panel()

# Ratings by country
rated <- read_b %>% filter(`My Rating` > 0)
avg <- mean(rated$`My Rating`)
cr <- rated %>% filter(!is.na(Author_Country), Author_Country != "Unknown") %>%
  group_by(Author_Country) %>% summarise(m = mean(`My Rating`), n = n(), .groups = "drop") %>%
  filter(n >= MIN_RATED) %>% arrange(desc(m))
rate_p <- if (nrow(cr) == 0) plot_spacer() else {
  d <- cr %>% mutate(label = factor(Author_Country, levels = rev(Author_Country)), y = as.numeric(label))
  ggplot(d) +
    geom_rect(aes(xmin = 1, xmax = 5, ymin = y - .3, ymax = y + .3), fill = COL$track) +
    geom_rect(aes(xmin = 1, xmax = m, ymin = y - .3, ymax = y + .3), fill = COL$red) +
    annotate("segment", x = avg, xend = avg, y = .4, yend = nrow(d) + .6, colour = COL$ink, linewidth = .7) +
    geom_text(aes(x = -1.1, y = y, label = Author_Country), hjust = 0, size = 3.6, colour = COL$ink2, family = SANS) +
    geom_text(aes(x = 5.12, y = y, label = sprintf("%.2f", m)), hjust = 0, size = 3.6, fontface = "bold",
              colour = COL$ink, family = SANS) +
    geom_text(aes(x = 5.75, y = y, label = n), hjust = 0, size = 3.1, colour = COL$muted, family = SANS) +
    scale_x_continuous(limits = c(-1.1, 6.3), expand = c(0, 0)) +
    scale_y_continuous(expand = expansion(add = .5)) +
    labs(title = paste0("Highest rated: ", cr$Author_Country[1]),
         subtitle = sprintf("Average rating by author country (%d+ rated books). Black tick = my overall average, %.2f.",
                            MIN_RATED, avg),
         caption = "Right-hand column = number of rated books. Scale runs 1–5 stars.") + theme_panel()
}

footer_p <- ggplot() + theme_void() +
  annotate("segment", x = 0, xend = 1, y = 1, yend = 1, colour = COL$line, linewidth = .3) +
  annotate("text", x = 0, y = .4, hjust = 0, size = 3, colour = COL$muted, family = SANS,
           label = "Source: Goodreads library export (duplicates removed, languages checked book by book)") +
  annotate("text", x = 1, y = .4, hjust = 1, size = 3, colour = COL$muted, family = SANS,
           label = paste("Generated", format(Sys.Date(), "%B %Y"))) +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) + scale_y_continuous(limits = c(0, 1.1)) +
  theme(plot.background = element_rect(fill = COL$bg, colour = NA), plot.margin = margin(10, 18, 18, 18))

# ---- 6. Assemble and save ------------------------------------------------------
final <- title_p / kpi_p / map_p /
  (gen_p | women_p) / (countries_p | lang_p) / (authors_p | rate_p) / footer_p +
  plot_layout(heights = c(.6, 1.05, 5.4, 3.2, 4.4, max(4.4, .38 * max(nrow(cr), TOP_AUTHORS) + 1.6), .45)) &
  theme(plot.background = element_rect(fill = COL$bg, colour = NA))

h <- 20.5 + max(0, nrow(cr) - 10) * .3
dev_fun <- if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_png else "png"
dir.create(dirname(OUTPUT), showWarnings = FALSE, recursive = TRUE)
ggsave(OUTPUT, final, width = 10, height = h, dpi = 200, bg = COL$bg, device = dev_fun)
message("Saved ", OUTPUT, " (", n_read, " books, ", length(countries_read), " countries, ",
        nrow(langs), " languages).")
