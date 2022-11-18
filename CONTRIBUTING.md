# Contribution Types

## Code Contributions

See [our setup guide](setup/setup-english.md) for information about setting up your development environment for FAF Lua code and a general description of our workflow schedule.

For file encoding, use UTF-8 and Windows-style line endings (CR LF) in the repository (Set core.autocrlf).

Your contribution license should be compatible with the Open-Source vision of the Forged Alliance Forever community - use the MIT license if you're unsure.
Note that unlicensed work is presumed to have its copyright fully protected by its author in most jurisdictions and may not be accepted in the future as FAF becomes more Open-Source.

Follow the [code style guidelines](codestyle.md) and the [annotation guidelines](annotation.md).

When possible, write a test for your contribution in [/lua/tests/](/lua/tests/) in a file starting with `test_` (Use the "luft" unit tester; see existing files for usage).
This will make your contribution easier to maintain and continue to get used (In addition, if you write the test before you start on the bulk of the contribution, it'll be even easier to debug while you write it).

When making *backwards incompatible API changes*, do so with a stub function and put in a logging statement including traceback.
This gives time for mod authors to change their code, as well as for us to catch any incompatibilities introduced by the change.

## Translation Contributions

This will entail a change in a file in `/loc/<LA>/strings_db.lua` (where `<LA>` is the language code).
If you do not find the language you would like to translate, contact an administrator to set it up for you.

If you are an individual blessed with the ability to translate more than one language, please put the translations for each language in a separate pull request, unless the langauges are similar enough for it to make less sense to do so.

Please adhere to the [localization guidelines](loc/guidelines.md).

## Asset Contributions

**TODO**

# Contributing Your Ideas

If you have an idea you would like to see in the game, the general workflow for contributions is as follows:

Phase 1 - design
* 1. An issue is opened by the contributor for larger ideas
* 2. The idea is discussed
* 3. A design plan is made

Phase 2 - development
* 4. The contributor starts work using the design plan and a pull request opened
* 5. The contributor works with the maintainer and other reviewers to resolve technical concerns and bugs

Phase 3 - wind-down
* 6. The maintainer makes sure the pull request is in proper shape to become part of Forged Alliance Forever
* 7. The pull request is merged and the behavior resulting from is monitored for several weeks to ensure stability

Smaller features or bug fixes can skip phase 1 and be opened as a pull request straightaway to reduce the workflow overhead.
Technical details will be discussed in tandem with design details (if any) to quickly merge the request.

After step 7, it may be determined that further bug fixing is required.
At this point, either someone else will have opened a new issue describing bugs that can be pursued or this process can be repeated again.

People also go through phase 1 to report complex bugs or suggest advanced features, even if they do not intend to be the contributor that tackles the issue in later phases.

## Phase 1 in detail

Please do not skip this phase.
If you start working on a large contribution on your own before running it by someone, you may end up needing to fundamentally change your design and redo a bunch of work which is no fun for anyone.

By the end of this phase, everyone should have the following be clear to them:
- What the scope of the issue being addressed is
- How the contribution will be designed
- A basic timeline of how its development will proceed
- To what extent the contributor and maintainer will work together

### Step 1 - inception

Open an issue clearly describing what you would like to contribute.
This allows for discussion and lets the idea to solidify its design and scope before anyone starts wastes time working on something that might end up getting changed.

### Step 2 - discussion

We discuss your contribution idea with you and explore possible side-effects, balance concerns, implementation concerns and other considerations from all parts of the Forged Alliance Forever project.

### Step 3 - planning

Once everyone interested understands what exactly is being proposed, a plan for how to, when to, and who will accomplish it is made together.
What is decided can vary greatly depending on the idea, but should fully encompass its design, scope, responsibilities, and also include a basic time-table that people can form development expectations around.

## Phase 2 in detail

Once the plan has been made, you will be given the approval to continue - in other words, a tentative "promise" that a pull request made using the plan will not have any problems being merged.
Understand, however, that this isn't at all like a contract.
It is merely a process designed to ensure that all everyone interested in making your contribution happen are on the same page about how that will look.
There may be questions raised later that reveal that this wasn't the case; this is okay.
Everyone will take a step back to regroup and form a new plan.

### Step 4 - pull request

Make sure you have this repository forked and have started a new branch in it with an appropriate name.
It isn't necessary for you to make sure the branch is created after approval.
Of course, you could have been working on the contribution all along or already have had parts it done in an unpublished branch - how you came to this point is up to you and the time/work tradeoffs you find important.

The important bit here is that you put in a pull request to the `deploy/fafdevelop` branch of this repository.

Please make sure "allow edits by maintainers" is checked.
The person merging may have a few trivial edits to make before merging that would take much longer if they had to go through you first (we will not fork your pull request, commit to & merge the fork, and then close yours).

If it wasn't decided on in the planning phase, the pull request will then be triaged, assigned labels, and assigned a maintainer.
Note that this doesn't mean that you won't be interacting anyone other than the maintainer - far from it!
Now that you've opened a pull request, lots of other people might become interested in your work.
This maintainer will simply be the one responsible for merging it at the end.

### Step 5 - following the plan

Commits and reviewer check-ins are expected to be performed according to the plan, on a best-effort basis.

Use the normal git conventions for commit messages, with the following rules:
- Write in the declarative mood (i.e. it should make sense when used in the sentence "When merged, this pull request will <message>")
- Subject line shorter than 80 characters
- No trailing period
- For non-trivial commits after the first one, always include a commit message body, describing the change in detail

We use [git flow](http://nvie.com/posts/a-successful-git-branching-model/) for our branch conventions.

Your pull request will not be merged until reviewed and all conversations have been resolved.
Please let the reviewer resolve each conversation after you process their feedback or it may end up getting unresolved again and overlooked by you.

## Phase 3 in detail

This is the point that pull request is taken out of the hand of the contributor and into the maintainer's.
It may be a fuzzy transition.

### Step 6 - maintenence

The maintainer makes sure that the contribution meets the standards required to become part of Forged Alliance Forever.
This may include a commit of trivial changes to bring the pull request up to spec or requesting other finalizing details.
Depending on the implied consensus reached in the discussion phase (and anything explicit as well), the maintenence they do may be more or less involved, and they may wait for you raise objections (and move back to step 5) or to confirm what they've done before merging.

### Step 7 - wind-down

The pull request is merged and general feedback is slowly generated.
Please do utterly not abandon the pull request yet in case something comes up that needs clarifying.

## Workflow hurdles

If you notice your pull request isn't progressing, check the conversation for feedback you may have missed  - the reviewer will likely not take the time to remind you of unprocessed feedback or repeat previous comments each time you make a new commit or comment.
However, in the event you find yourself simply waiting on the reviewer for a long time without hearing anything, speak up - a miscommunication likely occurred and further communication is required for you to understand each other.
At the very worst, you'll learn that they're a busy person who hasn't had the time to do another review.

Please be aware that all contributors are volunteers and operate under a best-effort basis that may change with their life circumstances.

# Contributing Your Time, Skills, and Effort

If you don't have any particular idea or bugfix you would like to see in the game, you can still contribute!
There's a lot of work to be done, and chances are that someone else has an idea what that could look like.
Head on over to the [issues tab](https://github.com/FAForever/fa/pull/4318) and look for a topic that piques your interest.
