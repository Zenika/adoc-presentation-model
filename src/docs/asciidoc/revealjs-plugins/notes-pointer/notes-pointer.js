/**
 * Handles opening of and synchronization with the reveal.js
 * notes window.
 *
 * Handshake process:
 * 1. This window posts 'connect' to notes window
 *    - Includes URL of presentation to show
 * 2. Notes window responds with 'connected' when it is available
 * 3. This window proceeds to send the current presentation state
 *    to the notes window
 */
var RevealNotes = (function() {
    var config = Reveal.getConfig();
    var options = config.notes_pointer || {};
    var pointer_options = options.pointer || {};
    var notes_options = options.notes || {};

    var notesPopup = null;

    function addKeyBinding(key, keyCode, defaultKey, description, binding) {
        if (key === undefined && keyCode === undefined) {
            key = defaultKey;
        }

        if (keyCode === undefined) {
            keyCode = key.toUpperCase().charCodeAt(0);
        } else if (key === undefined) {
            key = String.fromCharCode(keyCode);
        }

        Reveal.addKeyBinding({keyCode: keyCode, key: key, description: description}, binding);
    }


    function openNotes( notesFilePath ) {

        if (notesPopup && !notesPopup.closed) {
            notesPopup.focus();
            return;
        }

        if( !notesFilePath ) {
            var jsFileLocation = document.querySelector('script[src$="notes-pointer.js"]').src;  // this js file path
            jsFileLocation = jsFileLocation.replace(/notes-pointer\.js(\?.*)?$/, '');   // the js folder path
            notesFilePath = jsFileLocation + 'notes.html';
        }

        notesPopup = window.open( notesFilePath, 'reveal.js - Notes', 'width=1100,height=700' );

        if( !notesPopup ) {
            alert( 'Speaker view popup failed to open. Please make sure popups are allowed and reopen the speaker view.' );
            return;
        }

        /**
         * Connect to the notes window through a postmessage handshake.
         * Using postmessage enables us to work in situations where the
         * origins differ, such as a presentation being opened from the
         * file system.
         */
        function connect() {
            // Keep trying to connect until we get a 'connected' message back
            var connectInterval = setInterval( function() {
                notesPopup.postMessage( JSON.stringify( {
                    namespace: 'reveal-notes',
                    type: 'connect',
                    url: window.location.protocol + '//' + window.location.host + window.location.pathname + window.location.search,
                    state: Reveal.getState()
                } ), '*' );
            }, 500 );

            window.addEventListener( 'message', function( event ) {
                var data = JSON.parse( event.data );
                if( data && data.namespace === 'reveal-notes' && data.type === 'connected' ) {
                    clearInterval( connectInterval );
                    onConnected();
                }
                if( data && data.namespace === 'reveal-notes' && data.type === 'call' ) {
                    callRevealApi( data.methodName, data.arguments, data.callId );
                }
            } );
        }

        /**
         * Calls the specified Reveal.js method with the provided argument
         * and then pushes the result to the notes frame.
         */
        function callRevealApi( methodName, methodArguments, callId ) {

            var result = Reveal[methodName].call( Reveal, methodArguments );
            notesPopup.postMessage( JSON.stringify( {
                namespace: 'reveal-notes',
                type: 'return',
                result: result,
                callId: callId
            } ), '*' );

        }

        /**
         * Posts the current slide data to the notes window
         */
        function post( event ) {

            var slideElement = Reveal.getCurrentSlide(),
                notesElement = slideElement.querySelector( 'aside.notes' ),
                fragmentElement = slideElement.querySelector( '.current-fragment' );

            var messageData = {
                namespace: 'reveal-notes',
                type: 'state',
                notes: '',
                markdown: false,
                whitespace: 'normal',
                state: Reveal.getState()
            };

            // Look for notes defined in a slide attribute
            if( slideElement.hasAttribute( 'data-notes' ) ) {
                messageData.notes = slideElement.getAttribute( 'data-notes' );
                messageData.whitespace = 'pre-wrap';
            }

            // Look for notes defined in a fragment
            if( fragmentElement ) {
                var fragmentNotes = fragmentElement.querySelector( 'aside.notes' );
                if( fragmentNotes ) {
                    notesElement = fragmentNotes;
                }
                else if( fragmentElement.hasAttribute( 'data-notes' ) ) {
                    messageData.notes = fragmentElement.getAttribute( 'data-notes' );
                    messageData.whitespace = 'pre-wrap';

                    // In case there are slide notes
                    notesElement = null;
                }
            }

            // Look for notes defined in an aside element
            if( notesElement ) {
                messageData.notes = notesElement.innerHTML;
                messageData.markdown = typeof notesElement.getAttribute( 'data-markdown' ) === 'string';
            }

            notesPopup.postMessage( JSON.stringify( messageData ), '*' );

        }


        /**
         * Called once we have established a connection to the notes
         * window.
         */
        function onConnected() {

            // Monitor events that trigger a change in state
            Reveal.addEventListener( 'slidechanged', post );
            Reveal.addEventListener( 'fragmentshown', post );
            Reveal.addEventListener( 'fragmenthidden', post );
            Reveal.addEventListener( 'overviewhidden', post );
            Reveal.addEventListener( 'overviewshown', post );
            Reveal.addEventListener( 'paused', post );
            Reveal.addEventListener( 'resumed', post );

            // Post the initial state
            post();

        }

        connect();

    }


    var RevealPointer = (function() {
        var isPointing = false;
        var callbackSet = false;
        var body = document.querySelector('body');
        var slides = document.querySelector('.slides');

        var s = pointer_options.size || 15;

        var pointer = document.createElement('div');
        pointer.style.position = 'absolute';
        pointer.style.width = s + 'px';
        pointer.style.height = s + 'px';
        pointer.style.marginLeft = '-' + Math.round(s / 2) + 'px';
        pointer.style.marginTop = '-' + Math.round(s / 2) + 'px';
        pointer.style.backgroundColor = pointer_options.color || 'rgba(255, 0, 0, 0.8)';
        pointer.style.borderRadius = '50%';
        pointer.style.zIndex = 20;
        pointer.style.display = 'none';
        slides.appendChild(pointer);  // a *slides* element, so position scales

        function trackMouse(e) {
            // compute x, y positions relative to slides element in unscaled coords
            var slidesRect = slides.getBoundingClientRect();
            var slides_left = slidesRect.left, slides_top = slidesRect.top;
            if (slides.style.zoom) {  // zoom is weird.
                slides_left *= slides.style.zoom;
                slides_top *= slides.style.zoom;
            }

            var scale = Reveal.getScale();
            var offsetX = (e.clientX - slides_left) / scale;
            var offsetY = (e.clientY - slides_top) / scale;

            point(offsetX, offsetY, true);
            postPointer(offsetX, offsetY, true);
        }

        function point(x, y, state) {
            if (state === true) {
                showPointer();
            } else if (state === false) {
                hidePointer();
            }

            // x, y are in *unscaled* coordinates
            pointer.style.left = x + 'px';
            pointer.style.top = y + 'px';
        }

        function postPointer(x, y, state) {
            if (notesPopup) {
                notesPopup.postMessage(JSON.stringify({
                    namespace: 'reveal-notes',
                    type: 'point',
                    x: x,
                    y: y,
                    state: state
                }), '*');
            } else if (Reveal.getConfig().postMessageEvents && window.parent !== window.self) {
                window.parent.postMessage(JSON.stringify({
                    namespace: 'reveal',
                    type: 'point',
                    x: x,
                    y: y,
                    state: state
                }), '*');
            }
        }

        function showPointer() {
            pointer.style.display = 'block';
        }

        function hidePointer() {
            pointer.style.display = 'none';
        }

        function pointerOn() {
            showPointer();
            body.style.cursor = 'none';
            if( !callbackSet ) {
                document.addEventListener('mousemove', trackMouse);
                callbackSet = true;
            }
            isPointing = true;
        }

        function pointerOff() {
            hidePointer();
            body.style.cursor = 'auto';
            if( callbackSet ) {
                document.removeEventListener('mousemove', trackMouse);
                callbackSet = false;
            }
            isPointing = false;
            postPointer(0, 0, false);
        }

        function togglePointer() {
            if (isPointing) {
                pointerOff();
            } else {
                pointerOn();
            }
        }

        addKeyBinding(pointer_options.key, pointer_options.keyCode, 'A',
                      'Toggle pointer', togglePointer);

        return {point: point, togglePointer: togglePointer};
    })();

    // add a Reveal.point API function, so postMessage can handle it
    Reveal.point = RevealPointer.point;

    // patch in Reveal.getSlidesAttributes, in dev branch but not in 3.7.0
    if( !Reveal.getSlidesAttributes ) {
        Reveal.getSlidesAttributes = function() {
            return Reveal.getSlides().map( function( slide ) {

                var attributes = {};
                for( var i = 0; i < slide.attributes.length; i++ ) {
                    var attribute = slide.attributes[ i ];
                    attributes[ attribute.name ] = attribute.value;
                }
                return attributes;

            } );

        }
    }


    if( !/receiver/i.test( window.location.search ) ) {

        // If the there's a 'notes' query set, open directly
        if( window.location.search.match( /(\?|\&)notes/gi ) !== null ) {
            openNotes();
        }

        // Open the notes when the 's' key is hit
        addKeyBinding(notes_options.key, notes_options.keyCode, 'S',
                      'Speaker notes view', function() { openNotes(); });
    }

    return { open: openNotes, RevealPointer: RevealPointer };
})();