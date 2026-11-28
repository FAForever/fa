{% unit enhancements/uef/drone %}
UEF ACU and SACU Engineering Drones
{% endunit %}
Remove the drones' auto-rebuild toggle, so a drone that dies is always rebuilt while its enhancement is installed. With the toggle off, a dead drone removed its enhancement, and the left drone of an ACU with both drones removed the right drone too (#7440).
