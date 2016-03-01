# koa-signed-url

[![NPM][npmjs-img]][npmjs-url]
[![Build Status][travis-img]][travis-url]
[![Coverage Status][cover-img]][cover-url]
[![Dependency Status][david-img]][david-url]
[![Dev Dependency Status][david-dev-img]][david-dev-url]

[Koa][koa] middleware that sets a `404 Not Found` status when it can't verify
the signature on a *signed URL*. Signed URLs are much like [signed
cookies](https://code.djangoproject.com/wiki/Signing#Justification): data that
is sent to the user for eventual return to the server, where the signature is
verified to confirm that the data has not been modified. Signed cookies work
well in the web browser, while signed URLs are necessary when data must be
verifiably communicated in other situations, such as through email. This module
uses [keygrip][keygrip] for signing and verifying, like the [cookies
](https://www.npmjs.com/package/cookies) module does.

The exported middleware function has a [`.sign()`][sign] function property for
generating signed URLs in the first place.  The idea is that a [Koa][koa]
application can generate signed URLs for e.g. a password reset facility,
distribute them via e.g. email or SMS, and then verify signatures on those URLs
when they are used, essentially as ["capability" URLs ][capability]. Because
[HMAC signatures](https://tools.ietf.org/html/rfc2104) are used, the [Koa][koa]
application just stores application-level symmetric keys, rather than a dynamic
list of all URLs that have ever been generated.  There are several factors to
consider when using this module to generate and verify secure URLs: see the
[Security Considerations](#security-considerations) section of this document.

## Example

Suppose we have an application that allows users to share uploaded documents
with their friends. The part of the application that generates "share"
notifications could look like this:
```javascript
var signed = require('koa-signed-url')(keys);
app.use(route.post('/document/:id/', function *(id) {
  yield sendEmail(signed.sign('https://example.com/shared-doc?id=' + id));
  this.status = 204
}));
```
Then the part of the application that serves the shared documents could be
something like this:
```javascript
app.use(signed);
app.use(function *() {
  this.body = yield getDocument(this.query.id);
});
```

## API

### koaSignedUrl(keys, [sigId], [expId]) ⟶ { [Function] sign: [Function] }

`keys` is either a single character string key (which should be at least 32
characters in length), or an array of such keys, or a `Keygrip` object. `sigId`
is optional, defaults to `"sig"`, and is the name of the query parameter used
to hold the URL signature. Likewise, `expId` is optional, defaults to `"exp"`,
and is the name of the query parameter used to hold the datestamp when the URL
signature expires.

The returned function is usable as [Koa][koa] middleware. It will attempt to
verify the URL signature on all requests. If it can verify the signature, it
will simply yield to the next middleware. If it cannot, it will set
`this.status = 404` and end request processing. Those requests that also
include an expiry timestamp (i.e. the query parameter name matches `expId`)
will be rejected, if that time has already passed. This middleware function has
a property `sign`, which is another function:

### sign (url, [duration])⟶ url

The `url` passed to this function is returned with a signature parameter
appended to the query string. If a non-zero `duration` is passed, an expiry
timestamp will be appended before signing, so that the expiry will also be
verified by the signature. `duration` is measured in milliseconds.

## Security Considerations

### Short-Lived URLs

As mentioned in the [W3C document][capability], it must be assumed that all
URLs will eventually be exposed, not least because their use in browsers is
very difficult to conceal. That document describes detection and handling of
compromised capability URLs, but that seems pointless for the uses we envision
for signed URLs. The best policy is simply for such URLs to be extremely
short-lived. There are several steps one could take to achieve this goal,
depending on the situation.

First, this module will generate an expiry timestamp query parameter whenever a
`duration` is passed to the [`.sign()`][sign] function. The middleware will
check that the timestamp is still in the future, when it's present in a signed
URL. Signature verification ensures that the timestamp may not be changed or
removed, and a simple `duration` is easy to vary in order to enforce desired
policies. In addition, timestamps act as anti-replay-attack "nonces".

Second, one could keep a dynamic "CRL"-style list of used URLs, and thus reject
URLs that have already been accessed. (In some cases, a hash, a set, or even a
[Bloom filter](//en.wikipedia.org/wiki/Bloom_filter) could be a more suitable
data stucture than a simple list.) In order to avoid having to track used URLs
over longer periods, this technique would be combined with the previous one. Or
it might be possible to control multiple uses of URLs in the underlying
resources to which they refer.

### *Try* to Keep URLs Secret, Anyway

As we envision signed URLs being used, there's no reason to ever include them
in a webpage. If a client can follow a link it can also save a session cookie,
which obviates signed URLs entirely. URLs are signed so that they may be
communicated without using web clients. That does not guarantee that they'll
never be seen by browsers, or passed on from browsers to other servers. As the
[W3C document][capability] suggests, [`robots.txt`](http://www.robotstxt.org/),
user-input data sanitization, and `rel=noreferrer` should be used to protect
signed URLs once they reach the web browser.

### "Canonicalization"

It is important to avoid what could be called a "canonicalization"
vulnerability. Such a vulnerability would allow an attacker to e.g. append an
additional `&user=alice` query parameter to the end of a signed URL. This
module will reject such "extended" URLs automatically, but that could be
defeated if implementors attempt to be too clever in routing or authorizing
*before* signature verification takes place. For example the following code is
very bad:
```javascript
/* VERY BAD INSECURE CODE DO NOT USE!!! */
app.use(function *(next) {
  if (this.query.logged_in === 'true') {
    this.session.logged_in = true;
  }
  yield next;
});
app.use(signed);    /* too late!!! */
```
The solution to this problem is to completely determine the URL (protocol,
host, port, path, *and* query) *before* signing it, and to verify the URL
*before* doing anything with any component of it. One should `app.use()` the
middleware provided by this module as soon as possible. No sooner than that,
however: the middleware will reject all URLs without signatures, and most of
your URLs don't need to be signed. This means either that you'll handle URLs
that need to be signed last, or you'll need some sort of strange nested `yield`
hack. [This limitation is not ideal, so suggestions for improvement are
welcome. Any suggestion that the module should ever accept unsigned (rather
than signed with an invalid signature) URLs is right out, however, since that
would introduce dangerous failure modes.]

### SHA-256 Please

This module depends on version 2 of [keygrip][keygrip]. That version [wisely
](http://csrc.nist.gov/publications/drafts/800-131A/sp800-131a_r1_draft.pdf)
upgrades the default hash algorithm to SHA-256. **Do not** pass in a `Keygrip`
object with the hash algorithm downgraded to e.g. SHA-1 or MD5.

### Unique Identifiers

Depending on the situation, a simple url like
```
https://example.com/reset-passwd?user=alice&exp=1448688469&sig=fh0B70oHoT0tjP9Ip+whuktdr8EcUjJVsJetJLUVJAE=
```
may suffice. In other contexts, it may be necessary to generate a unique random
identifier to include in a signed URL. This could be if the URL is of a
transactional nature: each transaction that requires user action would have its
own URL. [Experts
](http://www.daemonology.net/blog/2009-06-11-cryptographic-right-answers.html)
[agree](https://gist.github.com/tqbf/be58d2d39690c3b366ad), random identifiers
should be 256 bits in size. Since this identifier is used in a URL, it should
be base64-encoded. The following produces the right sort of identifier:
```javascript
id = require('crypto').pseudoRandomBytes(32).toString('base64');
url = signed.sign('https://example.com/view-order?id=' + id);
```

### Please Suggest Additional Security Considerations

This is certainly not an exhaustive list of security considerations. Please let
the module maintainer know of anything else that should be included.

## Thanks!

**koa-signed-url** is by Jess Austin and is distributed under the terms of the
[MIT License](http://opensource.org/licenses/MIT). Any and all potential
contributions of issues and pull requests are welcome!

[sign]: #sign-url-duration-url
[koa]: http://koajs.com/
[keygrip]: https://www.npmjs.com/package/keygrip
[capability]: http://www.w3.org/TR/capability-urls/
[npmjs-url]: https://www.npmjs.org/package/koa-signed-url "npm Registry"
[npmjs-img]: https://badge.fury.io/js/koa-signed-url.svg
[travis-img]: https://travis-ci.org/jessaustin/koa-signed-url.svg?branch=master
[travis-url]: https://travis-ci.org/jessaustin/koa-signed-url "Travis"
[cover-img]: https://coveralls.io/repos/jessaustin/koa-signed-url/badge.svg
[cover-url]: https://coveralls.io/github/jessaustin/koa-signed-url "Coveralls"
[david-img]: https://david-dm.org/jessaustin/koa-signed-url.svg
[david-url]: https://david-dm.org/jessaustin/koa-signed-url "David"
[david-dev-img]: https://david-dm.org/jessaustin/koa-signed-url/dev-status.svg
[david-dev-url]: https://david-dm.org/jessaustin/koa-signed-url#info=devDependencies
  "David for devDependencies"
