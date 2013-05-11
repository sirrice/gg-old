;(function () {

  var render_query = function() {
  }

  var onSubmit = function() {
    var csvname = $("#csvname").val();
    d3.csv(csvname, function(error, data) {
      renderData(data);
      var text = $("#query").val();
      eval("var specs = " + text);
      console.log(specs);
      //var specs = JSON.parse(text);
      specs = _.flatten([specs]);
      specs = {layers: specs};

      render(specs, data);
    });
  };

  var renderData = function(rows) {
    var table = $("#sample_data");
    var keys = _.keys(rows[0]);
    var header = {};
    keys.forEach(function(key){header[key]=key;});
    var sample = [header];

    sample.concat(rows.slice(0, 5)).forEach(function(row) {
      var tr = $("<tr></tr>");

      _.map(keys, function(key) {
        var td = $("<td></td>")
          .text(row[key]);
        tr.append(td);
      });
      table.append(tr);


    });
  }


  var render = function(specs, rows, w, h) {
    var w    = w || 800;
    var h    = h || 400;
    var ex   = function () {
      $("#examples").empty();
      return d3.select('#examples').append('span');
    }();
    var plot = gg(specs)
    plot.render(w, h, ex, rows)
  }



  // This file contains the code to define the graphics and then
  // renders them using data randomly generated by data.js.

  $(document).ready(function() {
    Math.seedrandom("zero");

    $("#submit").click(onSubmit);
  });
})();
