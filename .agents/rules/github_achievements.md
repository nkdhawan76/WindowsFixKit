# GitHub Profile Achievements & Badges Automation Rule

This rule enforces best practices and commit/PR workflows across the repository to systematically unlock and upgrade GitHub Profile Achievements for the repository owner (@nkdhawan76):

---

## 1. 👥 Pair Extraordinaire Badge
- **Rule**: Whenever creating Git commits for features, bug fixes, or documentation updates, ALWAYS append a `Co-authored-by` trailer at the bottom of the commit message.
- **Commit Format**:
  ```git
  feat(module): description of changes

  Co-authored-by: Nikil Dhawan <devsparksindia@gmail.com>
  Co-authored-by: DevSparks Support <9521032268@devsparksindia.com>
  ```
- **Result**: Merging commits with co-authors automatically activates and upgrades the **Pair Extraordinaire** badge.

---

## 2. 🦈 Pull Shark (x2, x3, Gold Tier) & 🤠 YOLO Badges
- **Rule**: Develop updates in dedicated feature branches (e.g. `feature/driver-diagnostics`, `docs/release-v1.4.0`) rather than direct commits only.
- **Workflow**:
  1. `git checkout -b feature/improvement-name`
  2. Commit changes with Co-authored trailer.
  3. `git push origin feature/improvement-name`
  4. Open Pull Request on GitHub.
  5. Merge directly without requesting third-party review (unlocks **YOLO** badge).
  6. Each merged PR increments the counter toward **Pull Shark Tier 2 (16 PRs)** and **Tier 3 Gold Shark (128 PRs)**.

---

## 3. ⚡ Quickdraw Badge
- **Rule**:
  1. Open a new tracking Issue or quick patch PR on `nkdhawan76/WindowsFixKit`.
  2. Close the Issue or merge/close the PR within 5 minutes of opening.
  3. Badge instantly awards on profile.

---

## 4. 🧠 Galaxy Brain Badge
- **Rule**:
  1. Enable GitHub Discussions on the repository (`Settings -> General -> Features -> Discussions`).
  2. Create a Discussion thread in the "Q&A" category.
  3. Provide an answer/resolution and click **"Mark as answer"**.
  4. Accumulate 2 accepted answers to unlock and level up Galaxy Brain (x2, x3, x4).

---

## 5. ⭐ Starstruck Badge (x2, x3, x4)
- **Target**: 16 Stars (Tier 1), 128 Stars (Tier 2), 512 Stars (Tier 3).
- **Action**: Share WindowsFixKit releases across DevSparks India social media, LinkedIn, WhatsApp groups, and developer communities.

---

## 6. 💖 Public Sponsor Badge
- **Action**: Sponsor any active open-source creator or project on GitHub Sponsors ($1 - $5) to permanently unlock the badge on profile.
