- (#6681) Don't initialize/alter objects during module loading in Construction.lua

Initializing/altering objects during loading of a module is a bad habbit, especially if it is from another module. In this case it can cause error and game freeze if UI mod tries to access `construction.lua` before UI is created.