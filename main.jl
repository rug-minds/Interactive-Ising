ENV["QSG_RENDER_LOOP"] = "basic"

# Need to add QML#qt6
using LinearAlgebra, Distributions, Random, GLMakie, FileIO, QML, Observables, ColorSchemes, Images, DataFrames, CSV, CxxWrap
using BenchmarkTools
import Plots as pl

# Add files
include("CreateFunc.jl")
import .CreateFunc as cf

include("ising_graph.jl")
include("ising_update.jl")
include("square_adj.jl")
include("plotting.jl")
include("interaction.jl")
include("analysis.jl")


#using Qt5QuickControls_jll, Qt5QuickControls2_jll,


qmlfile = joinpath(dirname(Base.source_path()), "qml", "Ising.qml")

# Observables & global variables
running = Observable(true) #not used right now, for closing background processes
NIs = Observable(3) #Graph size
TIs = Observable(1.0) #temperature
JIs = Observable(1.0) #interaction strength
pDefects = Observable(0) #percentage of defects to be added
isPaused = Observable(false) #MCMC updating or not
# Drawing on sim
brush = Observable(0) # set spins to -1, 0 or 1
brushR = Observable( Int(round(NIs[]/10)) ) #Radius of brush
# Magnetization
M = Observable(0.0)
M_array = []
# Graph and image
g = IsingGraph(NIs[]) #Graph itself
img = Observable(gToImg(g)) #image
# Track how many updates for functions that only need to run every so often
updates = Observable(0)



# Basically a dict of all properties, for QML interface
pmap = JuliaPropertyMap(
    "running" => running,
    "NIs" => NIs, 
    "TIs" => TIs, 
    "JIs" => JIs, 
    "isPaused" => isPaused, 
    "pDefects" => pDefects,
    "brush" => brush,
    "brushR" => brushR,
    "M" => M,
)

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

# Update the image
function updateImg(img)
    img[] = gToImg(g)
end


function startSim()
    timedFunctions()
    updateGraph()
end

# For analysis every so many loops
analysis_func = Threads.@spawn on(updates) do val
    if updates[] > g.size #if as many spins as in graph are updated
        begin
            magnetization(g,M,M_array)
            updates[] = 0
        end
    end
end

"""QML Functions"""
# Reinitialize the graph and analysis functions which average over a timerange
function initIsing()
    reInitGraph!(g) 
    M[] = 0
end

# Draw circle to state
circleToStateQML(i,j) = Threads.@spawn circleToState(g,i,j,brushR[],brush[])

# Add random defects to graph
addRandomDefectsQML() = Threads.@spawn addRandomDefects!(g,pDefects)

# Do a sweep over temperatures and gather Magnetization and Correlationlength data
tempSweepQML() = Threads.@spawn CSV.write("sweepData.csv", dataToDF(tempSweep(g,TIs,M_array)))

# Functions that can be called from QML
@qmlfunction println
@qmlfunction addRandomDefectsQML
@qmlfunction initIsing
@qmlfunction circleToStateQML
@qmlfunction startSim
@qmlfunction tempSweepQML

# For showing the image in the QML canvas
function showlatest(buffer::Array{UInt32, 1}, width32::Int32, height32::Int32)
    buffer = reshape(buffer, size(img[]))
    buffer = reinterpret(ARGB32, buffer)
    buffer .= img[]
    return
  end

showlatest_cfunction = CxxWrap.@safe_cfunction(showlatest, Cvoid, (Array{UInt32,1}, Int32, Int32))

# Start Simulation
# startSim()


# loadqml( qmlfile, obs =  pmap, showlatest = showlatest_cfunction); exec() #doesn't work for some reason

# loadqml( qmlfile, obs =  pmap, showlatest = showlatest_cfunction); exec_async()








