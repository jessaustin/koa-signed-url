###
Copyright © 201{5,6} Jess Austin <jess.austin@gmail.com>
Released under MIT License
###

{ parse } = require 'url'
debug = (require 'debug') 'koa-signed-url'
Keygrip = require 'keygrip'

add_query_parameter = (url, name, value) ->
  [ url, query ] = url.split '?'
  "#{url}?#{if query? then query + '&' else ''}#{name}=#{value}"

# Export a function that returns url-signature-verifying middleware, with a
# "sign" property containing a url-signing function. Urls are signed by
# appending a signature to the query string. See readme.md for advice on secure
# use of this module.
module.exports = (keys, sigId='sig', expId='exp') ->
  # keys can be passed in as a single key, an array of keys, or a Keygrip
  unless keys?.constructor?.name is 'Keygrip'
    unless Array.isArray keys
      keys = [ keys ]
    keys = Keygrip keys

  debug "using Keygrip with hash #{keys.hash} and keys #{keys}"

  fn = (next) ->          # this is the koa middleware
    [ ..., url, sig ] = @href.split ///[?&]#{sigId}=///
    # Buffer will ignore anything after a '=', so check for that
    [ sig, rest... ] = sig.split '='
    rest = rest.reduce ((acc, {length}) -> acc or length), false
    unless url? and not rest and keys.verify url, new Buffer sig, 'base64'
      @status = 404
      debug "failed to verify #{@href}"
    else
      { query } = parse url, yes
      if new Date().valueOf() >= parseInt query[expId]
        @status = 404
        debug "#{@href} expired at #{query[expId]}"
      else
        debug "verified #{@href}"
        yield next

  fn.sign = (url, duration=0) ->  # sign() is a property of preceeding function
    # don't sign fragment
    [ url, fragment ] = url.split '#'
    if duration
      url = add_query_parameter url, expId, new Date().valueOf() + duration
    sig = keys.sign url
      .toString 'base64'
    debug "signing #{url} with signature #{sig}"
    add_query_parameter(url, sigId, sig) + if fragment? then '#' + fragment else ''

  fn                      # now return the original function
