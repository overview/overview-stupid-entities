express = require('express')
compression = require('compression')
morgan = require('morgan')
stream = require('stream')
oboe = require('oboe')

TokenCounter = require('./lib/TokenCounter')
NTokensInHeartbeat = 200 # Number of tokens to send every so often while processing
NTokensInResponse = 3000 # Number of tokens to send when request completes
HeartbeatInterval = 1000 # Minimum number of milliseconds between heartbeats

app = express()
app.use(compression())
app.use(morgan('combined'))

streamDocuments = (options) ->
  throw 'Must pass options.server, a String' if !options.server
  throw 'Must pass options.apiToken, a String' if !options.apiToken
  throw 'Must pass options.documentSetId, a String' if !options.documentSetId
  throw 'Must pass options.onText, a Function(String)' if !options.onText
  throw 'Must pass options.onStart, a Function(nTexts)' if !options.onStart
  throw 'Must pass options.onDone, a Function()' if !options.onDone
  throw 'Must pass options.onFail, a Function({thrown,statusCode,body,jsonBody})' if !options.onFail

  req = oboe
    url: "#{options.server}/api/v1/document-sets/#{options.documentSetId}/documents?fields=id,text&stream=true"
    headers:
      Authorization: "Basic #{new Buffer(options.apiToken + ':x-auth-token').toString('base64')}"

  req.on('fail', options.onFail)
  req.on('done', options.onDone)
  req.node
    'pagination.total': (total) ->
      options.onStart(total)

    'items.*': (doc) ->
      options.onText(doc.text)
      oboe.drop # save memory

  undefined

app.get '/generate', (req, res) ->
  counter = new TokenCounter
    lang: req.query.lang
    ignore: String(req.query.ignore || '').split(/\s+/)

  processed = 0
  total = null
  lastHeartbeat = null # a Date

  writeSnapshot = (nTokens) ->
    progress = if total?
      if total == 0
        1
      else
        processed / total
    else
      0

    snapshot = counter.snapshot(nTokens)
    snapshot.progress = progress

    json = JSON.stringify(snapshot)
    res.write(json)

  streamDocuments
    documentSetId: req.query.documentSetId
    server: req.query.server
    apiToken: req.query.apiToken

    onFail: (obj) ->
      return if !res.thrown && !res.body
      if total? # we've already called onStart; we thought we were okay
        res.write(JSON.stringify(obj))
        res.write(']')
        res.end()
      else
        res.status(502).json(obj)

    onStart: (n) ->
      total = n
      res.status(200)
      res.header('Content-Type', 'application/json')
      res.write('[')
      lastHeartbeat = new Date()

    onText: (text) ->
      counter.write(text)
      processed += 1
      if new Date() - lastHeartbeat > HeartbeatInterval && processed != total
        writeSnapshot(NTokensInHeartbeat) # might be slow-ish
        res.write(',')
        lastHeartbeat = new Date()

    onDone: ->
      writeSnapshot(NTokensInResponse)
      res.write(']')
      res.end()

app.get '/show', (req, res, next) ->
  res.render('show.jade', res.query)

app.get '/metadata', (req, res, next) ->
  res.status(204).header('Access-Control-Allow-Origin', '*').send()

app.use('/js', express.static(__dirname + '/public/js'))
app.use('/css', express.static(__dirname + '/public/css'))

port = process.env.PORT || 9001
app.listen(port)
console.log("Serving at http://localhost:#{port}")
