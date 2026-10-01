# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-10-01

## In progress

- #22 Use the current GPS position (foreground only)

## Up next

- #124 Pick a place on the map → #13 Draw the trip route

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| ~~#70 Look & feel~~ (done) | ~~#71~~ → ~~#72~~ → ~~#73~~ → ~~#74~~ → ~~#75~~ |
| ~~#1 Foundation~~ (done) | ~~#2~~ → ~~#3~~ → ~~#4~~ |
| #5 Photos | ~~#6~~ → ~~#7~~ → ~~#126 Bug: photo locations lost when picking~~ → #114 Evening recap: add today's photos as entries (needs decision) |
| ~~#8 Timeline~~ (done) | ~~#9~~ → ~~#10~~ |
| #14 Data safety and sharing | ~~#15 Backup and export~~ → #101 Automatic backups to Google Drive including photos (needs Google Cloud setup) → #16 Share a trip as image or PDF → #111 Store the release signing key safely (user task, after vacation) |
| #20 Location capture | ~~#21 Pick places manually (cities and places)~~ → ~~#123 Find small towns and villages~~ → #22 Use the current GPS position → #124 Pick a place on the map → #125 Create an entry from a place shared by another app |
| #11 Map | ~~#12 Entries as markers on a map~~ → #13 Draw the trip route |

## Recently done

- #123 Place search with 171k places from 1,000 inhabitants (Kotor, Bled, Positano) and regions in suggestions
- #126 Own gallery picker (trip photos first) keeps the photos' GPS position; hint when a photo has no location
- #21 Place suggestions from a bundled city list (34k cities, offline), coordinates and place names filled automatically
- #12 Map with numbered markers (OpenStreetMap) on the trip page and in full screen
- Release signing with a fixed key: APKs now update the installed app

## Open decisions (user only)

- #114 Evening recap: allow notifications and reading the gallery? Reminder time?
- #125 Google Maps links: may the app use the internet beyond map tiles to resolve them?
- Android only, or iOS later?
