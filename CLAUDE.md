# Trailtale – How Claude works in this repo

Android app (Flutter): a travel journal that automatically turns places, photos and notes into a map with a day-by-day timeline.
Claude works in this repo **autonomously**. This file is binding.

## Language

- Everything in the repo is **English**: code, comments, UI texts, docs, issues,
  commit messages and PR descriptions (the app is meant to be marketable
  internationally).
- UI texts go through Flutter localization (`flutter_localizations` + ARB files,
  `app_en.arb` as the template) from day one, so more languages can be added later.
- Chat with the user may be in German; answer in the user's language.

## Product vision

Trailtale captures trips without the effort of keeping a diary. For each trip the
app collects entries with place, time, photos and short notes. Photos from the
gallery bring their date and location (EXIF) along automatically. From that, the
app builds a map with the route and a day-by-day timeline. Everything stays local;
sharing via export.
Domain terms:

- **Trip** – `Trip` – title, date range, cover photo
- **Entry** – `Entry` – time, place, note, photos
- **Place** – `GeoPoint` – latitude/longitude value object, optional place name
- **Trip day** – `TripDay` – grouping by calendar day, derived from entries

## Structure: Epic → Story → Task

Everything lives in GitHub issues, linked via sub-issues:

| Level | Label | Content |
|---|---|---|
| Epic | `epic` | Big goal; stories as sub-issues, order listed in the description |
| Story | `story` | User-visible feature; tasks as sub-issues |
| Task | `task` | Exactly one PR, TDD, testable acceptance criteria |

Story status (label, exactly one; done = closed):
- `backlog` – idea, roughly described, **no tasks yet**
- `ready` – refined, tasks with acceptance criteria exist
- `in-progress` – currently being implemented (only one story at a time)

Rules:
- Tasks are only written when a story moves from `backlog` to `ready`.
- New ideas from the user become a `backlog` story in the matching epic.
- The user decides which story comes next; without guidance, take the next
  `ready` story in epic order.

## First start (once)

While there are no issues yet:
1. Create labels: `epic`, `story`, `task`, `backlog`, `ready`, `in-progress`.
2. Create the epics and stories from `STATUS.md` (“Planned epics”) as issues,
   stories as sub-issues of their epic, all stories `backlog`.
3. Run the **Scaffold** workflow (`.github/workflows/scaffold.yml`) via
   `workflow_dispatch` → generates the Flutter project. CI must be green afterwards.
4. Refine the first story of the “Foundation” epic to `ready`.
5. Update `STATUS.md` with the real issue numbers.

## Keeping the status (`STATUS.md`)

`STATUS.md` is the short summary of the project state. The user reads it as
context in a Claude project. It must always match the issues.

- Claude updates `STATUS.md` whenever any of it changes: a story changes status
  (`backlog`/`ready`/`in-progress`) or is closed, a new story or epic, order
  changes, a decision is made.
- Content: In progress · Up next · Backlog by epic · Recently done (max. 5,
  newest first) · Open decisions · “Last updated” date.
- When closing a story, the update belongs in the story's last PR. Pure status
  changes without a PR: direct commit to `main` (`docs: update status`).
- Keep it short: number + title, no task details.

### Claude project sync

The user reads the repo state in the Claude project “Trailtale”. When the
session is attached to that project, Claude writes `CLAUDE.md`, `PROJECT.md`
and `STATUS.md` as project docs (same file names) after every push that
changes one of them, so the project always matches `main`.

## Workflow: Story → sub-issues

1. Every functional requirement is a **story** (issue with label `story`).
2. The story is split into **sub-issues** (label `task`), linked via GitHub's
   sub-issue feature. Each sub-issue is small enough for one PR and contains
   **acceptance criteria as testable statements**.
3. Independent sub-issues may be worked on in parallel (subagents).
   Dependencies are listed in the issue under “Depends on”.
4. The story is closed when all its sub-issues are closed.

## TDD per sub-issue (mandatory)

1. Branch `task/<issue-nr>-<short-name>` from the current `main`.
2. **Red:** First write tests for the acceptance criteria, commit
   (`test: … (#nr)`), push. CI must fail because of these tests.
3. **Green:** Write the minimal code until `flutter test` passes (`feat: … (#nr)`).
4. **Refactor:** Clean up, tests stay green (`refactor: … (#nr)`).
5. PR with `Closes #nr` in the body. Description: what, why, which tests.

## Merging

- Claude may **squash-merge PRs into `main` itself** once CI (analyze + format + test)
  is green. Never merge with red or running CI.
- Larger epics may be collected on a branch `epic/<name>`; it is merged into
  `main` only after green CI and a test by the user (APK on the phone).
- No direct push to `main` except for repo infrastructure (CI, this file,
  `STATUS.md`).
- Delete the branch after merging.

## Tech

**Binding:** Before any work on `.dart` files, tests, `pubspec.yaml` or Android
configuration, load and follow the skill `.claude/skills/flutter-dart/SKILL.md`
(architecture, state, style, widgets, tests, definition of done).

- Flutter (stable), Dart, Android as the only target platform for now.
- Package name `trailtale`, organization `de.maestrodev`.
- Structure: `lib/domain` (pure Dart logic, no Flutter imports),
  `lib/data` (repositories, persistence, platform services), `lib/ui` (screens, widgets),
  `lib/l10n` (ARB files).
- Domain logic is pure Dart and covered by unit tests; UI by widget tests.
  Time is always passed in via an injectable `Clock`, never `DateTime.now()`
  directly in logic.
- Data access only through repository interfaces, so a backend or sync can be
  added later.
- Permissions: Read photos/media incl. `ACCESS_MEDIA_LOCATION` (photos epic), `ACCESS_FINE_LOCATION` only “while in use”, `INTERNET` for map tiles (OpenStreetMap, decided).
- `flutter analyze` must report no issues.

## Release signing

APKs are signed with the release key from the repository secrets
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD` (CI decodes the keystore; `android/app/build.gradle.kts`
reads it from the environment). Every CI build gets `github.run_number` as
version code, so the phone accepts it as an update. Never commit the keystore
or its passwords; the user keeps a backup of the keystore (losing it means no
more updates for installed apps).

## Environment note

Flutter cannot be installed in Claude's cloud environment (download servers
blocked). Tests therefore run via **GitHub Actions** (`.github/workflows/ci.yml`);
results are read via the GitHub API (on failure, CI posts the output as a
commit comment).

## Decisions (made by the user)

- **Look & feel (2026-09-30):** “field journal” design from the Trailtale Design
  canvas – paper `#F6F1E7`, ink `#1F3B34`, clay `#B84A22`, sunset `#E07A45`,
  sea `#2F6F7E`; Fraunces (headings) + Manrope (text), bundled; app icon concept A
  (dotted trail to a pin). Epic #70.
- **Map (2026-09-30):** OpenStreetMap with `flutter_map`. OSM tile servers
  directly for now (unique User-Agent, visible attribution, caching, no bulk or
  offline download); switch to a tile provider with a free tier before a Play
  Store release. `INTERNET` is allowed for map tiles. Epic #11.
- **Location (2026-09-30):** place names from a bundled offline city list
  (GeoNames, CC BY 4.0) incl. reverse lookup; GPS “current position” only while
  in use; **no background tracking**. Epic #20.
- **Backup (2026-09-30):** very important; export/restore everything incl.
  photos, ideally automatic backups to Google Drive. Epic #14.

## Open decisions (only the user decides)

- Android only, or iOS later?
