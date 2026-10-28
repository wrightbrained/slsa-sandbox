# Control definition and continuity (Lab 8.1)

## Definition (written for a consumer)
- Control: Every change to `main` must arrive through a pull request. It is enforced by the GitHub ruleset `protect-main-and-release`, which also covers the `release` branch.
- Approvals required: 0. This is a one-person sandbox, so the pull request is a record of the change, not a second person's review. Two-party review comes in Lab 9.1.
- May the author approve? Not applicable, since no approval is required. GitHub never lets authors approve their own pull requests.
- What happens to approvals when new commits arrive: Nothing, because none are required. Dismissing stale approvals is off.
- Who may bypass: Nobody. The bypass list is empty. The repository admin (wrightbrained) cannot bypass the rule but can edit or delete the ruleset, which is exactly how the lapse below happened.
- Which automation is exempt: None. No apps or bots are on the bypass list. GitHub Actions workflows only create tags and releases; they do not push to `main`.

## Continuity
| Event | Revision ID | When (UTC) |
| --- | --- | --- |
| Control configured at | b3355a3 | ruleset created 2026-10-28 18:42 |
| First protected (start) revision | 7882e32 (PR #1) | 2026-10-28 19:03 |
| Lapse began | rule removed after 7882e32 | 2026-10-28 19:13 |
| Landed during the lapse (direct pushes) | 7059a78, 3f4ef32 | 19:15:30 and 19:15:33 |
| Lapse ended | rule restored after 3f4ef32 | 2026-10-28 19:15:53 |
| New start revision | cc57a5f (PR #3) | 2026-10-28 19:17 |

```
b3355a3 ── 7882e32 ── 7059a78 ── 3f4ef32 ── cc57a5f ──▶ main
   │          │       └──── lapse ────┘        │
configured  start                          new start
```

**The one sentence I can defend about this branch:** Since cc57a5f, every change to `main` has arrived through a pull request; 7059a78 and 3f4ef32 did not, and because no approvals are required, none of it was reviewed by a second person.

## Could I have detected the lapse from records alone?
Yes, but only by going looking. Nothing alerted me.
- The ruleset history (`gh api repos/<you>/slsa-sandbox/rulesets/<id>/history`) shows three versions: created at 13:42, changed at 14:13 and changed again at 14:15 (Central time). Fetching each version (`.../history/<version_id>`) shows that the 14:13 version has no pull request rule.
- The repository activity log (`gh api "repos/<you>/slsa-sandbox/activity?ref=refs/heads/main"`) shows 7059a78 and 3f4ef32 as `push`, not `pr_merge`, landing between those two changes.
- Gaps: the ruleset history names the actor only by numeric ID (348892104), which has to be looked up to get a username. The two logs use different time zones (Central and UTC), which makes matching them easy to get wrong. A personal-account repository has no organization audit log. Most importantly, nothing notified anyone when the rule was removed. This is a monitoring gap, not a configuration one.

## Disclosure note to a consumer
On October 28, 2026, the pull request requirement on `main` in wrightbrained/slsa-sandbox was turned off from 19:13 to 19:15 UTC. Two commits, 7059a78 and 3f4ef32, were pushed directly during that window and did not go through a pull request. Our new start revision is cc57a5f: every change since then has gone through a pull request. Earlier claims that "every change since 7882e32 went through a pull request" are no longer true and should not be relied on. To keep this from happening silently again, we will check the ruleset history and the activity log weekly for any `push` to `main` and any ruleset change, and record each check.
