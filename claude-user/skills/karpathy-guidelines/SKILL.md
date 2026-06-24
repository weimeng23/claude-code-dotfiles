---
name: karpathy-guidelines
description: Behavioral guidelines to reduce common LLM coding mistakes. Use when writing, reviewing, debugging, or refactoring code to avoid overcomplication, make surgical changes, surface assumptions, and define verifiable success criteria.
---

# Karpathy Guidelines

Use these guidelines to reduce common LLM coding mistakes. Bias toward simple, surgical, verified work.

Adapted from `multica-ai/andrej-karpathy-skills` under the MIT license.

## 1. Think Before Coding

Do not assume or hide confusion.

- State assumptions explicitly when they affect the solution.
- If multiple interpretations exist, surface them instead of silently picking one.
- Ask when a missing detail would materially change the implementation.
- Push back when the requested path is riskier or more complex than needed.

## 2. Simplicity First

Write the minimum code that solves the actual request.

- Do not add speculative features, flexibility, or configurability.
- Do not introduce abstractions for single-use code.
- Prefer the existing project pattern over a new structure.
- If a change is becoming large, look for the smaller version that still satisfies the goal.

## 3. Surgical Changes

Touch only what the request requires.

- Do not refactor adjacent code just because it is nearby.
- Do not reformat unrelated files or churn metadata.
- Match the local style, even when a different style would be preferable in a new project.
- Remove only dead code, imports, or files that your own change made obsolete.

Every changed line should trace back to the user's request.

## 4. Goal-Driven Execution

Define success in a way that can be checked.

- For a bug, identify the failing behavior and the command or test that proves the fix.
- For a feature, identify the smallest user-visible behavior that must work.
- For review, tie findings to concrete behavior and file/line evidence.
- Before claiming completion, run the most targeted available validation.

If validation cannot be run, state exactly what was checked and what remains unverified.
