
## When making a PR:

If you plan a bigger change, make an issue first to discuss the feature. This way you can avoid spending time on something that would ultimately be denied integration.

- Target the `develop` branch.
- Start your PR as draft.
- Don't forget to add appropriate tags.

Each PR needs a [snippet](https://faforever.github.io/fa/development/changelog) for the changelog file of the release.
When you have made all the changes you intended to do and have added the snippet, you can mark the PR as ready for review by removing the draft status from the PR.
Now the PR should be milestoned to the next release.
You can request reviews from people that a knowledgable in the domains of the code you changed (See below).


## How to do a review:

1. Do we want this feature?  
   If it's just a bugfix this can generally be answered as yes.  
   If it's a new feature or changes gameplay in a more meaningful way there is ideally a linked issue where the discussion already happened and it was concluded that we want this feature.  
   Sanity check: Should this rather be a sim/ui mod?

2. Functionality  
   Start the game with these changes and see if the described changes work as intended.  
   Test if related functionality still works and didn't inadvertantly break.
   There is no hard rule how much testing is needed, especially as we can't automate this. You don't have to go overboard with testing as we still have the duration between the merge and the next release to notice bugs during actual gameplay.

3. Technical code review  
   Is the code style correct? Please follow the [Lua Style Guide](http://lua-users.org/wiki/LuaStyleGuide).  
   Is the code readable and doing things the way things should be done?  
   This step should be done by people that have knowledge of the affected domains of the code base (See below).

4. Balance implications (only for PRs labeled as balance)  
   Changes touching balance need a green light from the balance team.

It's totally possible to review not all steps if you don't have the knowledge or motivation to do them all. Someone else can pick up the other steps.  
If you don't review all steps, don't formally approve the PR, but state your approval of the steps you did in a review comment. Only PRs that passed all review steps should be formally approved.


## When to merge:

After all the necessary reviews have passed and the PR has been approved it can be merged. We suggest to wait 24 hours after approval, so the owner of the PR can interject if there was some sort of miscommunication and the owner still intends to do some changes. The PR owner can also merge the PR if they want.

Merge by using the squash option.  
Use the normal git conventions for the commit message, with the following rules:

- Subject line shorter than 80 characters
- Pull request number at the end
- No trailing period
- For non-trivial commits, always include a commit message body, describing the change in detail

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