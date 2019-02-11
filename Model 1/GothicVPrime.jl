#Julia file hosting the function definition of GothicVPrime
#GothicVPrime takes in a saving value and returns marginal value of end of period wealth(savings)

function GothicVPrime(a,age::Int64)
    #a is a vector of savings. For each value in this vector, we want the corresponding
    #marginal end of period wealth

    #EUP is short fo expected utility prime. Note that there is no uncertainty so expected is redundant.
    EUP = zeros(size(a))

    #no need to perform a sum over discrete probabilities of income since no income.
    #cash on hand for period t+1 is just the savings s_t times interest. No income.
    EUP = β*Φ(age)*R*UPrime(cNextPeriod(R*a),ρ)

    return EUP
end
