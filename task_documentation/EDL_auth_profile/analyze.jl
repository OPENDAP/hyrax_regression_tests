using CairoMakie
using DataFrames
using StatsBase

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

    # CDF 
    cdf = Figure()
    Axis(cdf[1, 1]; xlabel="Time (s)", title=title * ": CDF of time to return first byte",
        ylabel="% of requests with first byte already returned",
        yticks=(0:0.2:1.0, map(v -> "$(Int(100*v))%", 0:0.2:1.0)),
        xticks=0:0.05:10,
    )
    for g in gdf
        color = colors[findfirst(isequal(first(g.source)), unique(category_labels))]
        ecdfplot!(g.values; color)
    end
    xlims!(xlims...)
    fp = replace(savepath, ".png" => "_cdf.png")
    save(fp, cdf)
    println("\t- CDF plot saved to $fp")

    # Box plot 
    axis = (; xlabel="Time (s)", title=title * ": Time to return first byte",
        yticks=(1:length(labels), labels),
    )
    categories = map(l -> contains(l, "new") ? 1 : 2, df.source)
    b = boxplot(categories, df.values;
        axis,
        show_notch=true,
        orientation=:horizontal,
        show_outliers=false,
        color=colors[categories])
    xlims!(xlims...)
    fp = replace(savepath, ".png" => "_percentiles.png")
    save(fp, b)
    println("\t- Boxplot saved to $fp")
    # return b
    return stats
end

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
