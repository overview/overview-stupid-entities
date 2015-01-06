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
  ru: readDictionary('ru')

# Turns "en+ru" into a big dictionary
combineDictionaries = (spec) ->
  if spec of Dictionaries
    Dictionaries[spec]
  else
    ret = Object.create(null)

    for lang in spec.split('+')
      dictionary = Dictionaries[lang]
      for k, __ of dictionary
        ret[k] = true

    Dictionaries[spec] = ret

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
    throw 'Must pass options.lang, a String like "en" or "en+ru"' if !options.lang

    @dictionary = combineDictionaries(options.lang)

    # Hint for the uninitiated: we need to use `Object.create(null)` here, not
    # `{}`, so that we don't have a prototype. That's how we can handle the
    # English tokens "prototype" and "constructor", which would otherwise wreak
    # havoc.
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
  # A snapshot is a JSON object that includes these:
  #
  # * counts: { String => Number} The top `nTokens` tokens and their counts.
  #           This can help the client include new tokens without refreshing
  #           the page.
  # * useful: [ String ] Non-dictionary tokens, from most to least common.
  snapshot: (nTokens) ->
    allCounts = @tokens
    tokens = @tokensKeys
      .sort((t1, t2) -> allCounts[t2] - allCounts[t1])
      .slice(0, nTokens)

    counts = Object.create(null)
    counts[token] = allCounts[token] for token in tokens

    useful = []
    for token in tokens
      if @dictionary[token] != true
        useful.push(token)

    counts: counts
    useful: useful
