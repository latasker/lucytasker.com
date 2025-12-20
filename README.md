# lucytasker.com

The source code of https://lucytasker.com

## Maintenance procedures

### Adding new gigs from GitHub's web UI

1. Open [the gig data file in the online editor](https://github.com/latasker/lucytasker.com/edit/main/gigs.toml).
2. Add a new entry at the top (for tidyness, below the header). For example:
  ```
  [[gigs]]
    date = "2038-01-19"
    time = "9pm"
    location = "USA, New York"
    venue = "Carnegie Hall"
  ```
3. Press the "Commit changes" button.
  It's a good idea to add something informative in the "Commit message" field, like "Add a January gig in Carnegie Hall".
4. That's it — the [GitHub Actions CI workflow](https://github.com/latasker/lucytasker.com/blob/main/.github/workflows/main.yml)
  will rebuild and update the live website when you commit the change.

