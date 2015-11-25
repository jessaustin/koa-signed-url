# koa-signed-url

[Koa][koa] middleware that yields a `404 Not Found` status when it can't verify
the signature on a <abbr title='Uniform Resource Locator'>URL</abbr>. This
module uses [keygrip][keygrip] for signing and verifying, like the [cookies](
https://www.npmjs.com/package/cookies) module does. The exported middleware
function has a `.sign()` function property for signing URLs in the first place.
The idea is that a [Koa][koa] application can generate signed URLs for
distribution via e.g. email or <abbr title='Short Message Service'>SMS</abbr>
and then verify signatures on those URLs when they are used, typically as
["capability" URLs](http://www.w3.org/TR/capability-urls/). Because [HMAC
signatures](https://tools.ietf.org/html/rfc2104) are used, the [Koa][koa]
application just stores application-level symmetric keys, rather than a dynamic
list of all the URLs that have ever been generated. There are several factors
to consider when using this module to generate and verify secure URLs: see the
[Security Considerations](#security-considerations) section of this document.

[![Build Status][travis-img]][travis-url]
[![Coverage Status][cover-img]][cover-url]
[![Dependency Status][david-img]][david-url]
[![Dev Dependency Status][david-dev-img]][david-dev-url]

## Example

## Security Considerations

[koa]: http://koajs.com/
[keygrip]: https://www.npmjs.com/package/keygrip
[travis-img]: https://travis-ci.org/jessaustin/koa-signed-url.svg?branch=master
[travis-url]: https://travis-ci.org/jessaustin/koa-signed-url "Travis"
[cover-img]: https://coveralls.io/repos/jessaustin/koa-signed-url/badge.svg?branch=master&service=github
[cover-url]: https://coveralls.io/github/jessaustin/koa-signed-url?branch=master "Coveralls"
[david-img]: https://david-dm.org/jessaustin/koa-signed-url.svg
[david-url]: https://david-dm.org/jessaustin/koa-signed-url "David"
[david-dev-img]: https://david-dm.org/jessaustin/koa-signed-url/dev-status.svg
[david-dev-url]: https://david-dm.org/jessaustin/koa-signed-url#info=devDependencies "David for devDependencies"
