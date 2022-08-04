module ParseOSM

using JLD2
using FileIO
using EzXML
using Graphs
using SimpleWeightedGraphs
using MetaGraphs
using ProgressBars


# constants, utilities
include("util.jl")

# OSM parser/builder/visualizer
include("parser/parse_osm.jl")
include("builder/build_osm.jl")
include("visualizer/vis_osm.jl")

end