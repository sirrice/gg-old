#<< gg/wf/node

# General UDF operator
#
# Developer only writes a Compute function that returns a table,
# node handles the rest.
#
class gg.wf.Exec extends gg.wf.Node
  @ggpackage = "gg.wf.Exec"

  constructor: (@spec={}) ->
    super
    @type = "exec"
    @name = _.findGood [@spec.name, "exec-#{@id}"]

    @params.ensure 'compute', ['f'], null

  compute: (table, env, params) -> table

  # @return emits to single child node
  run: ->
    throw Error("node not ready") unless @ready()

    params = @params
    f = (data) =>
      table = @compute data.table, data.env, params
      data = new gg.wf.Data table, data.env
      data
    outputs = gg.wf.Inputs.mapLeaves @inputs[0], f

    @output 0, outputs
    outputs

  @create: (params, compute) ->
    new gg.wf.Exec
      params: params
      f: compute





