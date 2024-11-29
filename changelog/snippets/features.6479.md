- (#6479) Rework the in-game matchmaker lobby from the ground up

    From a user perspective there should be essentially no changes. A new connection matrix is introduced that can help players to understand what source (a player) is connected to what source (another player). The diagonal represents what sources (other players) the local client is connected to. When you receive a message from a peer then it blinks the corresponding box in the matrix.

    There are further features ready such as a map preview that can help you prepare for the match ahead. That is not shown however until we have better tooling in place to gauge its impact.

    From a developers perspective the matchmaker lobby is now maintainable. You can now start the matchmaker lobby locally through your development environment. This allows you to run the matchmaker lobby as if you would find a match in the client. The matchmaker lobby is build from the ground up with maintainability in mind. It now supports a hot reload-like functionality for the interface. This allows you to change the interface on the go, without having to relaunch the game.

    All taken together this is still very much a work in progress and we would love to hear the feedback of the community. We welcome you on Discord in the dev-talk channel.
