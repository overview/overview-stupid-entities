Backbone = require('backbone')
oboe = require('oboe')

NVisibleTokens = 150

module.exports = class State extends Backbone.Model
  defaults:
    lang: 'en'
    ignore: [] # Ignored words (above and beyond dictionary words)
    include: [] # Included words (regardless of ignore/dictionaty)
    missing: [] # Words in "included" which we can't see
    nUseful: 0 # _Total_ number of useful words in the docset
    lastServerResponse: null
    lastServerError: null
    progress: 1
    tokens: [] # Array of [ token, nOccurrences ] Arrays
    showingIgnore: false  # if true, a textarea covers the screen
    showingInclude: false # if true, a textarea covers the screen

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

    @listenTo(@, 'change:ignore change:include change:lastServerResponse', @_refreshTokens)

  _responseToAttributes: (response) ->
    json = response.tokens

    keys = Object.keys(json.useful)
    tokens = keys
      .sort((t1, t2) -> json.useful[t2] - json.useful[t1])
      .filter((k) => !@ignore[k])
      .slice(0, NVisibleTokens)
      .map((k) -> [ k, json.useful[k] ])

    for k, v of json.included
      tokens.push([ k, v ])

    missing = []
    for token in @get('include')
      missing.push(token) if !json.include[token]?

    missing: missing
    nUseful: json.nUseful
    lastServerResponse: response
    lastServerError: null
    tokens: tokens
    progress: response.progress

  # Stream a response from the server. Will update lots of attributes:
  #
  # * progress: will start at 0 and move to 1
  # * missing, nUseful, lastServerResponse: will get updated a few times
  # * lastServerError: will become null, or change to set
  refresh: ->
    @oboe?.abort()
    @set
      missing: []
      nUseful: 0
      lastServerResponse: null
      lastServerError: null
      progress: 0
      tokens: []

    @oboe = oboe("/generate?server=#{encodeURIComponent(@config.server)}&apiToken=#{encodeURIComponent(@config.apiToken)}&documentSetId=#{encodeURIComponent(@config.documentSetId)}&lang=#{encodeURIComponent(@get('lang'))}&ignore=#{encodeURIComponent(@get('ignore').join(' '))}&include=#{encodeURIComponent(@get('include').join(' '))}")
      .node '![*]', (response) =>
        # Oboe eats up errors. Use process.nextTick to crash properly
        process.nextTick(=> @set('lastServerResponse', response))
        oboe.drop
      .done =>
        @oboe = null
      .fail (obj) =>
        @set
          missing: []
          nUseful: 0
          lastServerResponse: null
          progress: 0
          lastServerError: obj
          tokens: []
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

  setInclude: (include) ->
    @include = Object.create(null) # no prototype/constructor
    (@include[token] = true) for token in @get('include')
    @set(include: include)
    @

  _refreshTokens: ->
    return if !@get('lastServerResponse')
    attrs = @_responseToAttributes(@get('lastServerResponse'))
    @set(attrs)
