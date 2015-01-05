Backbone = require('backbone')
_ = require('lodash')

module.exports = class IgnoreTokensView extends Backbone.View
  className: 'ignore-tokens'
  template: _.template('''
    <div class="ignore-tokens-button">
      <button class="open">...</button>
    </div>
    <div class="ignore-tokens-edit hidden">
      <div class="inner">
        <p>Write a list of words to omit from this view.</p>
        <p>The next-most-popular words will appear instead.</p>
        <textarea name="ignore"></textarea>
        <p class="help-block">One word per line</p>
        <p class="actions"><button class="done">Save list</button></p>
      </div>
    </div>
  ''')

  events:
    'click button.open': 'onClickOpen'
    'click button.done': 'onClickDone'

  initialize: ->
    throw 'Must pass model, a State' if !@model

    @listenTo(@model, 'change:showingIgnore change:ignore', @render)

  render: ->
    @initialRender() if !@textarea

    @renderTextarea()
    @renderButton()

  renderTextarea: ->
    Backbone.$(@edit).toggleClass('hidden', !@model.get('showingIgnore'))
    Backbone.$(@textarea).val(@model.get('ignore').join('\n'))

  renderButton: ->
    ignore = @model.get('ignore')
    text = switch ignore.length
      when 0 then 'Ignore a word'
      when 1 then '1 ignored word'
      else "#{ignore.length} ignored words"

    Backbone.$(@button).text(text)

  initialRender: ->
    @$el.html(@template())
    @button = @$el.find('button.open').get(0)
    @textarea = @$el.find('textarea').get(0)
    @edit = @$el.find('.ignore-tokens-edit').get(0)

  onClickOpen: (e) -> @model.set(showingIgnore: true)
  onClickDone: (e) ->
    text = Backbone.$(@textarea).val()
    words = text.trim().toLowerCase().split(/\s+/g).filter((s) -> s.length)
    @model.setIgnore(words)
    @model.set(showingIgnore: false)
