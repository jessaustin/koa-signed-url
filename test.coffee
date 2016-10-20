###
Copyright © 201{5,6} Jess Austin <jess.austin@gmail.com>
Released under MIT License
###

{ createServer } = require 'http'
koa = require 'koa'
request = require 'co-request'
sleep = require 'co-sleep'

signed = require '.'

require('tape') 'Koa-Signed-URL Test', require('co-tape') (tape) ->
  body = 'This is a test.'
  port = 2999

  keysList = [
    'secret'
    ['secret', 'another']
    require('keygrip') ['secret', 'another']
  ]
  pathParts = ['', 'path', '/subpath/', 'leaf.ext', '?q=query', '&r=queries']
  tape.plan 9 * pathParts.length * keysList.length

  for keys in keysList
    url = "http://localhost:#{port}/"
    app = koa()
    signedUrl = signed keys
    app.use signedUrl
    app.use (next) ->
      @body = body
      yield next
    server = createServer app.callback()
      .listen port

    for part in pathParts
      url += part

      sig = signedUrl.sign url
      tape.equal "#{sig}#fragment", signedUrl.sign("#{url}#fragment"),
                                       'Should ignore fragment'
      resp = yield request sig
      tape.equal resp.statusCode, 200, 'Should verify correct signature.'
      tape.equal resp.body, body, 'Should serve correct body.'
      resp = yield request sig.replace /[?&]sig=.*$/, ''
      tape.equal resp.statusCode, 404, 'Should reject lack of signature.'
      resp = yield request sig + 'x'
      tape.equal resp.statusCode, 404, 'Should reject expanded signature.'
      resp = yield request sig[...-3]
      tape.equal resp.statusCode, 404, 'Should reject truncated signature.'
      resp = yield request sig + '&yet=another_query'
      tape.equal resp.statusCode, 404, 'Should reject non-canonical URL.'

      sig = signedUrl.sign url, 10000
      resp = yield request sig
      tape.equal resp.statusCode, 200, 'Should verify correct signature.'

      sig = signedUrl.sign url, 1
      resp = yield request sig
      yield sleep 100
      tape.equal resp.statusCode, 404, 'Should reject expired url'

    server.close()
