# Safe expunging process (Lab 7.1)

- **Who can request a removal:** Anyone with access to the repository, or anyone outside it who finds their own personal data or a secret in it. Requests go to the repository owner (wrightbrained) privately, never in a public issue.
- **Acceptable grounds:** Only three. A leaked secret (key, token or password), after it has already been revoked and replaced. Personal data that should never have been committed. Content there is a legal duty to remove, such as a court order or a valid copyright takedown. Code that is wrong, embarrassing or inconvenient is not grounds; it gets fixed with a new commit.
- **Who approves:** The repository owner, plus a second person who did not make the request. This sandbox has no second person, which is a gap I am recording rather than hiding.
- **How the request and action are tracked:** Each request gets a private GitHub security advisory recording the date, who asked, the grounds, the exact commits and files, the decision and who made it. For a secret, the advisory must show it was revoked before the removal is approved.
- **How the removal is logged:** The advisory records the old and new commit IDs of every rewritten branch and tag, when the ruleset was switched off for the rewrite, when it was switched back on, and who did both. GitHub's ruleset history and push log record the same changes independently. Anyone who depends on the repository is told which revisions changed and why.

## Worked refusal
A request I would refuse, and why: A developer asks to remove a commit from main because a bug in it broke a release and they would rather nobody saw it. I would refuse. A bug is not a secret, personal data or a legal duty. Removing it would cut loose every review and attestation that names that commit, which is exactly the history rewrite (threat B2) that Source L2 exists to stop. The fix is a new commit that corrects the bug, and the history stays as it is.
