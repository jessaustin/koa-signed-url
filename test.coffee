###
Copyright (c) 2015 Jess Austin <jess.austin@gmail.com>
Released under MIT License
###

http = require 'http'
Keygrip = require 'keygrip'
koa = require 'koa'
request = require 'co-request'

signed = require '.'

require('tape') 'Koa-Signed-URL Test', require('co-tape') (tape) ->
  body = 'This is a test.'
  port = 2999
  yieldBody = (next) ->
    @body = body
    yield next

  keysList = [ 'secret', ['secret', 'another'], Keygrip ['secret', 'another'] ]
  pathParts = ['', 'path', '/subpath/', 'leaf.ext', '?q=query', '&r=queries']
  tape.plan 5 * pathParts.length * keysList.length

  for keys in keysList
    url = "http://localhost:#{port}/"
    app = koa()
    signedUrl = signed keys
    app.use signedUrl
    app.use yieldBody
    server = http.createServer app.callback()
      .listen port

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
