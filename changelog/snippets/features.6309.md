- (#6309) The movement speed of transports now changes based on how many and which types of units they have loaded.
    - Units slow down transports based on their `TransportSpeedReduction` stat. If a unit has a `TransportSpeedReduction` of 1, each instance of this unit will slow down the transport's `MaxAirspeed` by 1. The primary implication of this change is that the effectiveness of the currently too oppressive Zthuee drops is reduced in an intuitive way. The effectiveness of ACU drops via Tech 2 transports remains unchanged.

        - TransportSpeedReduction: 0.15 (Tech 1 land units)
        - TransportSpeedReduction: 0.3 (Tech 2 land units)
        - TransportSpeedReduction: 0.6 (Tech 3 land units)
        - TransportSpeedReduction: 1 (ACUs and SACUs)
        - TransportSpeedReduction: 1 (Tech 4 land units for compatibility with survival maps)

    - To prevent drops from being overnerfed by this change, the speeds of all transports is increased.

        - MaxAirspeed: 10 --> 10.75 (Tech 1 transports)
        - MaxAirspeed: 13.5 --> 14.5 (Tech 2 transports)
        - MaxAirspeed: 15 --> 17.5 (The Continental)

- (#6309) Display the `TransportSpeedReduction` stat in the additional unit details displayed when `Show Armament Detail in Build Menu` is enabled in the settings.
