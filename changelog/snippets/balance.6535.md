- (#6535) Improve the maneuverability and reliability of Strategic Bombers to promote proactive use of them and as a competing option to T3 gunships
  - Maneuverability: 
    - Increase turn speed: 0.8 -> 1.5
      This lets it effectively micro against flak damage, and leaves less time/opportunities for ASF/SAMs to deal damage.
    - Increase Lift Factor: 7 -> 17
      This improves the speed of the bomber lifting off, complementing the new turn speed.
  - Reliability:
    - Bomb drop threshold: 3.5 -> 10
      This greatly improves the ability of the bomber to fire on uneven terrain or during turns, where it may get a less than ideal path. It is necessary because every bomb of a strategic bomber matters, and it can be devastating if one of them doesn't fire because the engine decided the small drop zone was unfortunately in the wrong place. A similar massive increase for the threshold was done for the Ahwassa (4 -> 20) (#2465)[https://github.com/FAForever/fa/pull/2465].
    - Smaller loops on auto attack to maximize DPS: 
      This only increases DPS when bombing a single target with multiple passes, so I wouldn't put it exactly under the HP/DPS buff restriction. Previously bombs would drop only every ~13 seconds, and with the turn speed and breakoff distance reduction they drop every ~8 seconds.
      It can also be argued that this is just simplifying the micro of multiple bombers when you want to maximize DPS. There will of course still be micro against AA or to have good bombing paths that make use of the reload, both of which are far more engaging than figuring out when to turn multiple bombers just to bomb a single target on reload with multiple passes.
      - `BreakOffDistance`: 60 -> 40
      - `RandomBreakOffDistanceMult`: 1.5 -> 1
