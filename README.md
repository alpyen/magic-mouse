# magic-mouse

Steam Workshop Page: <a href="">Steam Workshop::TBA</a>

Cast your way through 2.5D levels by drawing bridges with your mouse and hopping onto them.

An Overgrowth puzzle mod which makes use of the mouse.

### ToDo-List

- Add Mod menu to editor for settings
	- Open Workshop page button (niy)
- Switch Hotspot uses Reset() and runs before post_reset. Hook LevelMessages and wait for post_reset?
- Win Level only if the player is alive
- Optimize (Un-)Hovering of the Switch Hotspots (do not send messages every frame)
	- Add disabling to mod settings menu if it draws too much performance on low-end systems?
- Test if menu hook is drawing performance from non-magic-mouse levels.
- Add levels with NPCs
- Add levels with switches