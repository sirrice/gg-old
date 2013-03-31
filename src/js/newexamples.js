;(function () {

  // This file contains the code to define the graphics and then
  // renders them using data randomly generated by data.js.

  $(document).ready(function() {
    Math.seedrandom("zero");

    var specs = {
      layers: [
/*      {
        geom: { type:"interval", aes: {y: 'total', r: 'total'} },
        aes: {x: 'd', y: 'r', 'fill': 'f',  "fill-opacity": 0.9},
        stat: "bin"
      }
     ,*/{
        geom: { type:"point"},//, aes: {y: 'total', r: 'total', fill: 'red'} },
        aes: {x: 'd', y: 'r', fill: 'g'},
        pos: { type: 'jitter', y:0.1, x:0}
        //stat: "bin"
      }


      ],
      facets: {x: 'f', y: 'g', fontSize: "10pt"},
      scales: {
        x: {type: 'linear'},
        y: {type: 'linear'},//, lim: [0, 500]},
        r: {type: 'linear', range: [3,6]}
      }
    }



    var w    = 800;
    var h    = 600;
    var ex   = function () { return d3.select('#examples').append('span'); };
    var bigdata = _.map(_.range(0, 1000), function(d) {
      g = Math.floor(Math.random() * 3);
      f = Math.floor(Math.random() * 3);
      t = Math.floor(Math.random() * 3);
      return {d:d, r: d, g: g, f:f, t:t};
    })

    var scatterplot = gg(specs)
    scatterplot.render(w, h, ex(), bigdata)



  });
})();
