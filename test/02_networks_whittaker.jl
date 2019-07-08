module MangalSuppMatWhittakerBiome

using DataFrames
using CSV
using Plots

mangal = CSV.read("networkinfo.dat")

# Remove everything that has a missing date
whittaker = dropmissing(mangal, [:bc1, :bc12]; disallowmissing = true)

para = whittaker[whittaker.parasitism .> 0, :]
mutu = whittaker[whittaker.mutualism .> 0, :]
pred = whittaker[whittaker.predation .> 0, :]

n_para = size(para)[1]
n_mutu = size(mutu)[1]
n_pred = size(pred)[1]

# And plot 
scatter(para.bc12./10.0, para.bc1, lab="Parasitism (n=$n_para)", c=:black)
scatter!(mutu.bc12./10.0, mutu.bc1, lab="Mutualism (n=$n_mutu)", c=:grey)
scatter!(pred.bc12./10.0, pred.bc1, lab="Predation (n=$n_pred)", c=:white)
xaxis!("Annual precipitation", [0.0, 400.0])
yaxis!("Average temperature", :flip, [-20.0,30.0])
savefig(joinpath(@__DIR__, "..", "figures", "figure_02.pdf"))

end
