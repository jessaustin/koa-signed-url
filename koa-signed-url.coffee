# copyright (c) 2015 Jess Austin <jess.austin@gmail.com>
# released under MIT License

debug = (require 'debug') 'koa-signed-url'
Keygrip = require 'keygrip'

# Export a function that returns url-signature-verifying middleware, with a
# "sign" property containing a url-signing function. Urls are signed by
# appending a signature to the query string. See readme.md for advice on secure
# use of this module.
module.exports = (keys, sigId='sig') ->
  # keys can be passed in as a single key, an array of keys, or a Keygrip
  unless keys?.constructor?.name is 'Keygrip'
    unless Array.isArray keys
      keys = [ keys ]
    keys = Keygrip keys

  debug "using Keygrip with hash #{keys.hash} and keys #{keys}"

  fn = (next) ->
    # don't let anything through that will cause Keygrip.verify() to stop early
    match = @href
      .match ///[?&]#{sigId}=                        # don't capture this
                ((?:[A-Z]|[a-z]|\d|[+/])*={0,2})$/// # only 64 chars + 0-2 "="s

    if match? and
              keys.verify @href[...match?.index], new Buffer match[1], 'base64'
      debug "verified #{@href}"
      yield next
    else
      @status = 404
      debug "failed to verify #{@href}"

  fn.sign = (url) ->      # add function as a property of preceeding function
    sig = keys.sign url
      .toString 'base64'
    debug "signing #{url} with signature #{sig}"
    "#{url}#{if url.search '?' is -1 then '?' else '&'}#{sigId}=#{sig}"

  fn                      # now return the original function
