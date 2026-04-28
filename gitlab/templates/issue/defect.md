<!--
  Defect Issue Template
  Deploy to: .gitlab/issue_templates/defect.md in your GitLab repo

  After creating the issue, apply these labels:
    Kind: Working Item
    Group: Defects
    Type: BUG
    Priority: <High | Medium | Low | Un-priority>
    Platform: <platform where bug was found>
    Dev Status: Todo              ← authoritative status for defects
    QA Status: Pending Retest     ← authoritative status for defects
    DO NOT apply Status::* labels to Defect issues (§4)

  Owner   = Dev who fixes (set as GitLab assignee)
  Reviewer = QA who reported and will retest (note their @username below)
  Both are required when the defect is opened (§11).
  Set Milestone to the release version where the bug was found.
-->

## Summary

<!-- One-sentence bug description -->

## Feature Area

<!-- e.g. Transaction Limit, Registration, Wallet UI -->

## Release Found

<!-- e.g. v3.0.0-beta.24 -->

## Owner (Dev)

@<!-- dev_username --> — responsible for fixing

## Reviewer (QA)

@<!-- qa_username --> — reported and will retest

## Steps to Reproduce

1. 
2. 
3. 

## Expected Behavior

## Actual Behavior

## Environment

- Platform: 
- OS / Device: 
- App version: 

## Attachments

<!-- Screenshots, logs, videos -->

## Retest Log

<!-- QA appends a result after each retest:
  YYYY-MM-DD — Pass/Fail — <notes> (@qa_username)
-->
