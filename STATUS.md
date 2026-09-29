# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-29

## In progress

- Nothing – next up is #2.

## Up next

- #2 Project setup (`ready`) – tasks #17, #18, #19

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| #1 Foundation | #2 Project setup (`ready`) → #3 Create, edit and delete trips → #4 Entries with text, date and place (manual) |
| #5 Photos | #6 Add photos from the gallery → #7 Take date and location from EXIF |
| #8 Timeline | #9 Entries grouped by day → #10 Trip summary (places, days, kilometers) |
| #11 Map | #12 Entries as markers on a map (after map provider decision) → #13 Draw the trip route |
| #14 Data safety and sharing | #15 Backup and export → #16 Share a trip as image or PDF |

## Recently done

- First start: labels, epics and stories created; Flutter project scaffolded, CI green
- Repo created with CLAUDE.md, STATUS.md, Flutter skill and CI

## Open decisions (user only)

- Map provider: OpenStreetMap (`flutter_map`, no key, respect tile usage policy) or Google Maps (API key)
- Capture location automatically via GPS, or only from photos/manually?
- Android only, or iOS later?
