Backbone = require('backbone')
d3 = require('d3')
d3.layout.cloud = require('../../node_modules/d3.layout.cloud/d3.layout.cloud')

AnimationDuration = 500 # ms

# A D3-backed view.
#
# This View is a div with a single svg child.
module.exports = class VizView extends Backbone.View
  className: 'd3-container'

  events:
    'click button.ignore-token': 'onClickIgnore'

  initialize: (options) ->
    throw 'Must pass options.model, a State' if !@model?
    throw 'Must pass options.server, a String' if !options.server?

    @server = options.server

    @listenTo(@model, 'change:tokens', @render)

  render: ->
    @initialRender() if !@svg?
    @delete?.remove()
    @delete = null

    w = @el.parentNode.clientWidth || 100
    h = @el.parentNode.clientHeight || 100
    size = [ w, h ]
    tokens = @model.get('tokens')

    minCount = Infinity
    maxCount = 0
    for token in tokens
      count = token[1]
      minCount = count if count < minCount
      maxCount = count if count > maxCount

    @svg
      .attr('width', w)
      .attr('height', h)
      .size(size)

    @fontSize
      .domain([ minCount, maxCount ])
      .rangeRound([ Math.round(w / 70), Math.round(w / 20) ])

    @texts
      .attr('transform', "translate(#{w >> 1},#{h >> 1})")

    @layout
      .stop()
      .size(size)
      .words(tokens)
      .start()

  initialRender: ->
    @svg = d3.select(@el).append('svg')
    @texts = @svg.append('g').attr('class', 'tokens')

    @svg.on 'click', => @_onClickSvg(d3.event.target)

    @fontSize = d3.scale.linear()
      .domain([ 1, 2 ])
      .rangeRound([ 1, 2 ])

    @layout = d3.layout.cloud()
      .timeInterval(100)
      .padding(2)
      .font('Helvetica, Arial, sans-serif')
      .fontSize((d) => @fontSize(d[1])) # each datum is [ token, count ]
      .text((d) -> d[0])                # each datum is [ token, count ]
      .rotate(-> (Math.random() - 0.5) * 60) # -30 .. +30
      .on('end', @_drawFromLayout.bind(@))

    @

  _onClickSvg: (el) ->
    if el.nodeName == 'text'
      @_onClickText(el)
    else
      @_onUnclick()

  _onUnclick: ->
    @delete?.remove()
    @delete = null

    window.parent.postMessage({
      call: 'setDocumentListParams'
      args: [ { name: "in document set" } ]
    }, @server)

  _onClickText: (el) ->
    text = d3.select(el)
    token = text.data()[0]

    matrixStack = []
    node = el
    while node != @svg.node()
      matrixStack.push(node.transform.baseVal.consolidate().matrix)
      node = node.parentNode

    m = matrixStack.pop()
    while matrixStack.length
      m = m.multiply(matrixStack.pop())

    cssTransform = "matrix(#{m.a},#{m.b},#{m.c},#{m.d},#{m.e},#{m.f})"

    @delete?.remove()
    @delete = d3.select(@el).append('div')
      .attr('class', 'ignore-token')
      .style('position', 'absolute')
      .style('white-space', 'nowrap')
      .style('top', 0)
      .style('left', 0)
      .style('width', 0)
      .style('height', 0)
      .style('transform', cssTransform)

    @delete.append('button')
      .attr('data-token', token[0])
      .attr('class', 'ignore-token')
      .style('position', 'relative')
      .text('Ignore this word')
      .style('text-align', 'center')
      .style('width', '9em')
      .style('left', '-4.5em')
      .style('top', '3px')

    @delete.append('div')
      .attr('class', 'count')
      .style('position', 'relative')
      .text("(appears #{token[1]} times)")
      .style('text-align', 'center')
      .style('width', '10em')
      .style('left', '-5em')
      .style('top', '3px')
      .style('text-shadow',
        'white -1px -1px, white -1px 1px, white 1px -1px, white 1px 1px, -1px 0 1px white, 1px 0 1px white, 0 -1px 1px white, 0 1px 1px white'
      )

    window.parent.postMessage({
      call: 'setDocumentListParams'
      args: [ { q: token[0], name: "with word “#{token[0]}”" } ]
    }, @server)

  _drawFromLayout: (data) ->
    texts = @texts.selectAll('text').data(data, (d) -> d[0])

    # Modify existing <text> elements
    texts.transition()
      .duration(AnimationDuration)
      .style('opacity', 1) # in case we interrupted an earlier transition
      .attr('transform', (d) -> "translate(#{d.x},#{d.y}),rotate(#{d.rotate})")
      .style('font-size', (d) -> "#{d.size}px")

    # Add new <text> elements and animate their opacity
    texts.enter().append('text')
      .text((d) -> d.text)
      .attr('text-anchor', 'middle')
      .attr('transform', (d) -> "translate(#{d.x},#{d.y}),rotate(#{d.rotate})")
      .attr('draggable', 'yes')
      .style('font-family', (d) -> d.font)
      .style('font-size', (d) -> "#{d.size}px")
      .style('fill', '#666')
      .style('opacity', 1e-6)
      .transition()
        .duration(AnimationDuration)
        .style('opacity', 1)

    # Remove old <text> elemtents: move them to a new <g> that's identical to
    # g.texts, then fade out the <g>.
    exit = @svg.append('g')
      .attr('class', 'exit')
      .attr('transform', @texts.attr('transform'))

    exitNode = exit.node()
    texts.exit().each(-> exitNode.appendChild(@))

    exit.transition()
      .duration(AnimationDuration)
      .style('opacity', 1e-6)
      .remove()

  onClickIgnore: (el) ->
    token = Backbone.$(el.currentTarget).attr('data-token')
    @model.addIgnore(token)
