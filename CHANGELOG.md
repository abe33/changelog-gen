<a name="v0.2.1"></a>
# v0.2.1 (2014-05-29)

## :bug: Bug Fixes

- Fix closing external repo hook not recognized ([97f4e284](https://github.com/abe33/changelog-gen/commit/97f4e28452cb0f013a3c4676a921eb2c148844ab))

<a name="v0.2.0"></a>
# v0.2.0 (2014-05-28)

## :sparkles: Features

- Implement CLI accepting a version as argument ([4ffc248e](https://github.com/abe33/changelog-gen/commit/4ffc248e16f22de82455e2be4de8b0aea0da3f77))  <br>Calling `changelog {TAG}` will allow to replace the normally
  `undefined` tag in the generated markdown by the value of
  `{TAG}`.
- Add one letter aliases for all cli options ([be7ab24d](https://github.com/abe33/changelog-gen/commit/be7ab24df7a8a51b2bc37481ec7a16cdb25e8073))
- Add angular configuration and `--angular` cli option ([520eebb2](https://github.com/abe33/changelog-gen/commit/520eebb263f347775db4318d3ef5de5a49d19113))  <br>When passing `—-angular` to the cli, the Angular configuration
  is automatically selected.
  The `angular.cson` file contains a configuration that mimics the
  current Angular changelog script.

## :bug: Bug Fixes

- Fix sections randomized order ([12176d8b](https://github.com/abe33/changelog-gen/commit/12176d8b5fa8476e49f110ebd726a2ca6c4a53db))
- Fix `undefined` appearing after a commit link ([879d0604](https://github.com/abe33/changelog-gen/commit/879d0604139cf5fb40c4c0278a65bdd3ad0540f5))
- Fix config paths reversed order ([2b3be1e2](https://github.com/abe33/changelog-gen/commit/2b3be1e2fa26e0ef5a490fa0e5de63a8c6aa707f))
