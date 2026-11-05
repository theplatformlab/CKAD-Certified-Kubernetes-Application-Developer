# Study Paths by Timeline

Treat these as planning templates, not guarantees. A reasonable session is one short review, one hands-on attempt, verification, and a retry of an earlier miss. Adjust the pace if you are learning Kubernetes fundamentals at the same time.

## 1 Week Plan

**Rough effort:** 30-40 hours. Best suited to someone already comfortable with Pods, Deployments, Services, YAML, and the command line.

### Days 1-2: Find the Gaps

- Attempt [Mock Exam 01](mock-exams/MOCK-EXAM-01.md) as a diagnostic, or work through [Exercises 01-04](exercises/README.md).
- Review [RBAC](patterns/rbac-debug.md), [Deployment debugging](patterns/deployment-fix.md), and [Service selectors](patterns/service-selector-mismatch.md) only where you struggled.
- Retry missed tasks without looking at the solution.

### Days 3-4: Network and Configuration Practice

- Work through [NetworkPolicy](patterns/networkpolicy-allow-deny.md), [Ingress](patterns/ingress-debug.md), and the [ConfigMap/Secret](exercises/03-configmap-secret/README.md) lab.
- Use [timed drills](exercises/timed-exercises.md) to practice command speed after the workflow is understood.
- Verify traffic and application state, not just resource creation.

### Day 5: Integrated Tasks

- Attempt the [multi-step scenarios](exercises/multi-step-scenarios.md).
- Review [CronJobs](patterns/cronjob-create.md) and any remaining topic from the [exercise catalog](exercises/README.md).

### Day 6: Timed Mock

- Take [Mock Exam 02](mock-exams/MOCK-EXAM-02.md) in one sitting.
- Review each missed requirement and identify whether the cause was knowledge, command syntax, or skipped verification.

### Day 7: Retry and Rest

- Retry missed tasks from memory, then use the [exam strategy](exam-strategy.md) as a checklist.
- Avoid treating a mock percentage as a prediction of the live result. Check the current official exam information before your appointment.

## 2 Week Plan

**Rough effort:** 50-60 hours. Use the first week to learn and the second to integrate, debug, and repeat.

### Week 1: Build the Core Workflow

- Days 1-2: Exercises 01-04 and the matching [Pod](patterns/deployment-fix.md) and [RBAC](patterns/rbac-debug.md) references.
- Days 3-4: Exercises 05-09; focus on NetworkPolicy, selectors, probes, Ingress, and Gateway prerequisites.
- Day 5: Exercises 10-14; note any environment-specific dependency such as storage classes or feature support.
- Day 6: Complete [timed drills](exercises/timed-exercises.md) and inspect the [kubectl cheatsheet](KUBECTL-CHEATSHEET.md).
- Day 7: Retry two difficult labs without opening their solutions.

### Week 2: Integrate and Review

- Days 1-2: Complete [multi-step scenarios](exercises/multi-step-scenarios.md) and [troubleshooting practice](troubleshooting/networking/networking-debug.md).
- Day 3: Take [Mock Exam 01](mock-exams/MOCK-EXAM-01.md), then review misses.
- Days 4-5: Revisit weak topics and use [broken manifests](troubleshooting/broken/) for diagnosis practice.
- Day 6: Take [Mock Exam 02](mock-exams/MOCK-EXAM-02.md), then write down unresolved gaps.
- Day 7: Light review or rest. Do not cram new material if it is not sticking.

## 3-4 Week Plan

**Rough effort:** 80-100 hours. This pace leaves room for learning concepts, practicing, and revisiting mistakes.

### Week 1: Foundations

- Work through Exercises 01-04.
- Practice creating resources imperatively, then inspect and explain the resulting YAML.
- Write down the difference between desired state, observed state, and readiness for each resource.

### Week 2: Configuration and Networking

- Work through Exercises 05-10.
- Practice NetworkPolicy rules with both allowed and denied traffic.
- Check prerequisites before Gateway, Ingress, and storage tasks; a missing controller or class can make an otherwise correct manifest appear broken.

### Week 3: Workloads and Troubleshooting

- Work through Exercises 11-14 and the [troubleshooting scenarios](troubleshooting/).
- Complete [multi-step scenarios](exercises/multi-step-scenarios.md).
- Retry the hardest tasks from Week 1 without hints.

### Week 4: Timed Practice

- Take both written mocks on separate days and reserve time to review them.
- Repeat only tasks where you missed a requirement or could not explain the verification.
- Check the current [curriculum](https://github.com/cncf/curriculum/tree/main/ckad), [exam FAQ](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks), and allowed-resource policy before the exam.

## A Repeatable Session

For a two-hour study block:

- 10 minutes: choose one topic and recall its steps from memory.
- 60 minutes: attempt one lab or a small set of related tasks.
- 20 minutes: verify requirements, inspect events/logs, and clean up.
- 20 minutes: compare against the solution and retry the missed part.
- 10 minutes: write a short note about the mistake and how you detected it.

Use the [mock exam guide](mock-exams/README.md) for practice scoring. Scores help identify gaps; they do not establish readiness or predict a pass.
