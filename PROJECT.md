# Trailtale – texts to copy

## GitHub repository

- **Repository name:** `trailtale`
- **Description:** Travel journal that turns places, photos and notes into a map with a timeline.
- **Topics:** `flutter` `dart` `android` `tdd` `trailtale`

## Claude project

**Project name:** 🗺️ Trailtale

**Project description:**
Android app (Flutter): a travel journal that automatically turns places, photos and notes into a map with a day-by-day timeline.

**Project instructions (custom instructions):**

```
This project belongs to the app “Trailtale” – Travel journal that turns places, photos and notes into a map with a timeline.
Repository: github.com/maestroDev3/trailtale

- CLAUDE.md (working rules) and STATUS.md (current state) in the repo are authoritative.
  Read STATUS.md at the start of every conversation.
- Everything in the repo is English (code, UI, docs, issues, commits). You may talk
  to me in German.
- Planning runs through GitHub issues: Epic → Story → Task (sub-issues), status labels
  backlog / ready / in-progress. New ideas become a backlog story in the matching epic.
- Implementation strictly TDD (red → green → refactor), one PR per task, squash-merge
  when CI is green.
- For Dart/Flutter work, the skill .claude/skills/flutter-dart/SKILL.md applies.
- Keep answers short and concrete. Never make the open decisions listed in STATUS.md
  yourself – present them to me.
```

**Project knowledge:** upload this ZIP (or `CLAUDE.md` and `STATUS.md`).

## First message to Claude (session with the repo attached)

```
The attached ZIP contains the starter files for Trailtale. Extract its contents
into the root of github.com/maestroDev3/trailtale (create the repo if it does not exist yet,
private, default branch main), commit ("chore: add working rules, skill and CI")
and push to main.
Then run the "First start" from CLAUDE.md: create labels, create epics and stories
from STATUS.md as issues (with sub-issues), run the Scaffold workflow, get CI green,
refine the first story and update STATUS.md with the issue numbers.
```
