//
// CHALKBOARD PLUGIN https://github.com/rajgoel/reveal.js-plugins/tree/master/chalkboard
//
chalkboard: { 
	readOnly: false, // Configuation option allowing to prevent changes to existing drawings.
	transition: 800, // Gives the duration (in milliseconds) of the transition for a slide change, so that the notes canvas is drawn after the transition is completed.
	theme: "chalkboard", // Can be set to either "chalkboard" or "whiteboard".
	color: [ 'rgba(150,150,150,1)', 'rgba(255,255,255,0.5)' ], // The first value gives the pen color, the second value gives the color of the chalk.
	background: [ 'rgba(141,191,68,.1)' , 'revealjs-plugins/chalkboard/img/blackboard.png' ] // The first value expects a (semi-)transparent color which is used to provide visual feedback that the notes canvas is enabled, the second value expects a filename to a background image for the chalkboard.
},
keyboard: {
	//List of codes here : https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/keyCode
	    67: function() { RevealChalkboard.toggleNotesCanvas() },	// toggle notes canvas when 'c' is pressed
	    66: function() { RevealChalkboard.toggleChalkboard() },	// toggle chalkboard when 'b' is pressed
	    46: function() { RevealChalkboard.clear() },	// clear chalkboard when 'DEL' is pressed
	     8: function() { RevealChalkboard.reset() },	// reset chalkboard data on current slide when 'BACKSPACE' is pressed
		68: function() { RevealChalkboard.download() },	// download recorded chalkboard drawing when 'd' is pressed
		72: function() { window.open("../index.html","_self") } // 'H' to index page
},
//
// MENU PLUGIN https://github.com/denehyg/reveal.js-menu
//
menu: {
	numbers: true, // Add slide numbers to the titles in the slide list.
	titleSelector: 'h1, h2, div.title, caption.title, #toctitle', // Specifies which slide elements will be used for generating the slide titles in the menu. 
	transitions: true, // Specifies if the transitions menu panel will be shown.
	openButton: true, // Adds a menu button to the slides to open the menu panel.
	openSlideNumber: false, // If 'true' allows the slide number in the presentation to open the menu panel
	loadIcons: true, // By default the menu will load it's own font-awesome library icons
	sticky: true, // If 'true', the sticky option will leave the menu open until it is explicitly closed
	custom: [
		{ title: 'Keys', icon: '<i class="fa fa-keyboard">', content: `
		<ul class="slide-menu-items">
		<li class="slide-menu-item">
			<h3>Core</h3>
			<p>? : Show core keys</p>
		</li>
		<li class="slide-menu-item">
			<h3>Zoom</h3>
			<p>ALT+CLICK : Zoom-in</p>
		</li>
		<li class="slide-menu-item">
			<h3>Chalkboard</h3>
			<p>C : Notes canvas on/off</p>
			<p>B : Chalkboard on/off</p>
			<p>DEL : Clear canvas/chalkboard</p>
			<p>BASCKSPACE : Reset chalkboard data on current slide</p>
			<p>D : Download drawing as JSON</p>
		</li>
		<li class="slide-menu-item">
			<h3>Menu</h3>
			<p>M : Open menu</p>
			<p>H or LEFT : Next left panel</p>
			<p>L or RIGHT : Next right panel</p>
			<p>K or UP : Up</p>
			<p>J or DOWN : Down</p>
			<p>U or PAGE UP : Page up</p>
			<p>D or PAGE DOWN : Page down</p>
			<p>HOME : Top</p>
			<p>END : Bottom</p>
			<p>SPACE or RETURN : Selection</p>
			<p>ESC : Close menu</p>
		</li>
		<li class="slide-menu-item">
			<h3>Custom</h3>
			<p>H : ../index.html</p>
		</li></ul>` }
	],
  	themes: // Specifies the themes that will be available in the themes menu panel. Set to 'true' to show the themes menu panel with the default themes list. 
	  	   [ { name: 'dark', theme: 'themes/css/reveal-zenika-dark.css' },
			 { name: 'light', theme: 'themes/css/reveal-zenika-light.css' },
			 { name: 'algeria-timgad', theme: 'themes/css/reveal-zenika-algeria-timgad.css' },
			 { name: 'argentina-perito-moreno', theme: 'themes/css/reveal-zenika-mountain.css' },
			 { name: 'bali-river', theme: 'themes/css/reveal-zenika-bali.css' },
			 { name: 'brest-sea', theme: 'themes/css/reveal-zenika-brest-sea.css' },
			 { name: 'cambodia-relax', theme: 'themes/css/reveal-zenika-cambodia-relax.css' },
			 { name: 'greece-architecture', theme: 'themes/css/reveal-zenika-grece-architecture.css' },
			 { name: 'guadeloupe-pool', theme: 'themes/css/reveal-zenika-guadeloupe.css' },
			 { name: 'iceland-blocks', theme: 'themes/css/reveal-zenika-iceland-blocks.css' },
			 { name: 'iceland-waterfall-shirt', theme: 'themes/css/reveal-zenika-iceland-waterfall-shirt.css' },
			 { name: 'iceland-waterfall-zenikanard', theme: 'themes/css/reveal-zenika-iceland-waterfall-zenikanard.css' },
			 { name: 'iceland-white', theme: 'themes/css/reveal-zenika-iceland-white.css' },
			 { name: 'japan-roe', theme: 'themes/css/reveal-zenika-japan-biche.css' },
			 { name: 'japan-fujisan', theme: 'themes/css/reveal-zenika-japan-fujisan.css' },
			 { name: 'japan-garden', theme: 'themes/css/reveal-zenika-japan-garden.css' },
			 { name: 'mauricia-bridge', theme: 'themes/css/reveal-zenika-mauricia-bridge.css' },
			 { name: 'ocean-boats', theme: 'themes/css/reveal-zenika-ocean-boats.css' },
			 { name: 'patagonia', theme: 'themes/css/reveal-zenika-patagonia.css' },
			 { name: 'pilat-back', theme: 'themes/css/reveal-zenika-pilat-back.css' },
			 { name: 'pilat-black-bag', theme: 'themes/css/reveal-zenika-pilat-black-bag.css' },
			 { name: 'pompei', theme: 'themes/css/reveal-zenika-pompei.css' },
			 { name: 'rock-climbing', theme: 'themes/css/reveal-zenika-escalade.css' },
			 { name: 'thailand-phang-nga-back', theme: 'themes/css/reveal-zenika-thailand-cheow-lan-back.css' },
			 { name: 'thailand-phang-nga-shirt', theme: 'themes/css/reveal-zenika-thailand-cheow-lan-shirt.css' },
			 { name: 'usa-city', theme: 'themes/css/reveal-zenika-usa-city.css' },
			 { name: 'vietnam-flag', theme: 'themes/css/reveal-zenika-vietnam-flag.css' },
			 { name: 'cambodia-sunset', theme: 'themes/css/reveal-zenika-cambodia-sunset.css' },
			 { name: 'greece-beach', theme: 'themes/css/reveal-zenika-grece-beach.css' },
			 { name: 'japan-roe-dark', theme: 'themes/css/reveal-zenika-japan-biche-dark.css' },
			 { name: 'japan-shibuya', theme: 'themes/css/reveal-zenika-tokyo-shibuya.css' },
			 { name: 'japan-street-old', theme: 'themes/css/reveal-zenika-japan-street-old.css' },
			 { name: 'japan-table', theme: 'themes/css/reveal-zenika-japan-table.css' },
			 { name: 'mauricia-hotel', theme: 'themes/css/reveal-zenika-mauricia-hotel.css' },
			 { name: 'music-beatles', theme: 'themes/css/reveal-zenika-beatles.css' },
			 { name: 'scuba-diving', theme: 'themes/css/reveal-zenika-scuba-diving.css' }]
}