ENV["QSG_RENDER_LOOP"] = "basic"

using LinearAlgebra, Distributions, Random, GLMakie, FileIO, QML, Observables, ColorSchemes, Images, DataFrames, CSV, CxxWrap
using BenchmarkTools
import Plots as pl
# Qt5QuickControls_jll, Qt5QuickControls2_jll,


include("IsingGraphs.jl")
using .IsingGraphs

include("Interaction/Interaction.jl")
using .Interaction
include("Analysis.jl")
using .Analysis

include("MCMC.jl") 
include("GPlotting.jl")
# using .GPlotting

qmlfile = joinpath(dirname(Base.source_path()), "qml", "Ising.qml")

#Observables
const running = Observable(true)
const gSize = Observable(512)
const NIs = Observable(gSize[])
const TIs = Observable(1.0)
const JIs = Observable(1.0)
const pDefects = Observable(0) #percentage of defects to be added
const isPaused = Observable(false) 
const brush = Observable(0)
const brushR = Observable( Int(round(NIs[]/10)) )
const circ  = Observable(getOrdCirc(brushR[]))
const M = Observable(0.0)
const M_array = []

const updates = Observable(0)

# Global Variables
const g = IsingGraph(NIs[])
const img = Observable(gToImg(g))

# Basically a dict of all properties
const pmap = JuliaPropertyMap(
    "running" => running,
    "gSize" => gSize,
    "NIs" => NIs, 
    "TIs" => TIs, 
    "JIs" => JIs, 
    "isPaused" => isPaused, 
    "pDefects" => pDefects,
    "brush" => brush,
    "brushR" => brushR,
    "M" => M,
)

"""QML Functions"""
# Initialize isinggraph and display
function initIsing()
    reInitGraph!(g) 
    M[] = 0
end

# Main loop for for MCMC
function updateGraph()
    Threads.@spawn begin
        while running[]
        
            if !isPaused[] # if sim not paused
                updateMonteCarloQML!(g,TIs[],JIs[])
                updates[] += 1
            else
                sleep(0.2)
            end
            
        end
    end
end

function updateGraphREPL()
        while running[]
        
            if !isPaused[] # if sim not paused
                updateMonteCarloQML!(g,TIs[],JIs[])
                updates[] += 1
            else
                sleep(0.2)
            end
            
        end
end

# Functions that happen on time intervals
function timedFunctions()
    Threads.@spawn begin
        tfs = time()
        while running[]
            if time() - tfs > 0.01
                updateImg(img)
            end
            sleep(0.001)
        end
        
    end
end

function updateImg(img)
    img[] = gToImg(g,gSize[])
end


function startSim()
    timedFunctions()
    updateGraph()
end

analysis_func = Threads.@spawn on(updates) do val
# analysis_func = on(updates) do val   
    if updates[] > g.size
        begin
            magnetization(g,M,M_array)
            updates[] = 0
        end
    end
end

# Draw circle to state
circleToStateQML(i,j) = Threads.@spawn circleToState(g,circ[],i,j,brush[])
circleToStateREPL(i,j) = circleToState(g,circ[],i,j,brush[])

addRandomDefectsQML() = Threads.@spawn addRandomDefects!(g,pDefects)

# Make an interface for this
tempSweepQML() = Threads.@spawn CSV.write("sweepData.csv", dataToDF(tempSweep(g,TIs,M_array, 7, 0.1, 12, 2, 5)))

# New circle
function newCirc()
    circ[] = getOrdCirc(brushR[])
end

@qmlfunction println
@qmlfunction addRandomDefectsQML
@qmlfunction initIsing
@qmlfunction circleToStateQML
@qmlfunction startSim
@qmlfunction tempSweepQML
@qmlfunction newCirc

function showlatest(buffer::Array{UInt32, 1}, width32::Int32, height32::Int32)
    buffer = reshape(buffer, size(img[]))
    buffer = reinterpret(ARGB32, buffer)
    buffer .= img[]
    return
  end


# Start Simulation
startSim()

showlatest_cfunction = CxxWrap.@safe_cfunction(showlatest, Cvoid, 
                                               (Array{UInt32,1}, Int32, Int32))

# loadqml( qmlfile, obs =  pmap, ); exec_async() 

loadqml( qmlfile, obs =  pmap, showlatest = showlatest_cfunction); exec_async()






