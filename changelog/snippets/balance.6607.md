- (#6607) Improve the functionality of a number of anti-torpedo weapons by giving them a minimum range and altering their targeting. The addition of a `MinRadius` prevents the weapon from locking onto projectiles it cannot reasonably intercept anymore. In particular, the torpedo defense of the Aeon T3 Sonar should perform noticeably better with these changes. Additionally, audio queues are added to the torpedo defenses of the Seraphim Tech 1 and Tech 3 submarines.

  - **Aeon T3 Sonar Platform (UAS0305):**
    - Quasar Anti Torpedo
      - FiringTolerance: 2 --> 180
      - MinRadius: 0 --> 5
      - `UseFiringSolutionInsteadOfAimBone`: `false` --> `true`

  - **Sou-istle: T1 Attack Submarine (XSS0203):**
    - Ajellu Anti-Torpedo Defense
      - FiringTolerance: 0 --> 180
      - MinRadius: 0 --> 5
      - `UseFiringSolutionInsteadOfAimBone`: `false` --> `true`
      - Audio queue added

  - **Yathsou: T3 Submarine Hunter (XSS0304):**
    - Ajellu Anti-Torpedo Defense (x2)
      - MinRadius: 0 --> 10
      - Audio queue added

  - **Barracuda (XRS0204) and Megalith (XRL0403)**
    - Anti-Torpedo Flare
      - MinRadius: 0 --> 5
