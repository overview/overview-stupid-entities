Backbone = require('backbone')
d3 = require('d3')
d3.layout.cloud = require('../../node_modules/d3.layout.cloud/d3.layout.cloud')

AnimationDuration = 500 # ms

# A D3-backed view.
#
# This View is a div with a single svg child.
module.exports = class VizView extends Backbone.View
  className: 'd3-container'

  initialize: ->
    throw 'Must pass options.model, a State' if !@model?

    @listenTo(@model, 'change:tokens', @render)

  render: ->
    @initialRender() if !@svg?

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
      .rangeRound([ Math.round(w / 60), Math.round(w / 15) ])

    @texts
      .attr('transform', "translate(#{w >> 1},#{h >> 1})")

    @layout
      .stop()
      .size(size)
      .words(tokens)
      .start()

  initialRender: ->
    @svg = d3.select(@el).append('svg')
    @background = @svg.append('g').attr('class', 'background')
    @texts = @svg.append('g').attr('class', 'tokens')

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

  _drawFromLayout: (data) ->
    texts = @texts.selectAll('text').data(data)

    # Modify existing <text> elements
    texts.transition()
      .duration(AnimationDuration)
      .attr('transform', (d) -> "translate(#{d.x},#{d.y}),rotate(#{d.rotate})")
      .style('font-size', (d) -> "#{d.size}px")

    # Add new <text> elements and animate their opacity
    texts.enter().append('text')
      .text((d) -> d.text)
      .attr('text-anchor', 'middle')
      .attr('transform', (d) -> "translate(#{d.x},#{d.y}),rotate(#{d.rotate})")
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
