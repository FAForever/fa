- (#6681) Don't initialize/alter objects during module loading in `construction.lua` for the draggable queue option.

  Initializing/altering objects during loading of a module is a bad habit, especially if done from another module. In this case it caused an error and a game freeze if a UI mod tried to access `construction.lua` before the UI was created.
