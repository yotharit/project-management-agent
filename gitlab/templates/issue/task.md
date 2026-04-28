<!--
  Task (Subitem) Issue Template
  Deploy to: .gitlab/issue_templates/task.md in your GitLab repo

  After creating the issue, apply these labels:
    Kind: Task
    Status: Todo
    Priority: <inherit from parent Working Item>
    Group: <same as parent Working Item>
    Platform: <same as parent Working Item>

  Set Milestone to match parent Working Item.
  Link to parent by adding "Part of #<working_item_iid>" in the description below.
-->

## Parent Working Item

Part of #<!-- working_item_iid -->

## Summary

<!-- Atomic, action-oriented task — start with a verb (e.g. "Implement", "Fix", "Write") -->

## Owner

@<!-- username -->

## Reviewer

@<!-- qa_username -->

## Timeline

- Start: YYYY-MM-DD
- End: YYYY-MM-DD

## Description

<!-- Implementation notes, edge cases, subtleties. Keep brief. -->

## Status Log

<!-- Agent appends a line here on every standup update:
  YYYY-MM-DD HH:MM — Status: <old> → <new> — Yesterday: <...> | Today: <...> | Blockers: <...>
-->
