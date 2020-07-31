using DataFrames
using CSV
using Plots
using SimpleSDMLayers
using Statistics

include(joinpath("..", "lib", "zscores.jl"))

mangal = CSV.read(joinpath("data", "network_data.csv"))

# Remove everything that has a missing latitude, longitude, or bc1
bcdata = dropmissing(mangal, [:latitude, :longitude, :bc1]; disallowmissing = true)

prdata = bcdata[bcdata.predation .> 0, :]
padata = bcdata[bcdata.parasitism .> 0, :]
mudata = bcdata[bcdata.mutualism .> 0, :]

# Transform the bioclim layers
bc = worldclim(1:19; resolution=10.0, bottom=-60.0)
zbc = z.(bc)

function distmap(intdata; k=5)
    geo_dis = similar(first(bc))
    env_dis = similar(first(bc))
    all_cells = [(b.longitude, b.latitude) for b in eachrow(intdata)]
    bc_obs = ones(Float64, (length(bc), length(all_cells)))
    for j in 1:length(all_cells)
        try
            this_bc = [zb[all_cells[j]...] for zb in zbc]
            bc_obs[:,j] = this_bc
        catch
        end
    end
    Base.Threads.@threads for lon in longitudes(geo_dis)
        for lat in latitudes(geo_dis)
            cell = (lon, lat)
            if !isnothing(geo_dis[cell...])
                # Climatic distance
                cell_bc_values = [zb[cell...] for zb in zbc]
                cell_bc_distance = vec(sum(sqrt.((bc_obs'.-cell_bc_values').^2.0); dims=2))
                env_dis[cell...] = Float32(mean(sort(cell_bc_distance)[1:k]))
                # Haversine distance
                all_dist = [SimpleSDMLayers.haversine(c, cell) for c in all_cells]
                geo_dis[cell...] = Float32(mean(sort(all_dist)[1:k]))
            end
        end
    end
    return (geo_dis, env_dis)
end

geo_par, env_par = distmap(padata)
geo_mut, env_mut = distmap(mudata)
geo_prd, env_prd = distmap(prdata)

p1 = heatmap(log1p(geo_par), c=:viridis)
p2 = heatmap(log1p(geo_mut), c=:viridis)
p3 = heatmap(log1p(geo_prd), c=:viridis)
plot(p1, p2, p3)
savefig(joinpath("figures", "geo-distance.png"))
