Backbone = require('backbone')

module.exports = class ProgressView extends Backbone.View
  tagName: 'progress'

  initialize: ->
    throw 'Must pass options.model, a State' if !@model?

    @listenTo(@model, 'change:progress', @render)

  render: ->
    progress = @model.get('progress')

    @$el
      .attr('value', progress || 0)
      .toggleClass('done', !progress? || progress == 1)
