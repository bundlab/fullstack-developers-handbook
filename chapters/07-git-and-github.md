# Chapter 07: Git and GitHub

Mastering version control ensures source code integrity, streamlines team collaboration, provides clear audit trails, and enables automated deployment pipelines.

---

## 1. Fundamental Git Architecture & States

Git tracks file snapshots across three primary local areas before synchronizing with a remote repository.

```
┌─────────────────────────┐      git add       ┌─────────────────────────┐
│    Working Directory    │ ─────────────────> │      Staging Area       │
│  (Unstaged modifications)│                    │  (Index / Prepared)     │
└─────────────────────────┘                    └────────────┬────────────┘
             ▲                                              │
             │                                              │ git commit
             │              git checkout / switch           │
             └──────────────────────────────────────────────┼────────────┐
                                                            ▼            │
                                               ┌─────────────────────────┴┐
                                               │    Local Repository      │
                                               │  (.git directory / HEAD) │
                                               └────────────┬─────────────┘
                                                            │
                                                            │ git push
                                                            ▼
                                               ┌──────────────────────────┐
                                               │    Remote Repository     │
                                               │   (GitHub / GitLab)      │
                                               └──────────────────────────┘

```

---

## 2. Branching Strategies: Trunk-Based vs. GitFlow

Choosing the right branching strategy depends on team velocity, delivery cadence, and release models.

```
Trunk-Based Development (Recommended for Modern SaaS / CI/CD)

  main ───●───────●───────●───────●───────●─── (Continuous Integration)
           \     /       \     /
  feature   └──●─┘        └──●─┘

```

| Feature | Trunk-Based Development | GitFlow |
| --- | --- | --- |
| **Branch Lifetime** | Short-lived (hours to days) | Long-lived (weeks to months) |
| **Complexity** | Low | High (`main`, `develop`, `feature`, `release`, `hotfix`) |
| **Merge Friction** | Minimal (Frequent small merges) | High (Infrequent massive merges) |
| **Best For** | Continuous Delivery, SaaS, Microservices | Scheduled releases, Mobile apps, On-premise software |

---

## 3. Merge vs. Rebase & Conflict Resolution

### Merging vs. Rebasing

* **`git merge`**: Creates a non-destructive merge commit combining history. Preserves exact historical chronology but can result in messy commit graphs.
* **`git rebase`**: Replays local commits on top of the target branch's latest HEAD. Produces a clean, linear project history.

```
Git Merge:                               Git Rebase:
      A---B---C  (feature)                     A'--B'--C' (feature)
     /                                        /
D---E---F---G    (main)                  D---E---F---G    (main)

```

> **Golden Rule of Rebasing:** Never rebase branches that have already been pushed to a public or shared repository.

### Interactive Rebase Command Checklist

```bash
# Squash or edit the last 3 commits before merging a pull request
git rebase -i HEAD~3

```

* `pick`: Keep the commit.
* `squash` (s): Meld the commit into the previous commit.
* `reword` (r): Keep commit content but rewrite the commit message.

---

## 4. Conventional Commits Standard

Standardizing commit messages enables automated semantic versioning (`semver`), changelog generation, and automated release notes.

### Commit Format

```text
<type>(<scope>): <short description>

[optional body]

[optional footer]

```

### Common Commit Types

* `feat`: A new feature for the user.
* `fix`: A bug fix.
* `docs`: Documentation changes only.
* `style`: Code style/formatting changes (no logic change).
* `refactor`: Code change that neither fixes a bug nor adds a feature.
* `test`: Adding or correcting tests.
* `chore`: Maintenance, dependencies, or build tool updates.

#### Example

```text
feat(auth): add JWT refresh token rotation mechanism

Implements token rotation on every refresh request to prevent replay attacks.
Invalidates compromised refresh tokens automatically upon reuse.

Closes #104

```

---