{% unit UAB2302 %}
Emissary: T3 Heavy Artillery Installation
{% endunit %}
Increase the duration between the two damage pulses so that engineer shield assist is more effective against it, but also overhaul the projectile so that it goes through shields that it kills with the first pulse (#7335).
- Sonance Artillery:
  - DoT Duration: 1.0s -> 3.8s
  - Projectile pierces shields and units that die during the DoT duration. This allows the initial 6k damage to break a shield, have the projectile travel through the shield, and deal the second 6k damage underneath the shield. Basically this reduces Emissary's massive overkill.
