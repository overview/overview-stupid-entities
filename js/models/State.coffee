Backbone = require('backbone')
oboe = require('oboe')

NVisibleTokens = 500

module.exports = class State extends Backbone.Model
  defaults:
    lang: 'en+ru'
    ignore: [] # Ignored words (above and beyond dictionary words)
    serverResponse: null
    serverError: null
    progress: 1
    showingIgnore: false  # if true, a textarea covers the screen

  initialize: (attrs, options) ->
    throw 'Must set options.server, a Server' if !options.server
    throw 'Must set options.documentSetId, a String' if !options.documentSetId
    throw 'Must set options.apiToken, a String' if !options.apiToken

    # "Private" members:
    #
    # * @config: server config
    # * @ignore: ignored words (Object mapping token -> true)
    # * @oboe: running Oboe request, if there is one

    @config =
      server: options.server
      documentSetId: options.documentSetId
      apiToken: options.apiToken

    @ignore = Object.create(null) # no prototype/constructor
    (@ignore[token] = true) for token in @get('ignore')

    @oboe = null

  # Returns an Array of { text, count } objects.
  #
  # The result will be truncated to NVisibleTokens tokens and will not include
  # any words that have been ignored.
  getTokens: ->
    response = @get('serverResponse')
    return [] if !response

    counts = response.counts

    ret = []
    for token in response.useful
      continue if @ignore[token]
      break if ret.length >= NVisibleTokens
      ret.push(text: token, count: counts[token])

    ret

  # Stream a response from the server. Will update lots of attributes:
  #
  # * progress: will start at 0 and move to 1
  # * serverResponse: will get updated a few times
  # * serverError: will become null, or change to set
  refresh: ->
    @oboe?.abort()
    @set
      serverResponse: null
      serverError: null
      progress: 0

    @oboe = oboe("/generate?server=#{encodeURIComponent(@config.server)}&apiToken=#{encodeURIComponent(@config.apiToken)}&documentSetId=#{encodeURIComponent(@config.documentSetId)}&lang=#{encodeURIComponent(@get('lang'))}&ignore=#{encodeURIComponent(@get('ignore').join(' '))}}")
      .node '![*]', (response) =>
        # Oboe eats up errors. Use process.nextTick to crash properly
        process.nextTick =>
          @set
            serverResponse: response
            serverError: null
            progress: response.progress
        oboe.drop
      .done =>
        @oboe = null
      .fail (obj) =>
        @set
          serverResponse: null
          progress: 1
          serverError: obj
        @oboe = null

  setIgnore: (ignore) ->
    @ignore = Object.create(null) # no prototype/constructor
    (@ignore[token] = true) for token in ignore
    @set(ignore: ignore)
    @

  addIgnore: (token) ->
    @ignore[token] = true
    newIgnore = @get('ignore').slice(0)
    newIgnore.push(token)
    @set(ignore: newIgnore)
    @
