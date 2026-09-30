# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-30

## In progress

- Nothing – next up is #6.

## Up next

- #6 Add photos from the gallery

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| #1 Foundation | ~~#2 Project setup~~ → ~~#3 Create, edit and delete trips~~ → ~~#4 Entries with text, date and place (manual)~~ |
| #5 Photos | #6 Add photos from the gallery → #7 Take date and location from EXIF |
| #8 Timeline | #9 Entries grouped by day → #10 Trip summary (places, days, kilometers) |
| #20 Location capture | #21 Pick places manually (cities and places) → #22 Use the current GPS position for an entry (open questions in #20) |
| #11 Map | #12 Entries as markers on a map (after map provider decision) → #13 Draw the trip route |
| #14 Data safety and sharing | #15 Backup and export → #16 Share a trip as image or PDF |

## Recently done

- #4 Entries with text, date and place (manual): entry list, form, `GeoPoint`, local time
- #3 Create, edit and delete trips (list, form, detail, JSON file storage)
- #2 Project setup: theme, localization, app shell, `pumpApp`, `Clock`/`dayOf`; CI checks format
- New epic #20 Location capture (backlog)
- First start: labels, epics and stories created; Flutter project scaffolded, CI green

## Open decisions (user only)

- Map provider: OpenStreetMap (`flutter_map`, no key, respect tile usage policy) or Google Maps (API key)
- Location capture (GPS, manual places, route tracking) – see epic #20
- Android only, or iOS later?
