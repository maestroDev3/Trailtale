# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-10-02

## In progress

- #16 Share a trip as one picture – incl. real map (#180) and choosing photos (#181), all on `epic/share-trip-picture`; **waiting for the user's test of the "preview" APK**, then merge to `main`

## Up next

- Candidates without blockers: #125 Create an entry from a shared place (`geo:` links; Google Maps links need a decision), #160 Trip slideshow as PDF

## Backlog by initiative → epic

**#153 Effortless capture**

| Epic | State | Stories (in order) |
|---|---|---|
| #20 Location capture | 4 of 5 closed | ~~#21~~ → ~~#123~~ → ~~#22~~ → ~~#124~~ → #125 Create an entry from a place shared by another app |
| #157 Evening recap | 0 of 1 closed | #114 Evening recap: add today's photos as entries (needs decision) |
| ~~#1 Foundation~~, ~~#5 Photos~~ | done | |

**#155 Own your data**

| Epic | State | Stories (in order) |
|---|---|---|
| #14 Data safety and sharing | 1 of 6 closed | ~~#15~~ → #101 Automatic backups to Google Drive including photos (needs Google Cloud setup) → #16 Share a trip as one picture (Instagram) → #160 Trip slideshow as PDF → #161 Instagram carousel, one picture per day → #162 Animated route video (later) |

**#156 Ship it**

| Epic | State | Stories (in order) |
|---|---|---|
| #158 Release readiness | 0 of 2 closed | #111 Store the release signing key safely (user task, after vacation) → #159 Switch the map to a tile provider with a free tier |

**Dormant**

- #154 The trip as a story – all epics done (latest: ~~#169~~ cover photo, ~~#177~~ map opens on the trip)

## Recently done

- #178 Bug fixed: the trip map opens zoomed to the trip's places
- #170 Choose the trip's cover photo ("Choose cover" on the trip page, "Automatic" to go back)
- #13 Trip route on the map (sea-blue line, legs over 300 km dashed)
- #124 "Pick on map": crosshair map picker with town search, my position and nearest town
- #22 "Use my position" in the entry form (one GPS fix while in use, no background service)

## Open decisions (user only)

- Newly created – please confirm or re-sort: epics #169 Trips look the way I want (#170, done) and #177 The map opens on my trip (#178), both in initiative #154.
- Planning structure introduced 2026-10-01 – please confirm or re-sort: initiatives #153 Effortless capture, #154 The trip as a story, #155 Own your data, #156 Ship it; new epics #157 Evening recap (#114 moved from #5, #5 closed again) and #158 Release readiness (#111 moved from #14, new story #159).
- #114 Evening recap: allow notifications and reading the gallery? Reminder time?
- #125 Google Maps links: may the app use the internet beyond map tiles to resolve them?
- Android only, or iOS later?
