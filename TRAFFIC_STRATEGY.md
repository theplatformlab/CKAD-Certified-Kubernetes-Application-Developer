# Growth Strategy — Making This the #1 CKAD Repo

Actionable checklist to maximize reach, stars, and traffic.

## Phase 1: Content Completeness (Week 1-2)

- [ ] Add Exercise 11: StatefulSet (stable identity, headless Service, persistent storage)
- [ ] Add Exercise 12: DaemonSet (node-level logging agent, tolerations)
- [ ] Add Exercise 13: Init Containers (dependency checks, migration runners)
- [ ] Add Exercise 14: In-Place Pod Vertical Scaling (stable since v1.35; current practice target v1.37)
- [ ] Add difficulty badges to every exercise README (`Easy` / `Medium` / `Hard`)
- [ ] Add `verify.sh` scripts to exercises (automated answer checking)
- [ ] Create Anki deck export (.apkg) of key kubectl commands + YAML patterns

## Phase 2: CI/CD & Quality Signals (Week 1)

- [x] GitHub Actions: validate all skeleton YAML with kubeconform
- [x] GitHub Actions: lint markdown files
- [ ] Add badges to README: build passing, YAML valid, last commit, stars count
- [ ] Add `.markdownlint.json` config for consistent formatting

## Phase 3: SEO & Discoverability (Week 2)

- [ ] Set GitHub repo **description**: `CKAD Exam 2026 — Practice Questions, Mock Exam, Exercises & Study Guide | Kubernetes v1.37 | Scored 91%`
- [ ] Set GitHub **topics**: `ckad`, `kubernetes`, `ckad-exam`, `ckad-exercises`, `kubernetes-certification`, `ckad-2026`, `ckad-practice`, `kubectl`, `cncf`, `ckad-study-guide`, `gateway-api`
- [ ] Set **website** field to blog post URL
- [ ] Enable GitHub Pages (render README as searchable site)
- [ ] Add `<meta>` SEO in GitHub Pages `_config.yml`: title, description, keywords
- [ ] Cross-link: blog → repo, repo → blog (done), LinkedIn → repo
- [ ] Submit to Google Search Console once Pages is live

## Phase 4: Community & Social Proof (Week 2-3)

- [ ] Enable GitHub Discussions (Q&A, exam results sharing, study groups)
- [ ] Add "Contributors" section to README with `all-contributors` bot
- [ ] Add Star History badge from `star-history.com`
- [ ] Add "If this helped, star the repo" CTA at top AND bottom of README
- [ ] Create issue templates: bug report, exercise request, content update

## Phase 5: Distribution Blitz (Week 3)

- [ ] **Reddit**: Post to r/kubernetes, r/devops, r/CKAD, r/sysadmin — angle: "Scored 91%, open-sourcing my complete CKAD prep (K8s v1.37, Gateway API)"
- [ ] **Hacker News**: "Show HN: CKAD Study Guide — scored 91%, open-sourced" 
- [ ] **Dev.to**: Write article "How I Passed CKAD 2026 with 91% — Complete Open Source Study Guide"
- [ ] **LinkedIn**: Write post with exam score card image
- [ ] **Twitter/X**: Thread — "I just passed CKAD with 91%. Here's everything I used (open source):" with 10-tweet breakdown
- [ ] **YouTube**: Record 5-10 min overview walkthrough of the repo + exercises
- [ ] **Discord**: Post in Kubernetes, CNCF, DevOps Discord servers

## Phase 6: Backlinks & Partnerships (Week 3-4)

- [ ] Email/DM authors of popular "How I passed CKAD" blog posts — ask to link this repo
- [ ] Submit to awesome-kubernetes / awesome-ckad lists
- [ ] Reach out to Killercoda — propose integration or cross-link
- [ ] Create a PR to `kubernetes/community` repo linking this as a study resource
- [ ] Comment on Stack Overflow CKAD questions with link to repo (where relevant and helpful)

## Phase 7: Unique Features (Ongoing)

- [x] Interactive quiz script (`scripts/quiz.sh`)
- [ ] Exam simulator: bash script that deploys kind cluster + presents 17 timed questions
- [ ] PDF export of the README (for offline study)
- [ ] Flashcard mode in terminal (kubectl commands + expected output)
- [ ] Weekly automated check that Kubernetes version references are current

## Competitive Analysis

| Repo | Stars | Weakness | Our Advantage |
|------|-------|----------|---------------|
| dgkanatsios/CKAD-exercises | 8k+ | Outdated (v1.28), no Gateway API, no mock exam | Current v1.37, Gateway API, full mock exam |
| bmuschko/ckad-crash-course | 2k+ | Minimal explanations, no exam tips | Deep exam strategy, mistakes section, PSI tips |
| lucassha/CKAD-resources | 1k+ | Link collection only, no original content | Full original content, exercises, skeletons |

## Key Metrics to Track

- GitHub stars (weekly)
- Google ranking for "CKAD study guide 2026"
- README page views (GitHub Insights → Traffic)
- Blog post organic traffic
- Reddit/HN post engagement
- Contributors count
