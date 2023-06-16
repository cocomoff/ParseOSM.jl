module ParseOSM

using JLD2
using JSON
using FileIO
using EzXML
using Graphs
using SimpleWeightedGraphs
using MetaGraphs
using ProgressBars
using GraphPlot
using Colors
using Compose
using Cairo
using GraphIO


# constants, utilities
include("util.jl")

# OSM parser/builder/visualizer
include("parser/parse_osm.jl")
include("builder/build_osm.jl")
include("visualizer/vis_osm.jl")

export parse_and_visualize

function parse_and_visualize(; name="shinjuku.osm", target_set=Set{String}(["pedestrian"]), cleanup=false, overwrite=false)
    basename = splitext(name)[1]
    ParseOSM.extract(; name=name, target_set=target_set, cleanup=cleanup, overwrite=overwrite)
    ParseOSM.build_lightgraph(; name=name, jld2nameD="$(basename)_plotinfo.jld2", overwrite=overwrite)
    ParseOSM.visualize_lightgraph(; name="$(basename)_graph.jld2")
end


end