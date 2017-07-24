<a name="v1.0.1"></a>
# v1.0.1 (2017-07-24)

## :bug: Bug Fixes

- Fix issue with % in string on new node versions ([2f94e996](https://github.com/abe33/changelog-gen/commit/2f94e9966414ad6567ab8742d07e3fb2ae81ab95))

<a name="v1.0.0"></a>
# v1.0.0 (2017-02-23)

:fire: :package: oniguruma ([a9b21fa9](https://github.com/abe33/changelog-gen/commit/a9b21fa91fa2f0b315b1a7a16a10999fc5d2e751))

It now only relies on native JS Regular Expressions.

## :bug: Bug Fixes

- Fix bad arguments type in error function ([efad9ef0](https://github.com/abe33/changelog-gen/commit/efad9ef0e28e29bb2c73af093b631365c30a3c79))

<a name="v0.8.1"></a>
# v0.8.1 (2016-01-03)

## :bug: Bug Fixes

- Fix bad arguments type in error function ([887780f0](https://github.com/abe33/changelog-gen/commit/887780f0fe390d223fcadb1858616684b6e5efcc))

<a name="v0.8.0"></a>
# v0.8.0 (2015-10-12)

## :bug: Bug Fixes

- Fix missing promise failure trap ([edaa8be5](https://github.com/abe33/changelog-gen/commit/edaa8be5052b0df16fa3d629c70eedb7b5af0c99), [#9](https://github.com/abe33/changelog-gen/issues/9))

## :arrow_up: Dependencies Update

- Bump cson to version 3 ([ea1a5df3](https://github.com/abe33/changelog-gen/commit/ea1a5df329ed99dab3f43d95e5c6b7434fa5883b))

<a name="v0.7.0"></a>
# v0.7.0 (2015-09-21)

## :bug: Bug Fixes

- Fix typo in README ([a7a92179](https://github.com/abe33/changelog-gen/commit/a7a921795f145db4b667d78b8a02f84d18420454))

## :arrow_up: Dependencies Update

- Bump oniguruma to version 5.x ([9f824789](https://github.com/abe33/changelog-gen/commit/9f8247894550892d5269f32f4a9b904ae9fa6572))

<a name="v0.6.2"></a>
# v0.6.2 (2015-02-16)

## :bug: Bug Fixes

- Fix broken CSON loading ([7688d90d](https://github.com/abe33/changelog-gen/commit/7688d90d883bf46f0ecdc85f7818b8190bc3b3a0))

<a name="v0.6.1"></a>
# v0.6.1 (2015-02-10)

## :arrow_up: Dependencies Update

- Update most dependencies

<a name="v0.6.0"></a>
# v0.6.0 (2015-02-10)

## :sparkles: Features

- Add a new default section for dependencies updates ([e0f15176](https://github.com/abe33/changelog-gen/commit/e0f15176a26aafd4865cb017c1e98cbd3f989229))

<a name="v0.5.0"></a>
# v0.5.0 (2014-11-24)

## :sparkles: Features

- Add match for :warning: as breaking change indicator ([6cbcbf31](https://github.com/abe33/changelog-gen/commit/6cbcbf31ff0132b3e3873c3246b04da026feb8ff))  <br>Small change to save some typing on breaking changes, allows using
either `

## :bug: Bug Fixes

- Fix multiple breaking changes appearing on a single line ([c0979a62](https://github.com/abe33/changelog-gen/commit/c0979a624e998fdcb10fbd05148d7ff8d6d6fefd))
- Fix log output corrupting markdown ([0c64cf5c](https://github.com/abe33/changelog-gen/commit/0c64cf5cd08a1875205c31784b41dc6476920416))
- Fix `include_body` should not include breaking changes ([484c24f0](https://github.com/abe33/changelog-gen/commit/484c24f0ab1b3435f8d6df765e8954f90f975d60))

<a name="v0.4.0"></a>
# v0.4.0 (2014-05-31)

## :sparkles: Features

- Implement reading dates from tag when tag is available ([eb21ca85](https://github.com/abe33/changelog-gen/commit/eb21ca853f9357ef0b55b4d6e7516f1a6e1c1238))

<a name="v0.3.0"></a>
# v0.3.0 (2014-05-30)

## :sparkles: Features

- Change default config to better handle fix commits ([54c0f26](https://github.com/abe33/changelog-gen/commit/54c0f2621ff95b67a2bf6964b565119d956a3272))
  <br>It will now match both commits starting with `:bug:` and commits starting with `Fix`.

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
