# koa-signed-url

[Koa][koa] middleware that sets a `404 Not Found` status when it can't verify
the signature on a URL. This module uses [keygrip][keygrip] for signing and
verifying, like the [cookies](https://www.npmjs.com/package/cookies) module
does. The exported middleware function has a `.sign()` function property for
generating signed URLs in the first place.  The idea is that a [Koa][koa]
application can generate signed URLs for distribution via e.g. email or SMS and
then verify signatures on those URLs when they are used, typically as
["capability" URLs][capability]. Because [HMAC signatures
](https://tools.ietf.org/html/rfc2104) are used, the [Koa][koa] application
just stores application-level symmetric keys, rather than a dynamic list of all
the URLs that have ever been generated. There are several factors to consider
when using this module to generate and verify secure URLs: see the [Security
Considerations](#security-considerations) section of this document.

[![Build Status][travis-img]][travis-url]
[![Coverage Status][cover-img]][cover-url]
[![Dependency Status][david-img]][david-url]
[![Dev Dependency Status][david-dev-img]][david-dev-url]

## Example

## Security Considerations



[Experts
](http://www.daemonology.net/blog/2009-06-11-cryptographic-right-answers.html)
[agree](https://gist.github.com/tqbf/be58d2d39690c3b366ad), random identifiers
should be 256 bits in size. Since this identifier is used in a URL, it should
be base64-encoded. The following produces the right sort of identifier:

```javascript
id = require('crypto').pseudoRandomBytes(32).toString('base64');
```

## Notice

**koa-signed-url** is by Jess Austin and is distributed under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

[koa]: http://koajs.com/
[keygrip]: https://www.npmjs.com/package/keygrip
[capability]: http://www.w3.org/TR/capability-urls/
[travis-img]: https://travis-ci.org/jessaustin/koa-signed-url.svg?branch=master
[travis-url]: https://travis-ci.org/jessaustin/koa-signed-url "Travis"
[cover-img]: https://coveralls.io/repos/jessaustin/koa-signed-url/badge.svg
[cover-url]: https://coveralls.io/github/jessaustin/koa-signed-url "Coveralls"
[david-img]: https://david-dm.org/jessaustin/koa-signed-url.svg
[david-url]: https://david-dm.org/jessaustin/koa-signed-url "David"
[david-dev-img]: https://david-dm.org/jessaustin/koa-signed-url/dev-status.svg
[david-dev-url]: https://david-dm.org/jessaustin/koa-signed-url#info=devDependencies
  "David for devDependencies"
