$ = require('jquery')
_ = require('lodash')
Promise = require('bluebird')

State = require('./models/State')
VizView = require('./views/VizView')
ProgressView = require('./views/ProgressView')

Params =
  server: 'a String'
  documentSetId: 'a String'
  apiToken: 'a String'

module.exports = class App
  constructor: (@options) ->
    for k, v of Params
      throw "Must pass options.#{k}, a #{v}" if !@options[k]
      @[k] = @options[k]

    @state = new State({}, @options)

  attach: (el) ->
    @$el = $(el)

    @viz = new VizView(model: @state)
    @progress = new ProgressView(model: @state)
    @$el.append(@viz.el)
    @$el.append(@progress.el)

    @state.refresh()

    undefined
