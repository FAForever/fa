- (#6720) Various units had sonars and radars with ranges lower than their vision ranges, making these stats redundant and adding extra range rings which were not required. This PR removes the unnecessary sonar and radar ranges along with their corresponding range rings. Gameplay-wise, there is no change in functionality of the affected units.

  - For example, the Torrent had a `WaterVisionRadius` of `48`, a `RadarRadius` of `108`, but only a `SonarRadius` of `20`.

- (#6720) Align the Salem's RadarRadius with the other destroyers.
