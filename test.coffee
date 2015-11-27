# copyright (c) 2015 Jess Austin <jess.austin@gmail.com>
# released under MIT License

request = require 'co-request'

require('tape') 'Koa-Signed-URL Test', require('co-tape') (tape) ->
  body = 'This is a test.'
  port = 2999

  app = require('koa')()
  signedUrl = require('./koa-signed-url') 'secret'
  app.use signedUrl
  app.use (next) ->
    @body = body
    yield next
  server = require 'http'
    .createServer app.callback()
    .listen port

  url = "http://localhost:#{port}/"
  pathParts = ['', 'path', '/subpath/', 'leaf', '?q=query', '&more=queries']
  tape.plan 5 * pathParts.length

  for part in pathParts
    url += part

    sig = signedUrl.sign url
    resp = yield request sig
    tape.equal resp.statusCode, 200, 'Should verify correct signature.'
    tape.equal resp.body, body, 'Should serve correct body.'
    resp = yield request sig + 'x'
    tape.equal resp.statusCode, 404, 'Should reject expanded signature.'
    resp = yield request sig[...-3]
    tape.equal resp.statusCode, 404, 'Should reject truncated signature.'
    resp = yield request sig + '&yet=another_query'
    tape.equal resp.statusCode, 404, 'Should reject non-canonical URL.'

  server.close()
