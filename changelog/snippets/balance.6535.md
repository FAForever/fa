- (#6535) Improve the maneuverability and reliability of Strategic Bombers to promote proactive use of them and as a competing option to T3 gunships
  
  **Strategic Bombers (UAA0304, UEA0304, URA0304, XSA0304):**
    - Maneuverability: 
      - Increase turn speed: 0.8 -> 1.2

        Lets strats micro to more effectively avoid flak damage and leaves less opportunities for ASF/SAMs to deal damage.

      - Increase Lift Factor: 7 -> 10

        Complements the new turn speed by improving how quickly strats lift off and navigate up/down terrain.

    - Reliability:
      - Bomb drop threshold: 3.5 -> 8

        Greatly improves the reliability of bomb drops on uneven terrain or during turns. This is similar to what was done for the Ahwassa in [#2465](https://github.com/FAForever/fa/pull/2465).

        As a side effect, this usually makes the bomb drop from further away, so ACUs will have an easier time dodging bombs. Dodging was made more difficult with the strat elevation reduction in [#4799](https://github.com/FAForever/fa/pull/4799), so this counteracts that change.

      - Smaller loops on auto attack to maximize DPS:

        - `BreakOffDistance`: 60 -> 50
        - `RandomBreakOffDistanceMult`: 1.5 -> 1

        This only affects bombers automatically attacking from an idle state or from an attack, attack move, or patrol order. Previously strats would drop bombs every ~13 seconds, and now they drop every ~10 seconds.

- (#6535) Reduce the veterancy requirement for Strategic Bombers to match their mass cost reductions in previous patches.

  **Strategic Bombers (UAA0304, UEA0304, URA0304, XSA0304):**
    - Mass killed required per veterancy level: 4200 -> 2x of own mass cost (3500)
