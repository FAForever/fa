
## When making a Pull Request (PR):

If you plan a bigger change, make sure to discuss the feature first. This way you can avoid spending time on something that would ultimately be denied integration. You can open an issue to lay out the problem that you want to fix, but this is not strictly required.
We discuss changes on our discord, so start a discussion there and link the discussion in the PR description once a conclusion has been reached.

## Technical info

- Target the `develop` branch.
- Don't forget to add appropriate tags.

Useful tooling:
-  [ScreenToGif](https://www.screentogif.com/): Free, open source screen recorder that can export to MP4. If the changes are visual, these can help you tell us exactly what the changes imply!

Each PR needs a [snippet](https://faforever.github.io/fa/development/changelog) for the changelog file of the release.
We have an automatic workflow that adds a snippet template and tries to guess the category based on the PR tags. It also converts the PR to a draft.
When you have made all the changes you intended to do and have updated the snippet text, you can mark the PR as ready for review by removing the draft status from the PR.
You can request reviews from people that a knowledgable in the domains of the code you changed (See below).

## About reviews

To make reviews easier, reviewers are only tasked with making sure that a PR is technically correct, not if we want that feature at all. So at the stage of requesting reviewers it is important that it's clear that the intention behind the change is greenlighted. We already have a good game and adding new features does not necessarily make the holistic experience of the game better. 

There are various ways to consider a change to be greenlighted:
- It is a bugfix
- The game team lead has made a decision
- The discussion on discord has concluded positively.

If a feature changes the balance of the gameplay, then the balance team has to also be in favor. If there was a discussion on discord, a link to it should be inserted into the PR description, so people can later find it.

Sometimes it's necessary to test changes in a real game to be able to decide if integrating them is a good idea. To do this we can deploy changes to the fafbeta game mode to test them.

Once there is approval from a conceptual point of view, tick the box in the PR description. This way possible reviewers know that a technical review is the only step left to do when they have a look at the overview list of PRs.
Reviewers don't like to spend time on PRs that might never make it into the game, so they will probably ignore PRs that don't have this box set.

Try to keep PRs small to make reviews easier and consider splitting big features into multiple PRs.


## How to do a review:

1. Functionality  
   Start the game with these changes and see if the described changes work as intended.  
   Test if related functionality still works and didn't inadvertently break.
   There is no hard rule how much testing is needed, especially as we can't automate this. You don't have to go overboard with testing as we still have the duration between the merge and the next release to notice bugs during actual gameplay.
   If the PR author has already done extensive testing you can keep this short.

2. Technical code review  
   Is the code style correct? Please follow the [Lua Style Guide](http://lua-users.org/wiki/LuaStyleGuide).  
   Is the code readable and doing things the way things should be done?  
   This step should be done by people that have knowledge of the affected domains of the code base (See below).

It's totally possible to just do some testing if you don't have the knowledge to do a code review. Someone else can pick that up. In that case, don't formally approve the PR, but state what you tested in a comment. Knowing that the change has been tested well already helps for the code review.


## When to merge:

After the PR has been tested and approved it can be merged. We suggest to wait 24 hours after approval, so the owner of the PR can interject if there was some sort of miscommunication and the owner still intends to do some changes. The PR owner can also merge the PR if they want.

Merge by using the squash option.  
Use the normal git conventions for the commit message, with the following rules:

- Subject line shorter than 80 characters
- Pull request number at the end
- No trailing period

If the branch was in the FAForever repository, delete it after the merge, so it doesn't clutter the repo.

## Reviewers

These are people knowledgeable of the indicated areas, that are good candidates to request a review from.

**lua (ui)**  
@4z0t  
@Basilisk3  
@lL1l1  
@Garanas  
@Hdt80bro  
@clyfordv  
@speed2CZ  

**lua (sim)**  
@lL1l1  
@4z0t  
@Basilisk3  
@Garanas  
@Hdt80bro  
@clyfordv  
@speed2CZ  
@The-Balthazar  

**AI**  
@relent0r  
@Garanas  

**blueprints**  
@Basilisk3  
@Garanas  
@Hdt80bro  
@lL1l1  
@The-Balthazar  

**mapping**  
@speed2CZ  

**modeling**  
@MadMaxFAF  
@The-Balthazar  
@lL1l1  

**graphics**  
@BlackYps  
@Garanas  

**binary patches**  
@4z0t  
@Hdt80bro  