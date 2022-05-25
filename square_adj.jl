"""
Stuff for initialization of adjacency matrix
"""
# Put a lattice index back onto lattice
function latmod(i,N)
    if i < 1 || i > N
        return i = mod((i-1),N) +1
    end
    return i
end


# Input idx, gives all other indexes which it is coupled to. NN is how many nearest neighbors, 
# can set periodic or not
# rfunc is distance function
function adjEntry(idx, N, hfunc, NN = 1, periodic = true, rfunc = r->1/r^2)::Vector{Tuple{Int32,Float32,Function}}
    (i,j) = idxToCoord(idx, N)
    if periodic
        couple = [(coordToIdx(latmod(i2,N),latmod(j2,N),N), rfunc( sqrt((i-i2)^2 + (j-j2)^2) ), hfunc ) for i2 in (i-NN):(i+NN), j2 in (j-NN):(j+NN) if !(i2 == i && j2 == j) ]
    else
        couple =[ (coordToIdx(i2, j2,N), rfunc( sqrt((i-i2)^2 + (j-j2)^2) ), hfunc) for i2 in (i-NN):(1+NN), j2 in (j-NN):(j+NN) if ( !(i2 == i && j2 == j) && (i2 > 0 && j2 > 0 && i2 <= N && j2 <= N) )]
    end

    return couple
end


# Should also include function!!!!
# Init the adj list of g
function fillAdjList!(adj, N , hfunc , NN =1, periodic = true, rfuncstr = "1/r^2")
    rfunc(r) = Base.invokelatest(eval(Meta.parse("r->"*rfuncstr)),r)

    for idx in 1:N*N
        adj[idx] = adjEntry(idx, N, hfunc, NN, periodic, rfunc)
    end
    
end



# Input g instead of adj list directly
# Should copy all h funcs
initAdjList(g, NN =1, periodic = true, rfunc = r2 -> 1/r2) = initAdjList!(g.adj, g.N , g.hFuncs[1] , NN =1, periodic = true, rfunc = r2 -> 1/r2)