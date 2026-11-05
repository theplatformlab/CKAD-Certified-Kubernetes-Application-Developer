# Community Feedback Notes (2026)

This page is a collection of informal study observations, not a survey or verified report of CKAD exam content. The earlier draft included sample counts, pass-rate estimates, and claims about how often topics appeared, but did not include evidence that a reader could audit. Those figures have been removed.

Use the notes below as prompts for your own practice, not as a blueprint for the exam. No exam questions or reconstructed task wording belong in this repository.

## Practice Topics to Self-Check

When reviewing a lab or mock, ask whether you can:

- Explain why a Pod is not Ready using status, events, probes, and logs.
- Trace a Service request through selector, endpoints, Service port, and container port.
- Write NetworkPolicy rules and reason about which traffic is allowed or denied, including DNS when relevant.
- Verify RBAC with both an allowed action and an action that should be denied.
- Choose between environment variables and mounted configuration, and know when a workload restart is needed to consume an update.
- Combine related tasks, such as deploying an app, exposing it, applying policy, and checking the resulting behavior.
- Manage time by moving on from a stuck task and returning to it after completing work you can verify.

These are useful Kubernetes application-development skills. This list does not claim that any topic is more or less likely to appear on a particular exam version.

## Version-Dependent Practice

The repository currently uses Kubernetes v1.37 as its local practice baseline. Feature availability and behavior can also depend on the cluster provider, runtime, controllers, and configuration. For example, native sidecars are stable since v1.33 and in-place Pod resize is stable since v1.35, but that does not imply either is guaranteed to appear on the CKAD exam.

Before a 2027 exam, check the [current CNCF CKAD curriculum](https://github.com/cncf/curriculum/tree/main/ckad), [Linux Foundation FAQ](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks), and the exam's allowed-resource policy.

## Sharing Feedback

You can help improve this repository by sharing general preparation advice or noting a broken command. Keep feedback high-level and NDA-compliant:

- Do not post exam questions, wording, screenshots, task sequences, or reconstructed scenarios.
- Do not report scores or pass rates as representative without a documented, privacy-respecting method.
- Include the Kubernetes version and the date you checked a version-sensitive claim.
- Link to public sources for claims that can be verified independently.
