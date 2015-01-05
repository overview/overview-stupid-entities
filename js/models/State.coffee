Backbone = require('backbone')
oboe = require('oboe')
_ = require('lodash')

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

  initialize: (attrs, options) ->
    throw 'Must set options.server, a Server' if !options.server
    throw 'Must set options.documentSetId, a String' if !options.documentSetId
    throw 'Must set options.apiToken, a String' if !options.apiToken

    # "Private" members:
    #
    # * @config: server config
    # * @ignore: ignored words (Object mapping token -> true)
    # * @include: included words (Object mapping token -> true)
    # * @oboe: running Oboe request, if there is one

    @config =
      server: options.server
      documentSetId: options.documentSetId
      apiToken: options.apiToken

    @ignore = Object.create(null) # no prototype/constructor
    @include = Object.create(null) # no prototype/constructor

    (@ignore[token] = true) for token in @get('ignore')
    (@include[token] = true) for token in @get('include')

    @oboe = null

  _responseToAttributes: (response) ->
    json = response.tokens

    keys = Object.keys(json.useful)
    keys.sort((t1, t2) -> json.useful[t2] - json.useful[t1])
    keys = keys.slice(0, NVisibleTokens - Object.keys(json.included).length)

    tokens = keys.map((k) -> [ k, json.useful[k] ])

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
        process.nextTick =>
          attrs = @_responseToAttributes(response)
          @set(attrs)
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
    @set(ignore: ignore)
    @ignore = Object.create(null) # no prototype/constructor
    (@ignore[token] = true) for token in @get('ignore')
    @

  setInclude: (include) ->
    @set(include: include)
    @include = Object.create(null) # no prototype/constructor
    (@include[token] = true) for token in @get('include')
    @
