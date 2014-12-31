PCRE = require('pcre').PCRE
Promise = require('bluebird')
fs = require('fs')

MinTokenLength = 3

# Returns an Object which contains all common tokens in the given language.
#
# This method is SLOW: Only call it on load.
readDictionary = (lang) ->
  filename = "#{__dirname}/dictionaries/#{lang}.txt"
  text = fs.readFileSync(filename, 'utf-8')
  ret = Object.create(null)
  for token in text.split('\n')
    if token.length >= MinTokenLength
      ret[token] = true
  ret

Dictionaries =
  en: readDictionary('en')

findTokenOffsets = (buffer) -> findTokenOffsets.regex.execAll(buffer)
findTokenOffsets.regex = new PCRE("[-_’'\\p{L}\\p{N}]+", PCRE.PCRE_UTF8) # FIXME this is English-only
findTokenOffsets.regex.study(PCRE.PCRE_STUDY_JIT_COMPILE)

# Takes input text, splits it into tokens, and counts the tokens
#
# In theory, the TokenCounter stores a giant map of token -> nHits. This takes
# too much memory to send over the wire. (A reasonable 95th percentile:
# 1M tokens * (11b String+4b Int)/token = 15MB.) So the caller can ask for a
# "snapshot".
module.exports = class TokenCounter
  constructor: (options) ->
    throw 'Must pass options.lang, a String' if !options.lang
    throw 'Must pass options.ignore, an Array of Strings' if !options.ignore
    throw 'Must pass options.include, an Array of Strings' if !options.include

    @dictionary = Dictionaries[options.lang]

    # Hint for the uninitiated: we need to use `Object.create(null)` here, not
    # `{}`, so that we don't have a prototype. That's how we can handle the
    # English tokens "prototype" and "constructor", which would otherwise wreak
    # havoc.
    @ignore = Object.create(null)
    for token in options.ignore
      @ignore[token] = true

    @include = options.include

    @tokens = Object.create(null)
    @tokensKeys = [] # Optimization: Object.keys() is slow

  # Receives text, splits it into tokens, and stores the count
  write: (text) ->
    buffer = new Buffer(text.toLowerCase())
    offsetGroups = findTokenOffsets(buffer) || []
    for offsets in offsetGroups
      continue if offsets[1] - offsets[0] < MinTokenLength
      token = buffer.slice(offsets[0], offsets[1]).toString('utf-8')

      if @tokens[token]
        @tokens[token] += 1
      else
        @tokensKeys.push(token)
        @tokens[token] = 1

    undefined

  # Produces a snapshot of the tokens, suitable for transfer over the wire.
  #
  # A snapshot consists of three JSON Objects. Each maps tokens to their
  # frequencies:
  #
  # * included: all tokens in the `included` Array.
  # * all: the top `nTokens` tokens and their counts. This can help the client
  #        include new tokens without refreshing the page, as long as they are
  #        fairly common.
  # * useful: all tokens, minus dictionary tokens and ignored tokens. This does
  #           _not_ necessary include `included`. (The client should handle
  #           `included` itself.)
  snapshot: (nTokens) ->
    counts = @tokens
    tokens = @tokensKeys.sort((t1, t2) -> counts[t2] - counts[t1])

    all = {}
    (all[token] = counts[token]) for token in tokens.slice(0, nTokens)

    usefulTokens = []
    for token in tokens
      if @dictionary[token] != true && @ignore[token] != true
        usefulTokens.push(token)
        break if usefulTokens.length >= nTokens

    useful = {}
    (useful[token] = counts[token]) for token in usefulTokens

    included = {}
    (included[token] = counts[token]) for token in @include

    all: all
    useful: useful
    included: included
