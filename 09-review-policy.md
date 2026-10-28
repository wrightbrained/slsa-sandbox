# Review policy (Lab 9.1)

1. **Protected branches and trusted people:** `main` and `release` are protected by the ruleset `protect-main-and-release`. The only trusted person is the repository owner, wrightbrained. This is a one-person sandbox.
2. **Review shape, and whether authors can approve their own changes:** The rules require one approval from someone other than the person who made the most recent push, and any new commit cancels earlier approvals. Authors cannot approve their own pull requests. Because there is no second person, every merge uses a logged exception: the Repository admin role may bypass the review requirement through a pull request only (never a direct push), with `gh pr merge --admin`. So in practice this branch has one party, not two, and I say so rather than imply otherwise.
3. **What reviewers check (security-relevant properties, not "looks fine"):**
   - Any change under `.github/workflows/`: new or widened permissions (`contents: write`, `id-token: write`), new third-party actions, and that every action is pinned to a full commit SHA.
   - Any change to `build.sh` or to how artifacts are named, packaged or uploaded, since that changes what provenance describes.
   - New dependencies, downloads or network calls in the build.
   - That the commit being merged is the one that was reviewed (no unreviewed push after approval).
   - No secrets, keys or personal data in the diff.
4. **Robot exceptions in this policy** (each answering the four questions in section 9.4):

| Robot | Granted for | Who approves its changes |
| --- | --- | --- |
| GitHub Actions (`GITHUB_TOKEN`) | Default token is read-only and cannot approve pull requests. The release jobs are granted `contents: write`, `id-token: write` and `attestations: write` to create releases and attestations. | It never changes `main`: it is not on the bypass list, so the ruleset blocks it from pushing there. Its only writes are tags and releases. Any change to the workflows that grant it these permissions goes through a reviewed pull request (point 3). |

   No other bots, apps or deploy keys have access. If a dependency bot is added, its pull requests get the same review as a person's, and it is never added to the bypass list.

5. **When the policy is bypassed:** Every bypass merge is marked on the pull request in GitHub, and the repository activity log shows it as a merge by wrightbrained. Each bypass is noted in the pull request description with the reason. Once a week I review merged pull requests and the ruleset history, and record that I did. In a team, the person who bypassed tells the security lead the same day.

## Robot audit (step 4)
This sandbox has no production service, so I audited two things instead.

**My sandbox's own robot:**

| Robot or app | What it can do today | Matches the policy? |
| --- | --- | --- |
| GitHub Actions | Default workflow permissions `read`; `can_approve_pull_request_reviews: false`. Release jobs get `contents: write` and can create tags and releases, but are blocked from pushing to `main` by the ruleset. | Yes |

**A public project, from outside (cli/cli):** Its last five merged Dependabot pull requests (#14824, #14766, #14751, #14707, #14706) were all merged by a human maintainer, not by the bot. What I could not see from outside: the bypass list, which apps are installed, and what the bot's token is allowed to do. That is the finding: from outside you can show that a person merged the bot's changes, but not what the bot could do if it tried.

## Evidence
- Stale approval dismissed (date, PR): Not demonstrated; I work alone, so no one can approve. Documented instead: with `dismiss_stale_reviews_on_push` on, GitHub cancels an approval when new commits are pushed to the pull request. Setting confirmed on 2026-10-28.
- Most recent push needed someone else's approval (date, PR): Not demonstrated, for the same reason. With `require_last_push_approval` on, the person who made the last push cannot be the one who approves it. Setting confirmed on 2026-10-28. GitHub also turned on `require_extra_approval_for_unattributed_changes`.
- Direct push error: 2026-10-28, "Changes must be made through a pull request." (The admin exception covers pull requests only.)
- Dismissed-approval merge error: 2026-10-28, PR #5 without approval: "the base branch policy prohibits the merge." The same PR merged with `gh pr merge --admin`, which is the logged exception working, not the control failing.

## Customer-facing sentence (step 5)
The sentence: Every change to `main` goes through a pull request and cannot be force-pushed or merged unsigned; because this is a one-person project, changes are merged by the owner under a logged exception and are not reviewed by a second person.

Does it describe the guarantee, or a process that implies one? It describes the guarantee. It deliberately does not say "reviewed", because no second person reviews anything. What it leaves out: the owner can still edit or turn off the ruleset (see Lab 8.1), and the pull request requirement was off for two commits (7059a78 and 3f4ef32) on 2026-10-28.
