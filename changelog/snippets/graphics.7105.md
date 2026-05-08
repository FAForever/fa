- (#7105) Improve scoreboard legibility and internal text functions for mods/devs

  #### UI

  Improve scoreboard legibility with better alignment, tooltips, dropshadows, and text cropping.

  #### Modding/development

  added SetTruncationText() to assign custom trailing characters like "..." when text is cropped

  split SetText() into **SetText()** and its implicitly called **SetDisplayText()**. This allows for fancier text implementations like custom truncation.
