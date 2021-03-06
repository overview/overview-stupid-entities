$ = require('jquery')
_ = require('lodash')
Promise = require('bluebird')

State = require('./models/State')
VizView = require('./views/VizView')
ProgressView = require('./views/ProgressView')
IgnoreTokensView = require('./views/IgnoreTokensView')

MaxSaveDelay = 1000 # never save state more than once per MaxSaveDelay ms

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
    @state.fetch
      success: (state) ->
        saveCallback = _.throttle((-> state.save()), MaxSaveDelay, leading: false)
        state.on('change:ignore change:lang', saveCallback)
        state.refresh()

  attach: (el) ->
    @$el = $(el)

    @viz = new VizView(model: @state, server: @server)
    @progress = new ProgressView(model: @state)
    @ignore = new IgnoreTokensView(model: @state)

    @$el.append(@viz.el)
    @$el.append(@progress.el)
    @$el.append(@ignore.el)

    @progress.render()
    @ignore.render()

    undefined
