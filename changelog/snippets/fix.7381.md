- Fix engineers that start reclaiming a unit while it is being built continuing to unbuild it after other engineers finish it, which refunded the full build cost of the finished, working unit and left it alive at 0 health. Their orders now restart as the reclaim of a finished unit (#7381).

- Fix a single builder holding an unfinished unit at 0 health forever while other engineers reclaim it, which kept the builder and the reclaimers from moving on to their queued orders. The unit is now removed, as when it is reclaimed without a builder (#7381).
