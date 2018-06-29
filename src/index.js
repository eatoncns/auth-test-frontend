require('./index.html');
require('bootstrap');
require('./app.scss');
const auth0 = require('auth0-js');

const Elm = require('./Main.elm');

const webAuth = new auth0.WebAuth({
  domain: 'meiertech.eu.auth0.com',
  clientID: 'mrIo511PuwoUHJlU61CaL9ey47TIxDw6',
  scope: 'openid profile email',
  responseType: 'id_token',
  redirectUri: 'http://localhost:3000',
});
const storedProfile = localStorage.getItem('profile');
const storedToken = localStorage.getItem('token');
const authData = storedProfile && storedToken
  ? { profile: JSON.parse(storedProfile), token: storedToken }
  : null;
const app = Elm.Main.fullscreen(authData);

app.ports.auth0authorize.subscribe(() => {
  webAuth.authorize();
});

app.ports.auth0logout.subscribe(() => {
  localStorage.removeItem('profile');
  localStorage.removeItem('token');
});

webAuth.parseHash({ hash: window.location.hash }, (parseError, authResult) => {
  if (parseError) {
    console.error(parseError);
  }
  if (authResult) {
    const token = authResult.idToken;
    const { email, email_verified } = authResult.idTokenPayload;
    const profile = { email, email_verified };
    const result = {
      err: null,
      ok: {
        profile,
        token,
      },
    };
    localStorage.setItem('profile', JSON.stringify(profile));
    localStorage.setItem('token', token);
    app.ports.auth0authResult.send(result);
    window.location.hash = '';
  }
});
