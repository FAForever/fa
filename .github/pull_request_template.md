<!--
Write for a volunteer reviewer with a few minutes: the top sections should be enough to decide whether and how to review.
Delete the sections and comments that don't apply. A small PR may only need the description, testing and the checklist.
-->

## Problem
<!--
For a fix: the symptom, as a log excerpt, a screenshot or a short description.
For a feature or balance change: why players need it, with a link to the discussion that approved it.
If an issue already covers this, you can remove this section and link the issue in the description below.
-->


## Description of the proposed changes
<!--
What changes, in 1-3 sentences. Longer explanations go in the details section below.
Then link what a reviewer needs, if any:
- the issue, with a closing keyword: Fixes #1234
- the PR that caused the problem, so this PR also shows on its timeline
- related changes in faf-re or FA-Binary-Patches
-->


## Testing done on the proposed changes
<!--
Describe what you tested and what you saw in a few sentences, a screenshot, or a video. Put results that compare runs, such as observations or benchmarks before and after the changes, in a table.
Steps for reviewers to repeat go in a numbered list or a checklist.
Long setup goes in a details block:

<details><summary> Setup </summary>

</details>
-->


## Details
<!--
Add only the parts that apply, each in its own details block, so it stays collapsed until a reviewer opens it:
- Root cause: the chain from the symptom to the cause, one step per line, each with its evidence.
- Implementation: one change per bullet, grouped by behavior. Leave out what the diff shows.
- Alternatives considered, and why they weren't used.

<details><summary> Root cause </summary>

</details>
-->


## Checklist
- [ ] New code is annotated and has comments where useful
- [ ] Changes are documented in a changelog snippet according to the [guidelines](https://faforever.github.io/fa/development/changelog#format-of-a-snippet), or added to the snippet of the unreleased PR this one changes
- [ ] The change is conceptually approved ([explanation](https://github.com/FAForever/fa/blob/deploy/fafdevelop/CONTRIBUTING.md)): it is a bugfix, the team lead approved it, or a discussion concluded in its favor (linked above)
- [ ] Requested 2-3 reviewers from the [list of reviewers and their areas of knowledge](https://github.com/FAForever/fa/blob/deploy/fafdevelop/CONTRIBUTING.md#reviewers)
