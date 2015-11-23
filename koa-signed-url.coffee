debug = (require 'debug') 'koa-signed-url'
Keygrip = require 'keygrip'

# optionally pass in 'sigId'?
module.exports = (keys) ->
  # keys can be passed in as a single key, an array of keys, or a Keygrip
  unless keys?.constructor?.name is 'Keygrip'
    unless Array.isArray keys
      keys = [ keys ]
    keys = Keygrip keys

  debug "using Keygrip with hash #{keys.hash} and keys #{keys}"

  fn = (next) ->
    match = @href.match /[?&]sig=([^?&]*)$/
    if match?
      [_, sig] = match
      if keys.verify @href[...match?.index], new Buffer sig, 'base64'
        debug "verified #{@href}"
        yield next
    else
      @status = 404
      debug "failed to verify #{@href}"
      yield next # XXX need this? seems like implictly returning null would be fine

  fn.sign = (url) ->
    sig = keys.sign url
      .toString 'base64'
    rt = "#{url}#{if url.search '?' is -1 then '?sig=' else '&sig='}#{sig}"
    debug "signing #{url} with signature #{sig}: #{rt}"
    rt

  fn
