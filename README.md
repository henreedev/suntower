# Suntower <!-- omit in toc -->

Suntower is a Foddian rage platformer built in Godot. You help a sunflower reach the top of the tower, navigating difficult weather conditions along the way. The core mechanic is hook-based climbing with a rope that can extend and retract.

## [Play Suntower on itch.io](https://henree.itch.io/suntower) <!-- omit in toc -->

---

## Table of Contents <!-- omit in toc -->

- [Core Mechanics](#core-mechanics)
  - [Flower Movement - (`Head.gd`)](#flower-movement---headgd)
    - [State Machine](#state-machine)
    - [Rope Extension/Retraction](#rope-extensionretraction)
  - [Weather - `Tower.gd`](#weather---towergd)
- [Acknowledgments and Credits](#acknowledgments-and-credits)

---

## Core Mechanics

- **Flower Movement**: The player has certain states with different physical properties for movement. These include an **idle** state, **extending** state, and **retracting** state.

- **Weather**: There are four different sections of the tower, each with different weather conditions. These include **sunny**, **stormy**, **windy**, and **calm**.

### Flower Movement - [(`Head.gd`)](./scenes/character/Head.gd)

#### State Machine

The player's physical state is stored in an enum:

```gdscript
enum State {INACTIVE, EXTENDING, RETRACTING}
```

While inactive, the player can aim the Head with the mouse.
The player can begin extending if the Pot is stable:

```gdscript
# Player can extend if the pot is stable
can_extend = _pot.touching and _pot.linear_velocity.length_squared() < 2.0
```

The player's

#### Rope Extension/Retraction

- **Rope Extension/Retraction**: The stem of the flower can extend and retract, using rigid bodies chained together with pin joints.

- **Purpose**: Handles all player-related actions and interactions.
- **Main Functions**:
  - `move_player()`: Manages player movement based on user input.
  - `shoot_projectile()`: Creates and fires projectiles when the player presses the shoot button.
  - `take_damage(amount)`: Reduces health based on the damage amount and triggers game over if health is depleted.
- **Special Logic**: Briefly mention any unique code you’re proud of or that shows problem-solving skills.

### Weather - `Tower.gd`

- **Purpose**: Handles all player-related actions and interactions.
- **Main Functions**:
  - `move_player()`: Manages player movement based on user input.
  - `shoot_projectile()`: Creates and fires projectiles when the player presses the shoot button.
  - `take_damage(amount)`: Reduces health based on the damage amount and triggers game over if health is depleted.
- **Special Logic**: Briefly mention any unique code you’re proud of or that shows problem-solving skills.

## Acknowledgments and Credits

Programming and Art: **henree**
Music: [**jSeo.co.kr**]()

Thanks to all of my friends and classmates who playtested Suntower and provided early feedback that shaped the game.
