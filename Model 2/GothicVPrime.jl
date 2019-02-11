#Julia file hosting the function definition of GothicVPrime
#GothicVPrime takes in a saving value and returns marginal value of end of period wealth(savings)

function GothicVPrime(stateGrid::Array{Tuple{Float64,Float64},2},age::Int64)
    #stateGrid is a 2d array whose entries are a pair of annuity/saving Values
    #For each value in this vector, we want the corresponding marginal utility of end of period wealth

    #EUP is short for expected utility prime. Note that there is no uncertainty so expected is redundant.
    EUP = zeros(size(stateGrid))

    #no need to perform a sum over discrete probabilities of income since no income.
    #We calculate the associated cash on hand in cNextPeriod
    #println(age, " ",Φ(age))
    EUP = β*Φ(age)*R*UPrime(cNextPeriod(stateGrid),ρ)
    println(minimum(EUP),maximum(EUP))
    return EUP
end
