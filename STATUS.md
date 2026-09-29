# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-29

## In progress

- Nothing yet – the repo only contains the working rules, skill and CI.

## Up next

- “First start” from CLAUDE.md: create labels, epics and stories as issues,
  run the Scaffold workflow, refine the first story “Project setup”.

## Planned epics (no issue numbers yet)

| Epic | Stories (in order) |
|---|---|
| Foundation | Project setup (scaffold, green CI, theme, `pumpApp`) → Create, edit and delete trips → Entries with text, date and place (manual) |
| Photos | Add photos from the gallery → Take date and location from EXIF |
| Timeline | Entries grouped by day → Trip summary (places, days, kilometers) |
| Map | Entries as markers on a map (after map provider decision) → Draw the trip route |
| Data safety and sharing | Backup and export → Share a trip as image or PDF |

## Recently done

- Repo created with CLAUDE.md, STATUS.md, Flutter skill and CI

## Open decisions (user only)

- Map provider: OpenStreetMap (`flutter_map`, no key, respect tile usage policy) or Google Maps (API key)
- Capture location automatically via GPS, or only from photos/manually?
- Android only, or iOS later?
