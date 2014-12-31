express = require('express')
morgan = require('morgan')
oboe = require('oboe')

app = express()
app.use(morgan('combined'))

nextRequestId = 1

app.get '/generate', (req, res, next) ->
  res.header('Content-Type', 'application/json')
  res.json(foo: 'bar')

app.get '/show', (req, res, next) ->
  res.render('show.jade', res.query)

app.get '/metadata', (req, res, next) ->
  res.status(204).header('Access-Control-Allow-Origin', '*').send()

app.use('/js', express.static(__dirname + '/public/js'))
app.use('/css', express.static(__dirname + '/public/css'))

port = process.env.PORT || 9001
app.listen(port)
console.log("Serving at http://localhost:#{port}")
