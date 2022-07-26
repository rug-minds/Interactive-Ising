push!(LOAD_PATH, pwd())
push!(LOAD_PATH, pwd()*"/Interaction")
push!(LOAD_PATH, pwd()*"/Learning")


using IsingSim
using GPlotting
using IsingGraphs
using Interaction
using IsingMetropolis
using WeightFuncs
using Analysis
using Distributions
using IsingLearning

include("WeightFuncsCustom.jl")

weightFunc = isingNN2
# setAddDist!(weightFunc, Normal(0,0.1))

const sim = Sim(
    continuous = true, 
    graphSize = 84, 
    weighted = true;
    weightFunc
    )

g = sim(true);
