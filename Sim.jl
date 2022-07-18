"""File for all simulation functions. Shouldn't have to be touched by user"""


# For sysimage:
# PackageCompiler.create_sysimage([:Random, :GLMakie, :FileIO, :QML, :Observables, :ColorSchemes, :Images, :DataFrames, :CSV, :CxxWrap, :BenchmarkTools, :Plots]; sysimage_path="JuliaSysimage.dylib", precompile_execution_file="Sim.jl")
using LinearAlgebra, Distributions, Random, GLMakie, FileIO, QML, Observables, ColorSchemes, Images, DataFrames, CSV, CxxWrap
using BenchmarkTools
import Plots as pl
# Qt5QuickControls_jll, Qt5QuickControls2_jll,

include("SquareAdj.jl")
using .SquareAdj

include("WeightFuncs.jl")
using .WeightFuncs

include("IsingGraphs.jl")
using .IsingGraphs

include("Interaction/Interaction.jl")
using .Interaction

include("Analysis.jl")
using .Analysis

include("MCMC.jl") 
using .IsingMetropolis

include("GPlotting.jl")
using .GPlotting

include("Learning/IsingLearning.jl")
using .IsingLearning

""" Helper Functions """

# Insert a value in front of vector and push out last one.
function insertShift(vec::Vector{T}, el::T) where T
    newVec = Vector{T}(undef, length(vec))
    newVec[1:(end-1)] = vec[2:end]
    newVec[end] = el
    return newVec
end

# Spawn a new thread for a function, but only if no thread for that function was already created
# The function is "locked" using a reference to a Boolean value: spawned
function spawnOne(f::Function, spawned::Ref{Bool}, args...)
    # Run function, when thread is finished mark it as not running
    function runOne(func::Function, spawned::Ref{Bool}, args...)
        func(args...)
        spawned[] = false
        GC.safepoint()
    end

    # Mark as running, then spawn thread
    if !spawned[]
        spawned[] = true
        # Threads.@spawn runOne(f,spawned)
        runOne(f,spawned, args...)
    end
end

""" Persistent functions of the simulation """

# Main loop for for MCMC
function updateGraph()
        while running[]
            if !isPaused[] # if sim not paused
                updateMonteCarloIsing!(g,TIs[])
                updates[] += 1
            else
                sleep(0.2)
            end
            GC.safepoint()
        end
end

# Update the graph from the REPL, for debugging
function updateGraphREPL()
    while running[]
    
        if !isPaused[] # if sim not paused
            updateMonteCarloIsing!(g,TIs[])
            updates[] += 1
        else
            yield()
            # sleep(0.2)
        end
    end
end

function startSim()
    Threads.@spawn updateGraph()
end

"""Timed Functions"""
# Updating image of graph
function updateImg()
    img[] = gToImg(g)
end

# Track number of updates per frame
let avgWindow = 60, updateWindow = zeros(Int64,avgWindow), frames = 0
    global function updatesPerFrame()
        updateWindow = insertShift(updateWindow,updates[])
        if frames > avgWindow
            upf[] = round(sum(updateWindow)/avgWindow)
            frames = 0
        end
        frames += 1
        updates[] = 0
    end
end

# Averages M_array over an amount of steps
# Updates magnetization (which is thus the averaged value)
let avg_window = 60, frames = 0
    global function magnetization(g::AbstractIsingGraph,M, M_array)
        avg_window = 60 # Averaging window = Sec * FPS, becomes max length of vector
        M_array[] = insertShift(M_array[], sum(g.state))
        if frames > avg_window
            M[] = sum(M_array[])/avg_window 
            frames = 0
        end 
        frames += 1 
    end
end

""" QML FUNCTIONS """
# Initialize isinggraph and display
function initIsing()
    reInitGraph!(g) 
    M[] = 0
end

function annealing(Ti, Tf, initWait = 30, stepWait = 5; Tstep = .5, T_it = Ti:Tstep:Tf, reInit = true, saveImg = true)
    # Reinitialize
    reInit && initIsing()

    # Set temp and initial wait
    TIs[] = Ti
    sleep(initWait)
    
    for temp in T_it
        TIs[] = temp
        sleep(stepWait)
        if saveImg
            save(File{format"PNG"}("Images/Annealing/Ising T$temp.PNG"), img[])
        end
    end
end

# All functions that are run from the QML Timer
function timedFunctions()
    spawnOne(updateImg, updatingImg)
    spawnOne(updatesPerFrame, updatingUpf)
    spawnOne(magnetization, updatingMag, g,M, M_array)
end

# Add percentage of defects to lattice
addRandomDefectsQML(pDefects) = addRandomDefects!(g,pDefects)

# Draw circle to state
circleToStateQML(i,j,clamp=false) = Threads.@spawn circleToState(g,circ[],i,j,brush[]; clamp, imgsize = size(img[])[1])
circleToStateREPL(i,j, clamp = false) = circleToState(g,circ[],i,j,brush[]; clamp, imgsize = size(img[])[1])

# Sweep temperatures and record magnetization and correlation lengths
# Make an interface for this
function tempSweepQML(TI = TIs[], TF = 13, TStep = 0.5, dpoints = 12, dpointwait = 5, stepwait = 0, equiwait = 0 , saveImg = true)
    if !g.d.defects
        corrF = sampleCorrPeriodic
    else
        corrF = sampleCorrPeriodicDefects
    end
    Threads.@spawn tempSweep(g,TIs,M_array; TI,TF,TStep, dpoints , dpointwait, stepwait, equiwait, saveImg, img=img, analysisRunning=analysisRunning, corrF)
end

function tempSweepQMLRepl(TI = TIs[], TF = 13, TStep = 0.5, dpoints = 12, dpointwait = 5, stepwait = 0, equiwait = 0 , saveImg = true); analysisRunning[] = true; tempSweep(g,TIs,M_array; TI,TF,TStep, dpoints , dpointwait, stepwait, equiwait, saveImg, img=img, analysisRunning=analysisRunning, savelast = true) end

saveGImgQML() = saveGImg(g)

# Save a new circle with size brushR[]
function newCirc()
    circ[] = getOrdCirc(brushR[])
end

""" For QML canvas to show image """
function showlatest(buffer::Array{UInt32, 1}, width32::Int32, height32::Int32)
    buffer = reshape(buffer, size(img[]))
    buffer = reinterpret(ARGB32, buffer)
    buffer .= transpose(img[])
    return
end

showlatest_cfunction = CxxWrap.@safe_cfunction(showlatest, Cvoid, 
                                               (Array{UInt32,1}, Int32, Int32))

