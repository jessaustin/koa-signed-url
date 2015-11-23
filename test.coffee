app = require('koa')()
tape = require 'tape'
coRequest = require 'co-request'
coTape = require 'co-tape'
signedUrl = (require './koa-signed-url') 'secret'

app.use signedUrl
app.use (next) ->
  console.log 'in test'
  @body = 'This is a test.'
  yield next
app.listen 3000

url = 'http://localhost:3000/path'
sig = signedUrl.sign url
console.log sig

tape 'crappy test', (tape) ->
  tape.plan 1
  console.log 'in test'
  tape.test 'blah', coTape (t) ->
    resp = yield coRequest sig
    t.equal resp.statusCode, 200, 'should be equal'
