""" 

Define weighting functions here
Should be a function of the radius dr

"""
__precompile__()

module WeightFuncs

using Distributions

export WeightFunc, setAddDist!, setMultDist!, defaultIsingWF, altWF, altCrossWF, randWF

# Assuming one method,
# Returns symbols of argnames
function func_argnames(f::Function)
    ml = collect(methods(f))
    return Base.method_argnames(last(ml))[2:end]
end


mutable struct WeightFunc
    f::Function
    NN::Integer
    periodic::Bool
    invoke::Function
    addTrue::Bool
    multTrue::Bool
    addDist::Any 
    multDist::Any

    function WeightFunc(func::Function, ; NN::Integer)
        invoke(dr,i,j) = func(;dr,i,j)
        return new(func,Int8(NN), true, invoke, false, false)
    end

end


# Add an additive distribution
function setAddDist!(weightFunc, dist)
    weightFunc.addTrue = true
    weightFunc.addDist = dist

    
    if !weightFunc.multTrue
        inv = (dr,i,j) -> rand(weightFunc.addDist) + weightFunc.f(;dr,i,j)
    else
        inv = (dr,i,j) -> rand(weightFunc.multDist)*weightFunc.f(;dr,i,j)+rand(weightFunc.addDist)
    end

    weightFunc.invoke = inv
    
end

# Add an additive distribution
function setMultDist!(weightFunc, dist)
    weightFunc.multTrue = true
    weightFunc.multDist = dist

    if !weightFunc.addTrue
        inv = (dr,i,j) -> rand(weightFunc.multDist)*weightFunc.f(;dr,i,j)
    else
        inv = (dr,i,j) -> rand(weightFunc.multDist)*weightFunc.f(;dr,i,j)+rand(weightFunc.addDist)
    end

    weightFunc.invoke = inv
end

# Default ising Function
defaultIsingWF =  WeightFunc(
    (;dr, _...) -> dr == 1 ? 1. : 0., 
    NN = 1
)

altWF = WeightFunc(
    (;dr, _...) ->
        if dr % 2 == 1
            return 1.0*1/dr^2
        elseif dr % 2 == 0
            return -1*1/dr^2
        else
            return 1/dr^2
        end,
    NN  = 2
)

altCrossWF = WeightFunc(
    (;dr, _...) ->
        if dr % 2 == 1
            return -1
        elseif dr % 2 == 0
            return 1
        else
            return 0
        end,
    NN = 2
)

randWF = WeightFunc(
    (;dr, _...) ->
        if dist == nothing
            return rand()
        else
            return rand(dist)
        end,
    NN = 1
)


""" Old """
# Use distribution centered around zero
function randomizeWeights(dr, func , dist)::Float32
    weight = func(dr)
    if weight == 0
        return 0.
    else
        return weight + rand(dist)
    end
end

end


