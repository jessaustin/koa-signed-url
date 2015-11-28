# koa-signed-url

[Koa][koa] middleware that sets a `404 Not Found` status when it can't verify
the signature on a *signed URL*. Signed URLs are much like [signed
cookies](https://code.djangoproject.com/wiki/Signing#Justification): data that
is sent to the user for eventual return to the server, where the signature is
verified to confirm that the data has not been modified. Signed cookies work
well in the web browser, while signed URLs are necessary when data must be
verifiably communicated in other contexts, such as through email. This module
uses [keygrip][keygrip] for signing and verifying, like the [cookies
](https://www.npmjs.com/package/cookies) module does.

The exported middleware function has a `.sign()` function property for
generating signed URLs in the first place.  The idea is that a [Koa][koa]
application can generate signed URLs for e.g. a password reset facility,
distribe them via e.g. email or SMS, and then verify signatures on those URLs
when they are used, essentially as ["capability" URLs][capability]. Because
[HMAC signatures](https://tools.ietf.org/html/rfc2104) are used, the [Koa][koa]
application just stores application-level symmetric keys, rather than a dynamic
list of all URLs that have ever been generated. There are several factors to
consider when using this module to generate and verify secure URLs: see the
[Security Considerations](#security-considerations) section of this document.

[![Build Status][travis-img]][travis-url]
[![Coverage Status][cover-img]][cover-url]
[![Dependency Status][david-img]][david-url]
[![Dev Dependency Status][david-dev-img]][david-dev-url]

## Example

## Security Considerations

### Short-Lived URLs

As mentioned in the [W3C document][capability], it must be assumed that all
URLs will eventually be exposed, not least because their use in browsers is
very difficult to conceal. That document describes detection and handling of
compromised capability URLs, but that seems pointless for the uses we envision
for signed URLs. The best policy is simply for such URLs to be extremely
short-lived. Nothing in the current version of this module ensures that, but
there are several steps one could take, depending on the situation.

First, it seems wise to append an `expires=<timestamp>` query parameter to the
URL *before* signing it. (The timestamp would be a date in the very near
future.) Signature verification ensures that the timestamp may not be changed,
and a simple timestamp is easy to vary in order to enforce desired policies. In
addition, timestamps act as anti-replay-attack "nonces".

Second, one could keep a dynamic "CRL"-style list of used URLs, and thus reject
URLs that have already been accessed. In order to avoid having to track used
URLs over longer periods, this technique would be combined with the previous
one. Or it might be possible to control multiple uses of URLs in the underlying
resources to which they refer.

### *Try* to Keep URLs Secret, Anyway

As we envision signed URLs being used, there's no reason to ever include them
in a webpage. If a client can follow a link it can also save a session cookie,
which obviates signed URLs entirely. URLs are signed so that they may be
communicated without using web clients. That does not guarantee that they'll
never be seen by browsers, or passed on from browsers to other servers. As the
[W3C document][capability] suggests, [`robots.txt`](http://www.robotstxt.org/)
and `rel=noreferrer` should be used to protect signed URLs once they reach the
web browser. 

### "Canonicalization"

It is important to avoid what could be called a "canonicalization"
vulnerability. Such a vulnerability would allow an attacker to e.g. append an
additional `&user=alice` query parameter to the end of a signed URL. This
module will reject such "extended" URLs automatically, but that could be
defeated if implementors attempt to be too clever in routing or authorizing
*before* signature verification takes place. For example the following code is
very bad:
```javascript```
/* VERY BAD INSECURE CODE DO NOT USE!!! */
app.use(function *(next) {
  if (this.query.logged_in === 'true') {
    this.session.logged_in = true;
  }
  yield(next);
});
app.use(koaSignedUrl(keys)); /* too late!!! */
```
The solution to this problem is to completely determine the URL (protocol,
host, port, path, *and* query) *before* signing it, and to verify the URL
*before* doing anything with any component of it. One should `app.use()` the
middleware provided by this module *as soon as possible*.

### SHA256 Please

This module depends on version 2 of [keygrip][keygrip]. That version [wisely
](http://csrc.nist.gov/publications/drafts/800-131A/sp800-131a_r1_draft.pdf)
upgrades the default hash algorithm to SHA-256. **Do not** pass in a Keygrip
object with the hash algorithm downgraded to e.g. SHA-1 or MD5.

### Unique Identifiers

Depending on the situation, a simple url like
`https://example.com/reset-password?user=alice&timestamp=1448688469&sig=fh0B70oHoT0tjP9Ip=` may
suffice. In other contexts, it may be necessary to generate a unique random
identifier to include in a signed URL. This could be if the URL is of a
transactional nature: each transaction that requires user action should have
its own URL. [Experts
](http://www.daemonology.net/blog/2009-06-11-cryptographic-right-answers.html)
[agree](https://gist.github.com/tqbf/be58d2d39690c3b366ad), random identifiers
should be 256 bits in size. Since this identifier is used in a URL, it should
be base64-encoded. The following produces the right sort of identifier:
```javascript
id = require('crypto').pseudoRandomBytes(32).toString('base64');
url = koaSignedUrl.sign('https://example.com/view-order?id=' + id);
```

### Please Suggest Additional Security Considerations

This is certainly not an exhaustive list of security considerations. Please let
the module maintainer know of anything else that should be included. 

## Thanks!

**koa-signed-url** is by Jess Austin and is distributed under the terms of the
[MIT License](http://opensource.org/licenses/MIT). Any and all potential
contributions of issues or PRs are welcome!

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
