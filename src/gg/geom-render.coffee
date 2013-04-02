#<< gg/xform

#
# group attribute
#
class gg.GeomRender extends gg.XForm
  constructor: (@layer, @spec={}) ->
    @spec.name = findGoodAttr @spec, ['name'], @constructor.name
    super @layer.g, @spec
    @parseSpec()


  parseSpec: ->
    super

  svg: (table, env, node) ->
    info = @paneInfo table, env
    @g.facets.svgPane info.facetX, info.facetY



  groups: (g, klass, data) ->
    g.selectAll("g.#{klass}")
      .data(data)
      .enter()
      .append('g')
      .attr('class', "#{klass}")

  agroup: (g, klass, data) ->
    g.append("g")
      .attr("class", "#{klass}")
      .data(data)


  # given a dictionary of attributes, add them to the dom element
  applyAttrs: (domEl, attrs) ->
    _.each attrs, (val, attr) -> domEl.attr attr, val

  compute: (table, env, node) -> @render table, env, node

  # @override this
  render: (table) -> throw Error("#{@name}.render() not implemented")

  @klasses: ->
    klasses = [
      gg.GeomRenderPointSvg,
      gg.GeomRenderLineSvg,
      gg.GeomRenderRectSvg
    ]
    ret = {}
    _.each klasses, (klass) ->
      if _.isArray klass.aliases
        _.each klass.aliases, (alias) -> ret[alias] = klass
      else
        ret[klass.aliases] = klass
    ret


  @fromSpec: (layer, spec) ->
    klasses = gg.GeomRender.klasses()
    if _.isString spec
      type = spec
      spec = {type: type}
    else
      type = findGoodAttr spec, ['geom', 'type', 'shape'], 'point'
    console.log klasses
    klass = klasses[type] or gg.GeomRenderPointSvg
    console.log "geom-render klass #{type} -> #{klass.name}"
    new klass layer, spec




class gg.GeomRenderPointSvg extends gg.GeomRender
  @aliases = ["point", "pt"]

  defaults: (table, env) ->
    r: 2
    "fill-opacity": 0.5
    fill: "steelblue"
    stroke: "steelblue"
    "stroke-width": 0
    "stroke-opacity": 0.5
    group: 1

  inputSchema: (table, env) ->
    ['x', 'y']

  render: (table, env, node) ->

    data = table.asArray()
    svg = @svg table, env
    circles = @agroup(svg, "circles geoms", data)
      .selectAll("circle")
      .data(data)
    enter = circles.enter()
    exit = circles.exit()
    enterCircles = enter.append("circle")

    @applyAttrs enterCircles,
      class: "geom"
      cx: (t) -> t.get('x')
      cy: (t) -> t.get('y')
      "fill-opacity": (t) -> t.get('fill-opacity')
      "stroke-opacity": (t) -> t.get("stroke-opacity")
      fill: (t) -> t.get('fill')
      r: (t) -> t.get('r')

    cssOver =
      fill: (t) -> d3.rgb(t.get("fill")).darker(2)
      "fill-opacity": 1
      r: (t) -> t.get('r') + 2
    cssOut =
      fill: (t) -> t.get('fill')
      "fill-opacity": (t) -> t.get('fill-opacity')
      r: (t) -> t.get('r')

    _this = @
    circles
      .on("mouseover", (d, idx) -> _this.applyAttrs d3.select(@), cssOver)
      .on("mouseout", (d, idx) ->  _this.applyAttrs d3.select(@), cssOut)


    exit.transition()
      .duration(500)
      .attr("fill-opacity", 0)
      .attr("stroke-opacity", 0)
    .transition()
      .remove()






class gg.GeomRenderLineSvg extends gg.GeomRender
  @aliases = "line"

  defaults: (table) ->
    stroke-width: 1
    stroke: "black"

  inputSchema: (table, env) -> ['x1', 'y1', 'x2', 'y2']

  render: (table, env) ->
    lines = @groups(@svg(table, env), "lines geoms", table.asArray())
      .selectAll("line")
      .data(Object)
    enter = lines.enter()
    exit = lines.exit()
    enterLines = enter.append("line")

    @applyAttrs enterLines,
      class: "geom"
      x1: (t) -> t.get('x1')
      x2: (t) -> t.get('x2')
      y1: (t) -> t.get('y1')
      y2: (t) -> t.get('y2')
      "stroke": (t) -> t.get("stroke")
      "stroke-width": (t) -> t.get("stroke-width")
      "stroke-opacity": (t) -> t.get("stroke-opacity")


    exit.remove()

# XXX: DOES NOT WORK
class gg.GeomRenderRectSvg extends gg.GeomRender
  @aliases = "rect"

  defaults: (table, env) ->
    "fill-opacity": 0.5
    fill: "steelblue"
    stroke: "steelblue"
    "stroke-width": 0
    "stroke-opacity": 0.5
    group: 1

  inputSchema: (table, env) ->
    ['x0', 'x1', 'y0', 'y1']

  render: (table, env, node) ->
    console.log 'rendering rectangles!'

    data = table.asArray()
    rects = @agroup(@svg(table, env), "intervals geoms", data)
      .selectAll("rect")
      .data(data)
    enter = rects.enter()
    exit = rects.exit()
    enterRects = enter.append("rect")

    @applyAttrs enterRects,
      class: "geom"
      x: (t) -> t.get('x0')
      y: (t) -> t.get('y0')
      width: (t) -> t.get('width')
      height: (t) -> t.get('height')
      "fill-opacity": (t) -> t.get('fill-opacity')
      "stroke-opacity": (t) -> t.get("stroke-opacity")
      fill: (t) -> t.get('fill')

    cssOver =
      x: (t) -> t.get('x0') - t.get('width') * 0.05
      y: (t) -> t.get('y0') - t.get('height') * 0.05
      width: (t) -> t.get('width') * 1.1
      height: (t) -> t.get('height') * 1.1
      fill: (t) -> d3.rgb(t.get("fill")).darker(2)
      "fill-opacity": 1

    cssOut =
      x: (t) -> t.get('x0')
      y: (t) -> t.get('y0')
      width: (t) -> t.get('width')
      height: (t) -> t.get('height')
      fill: (t) -> t.get('fill')
      "fill-opacity": (t) -> t.get('fill-opacity')

    _this = @
    rects
      .on("mouseover", (d, idx) -> _this.applyAttrs d3.select(@), cssOver)
      .on("mouseout", (d, idx) ->  _this.applyAttrs d3.select(@), cssOut)



    exit.transition()
      .duration(500)
      .attr("fill-opacity", 0)
      .attr("stroke-opacity", 0)
    .transition()
      .remove()




class gg.GeomRenderPath extends gg.GeomRender
class gg.GeomRenderPolygon extends gg.GeomRender
class gg.GeomRenderSchema extends gg.GeomRender
class gg.GeomRenderGlyph extends gg.GeomRender
