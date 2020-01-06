# Reveal - Skip fragments
A [reveal.js](https://github.com/hakimel/reveal.js/) plugin to
 skip fragment animations on a slide by pressing a shortcut key.

You have prepared your beautiful presentation and have taken
 great care in choosing how to step through all the fragments
 in each slide, but when you are presenting you may need to
 go a bit faster than anticipated and just skip to the end of
 all fragments.
 
This plugin is here just for that, by adding:
- a shortcut to show all fragments in current slide; 
- a shortcut to hide all fragments in current slide.

A little caveat: terms like "show" are used here as synonyms
 for "activate", so it just means that the fragment 
 "does its thing", which may actually mean being hidden 
 (e.g. `fade-out` fragments).

## Installation

Copy this repository into the plugins folder of your reveal.js presentation, ie ```plugin/skip-fragments```.

Add the plugin to the dependencies in your presentation, as below.

```javascript
Reveal.initialize({
	// ...
	dependencies: [
		// ...
		{ src: 'plugin/skip-fragments/skip-fragments.js' },
	]
});
```

## Usage

The simplest way to use the plugin requires no additional configuration: while you are presenting, just press:
- `V` to show (**v**iew) all fragments;
- `C` to hide (**c**onceal) all fragments.

### Configuration

You can customize the shortcuts with `skipFragmentsShowShortcut` and `skipFragmentsHideShortcut` 
 parameters of your configuration. 

```javascript
Reveal.initialize({
	// ...

	// Shortcut for showing all fragments 
	skipFragmentsShowShortcut: 'V',

	// Shortcut for hiding all fragments 
	skipFragmentsHideShortcut: 'C',
});
```

## API

### Javascript

The plugin API is accessible from the global ```SkipFragments``` object.

```javascript
// Programmatically show all fragments on current slide
SkipFragments.showAll();

// Programmatically hide all fragments on current slide
SkipFragments.hideAll();
```

## License

[MIT licensed](https://en.wikipedia.org/wiki/MIT_License).

Copyright (C) 2018 [Damiano Salvi](https://github.com/PiDayDev)