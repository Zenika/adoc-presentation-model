# Spotlight - Reveal.js Plugin

A plugin for [Reveal.js](https://github.com/hakimel/reveal.js) allowing to highlight the current mouse position with a spotlight. 

It is off by default and you can trigger it with a keyboard press.

## Demo

![](img/demo.gif) 

## Hardware
I use "Aplic Wireless Mini Air Mouse" as presenter

## Installation

### Copy
Copy the file `spotlight.js` into the plugin folder of your reveal.js presentation, i.e. ```plugin/spotlight```.


### Dependencies
Add the plugin to the dependencies in your presentation, as below. 

```javascript
Reveal.initialize({
	// ...
	dependencies: [
		// ... 		
		{ src: 'plugin/spotlight/spotlight.js' },
		// ... 
	]
});
```

## Configuration
The plugin can be configured by providing a spotlight option containing an object i.e. with `size` and other configuration items within the reveal.js initialization options. By default spotlight is toggled by mouse down event. There is no cursor visible by default. You can switch from 'presentation mode' to 'normal mode' by pressing the 'Windows Menu / Right' key. But you can change this default behaviour.

```javascript
Reveal.initialize({
	// ...
	spotlight: {

			// size of the spotlight
			size: 60,
			
			// true: Locks the mouse pointer inside the presentation
			lockPointerInsideCanvas: false,

			// toggle spotlight by holding down the mouse key
			toggleSpotlightOnMouseDown: true,

			// choose the cursor when spotlight is on. Maybe "crosshair"?
			presentingCursor: 'none', 

			// true: cursor is always "none" except when spotlight is on. 
			presentingCursorOnlyVisibleWhenSpotlightVisible: true,

			// enable pointer mode
			useAsPointer: true,

			// pointer color (If pointer mode enabled)
			pointerColor: 'red'
	},
	keyboard: {	
			// alternative to toggleSpotlightOnMouseDown: 
			// toggle spotlight by pressing key 'c'
			// 67: function() { RevealSpotlight.toggleSpotlight() },

			// enter/leave presentation mode by pressing key 'Windows Menu/Right'
			93: function() { 
				RevealSpotlight.togglePresentationMode(); 
			},
	},
	// ...	
```

### Configuration items
#### size
Default: `60`

Configure the size of the spotlight

#### lockPointerInsideCanvas
Default: `false`

`true`:
Locks the mouse pointer inside the presentation. Press `Esc` to undo the lock. 

This is very useful especially when you present with a Presenter or a Wireless Air Mouse. 
Furthermore helpful if you have two screens (i.e. Beamer and Laptopscreen)

This feature relies on the experimental Browser Feature [PointerLock](https://developer.mozilla.org/en-US/docs/Web/API/Element/requestPointerLock)

#### toggleSpotlightOnMouseDown
Default: `true`

Toggle spotlight by holding down the mouse key. And switching to the cursor provided by the configuration item `presentingCursor`, if configuration item `presentingCursorOnlyVisibleWhenSpotlightVisible` is true.

#### presentingCursor
Default: `none`

Set the cursor value when presentation mode is toggled by `togglePresentationMode()`. Maybe "crosshair"?

#### presentingCursorOnlyVisibleWhenSpotlightVisible
Default: `true`

`true`:
When you are in presentation mode the cursor is always "none" except when spotlight is on. Then it uses the configuration item `presentingCursor` as cursor value.

`false`:
Configuration item `presentingCursor` is always used as cursor value, when you are in presentation mode.

#### useAsPointer
Default: `false`

Enables a mode where the screen is not dimmed and you can use the mouse as a pointer.
While using this option it makes sense to reduce the `size` to `6`

#### pointerColor
Default: `red`

Defines the pointer color if configuration item `useAsPointer` is `true`.

### Methods

#### toggleSpotlight()

Example:
```
RevealSpotlight.toggleSpotlight();
```

If the spotlight is on, it turns it off.
If the spotlight is off, it turns it on.

#### togglePresentationMode()

Example:
```
RevealSpotlight.togglePresentationMode();
```

If presentation mode is on, it turns it off and set the cursor to `normal`.
If presentation mode is off, it turns it on and set the cursor to the configuration item `presentingCursor`.
