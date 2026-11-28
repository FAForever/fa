{% unit enhancements/uef/drone %}
UEF ACU and SACU Engineering Drones
{% endunit %}
Remove the drones' auto-rebuild toggle, so a drone that dies is always rebuilt while its enhancement is installed. With the toggle off, a dead drone removed its enhancement, and on an ACU with both drones, the left drone's death emptied the Back slot while the right drone stayed alive (#7440).
