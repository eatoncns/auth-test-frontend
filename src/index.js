require('./index.html');
require('./style.css');
require('auth0-js');

const Elm = require('./Main.elm');

const mountNode = document.getElementById('main');
Elm.Main.embed(mountNode);
