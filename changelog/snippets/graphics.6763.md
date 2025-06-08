- (#6763) Introduce a new slider to adjust the rendering distance of shadows

Strogo made the observation that the extensive (default) rendering distance of shadows can have a significant impact on the framerate. We increased the default rendering distance of shadows in FAForever two years ago. At the time we did not notice this impact. With these changes we turn it into a slider in the graphics options. The default value (260) matches the value used by Steam version of the game.
