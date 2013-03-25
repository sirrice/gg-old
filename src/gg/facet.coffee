




#
# Processing:
# 1) Splits dataset to be processed for different facets
#
# Rendering
# 1) Allocates svg elements for each facet pane and
# 2) Provides API to access them
#
# XXX: in the future, this should be an abstract class that computes
#      offset and sizes of containers, and subclasses should use them
#      to create appropriate SVG/Canvas elements
#
#
# Spec:
#
#   facets: {
#     (x|y): ???
#     type: grid|wrap,
#     scales: free|fixed,
#     (size|sizing): free|fixed
#   }
#
class gg.Facets
  constructor: (@g, @spec={}) ->
    @parseSpec()

    @splitter = @splitterNodes()



    @panes = []
    # paneSvgMapper[x val][y val] -> svg for the pane
    @paneSvgMapper = {}
    @xAxisSvgMapper = {}
    @yAxisSvgMapper = {}



  parseSpec: ->
    @x = findGood [@spec.x, () -> 1]
    @y = findGood [@spec.y, () -> 1]
    @scales = findGood [@spec.scales, "fixed"]
    @type = findGood [@spec.type, "grid"]
    @sizing = findGood [@spec.sizing, @spec.size, "fixed"]
    @facetXKey = "facetX"
    @facetYKey = "facetY"

    # rendering options
    @margin = findGood [@spec.margin, 10]
    @facetXLabel = findGood [@spec.xLabel, "Facet X"]
    @facetYLabel = findGood [@spec.yLabel, "Facet Y"]
    @facetFontSize = findGood [@spec.facetFontSize, "12pt"]
    @facetPadding = findGood [@spec.facetPadding, "5"]
    @exSize = _.exSize @facetFontSize


  # Accessor for facet pane objects
  svgPane: (facetX, facetY) ->
    try
      @paneSvgMapper[facetX][facetY]
    catch error
      throw error


  # Create the appropriate workflow split/partition node given the facet's
  # x/y specification
  #
  # @param facet is the facet-X or facet-Y specification
  # @param the name of the facet's grouping column
  createSplitterNode: (facet, name) ->
      if _.isString facet
          new gg.wf.Partition {f: ((row) -> row.get(facet)), name: name}
      else if _.isFunction {f: facet, name: name}
          new gg.wf.Partition facet
      else if _.isArray(facet) and facet.length > 0
          if _.isString facet[0]
              colnames = facet
              f = (table) =>
                  # create a new table. creates a new column called {name}
                  # and populated with column in colnames
                  _.map colnames, (colname) ->
                      newtable = table.clone()
                      newtable.addColumn name, table.getColumn(colname)
                      {key: colname, table: newtable}
              new gg.wf.Split {f: f, name: name}
          else:
              throw Error("Faceting by transformations not implemented yet")
      # TODO: also support varying run-time parameters


  splitterNodes: ->
    # XXX: This implementation is not exactly right, because it will not result
    #      in groups for x/y facetpairs that don't have any tuples.
    #      (we expect the cross product!)
    facetXNode = @createSplitterNode @x, @facetXKey
    facetYNode = @createSplitterNode @y, @facetYKey
    [facetXNode, facetYNode]

  #########################
  #
  # Allocate containers and determine sizes for each pane
  # 1) compute dimensions given margins
  # 2) compute dimensions of the facet labels.  Instantiate them
  # 3) compute dimensions for each pane.  Instantiate them
  # 4) update the range of each pane's position scales
  #
  #########################

  collectXYs: ->
    # compute x and y group values
    @xs = {}
    @ys = {}
    _.each tables, (table) ->
      if table.nrows() > 0
        @xs[table.get(0, @facetXKey)] = yes
        @ys[table.get(0, @facetYKey)] = yes

    @xs = _.uniq _.keys(@xs)
    @ys = _.uniq _.keys(@ys)

    # sort x and y.
    # TODO: support custom ordering
    @xs.sort()
    @ys.sort()

  allocatePanesNode: ->
    new gg.wf.Barrier {
      f: (args...) => @allocatePanes(args...)
    }



  allocatePanes: ->
    @w = @g.wFacet
    @h = @g.hFacet
    @svg = @g.svgFacet
    margin = @margin / 2
    matrix = "#{1.0-2*margin/@w},0,0,
              #{1.0-2*margin/@h},
              #{margin}, #{margin}"
    svg = svg.append('g')
        .attr('transform', "matrix(#{matrix})")

    svg.append('rect')
        .attr('class', 'plot-background')
        .attr('x', 0)
        .attr('y', 0)
        .attr('width', @w)
        .attr('height', @h)

    # compute dimensions for each container
    # top facet space
    facetSize = @exSize.h + 2*@facetPadding
    paneWidth = @w - 2 * facetSize
    paneHeight = @h - 2 * facetSize
    yAxisOpts =
      left: 0
      top: facetSize
      width: facetSize
      height: @h - facetSize
      class: "y-axis axis"
    xAxisOpts =
      left: facetSize
      top: @h - facetSize
      width: @w - facetSize
      height: facetSize
      class: "x-axis axis"
    topFacetOpts =
      left: facetSize
      top: 0
      width: paneWidth
      height: facetSize
    rightFacetOpts =
      left: @w - facetSize
      top: facetSize
      width: facetSize
      height: paneHeight
    paneOpts =
      left: facetSize
      top: facetSize
      width: @w - 2* facetSize
      height: @h - 2*facetSize
      class: "facet-grid-container"

    xRange = d3.scale.ordina().domain(@xs).rangeBands [0, panelWidth], 0.05
    yRange = d3.scale.ordina().domain(@ys).rangeBands [0, panelHeight], 0.05
    xBand = xRange.rangeBand()
    yBand = yRange.rangeBand()


    #
    # create and populate svgs for the facet labels
    #
    svgTopLabels = _.subSvg @svg, topFacetOpts
    @renderTopLabels svgTopLabels, xRange
    svgRightLabels = _.subSvg @svg, rightFacetOpts
    @renderRightLabels svgRightLabels, yRange

    #
    # create svg elements for each pane, and add them to the map
    #
    svgPanes = _.subSvg @svg, paneOpts
    _.each @xs, (x, xidx) =>
      _.each @ys, (y, yidx) =>
        left = xRange x
        top = yRange y
        svgPane = _.subSvg svgPanes, {
          width: xBand
          height: yBand
          left: left
          top: top
          id: "facet-grid-#{xidx}-#{yidx}"
          class: "facet-grid"
        }
        @paneSvgMapper[x][y] = svnPane


    # update ranges for the scales

    #
    # create svgs for axes
    #
    #_.each @xs, (x) => @xAxisSvgMapper[x] = _.subSvg @svg, xAxisOpts
    #_.each @ys, (y) => @yAxisSvgMapper[y] = _.subSvg @svg, yAxisOpts
    #@renderXAxes xRange
    #@renderYAxes yRange

    # finally, update ranges of all the scales
    _.each @g.scales.scalesList, (ss) =>
      _.each gg.Scale.xs, (aes) =>
        if ss.contains aes
          ss.scale(aes).range 0, xRange
      _.each gg.Scale.ys, (aes) =>
        if ss.contains aes
          ss.scale(aes).range 0, yRange


    tables



  ###########################
  #
  # Make row/col-wise scales consistent
  #
  ###########################

  expandDomains: (scalesSet) ->
    # XXX: this should be done in the scales/scalesSet object!!!


  # train fixed scales (every pane has the same x,y domains)
  trainScales: ->
    @masterScales = gg.Scales.merge @g.scales.scalesList
    if @scales is "fixed"
      _.each @g.scales.scalesList, (scalesSet) => scalesSet.merge @masterScales, false
    else
      @trainFreeScales()

    tables

  trainFreeScales: ->
    # now compute the shared scales for each column and row
    @xScales = _.map @xs, (x) =>
        gg.Scales.merge(_.map @ys, (y) => @subFacets[x][y].scales)
            .exclude(gg.Scale.ys)

    @yScales = _.map @ys, (y) =>
        gg.Scales.merge(_.map @xs, (x) => @subFacets[x][y].scales)
           .exclude(gg.Scale.xs)


    # TODO: expand their domains -- or this should be a separate operation?
    #

    # expand each layer's scalesSet's domains
    _.each @xs, (x, xidx) =>
      _.each @ys, (y, yidx) =>
        layerScalesSets = @g.scales.scales(x, y)
        _.each layerScalesSets, (ss) =>
          ss.merge @xScales[xidx], no
          ss.merge @yScales[yidx], no






  ########################
  #
  # Rendering Nodes
  # TODO: separate steps to
  #   1) compute container offsets/sizes -- know scale ranges for each facet/layer
  #   2) actually rendering axes etc.
  #
  ########################

  renderTopLabels: (svg, xRange) ->
    labels = svg.selectAll("g").data(@xs)
    enter = labels.enter().insert("g").attr("class", "facet-label x")
    enter.append("rect")
    enter.append("text")

    labels.select("text").text(String)
    enter.select("text")
      .attr("x", (d) -> xRange(d) + xRange.rangeBand()/2)
      .attr("y", @facetPadding)
      .attr("dy", "0.2em")
    enter.select("rect")
      .attr("x", xFacet)
      .attr("y", 0)
      .attr("width", xFacet.rangeBand())
      .attr("height", svg.attr("height"))

  renderRightLabels: (svg, yRange) ->
    labels = svg.selectAll("g").data(@ys)
    enter = labels.enter().insert("g").attr("class", "facet-label y")
    enter.append("rect")
    enter.append("text")

    labels.select("text").text(String)
    enter.select("text")
      .attr("dx", "0.2em")
      .attr("y", (d) -> yRange(d) + yRange.rangeBand()/2)
      .attr("rotate", 90)
    enter.select("rect")
      .attr("x", 0)
      .attr("y", yRange)
      .attr("width", svg.attr("width"))
      .attr("height", yRange.rangeBand())



  renderAxes: (xRange) ->
    _.each @xs, (x, xidx) =>
      left = xRange(x)
      scales = @g.scales(x)
      axis = d3.svg.axis()
        .scale(scales.scale('x').d3Scale)
        .ticks(5)
        .tickSize(@h)
        .orient("bottom")
      axis.tickFormat('') unless text



  # render the panes
  renderPanesFunc: (tables, envs, barrier) ->

  renderPanes: -> new gg.wf.Barrier (args...) => @renderPanesFunc(args...)



