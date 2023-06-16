const TARGET_SET_FULL = Set{String}(["trunk", "primary", "secondary", "tertiary", "unclassified", "residential"])
const TARGET_SET_LARGE = Set{String}(["trunk", "primary", "secondary"])
const TARGET_SET_MEDIUM = Set{String}(["trunk", "primary", "secondary", "tertiary", "unclassified", "residential", "pedestrian"])
const TARGET_SET_PS = Set{String}(["primary", "secondary"])
const TARGET_SET_MORE = Set{String}(["trunk",
    "primary", "secondary", "tertiary", "unclassified", "residential",
    "road", "trunk_link", "primary_link", "secondary_link", "teritary_link"
])


function extract(; name = "shinjuku.osm",
    target_set = TARGET_SET_LARGE,
    DATA_URL = "./data",
    OUTPUT_URL = "./output",
    cleanup = false,
    overwrite = false)
    
    basename = splitdir(splitext(name)[1])[2]
    filepath = joinpath(DATA_URL, name)
    suffix = "" #get_suffix(target_set)
    nidname = joinpath(OUTPUT_URL, "$(basename)_nodeid$(suffix).csv")
    eidname = joinpath(OUTPUT_URL, "$(basename)_edgeid$(suffix).csv")

    @info "Input     : $(filepath)"
    @info "V-output  : $(nidname)"
    @info "E-output  : $(eidname)"
    @info "Target    : $(target_set)"

    if overwrite || !isfile(nidname)
        counter = 0
        counter_amenity = 0
        open(nidname, "w") do outfile
            reader = open(EzXML.StreamReader, filepath)
            while (item = iterate(reader)) !== nothing
                if reader.name == "node"
                    counter += 1
                    nid, nlat, nlon = reader["id"], reader["lat"], reader["lon"]

                    tree = expandtree(reader)
                    amenity = "none"
                    for c in eachelement(tree)
                        if c.name == "tag" && c["k"] == "amenity"
                            counter_amenity += 1
                            amenity = c["v"]
                        end
                    end
                    write(outfile, "$nid,$nlat,$nlon,$amenity\n")
                end
            end
        end
        @info "ratio: $(counter_amenity)/$(counter)"
    else
        @info "already exists: $(nidname)"
    end

    if overwrite || !isfile(eidname)
        open(eidname, "w") do outfile
            reader = open(EzXML.StreamReader, filepath)
            while (item = iterate(reader)) !== nothing
                if reader.name == "way" && reader.type == EzXML.READER_ELEMENT
                    way_id = reader["id"]
                    tree = expandtree(reader)

                    highwayType = ""
                    refs = String[]
                    data = Dict()
                    for c in eachelement(tree)
                        if c.name == "tag"
                            if c["k"] == "highway"
                                highwayType = c["v"]
                            else
                                data[c["k"]] = c["v"]
                            end
                        elseif c.name == "nd"
                            push!(refs, c["ref"])
                        end
                    end

                    if highwayType in target_set
                        # new cleaning
                        if haskey(data, "level") && parse(Int, data["level"]) < 0
                            continue
                        end
                        if haskey(data, "layer") && parse(Int, data["layer"]) > 0
                            continue
                        end
                        @info data
                        edgelist = join(refs, ",")
                        write(outfile, "$(way_id) $(edgelist)\n")
                        # println("$way_id $edgelist")
                    end

                end
            end
        end
    else
        @info "already exists: $(eidname)"
    end

    # build outdict file
    outdict = joinpath(OUTPUT_URL, "$(basename)_plotinfo$(suffix).jld2")
    @info "JLD2 file : $(outdict)"
    if overwrite || !isfile(outdict)
        # edge
        used_ids = Set()
        dict_edges = Dict()
        for line in ProgressBar(eachline(open(eidname)))
            linesplit = split(line, " ")
            way_id = parse(Int, linesplit[1])
            ids = parse.(Int, split(linesplit[2], ","))
            dict_edges[way_id] = ids
            for id in ids
                push!(used_ids, id)
            end
        end

        # node (required)
        dict_lat_lon = Dict()
        count0, count1 = 0, 0
        for line in ProgressBar(eachline(open(nidname)))
            linesplit = split(line, ",")
            nid = parse(Int, linesplit[1])
            lat, lon = parse.(Float64, linesplit[2:3])

            if nid in used_ids
                dict_lat_lon[nid] = (lat, lon)
            end
        end

        # edge and distance
        dict_dist = Dict()
        remove_ids = []
        for (way_id, way) in dict_edges
            flag = true
            for p in way
                if !haskey(dict_lat_lon, p)
                    flag = false
                    break
                end
            end

            # all nodes are valid
            if flag
                for i = 1:length(way)-1
                    pi, pj = way[i:i+1]
                    lat1, lon1 = dict_lat_lon[pi]
                    lat2, lon2 = dict_lat_lon[pj]
                    dij = dG(lat1, lon1, lat2, lon2)
                    dict_dist[(pi, pj)] = dict_dist[(pj, pi)] = dij
                end
            else
                push!(remove_ids, way_id)
            end
        end

        for way_id in remove_ids
            delete!(dict_edges, way_id)
        end

        # write
        jldopen(outdict, "w") do f
            f["dict_edges"] = dict_edges
            f["dict_lat_lon"] = dict_lat_lon
            f["dict_edge_dist"] = dict_dist
        end
    else
        @info "already exists: $(outdict)"
    end

    return outdict
end
