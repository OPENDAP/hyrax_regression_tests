using CairoMakie
using DataFrames
using StatsBase

SERVER_ENV_NAME = get(ARGS, 1, "HYRAX_SERVER")

function plot_data(df; xlims=(nothing, nothing), title, savepath)
    category_labels = df.source
    labels = unique!(select(df, :source)).source
    colors = Makie.wong_colors()
    axis = (; xlabel="Time (s)", title,
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
    return p
end

function plot_cdf_time_to_first_byte(; df, stats, gdf, xlims=(nothing, nothing), title, savepath_prefix)
    # CDF 
    cdf = Figure()
    category_labels = df.source
    labels = unique!(select(df, :source)).source
    Axis(cdf[1, 1]; xlabel="Time (s)", title=title * ": CDF of time to return first byte",
        ylabel="% of requests with first byte already returned",
        yticks=(0:0.2:1.0, map(v -> "$(Int(100*v))%", 0:0.2:1.0)),
        xticks=0:0.05:10,
    )
    colors = Makie.wong_colors()
    for g in gdf
        color = colors[findfirst(isequal(first(g.source)), unique(category_labels))]
        ecdfplot!(g.values; color)
    end
    xlims!(xlims...)
    fp = savepath_prefix * "_cdf.png"
    save(fp, cdf)
    println("\t- CDF plot saved to $fp")

    # Box plot 
    f = Figure(size=(600, 300))
    axis = Axis(f[1, 1]; xlabel="Time (s)", title=title * ": Time to return first byte",
        yticks=(1:length(labels), labels),
    )
    categories = map(l -> contains(l, "new") ? 1 : 2, df.source)
    boxplot!(axis, categories, df.values;
        range=1.5,
        # strokecolor=:black,
        strokewidth=:1,
        whiskerwidth=0.5,
        orientation=:horizontal,
        show_outliers=false,
        color=colors[categories])
    xlims!(xlims...)
    textlabel!(axis, Point2f(stats[1, :percentile50], 1); text="*Box denotes interquartile range (IQR)\n*Whiskers span 1.5*IQR", justification=:left)
    fp = savepath_prefix * "_percentiles.png"
    save(fp, f)
    println("\t- Boxplot saved to $fp")
    return f
end

function read_timing_files(fileset)
    df = DataFrame()
    for (filename, label) in fileset
        append!(df, DataFrame(; values=parse.(Float32, readlines(filename)),
            source=label))
    end
    sort!(df, [:source], rev=true)
    @info df

    # Stats
    gdf = groupby(df, :source)
    stats = combine(gdf, :values => median => :median,
        :values => mean => :mean,
        :values => std => :std,
        :values => minimum => :min,
        :values => maximum => :max,
        :values => (v -> percentile(v, 10)) => :percentile10,
        :values => (v -> percentile(v, 50)) => :percentile50,
        :values => (v -> percentile(v, 90)) => :percentile90,
        :values => (v -> percentile(v, 99)) => :percentile99)
    sort!(stats, :source)
    transform!(stats, :source => ByRow(s -> first(split(s, " \n"))), renamecols=false)

    d = select(stats, Not(:source))
    diffs = d[2:2,:] .- d[1:1,:]
    @info diffs
    diffs[!,:source] .= "Change [seconds]"
    append!(stats, diffs)

    show(stats)
    println("")
    println("")
    return (; df, stats, gdf)
end

if isfile("local_hr_keys.txt")
    @info "Plotting local data"

    fileset = [("local_hr_keys.txt", "JWKS auth \n(new)"),
        ("local_hr_nokeys.txt", "EDL auth \n(original)")]
    results = read_timing_files(fileset)
    title = "Local hyrax (Boston): Time to return first byte"
    savepath_prefix = "local_hyrax_boston"
    plot_data(results.df; title, savepath = savepath_prefix * ".png")
    plot_data(results.df; title=title * "- zoomed", xlims=(0, 0.1), savepath=savepath_prefix * "_zoomed.png")

    plot_cdf_time_to_first_byte(; results..., title, savepath_prefix)
    plot_cdf_time_to_first_byte(; results..., xlims=(0.3, 1.5), title=title * " - zoomed", savepath_prefix=savepath_prefix * "_zoomed.png")

else
    @warn "Not analyzing local data; data not found"
end

if isfile("$(SERVER_ENV_NAME)_hr_keys.txt")
    @info "Analyzing data from `$SERVER_ENV_NAME`"
    fileset = [("$(SERVER_ENV_NAME)_hr_keys.txt", "JWKS auth \n(new)"),
        ("$(SERVER_ENV_NAME)_hr_nokeys.txt", "EDL auth \n(original)")]
    results = read_timing_files(fileset)
    title=SERVER_ENV_NAME * ": Time to return first byte"

    savepath_prefix = SERVER_ENV_NAME
    plot_data(results.df; title, savepath=savepath_prefix * ".png")
    plot_data(results.df; xlims=(0.3, 1.5), title=title * " - zoomed", savepath=savepath_prefix * "_zoomed.png")

    plot_cdf_time_to_first_byte(; results..., title, savepath_prefix)
    plot_cdf_time_to_first_byte(; results..., xlims=(0.3, 1.5), title=title * " - zoomed", savepath_prefix=savepath_prefix * "_zoomed")

else
    @warn "Not analyzing `$(SERVER_ENV_NAME)` data; `$(SERVER_ENV_NAME)_hr_keys.txt` data not found"
end
