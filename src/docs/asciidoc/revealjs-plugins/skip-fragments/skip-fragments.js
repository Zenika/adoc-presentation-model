// Press V to View all fragments in current slide
// Press C to hide (Conceal) all fragments in current slide
const SkipFragments = (function (Reveal) {

    function showAll() {
        let {h, v} = Reveal.getIndices();
        Reveal.slide(h, v, +Infinity);
    }
    function hideAll() {
        let {h, v} = Reveal.getIndices();
        Reveal.slide(h, v, -1);
    }

    function installKeyBindings() {
        const config = Reveal.getConfig();
        if (!config.keyboard) {
            return;
        }
        const shortcut = {
            view: config.skipFragmentsShowShortcut || 'V',
            hide: config.skipFragmentsHideShortcut || 'C'
        };
        const keyboard = config.keyboard === true ? {} : config.keyboard;
        keyboard[shortcut.view.toUpperCase().charCodeAt(0)] = showAll;
        keyboard[shortcut.hide.toUpperCase().charCodeAt(0)] = hideAll;

        Reveal.registerKeyboardShortcut(shortcut.view, 'View slide fragments');
        Reveal.registerKeyboardShortcut(shortcut.hide, 'Hide slide fragments');
        Reveal.configure({
            keyboard: keyboard
        });
    }

    function install() {
        // Nope. You are not alone in this universe and there are some common rules :)
        // installKeyBindings();
    }

    install();

    return {
        showAll: showAll,
        hideAll: hideAll
    };

})(Reveal);