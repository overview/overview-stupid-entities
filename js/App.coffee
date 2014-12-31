$ = require('jquery')
_ = require('lodash')
Promise = require('bluebird')

Params =
  server: 'a String'
  documentSetId: 'a String'
  apiToken: 'a String'

module.exports = class App
  constructor: (@options) ->
    for k, v of Params
      throw "Must pass options.#{k}, a #{v}" if !@options[k]
      @[k] = @options[k]

    @_ajax = (options) =>
      auth = new Buffer(@apiToken + ':x-auth-token').toString('base64')

      options = _.extend({
        dataType: 'json'
        headers:
          Authorization: "Basic #{auth}"
      }, options)
      Promise.resolve($.ajax(options))

  $: (args...) -> @$el.find(args...)

  attach: (el) ->
    @$el = $(el)
    @$el.text('Hello…')
    undefined
