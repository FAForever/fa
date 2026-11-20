<!--
Write for a volunteer reviewer with a few minutes: Problem and Proposed Changes should be enough to decide whether and how to review.
Copy the examples you need out of the comments, then delete the sections and comments that don't apply. A small PR may only need Proposed Changes, Testing, and the checklist.
-->

## Problem
<!--
For a fix: the symptom as a log excerpt, a screenshot, or a short description.
For a feature or balance change: why players need it, with a link to the discussion that approved it.
For other changes, such as refactors, docs or tooling: why they're needed.
If an issue already covers this, you can remove this section and link the issue in Proposed Changes below.
-->


## Proposed Changes
<!--
What changes, in 1-3 sentences. Longer explanations go in the Details section below.
Then link what a reviewer needs, if any:
- the issue, with a closing keyword: Fixes #1234
- the PR that caused the problem, so this PR also shows on its timeline
- related changes in faf-re or FA-Binary-Patches
-->


## Testing
<!--
Steps that someone who doesn't know the change can follow to check it. If a linked issue already has complete steps, link them and add only what's missing.
Number every step, setup included. Put a code snippet longer than 3 lines in a details block inside its step, and the expected results in bullets under it. A screenshot can be an expected result.
When expected results are values such as benchmarks before and after the changes, put them in a table and refer to it from a bullet. When the test splits into parts with different steps, give each part a lettered heading that says which step it follows, and continue the numbering from that step, so a step can be referred to as A3 or B3.

1. Start ... and run `...`
2. Run ...
   <details><summary> Code snippet </summary>

   ```lua

   ```

   </details>

   - ... happens
   - ... matches the table below

### A: Option on (after step 2)
3. Do ...
   - ... happens

### B: Option off (repeat steps 1-2 with the option off)
3. Do ...
   - ... happens
-->


## Details
<!--
Add only the parts that apply, each in its own details block, so it stays collapsed until a reviewer opens it:
- Root cause: the chain from the symptom to the cause, one step per line, each with its evidence.
- Implementation: one change per bullet, grouped by behavior. Include what is easy to miss in the diff, such as the rule behind a change repeated across many files, or a small change inside a large one. Leave out what a reviewer sees at a glance, such as which files changed.
- Alternatives considered, and why they weren't used.
- Other long parts, such as a feature spec.

<details><summary> Root cause </summary>

</details>
-->


## Checklist
- [ ] New code is annotated and commented according to the [annotation guide](https://github.com/FAForever/fa/blob/deploy/fafdevelop/annotation.md)
- [ ] Changes are documented in a changelog snippet according to the [guidelines](https://faforever.github.io/fa/development/changelog#format-of-a-snippet), or added to the snippet of the unreleased PR this one changes
- [ ] The change is conceptually approved ([explanation](https://github.com/FAForever/fa/blob/deploy/fafdevelop/CONTRIBUTING.md)): it is a bugfix, the game or balance team lead approved it, or a discussion concluded in its favor (linked above)
- [ ] Requested or mentioned 2-3 reviewers from the [list of reviewers and their areas of knowledge](https://github.com/FAForever/fa/blob/deploy/fafdevelop/CONTRIBUTING.md#reviewers)
