# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-30

## In progress

- Nothing – next up is #15.

## Up next

- #15 Backup and export (next epic without open decisions; Location capture and Map wait for decisions)

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| ~~#1 Foundation~~ (done) | ~~#2~~ → ~~#3~~ → ~~#4~~ |
| ~~#5 Photos~~ (done) | ~~#6~~ → ~~#7~~ |
| ~~#8 Timeline~~ (done) | ~~#9~~ → ~~#10~~ |
| #20 Location capture | #21 Pick places manually (cities and places) → #22 Use the current GPS position for an entry (open questions in #20) |
| #11 Map | #12 Entries as markers on a map (after map provider decision) → #13 Draw the trip route |
| #14 Data safety and sharing | #15 Backup and export → #16 Share a trip as image or PDF |

## Recently done

- #10 Trip summary (days, entries, places, photos, km)
- #9 Entries grouped by day ("Day n" headers, local time)
- #7 Take date and location from EXIF (asks for media location access)
- #6 Add photos from the gallery (system photo picker, copies in the app, thumbnails)
- #4 Entries with text, date and place (manual): entry list, form, `GeoPoint`, local time

## Open decisions (user only)

- Map provider: OpenStreetMap (`flutter_map`, no key, respect tile usage policy) or Google Maps (API key)
- Location capture (GPS, manual places, route tracking) – see epic #20
- Android only, or iOS later?
