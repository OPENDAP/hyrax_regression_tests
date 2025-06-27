using CairoMakie
using DataFrames
using StatsBase

SERVER_ENV_NAME = get(ARGS, 1, "HYRAX_SERVER")

function plot_data(df; xlims=(nothing, nothing), title, savepath)
    category_labels = df.source
    labels = unique!(select(df, :source)).source
    colors = Makie.wong_colors()
    axis = (; xlabel="Time (s)", title=title * ": Time to return first byte",
        yticks=(1:length(labels), labels),
    )
    p = rainclouds(category_labels, df.values;
        axis,
        cloud_width=0.5,
        clouds=hist,
        orientation=:horizontal,
        hist_bins=1000,
        color=colors[indexin(category_labels, unique(category_labels))])
    xlims!(xlims...)
    save(savepath, p)
    println("\t- Plot saved to $savepath")

    gdf = groupby(df, :source)
    stats = combine(gdf, :values => median => :median,
        :values => mean => :mean,
        :values => std => :std,
        :values => (v -> percentile(v, 10)) => :percentile10,
        :values => (v -> percentile(v, 50)) => :percentile50,
        :values => (v -> percentile(v, 90)) => :percentile90,
        :values => (v -> percentile(v, 99)) => :percentile99)
    sort!(stats, :source)
    transform!(stats, :source => ByRow(s -> first(split(s, " \n"))), renamecols=false)
    return stats
end

if isfile("local_hr_keys.txt")
    @info "Plotting local data"
    fileset = [("local_hr_keys.txt", "JWKS auth \n(new)"),
        ("local_hr_nokeys.txt", "EDL auth \n(original)")]
    df = DataFrame()
    for (filename, label) in fileset
        append!(df, DataFrame(; values=parse.(Float32, readlines(filename)),
            source=label))
    end
    sort!(df, [:source], rev=true)
    stats = plot_data(df; title="Local hyrax (Boston)", savepath="local_hyrax_boston.png")
    plot_data(df; xlims=(0, 0.1), title="Local hyrax (Boston)", savepath="local_hyrax_boston_zoomed.png")
    show(stats)
    println("")
    println("")
else
    @warn "Not analyzing local data; data not found"
end

if isfile("$(SERVER_ENV_NAME)_hr_keys.txt")
    @info "Analyzing data from `$SERVER_ENV_NAME`"
    fileset = [("$(SERVER_ENV_NAME)_hr_keys.txt", "JWKS auth \n(new)"),
        ("$(SERVER_ENV_NAME)_hr_nokeys.txt", "EDL auth \n(original)")]
    df = DataFrame()
    for (filename, label) in fileset
        append!(df, DataFrame(; values=parse.(Float32, readlines(filename)),
            source=label))
    end
    stats = plot_data(df; title=SERVER_ENV_NAME, savepath="$(SERVER_ENV_NAME).png")
    plot_data(df; xlims=(0.3, 1.5), title=SERVER_ENV_NAME, savepath="$(SERVER_ENV_NAME)_zoomed.png")
    show(stats)
    println("")
    println("")
else
    @warn "Not analyzing `$(SERVER_ENV_NAME)` data; `$(SERVER_ENV_NAME)_hr_keys.txt` data not found"
end