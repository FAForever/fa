{% unit XAB1401 %}
Paragon: T4 Experimental Resource Generator
{% endunit %}
Reduce Paragon's max output so that it cannot simultaneously defend itself against land, air, and artillery while also making Salvations to kill enemy infrastructure. This ability made it far more powerful than other game enders and essentially unbeatable even if the enemy had nearly full map control, which is not the case for other game enders (#7131).
  - Output is now constant instead of only fulfilling excess resource usage.
    This allows it to transition from defense to salvation construction more quickly.
  - Mass output: 10k -> 4k
  - Energy output: 1000k -> 400k
  - Mass storage: 0 -> 280k
  - Energy Storage: 100k -> 12M
