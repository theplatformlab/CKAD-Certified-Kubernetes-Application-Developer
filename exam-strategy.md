# CKAD Exam Strategy — Time Management & Mental Checklist

**Duration:** 2 hours; the official exam does not publish a fixed task count
**Passing score:** 66%, according to the official FAQ checked November 5, 2026. Recheck the [official exam FAQ](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks) before your appointment.
**Practice note:** Mock scores and this time plan are study aids, not readiness predictions.

---

## Pre-Exam Week

### Days 1-3: Recall and Practice
- Attempt a task before reading its solution.
- Use a pattern file to understand the workflow, then repeat the task from a clean state.
- Practice recalling the next diagnostic command, not just memorizing command strings.

### Days 4-5: Timed Exercises  
- Do timed tasks; aim for <2 min per 2-min task
- Time yourself on 5-min and 10-min scenarios
- Identify which tasks you're slowest on

### Day 6: Mock Exam
- Choose a written mock from [`mock-exams/README.md`](mock-exams/README.md) and take it without interruption
- Time yourself strictly
- Score yourself

### Day 7: Rest
- Light review of weak areas
- Get 8+ hours sleep
- Relax

---

## Exam Day — Time Budget

```
The official exam allows two hours, but the task count and point values can vary. Read the value shown for each task in your exam interface and pace yourself against the remaining time. Do not assume every task should take the same number of minutes.

For practice, try a two-pass approach: bank work you can verify, mark a task when you have no useful next step, then return if time remains. Adjust the cutoff based on the task's value and the work left.
```

---

## Strategy: When to Skip (Critical)

### Pause and Reassess If:
- You have made no progress after several attempts; reread the requirements and inspect the resource state.
- A dependency appears missing; determine whether the task expects you to create it or whether the environment has a prerequisite.
- You are repeating the same failing command; check the error, namespace, selector, and resource schema before trying again.

### Keep Working If:
- You have a specific next diagnostic step.
- You can complete one independently verifiable part of a multi-part task.
- A quick check can confirm or rule out your current hypothesis.

---

## Real-Time Decision Logic (In Exam)

```
Task appears:
  ↓
Read question carefully (2x) — 1 min
  ↓
Type command / apply YAML — 4 min
  ↓
Verify with kubectl get / describe — 1 min
  ↓
Does it work? 
  ├─ YES → Mark as done, move to next
  └─ NO → Did I understand the question correctly?
       ├─ NO → Reread, start over
       └─ YES → Obvious fix?
            ├─ YES → Fix it (1 min)
            └─ NO → Mark for later, move on
  ↓
(Spend 30 min on marked tasks at end if time available)
```

---

## Command Execution Checklist

Before hitting Enter, verify:

- [ ] **Namespace correct?** Default or `ns xyz`? Recheck requirement.
- [ ] **Names spelled exactly?** Copy from requirement, not memory.
- [ ] **Flags correct?** `--dry-run=client` NOT `--dry-run` (old syntax fails)
- [ ] **YAML valid?** Indentation matters; test with DRY-RUN first
- [ ] **Selector/label format?** `key=value`, no spaces, case-sensitive
- [ ] **Service port vs targetPort?** Common mistake; recheck
- [ ] **Image exists?** `nginx:latest` works; `nginx:99.99` fails immediately

---

## Mental Checklist Per Question Type

### RBAC (ServiceAccount + Role + Rolebinding)
- [ ] SA created first
- [ ] Role has correct verbs and resources
- [ ] RoleBinding references both
- [ ] Namespace matches (all in same namespace)
- [ ] `kubectl auth can-i` passes

### Deployment/Pod Debugging
- [ ] Image exists (check docker registry)
- [ ] Ports match (container ↔ service ↔ ingress)
- [ ] Labels match service selector
- [ ] Probe paths and timing fit the actual container startup and health behavior
- [ ] Replicas correct

### NetworkPolicy
- [ ] podSelector specifies who is protected
- [ ] ingress/egress rules are explicit ALLOW
- [ ] Everything else is DENIED by default
- [ ] Label selectors correct

### Service/Ingress
- [ ] Service endpoints non-empty
- [ ] Service selector matches pod labels
- [ ] Ingress backend service name correct
- [ ] Ingress backend port = service port (NOT targetPort)

### CronJob
- [ ] Schedule valid UTC format
- [ ] Command/image correct
- [ ] History limits set
- [ ] restartPolicy: OnFailure (not Always)

---

## Last 10 Minutes (If You Finish Early)

1. **Go through marked tasks** (the ones you skipped)
2. **Try 2 of them** if they look solvable now
3. **Verify completed tasks** — run kubectl to confirm state;don't trust your memory
4. **Don't go back and second-guess** — you'll only break things
5. **Click Submit**

---

## Red Flags (Stop and Reread)

- ❌ Task says "across 2 namespaces" but you're only using 1
- ❌ "Ensure traffic is DENIED" but your policy allows
- ❌ "Pod must restart every 60 sec" but no restart trigger shown
- ❌ Service shows 0 endpoints (selector mismatch, not image problem)
- ❌ Ingress gives 503 (usually backend/selector issue, rarely ingress itself)

---

## Exam Day Mental State

### Morning (Before Exam)
- Review alias commands 5× (don't spend 30 min on review)
- Drink water, eat light
- Arrive 15 min early
- **Don't cram.** You either know it or you don't.

### During Exam  
- First 10 min: do 2 easy tasks to build confidence
- Don't panic if stuck (skip, come back later)
- Don't try to be perfect (66% passing)
- Read questions N times, type once

### If You Get Stuck
- "I don't know this" ≠ "This is impossible"
- Break it down: What's the smallest piece I understand?
- Use `kubectl explain <resource>` quickly
- Compare to pattern files from memory

---

## CLI Shortcuts to Memorize

```bash
# Dry-run (test before applying)
kubectl create deployment app --image=nginx --dry-run=client -o yaml

# Get quickly  
k get all -n <ns>

# Edit (faster than kubectl describe)
k edit deployment <name>

# Scale instantly
k scale deployment <name> --replicas=5

# Port forward (test service)
k port-forward svc/<name> 8080:80

# Get one value
k get deployment app -o jsonpath='{.spec.replicas}'

# Check auth quickly
k auth can-i [verb] [resource] --as=system:serviceaccount:<ns>:<sa>

# Verify endpoints
k get endpoints <svc>  # If empty = selector wrong
```

---

## Last Reminder

The exact task mix is not published as a fixed blueprint. Practice both creating resources and diagnosing failures, and use the patterns as reusable workflows rather than predictions about task frequency.

