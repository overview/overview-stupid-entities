App = require('./App')
Backbone = require('backbone')
$ = require('jquery')
Backbone.$ = $
QueryString = require('querystring')

$ ->
  options = QueryString.parse(window.location.search.substr(1))
  app = new App(options)
  app.attach($('#app'))
