function visualize_lightgraph(;
    name="shinjuku_graph_large.jld2",
    data="./output/")
    basename = splitdir(splitext(name)[1])[2]
    outpath = joinpath(data, "gplot_$(basename).png")
    fnpath = joinpath(data, name)
    println(fnpath)
    jldopen(fnpath, "r") do dict
        gg = dict["graph"]
        dict_map = dict["node_map"]
        inv_dict_map = Dict()
        for (k, v) in dict_map
            inv_dict_map[v] = k
        end

        println(nv(gg), " ", ne(gg))

        posX = Float64[]
        posY = Float64[]
        for n in 1:nv(gg)
            lat, lon = get_prop(gg, n, :lat), get_prop(gg, n, :lon)
            push!(posX, lon)
            push!(posY, lat)
        end
        gp = gplot(gg, posX, posY, nodefillc=colorant"black", edgelinewidth=1.0, EDGELINEWIDTH=0.05, edgestrokec=colorant"black")
        gpnew = compose(
            context(), 
            (context(mirror=Mirror(pi, 0.5, 0.5)), gp))
        draw(PNG(outpath, 12cm, 12cm), gpnew)
    end
end