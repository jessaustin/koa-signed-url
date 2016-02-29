###
Copyright © 201{5,6} Jess Austin <jess.austin@gmail.com>
Released under MIT License
###

debug = (require 'debug') 'koa-signed-url'
Keygrip = require 'keygrip'

add_query_parameter = (uri, name, value) ->
  [ uri, query ] = uri.split '?'
  "#{uri}?#{if query? then query + '&' else ''}#{name}=#{value}"

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
    [ ..., uri, sig ] = @href.split ///[?&]#{sigId}=///
    # clean up before passing to Buffer which will ignore anything after a '='
    [ sig, rest... ] = sig.split '='
    rest = rest.reduce ((acc, {length}) -> acc or length), false
    if uri? and not rest and keys.verify uri, new Buffer sig, 'base64'
      debug "verified #{@href}"
      yield next
    else
      @status = 404
      debug "failed to verify #{@href}"

  fn.sign = (uri, duration=0) ->  # sign() is a property of preceeding function
    # don't sign fragment
    [ uri, fragment ] = uri.split '#'
    if duration
      uri = add_query_parameter uri, expId, new Date().valueOf() + duration
    sig = keys.sign uri
      .toString 'base64'
    debug "signing #{uri} with signature #{sig}"
    add_query_parameter(uri, sigId, sig) + if fragment? then '#' + fragment else ''

  fn                      # now return the original function
