# Ising Graph Representation and functions
__precompile__()

module IsingGraphs
    
include("SquareAdj.jl")
using Random, Distributions, .SquareAdj

include("WeightFuncs.jl")
using .WeightFuncs

export IsingGraph, hIsing, reInitGraph!, coordToIdx, idxToCoord, ising_it, paintPoints!, addDefects!, remDefects!, addDefect!, remDefect!, connIdx, connW

# Aliases
Edge = Pair{Int32,Int32}
Vert = Int32
Weight = Float32
Conn = Tuple{Vert, Weight}

mutable struct IsingGraph
    # Global graph props to be tracked for performance
    N::Int32
    size::Int32
    # Vertices and edges
    state::Vector{Int8}
    adj::Vector{Vector{Conn}}
    # For tracking defects
    aliveList::Vector{Vert}
    defects::Bool
    defectBools::Vector{Bool}
    defectList::Vector{Vert}
    weighted::Bool
end

"""
INITIALIZERS
""" 
    #Initialization using only N
    IsingGraph(N::Int; weighted = false, weightFunc = DefaultIsing()) = 
        IsingGraph(
            N,
            N*N,
            initRandomState(N),
            initSqAdj(N, weightFunc = weightFunc), 
            weighted = weighted
            )

    # Initialize without defects
    IsingGraph(N,size,state,adj; weighted = false) = IsingGraph(N,size,state,adj,[1:size;], false ,[false for x in 1:size],[], weighted)

    #Initialization of graph using a state and adjacency matrix
    IsingGraph(state::Vector{Int8},adj::Dict{Vert,Vector{Vert}}) = let size = length(state)
        IsingGraph(sqrt(size), size, copy(state), adj)
    end

    # Copy graph data to new one
    IsingGraph(g::IsingGraph) = deepcopy(g)

    function reInitGraph!(g::IsingGraph)
        println("Reinitializing graph")
        g.state = initRandomState(g.N)
        g.defects = false
        g.aliveList = [1:g.size;]
        g.defectBools = [false for x in 1:g.size]
        g.defectList = []
    end

"""
Methods
"""
    # Matrix Coordinates to vector Coordinates
    @inline  function coordToIdx(i,j,N)
        return (i-1)*N+j
    end

    coordToIdx((i,j),N) = coordToIdx(i,j,N)
    # Go from idx to lattice coordinates
    @inline function idxToCoord(idx::Int,N)
        return ((idx-1)÷N+1,(idx-1)%N+1)
    end

    # Initialization of state
    function initRandomState(N)::Vector{Int8}
        return [sample([-1,1]) for x in 1:(N*N) ]
    end

    # Returns an iterator over the ising lattice
    # If there are no defects, returns whole range
    # Otherwise it returns all alive spins
    function ising_it(g::IsingGraph)
        if !g.defects
            it::UnitRange{Int32} = 1:g.size
            return it
        else
            return g.aliveList
        end

    end

# Get weight of connection
@inline function connIdx(conn::Conn)
    conn[1]
end

# Get weight of connection
@inline function connW(conn::Conn)
    conn[2]
end

# Initialization of adjacency matrix for a given ND
function initSqAdj(N; weightFunc = DefaultIsing())
    adj = Vector{Vector{Conn}}(undef,N^2)
    fillAdjList!(adj,N, weightFunc)
    return adj
end


""" Setting Elements and defects """

""" Adding Defects """

    """Helper Functions"""

        # Searches backwards from idx in list and removes item
        # This is because spin idx can only be before it's own index in aliveList
        function revRemoveSpin!(list,spin_idx)
            init = min(spin_idx, length(list)) #Initial search index
            for offset in 0:(init-1)
                @inbounds if list[init-offset] == spin_idx
                    deleteat!(list,init-offset)
                    return init-offset # Returns index where element was found
                end
            end
        end

        # Zip together two ordered lists into a new ordered list    
        function zipOrderedLists(vec1::Vector{T},vec2::Vector{T}) where T
            # result::Vector{T} = zeros(length(vec1)+length(vec2))
            result = Vector{T}(undef, length(vec1)+length(vec2))

            ofs1 = 1
            ofs2 = 1
            while ofs1 <= length(vec1) && ofs2 <= length(vec2)
                @inbounds el1 = vec1[ofs1]
                @inbounds el2 = vec2[ofs2]
                if el1 < el2
                    @inbounds result[ofs1+ofs2-1] = el1
                    ofs1 += 1
                else
                    @inbounds result[ofs1+ofs2-1] = el2
                    ofs2 += 1
                end
            end
    
            if ofs1 <= length(vec1)
                @inbounds result[ofs1+ofs2-1:end] = vec1[ofs1:end]
            else
                @inbounds result[ofs1+ofs2-1:end] = vec2[ofs2:end]
            end
            return result
        end

        # Deletes els from vec
        # Assumes that els are in vec!
        function remOrdEls(vec::Vector{T}, els::Vector{T}) where T
            # result::Vector{T} = zeros(length(vec)-length(els))
            result = Vector{T}(undef, length(vec)-length(els))
            
            it_idx = 1
            num_del = 0
            for el in els
                    while el != vec[it_idx]
                
                    result[it_idx - num_del] = vec[it_idx]
                    it_idx +=1
                end
                    num_del +=1
                    it_idx += 1
            end
                result[(it_idx - num_del):end] = vec[it_idx:end]
            return result
        end

        # Remove first element equal to el and returns correpsonding index
        function removeFirst!(list,el)
            for (idx,item) in enumerate(list)
                if item == el
                    deleteat!(list,idx)
                    return idx
                end
            end
        end

    """Actually Removing and adding defects"""
    
        # Adding a defect to lattice
        function addDefects!(g,spin_idxs::Vector{T}) where T <: Integer
            # Only keep elements that are not defect already
            # @inbounds d_idxs::Vector{Int32} = spin_idxs[map(!,g.defectBools[spin_idxs])]
            d_idxs = spin_idxs[map(!,g.defectBools[spin_idxs])]

            if isempty(d_idxs)
                return
            end
            
            if length(spin_idxs) > 1
                g.defectList = zipOrderedLists(g.defectList,d_idxs)  #Add els to defectlist
                g.aliveList = remOrdEls(g.aliveList,d_idxs) #Remove them from alivelist
                
            else #Faster for singular elements
                #Remove item from alive list and start searching backwards from spin_idx
                    # Since aliveList is sorted, spin_idx - idx_found gives number of smaller elements in list
                rem_idx = revRemoveSpin!(g.aliveList,spin_idxs[1])
                insert!(g.defectList,spin_idxs[1]-rem_idx+1,spin_idxs[1])
            end

            # Mark corresponding spins to defect
            # @inbounds g.defectBools[d_idxs] .= true
            g.defectBools[d_idxs] .= true

            # If first defect, mark lattice as containing defects
            if g.defects == false
                g.defects = true
            end

            # Set states to zero
            # @inbounds g.state[d_idxs] .= 0
            g.state[d_idxs] .= 0

        end

        # Removing defects, insert ordered list!
        function remDefects!(g, spin_idxs::Vector{T}) where T <: Integer
            
            # Only keep ones that are actually defect
            @inbounds d_idxs = spin_idxs[g.defectBools[spin_idxs]]
            if isempty(d_idxs)
                return
            end
        
            # Remove defects from defect list and add to aliveList
            # Assumes that els are in list!
            if length(spin_idxs) > 1
                g.aliveList = zipOrderedLists(g.aliveList, d_idxs)
                g.defectList = remOrdEls(g.defectList,d_idxs)
            else    #Is faster for singular elements
                # Add to alive list
                # Adds it to original index offset by how many smaller numbers are also removed
                rem_idx = removeFirst!(g.defectList,spin_idxs[1]) 
                insert!(g.aliveList,spin_idxs[1]-(rem_idx-1),spin_idxs[1])
            end

            # Spins not defect anymore
            @inbounds g.defectBools[d_idxs] .= false
        
            if isempty(g.defectList) && g.defects == true
                g.defects = false
            end

        end

        remDefect!(g, spin_idx::T) where T <: Integer = remDefects!(g,[spin_idx]) 
        addDefect!(g, spin_idx::T) where T <: Integer = addDefects!(g,[spin_idx]) 
        
        # Lattice indexing
        addDefect!(g,i,j) = addDefect!(g,coordToIdx(i,j,g.N))
        remDefect!(g,i,j) = remDefect!(g,coordToIdx(i,j,g.N))

        # Removes Multiple Defects
        function remDefects!(g,idxs::Vector{Any})
            for idx in idxs
                remDefect!(g,idx)
            end
        end

        # Removes All defects
        function restoreState!(g)
            remDefects!(g,g.defectList)
        end

        # Restores all defects to random states 
        function restoreDefects!(g)
            nDefects = length(g.defectList) # number of defects to be restored
            states = initRandomState(nDefects) # initialize a corresponding number of random states
            @inbounds  g.state[g.defectList] .= states  # set those states to the random states
            g.aliveList = zipOrderedLists(g.aliveList,g.defectList) # Zip lists into each other, making an ordered list
            g.defectList = [] # Remove defects
        end


"""Setting Elements"""

    """Backend """
        # Set element to -1 or +1, shouldn't be 0
        function setEls!(g,spin_idxs, brush)
            # First remove defect if it was defect
            remDefects!(g,spin_idxs)
            # Then set element
            @inbounds g.state[spin_idxs] .= brush
        end

        setEl!(g,spin_idx,brush) = setEls!(g, [spin_idx], brush)
        setEl!(g,i,j,brush) =  setEl!(g,coordToIdx(i,j,g.N),brush)

    """ User Functions """
        # Set points either to element or defect
        function paintPoints!(g, coords , brush)
            idxs::Vector{Int32} = coordToIdx.(coords,g.N)
            if brush != 0
                setEls!(g,idxs,brush)
            else
                addDefects!(g,idxs)
            end
        end

        paintPoint!(g,i,j,brush ) = paintPoints!(g, coordToIdx(i,j,g.N) , brush)



""" Get Hamiltonian """

function sortedPair(idx1::Integer,idx2::Integer):: Pair{Integer,Integer}
    if idx1 < idx2
        return idx1 => idx2
    else
        return idx2 => idx1
    end
end

function getH(g::IsingGraph, spindex::Integer ; weighted::Bool = false)
    @inbounds conns = g.adj[spindex]
    E = 0
    @inbounds state = g.state[spindex]
    # Energy always -J * state1 * state2
    if !weighted
        for conn in conns
            @inbounds E += -state*g.state[conn]
        end
    else
        for conn in conns
           @inbounds E += -g.eprops[sortedPair(spindex,conn)][:weight]*state*g.state[conn]
        end
    end

    return E
end

end
