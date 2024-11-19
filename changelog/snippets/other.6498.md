- (#6498, #6502, #6503, #6514, #6516, #6517, #6518, #6506) Refactor the Enhancements section in the ACU/SACU scripts

It replaces the long if/else chain with a more modular design that is easier to maintain and hook. Each enhancement has its own dedicated function, named with the format `ProcessEnhancement[EnhancementName]`. The CreateEnhancement function now calls the appropriate enhancement function automatically by that name format.
