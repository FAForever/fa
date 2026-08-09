- Rework the chat window (#7098, #7148, #7157, #7214).

  The chat window is re-implemented from scratch. It is rebuilt using the MVC-principle, creating a clear separation between state, viewing the state and interacting with the state. This rework fixes a few bugs:

  - The chat window fully supports UI scaling.
  - The chat will always snap to the frame when you open it, making it impossible for the chat to be off-screen after a resolution change.

  Adds a few features:

  - You can now issue various chat commands, use `/help` to learn more.
  - UI mods can add chat commands with ease.
  - Autocomplete on names when you start with `@`.
  - Convenient for the simulation (campaign, AIs, events) to send chat messages.
  - Click on a chat message to copy it to clipboard.

  And finally there are a few quirks:

  - The chat now starts bottom-up, instead of top-down.
