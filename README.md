# super-metal-mons-swift
[super metal mons (base game 1!)](https://x.com/supermetalx/status/1637955176035241984)

ios / macos

testflight @ [mons.link](https://mons.link)

![board](https://github.com/grachyov/super-metal-mons-swift/assets/7680193/ca624920-6d5d-4335-b20d-35073cc42bdc)

## rules

each player starts with **5 mons** and **5 mana pieces**

🎯 score 5 points by moving mana to the pools
* regular mana = 1 point
* super mana = 2 points
* opponent's mana = 2 points

↗️ on your turn
* move your mons up to a total of 5 spaces
* use one action ability
* move one of your mana by 1 space = end your turn


🪺 mon types [wip]
* **drainer** can pick up and move a single mana piece. When it lands on a space containing a mana piece, it picks up the piece. If it reaches a mana pool with a mana piece, that piece is instantly scored.

* **demon** can 'faint' another Mon by jumping exactly two spaces horizontally or vertically. The targeted Mon returns to its spawn point and skips its next turn.

* **mystic** can faint another Mon by projecting its power exactly two spaces diagonally. This power can pass over other pieces.

* **angel** protects any Mon within one space around it, but it does not protect itself or other Mons from the bomb.

* **spirit** can move any game piece (including Mons and mana) that is two spaces away by one space in any direction.

🤚 [wip] pick up items
In the game, there are special items, a bomb and a potion. When your Mon lands on a space with these items, you can choose which one to take:

* **Bomb:** Any Mon can pick up and throw the bomb up to three spaces away in any direction. The bomb faints the targeted Mon. If a Mon holding the bomb is fainted, the bomb explodes, and the attacking Mon also faints.

* **Potion:** The potion grants a one-time use ability that allows an extra action on your turn.

✅ also [wip]
* on the first turn of the game, you can only move mons.
* Each space can only be occupied by one Mon.
* Mon spawn points can only be occupied by the Mons assigned to them.
* Only a Drainer can share a space with a mana piece. It can carry only one item at a time.
* Mana cannot be scored if the mana pool space is occupied.
* If a Drainer carrying a mana piece faints, the mana piece stays there. If it was carrying the super mana, the super mana returns to the center.
* Mons cannot perform action abilities from their spawn point.
* The central space of the board is reserved for the super mana. If a Drainer carrying a super mana faints, the super mana piece is returned to this space.
