function GothicVPrime(stateGrid::Array{Tuple{Float64,Float64,Int64,Float64,Float64},5},age::Int64)
    #stateGrid is a 5d array whose entries are a 5-tuple of annuity/saving/health/cancerinsurance/LTCinsurance Values
    #For each value in this vector, we want the corresponding marginal utility of end of period wealth

    EUP = zeros(size(stateGrid))
    #Need to perform a sum over probabilities of future states.
    nextPeriodConsumption = cNextPeriod(stateGrid)
    for i in 1:n2
        for m in 1:n
            for J in 1:4 #This J refers to OLD health state. Capitalised to clarify.
            #Old health state is important for chance of survival.
                for k in 1:n3
                    for l in 1:n3
                        transMat = transitionMatrix(age)
                        #EUP[i,m,J,k,l] = β*Φ(age,0)*R*UPrime(nextPeriodConsumption[i,m,1,k,l],ρ)
                        #This thing commented out right below me is how you get 0*Inf which is NaN
                        #EUP[i,m,J,k,l] = β*Φ(age,J-1)*R*
                        #(UPrime(nextPeriodConsumption[i,m,1,k,l],ρ)*transMat[J,1] +
                        #UPrime(nextPeriodConsumption[i,m,2,k,l],ρ)*transMat[J,2] +
                        #UPrime(nextPeriodConsumption[i,m,3,k,l],ρ)*transMat[J,3] +
                        #UPrime(nextPeriodConsumption[i,m,4,k,l],ρ)*transMat[J,4])
                        for jj in 1:4
                            if transMat[J,jj] != 0
                                EUP[i,m,J,k,l] += β*Φ(age,J-1)*R*UPrime(nextPeriodConsumption[i,m,jj,k,l],ρ)*transMat[J,jj]
                            end
                        end
                    end
                end
            end
        end
    end
    #println(minimum(EUP)," ",maximum(EUP))
    return EUP
end
