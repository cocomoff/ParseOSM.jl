
function build_lightgraph(;
    name = "shinjuku.osm",
    jld2nameD = "shinjuku_plotinfo_large.jld2",
    OUTPUT_URL = "./output",
    overwrite = false)

    basename = splitdir(splitext(name)[1])[2]
    suffix = join(split(splitext(jld2nameD)[1], "_")[3:end], "_")
    outname = "$(basename)_graph$(suffix).jld2"
    jld2nameG = joinpath(OUTPUT_URL, outname)
    jld2nameDp = joinpath(OUTPUT_URL, jld2nameD)

    if !isfile(jld2nameG) || overwrite
        jldopen(jld2nameDp, "r") do file
            dict_edges = file["dict_edges"]
            dict_lat_lon = file["dict_lat_lon"]
            dict_edge_dist = file["dict_edge_dist"]
            dict_map = Dict()
            inv_dict_map = Dict()

            N = length(dict_lat_lon)
            g = MetaGraph(N)
            for (idn, (n, (lat, lon))) in enumerate(dict_lat_lon)
                dict_map[n] = idn
                inv_dict_map[idn] = n
                set_prop!(g, idn, :lat, lat)
                set_prop!(g, idn, :lon, lon)
            end

            # ways
            for (_, (_, ids)) in enumerate(dict_edges)
                for i = 1:length(ids)-1
                    ni, nj = ids[i], ids[i+1]
                    ii, jj = dict_map[ni], dict_map[nj]
                    dij = dict_edge_dist[(ni, nj)]
                    eij = Edge(ii, jj)
                    add_edge!(g, eij)
                    set_prop!(g, eij, :dist, dij)
                end
            end

            @info "Graph size |V|=$(nv(g)), |E|=$(ne(g))"

            # clean up
            clean_up!(g)

            # CC
            cc = connected_components(g)
            sizes = [(length(elem), elem) for elem in cc]
            sort!(sizes, by = x -> x[1], rev = true)
            @info "Top CC size: $([k[1] for k in sizes])"
            target = sizes[1][2]

            gg, mapgg = induced_subgraph(g, target)

            @info "Largest connected component of size $(length(target))"
            @info "$gg"
            
            # prepare simple weighted graph as well
            sg = SimpleWeightedGraph(nv(gg))
            dict_info = Dict("nodes" => [], "edges" => [])
            for n in vertices(gg)
                push!(dict_info["nodes"], [
                    get_prop(gg, n, :lat),
                    get_prop(gg, n, :lon)
                ])
            end
            for e in edges(gg)
                weight = get_prop(gg, e, :dist)
                add_edge!(sg, e.src, e.dst, weight)

                # @info dict_lat_lon[e.src]
                push!(dict_info["edges"], [
                    get_prop(gg, e.src, :lat),
                    get_prop(gg, e.src, :lon),
                    get_prop(gg, e.dst, :lat),
                    get_prop(gg, e.dst, :lon)
                ])
            end

            @info dict_info["nodes"]
            @info dict_info["edges"]

            # output graph jld
            jldopen(jld2nameG, "w") do outfile
                outfile["graph"] = gg
                outfile["swgraph"] = sg
                outfile["node_map"] = dict_map
                outfile["is_map"] = mapgg
                outfile["target"] = target
            end

            open("output.json","w") do f 
                JSON.print(f, dict_info)
            end

            # output graphML using GraphIO
            # savegraph("output/$(basename).gml", sg, EdgeListFormat())
        end
    else
        @info "already exists: $(jld2nameG)"
    end

    return outname
end
