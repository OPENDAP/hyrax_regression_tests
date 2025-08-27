using Pkg
Pkg.activate(@__DIR__)
using DataFrames
using JSON3
using Statistics
using CairoMakie
cd(@__DIR__)     # TODO - don't leave this!!

# log_path = "bes_log.json" # test file!
log_path = "cloudwatch_2025-08-26_hyrax-1835_bes-v3.json"

@info "Loading data from $log_path..."
json = JSON3.read(log_path)
logs = Dict()
if json isa JSON3.Object
    # Came from AWS, rather than locally!
    messages = [JSON3.parse(e.message) for e in json.events]
    for t in unique(j["hyrax-type"] for j in messages)
        logs[t] = DataFrame(filter(l -> l["hyrax-type"] == t, messages))
    end
else
    for t in unique(j["type"] for j in json)
        logs[t] = DataFrame(filter(l -> l["type"] == t, json))
    end
end

# Clean-up column names to make more usable later
for k in keys(logs)
    rename!(s -> replace(s, "hyrax-" => "", "-" => "_"), logs[k])
end

@info "Processing profiling logs..."
if "timing" in keys(logs)
    df_profiling = filter("timer_name" => startswith("Profile timing"), logs["timing"])
    logs["timing"] = filter("timer_name" => !startswith("Profile timing"), logs["timing"])
    if nrow(logs["timing"]) == 0
        delete!(logs, "timing")
    end

    parse_timer_name = str -> begin
        str = replace(str, "Profile timing: " => "")
        sp = split(str, " - "; limit=2)
        details = length(sp) == 2 ? last(sp) : ""
        return first(sp), details
    end
    transform!(df_profiling, :timer_name => ByRow(parse_timer_name) => [:action, :details])
    select!(df_profiling, Not(:timer_name))
    logs["profiling"] = df_profiling
end

print("Number of log lines per type:")
for k in keys(logs)
    str = lpad(k * ": ", 14)
    println("\t$str$(nrow(logs[k]))")
end

print("Example of first entry from each log type:")
for type in keys(logs)
    println("-> $(uppercase(type)):")
    row = first(logs[type])
    for k in names(logs[type])
        println("\t$k: \t$(row[k])")
    end
    println()
end

print("Number of request_id")
request_ids = []
for k in keys(logs)
    k == "start-up" && continue
    append!(request_ids, unique(logs[k].request_id))
end
@info "Total number of request ids: $(length(unique(request_ids)))"

# Let's do some exploring!
profile_logs = logs["profiling"]
transform!(profile_logs,
    :action => ByRow(a -> replace(a, "Request redirect url" => "Get signed url from TEA", "Request" => "Get", "Handle" => "Process", "unconstrained" => "")) => :action)
@info "Table Summary" num_requests = length(unique(profile_logs.request_id)) log_count = nrow(profile_logs)
combine(groupby(profile_logs, :action), nrow => "log count",
    :elapsed_us => (arr -> median(arr) / 1_000_000) => "median duration [s]",
    :elapsed_us => (arr -> maximum(arr) / 1_000_000) => "max duration [s]")

function plot_profile_rainclouds(df; xlims=(nothing, nothing), title, savepath)
    category_labels = df.source
    labels = unique!(select(df, :source)).source
    colors = Makie.wong_colors()
    axis = (; xlabel="Time (s)", title,
        yticks=(1:length(labels), labels),
    )
    p = rainclouds(category_labels, df.values;
        axis,
        figure=(size=(800, 400),),
        cloud_width=0.5,
        clouds=hist,
        orientation=:horizontal,
        hist_bins=2000,
        color=colors[indexin(category_labels, unique(category_labels))])
    xlims!(xlims...)
    save(savepath, p)
    println("\t- Plot saved to $savepath")
    return nothing
end


# Let's plot the non-superchunks
df_sans_superchunks = select(profile_logs, :action => :source,
    :elapsed_us => ByRow(v -> v / 1_000_000) => :values)
# filter!(:source => !contains("SuperChunk"), df_sans_superchunks)
plot_profile_rainclouds(df_sans_superchunks; title="Request profiling", savepath="profile_raincloud.png", xlims=(nothing, nothing))
plot_profile_rainclouds(df_sans_superchunks; title="Request profiling (zoomed)", savepath="profile_raincloud_zoomed.png", xlims=(0, 3))

# Okay, let's look at just the superchunks 
_parse_details = (str) -> begin
    str = replace(str, " - Using multithreading" => "")
    strs = split(str, " - ")
    byte_str = first(split(strs[end-1], " "))
    chunk_str = first(split(strs[end], " "))
    return parse(Int, byte_str), parse(Int, chunk_str)
end

df_sc = filter(:action => contains("SuperChunk"), profile_logs)
df_sc = select(df_sc,
    :action => ByRow(a -> contains(a, "Handle") ? "Process" : "Fetch") => :action,
    :elapsed_us => ByRow(v -> v / 1_000_000) => :sec,
    :details => ByRow(_parse_details) => [:bytes, :num_chunks])

title = "SuperChunk handling"
savepath = "superchunk_scatter.png"
axis = (; xlabel="Time (s)", title)
# yticks=(1:length(labels), labels),
p = scatter(df_sc.sec, df_sc.num_chunks;
    axis,
    color=:blue)
scatter!(df_sc.sec, df_sc.bytes; color=:red)
save(savepath, p)
println("\t- Plot saved to $savepath")
p

# TODO: plot directed graph 
