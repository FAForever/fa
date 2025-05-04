- (#5971) Add two new lobby options that determine how to share units of players who disconnect (DC) from the game: DC Share Conditions and DC ACU Share Conditions
This gives players of all types a way to lessen the impact of a disconnect in their games to a varying degree.
  - DC Share Conditions: Similar to the standard Share Conditions option, this determines how units are shared when a player disconnects.
    - The default is to copy the standard share condition, but it can be set independently.
    - To prevent abuse, the DC Share Conditions are not applied in Assassination games if the ACU takes damage or dies in 2 minutes (depending on the DC ACU Share Conditions).
  - DC ACU Share Conditions: Determines how ACUs are treated when a player disconnects. They can be split into two categories:
    - Instant conditions: These are applied instantly, so to prevent abuse, the DC Share Conditions are only applied if the ACU has not taken damage within the last 2 minutes.
      - Explode (Default): The current behavior of ACUs, where they explode when their player leaves.
      - Recall: Instead of exploding, the ACU peacefully recalls, keeping everything around intact. This can only happen if they weren't damaged in the last 2 minutes to prevent abuse.
    - ACU Sharing conditions: These share the disconnecting ACU. To prevent abuse, the DC Share Conditions are only applied if the ACU doesn't die within 2 minutes of being shared. After those 2 minutes, the DC Share Conditions apply when the ACU recalls or dies.
      - Delayed Recall: ACUs are very powerful, but also necessary early on, so this option shares the ACU for 2 minutes or until 5 minutes pass in the game (displayed as a countdown on the ACU). Afterwards, it recalls (except if it was damaged in 2 min, then it explodes). This gives players an opportunity to stabilize the new situation without getting a large long term advantage by controlling two ACUs.
      - Permanent: For those who don't mind it, or when the ACU is too precious to lose after a timer, the ACU can be shared permanently.

  Some examples:
  - Share until death players can use "Same as Share" and "Permanent" to keep players who disconnect snipeable, but not lose their entire base.
  - Survival/modded players can use "FullShare" and "Permanent" to keep everything.
  - Competitive players can use "FullShare" and "Delayed Recall" to not have to restart the lobby or draw because of an early disconnect, but without having an OP double ACU strategy.
  - Think getting bases or reclaim from disconnects is unfair? Make them recall and desert as civilians!
