{ src: '../../framework/revealjs-plugins/menu/menu.js', async: true },
{ src: '../../framework/revealjs-plugins/chalkboard/chalkboard.js', async: true },
{ src: '../../framework/revealjs-plugins/title-footer/title-footer.js', callback: function() { title_footer.initialize(); } },//not async because it may then not appear
{ src: '../../framework/revealjs-plugins/notes-pointer/notes-pointer.js', async: true },
{ src: '../../framework/revealjs-plugins/spotlight/spotlight.js' }, // does not work with current version of reveal.js
{ src: '../../framework/revealjs-plugins/skip-fragments/skip-fragments.js' }
