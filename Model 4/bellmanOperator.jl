#This file was written with reference to the bellmanOperator file on QuantEcon.
using BlackBoxOptim
using Dierckx
function bellman(WalueFunctions::Array{Float64,3},stateGrid::Array{Tuple{Float64,Float64},2}, R::Float64,
                β::Float64,ρ::Float64,utility,ageInPeriod::Int64, Φ)
    #ageInPeriod + number of periods previously calculated(size of 2nd dimension of Walue function) = 105
    @assert(ageInPeriod + size(WalueFunctions)[3] == 105)
    #WalueFunction is the value function W, represented by its value at points on the stateGrid for different t
    #It is reconstructed via interpolation. We use the part of it already calculated(periods later in time) to
    #find the value function for new periods of time as we work backwards in time.
    value_t = similar(WalueFunctions[:,:,end])
    consumptionPolicy_t = similar(stateGrid)
    #Data needs to be sorted to be interpolated, but its likely safe to say higher cash in hand corresponds to higher value
    value_tplus1 = Spline2D(cashGrid,annGrid,WalueFunctions[:,:,end],kx=1,ky=1) #Spline1D(xtplus1[i,:],ctplus1[i,:],k=1,bc="extrapolate")
    println(typeof(value_tplus1))
    #optimising over the choice of savings and nothing right now
    #enumerate doesn't support higher dimensions. We just ues nested loops instead.
    for i in 1:n
        for j in 1:n2
            #Note this is not the true cashPoint. The true cashPoint would include an extra initial payment from additional annuitisation.
            cashPoint = stateGrid[i,j][1]
            annPoint = stateGrid[i,j][2]
            #Our choice for new annuity is for how much to SPEND, not how much we're gonna get payed from it. Same thing tho, except in code.
            #cash on hand for next period is equal to savings*gross interest + currentann + new annuity
            #x_tplus1 = R*(cashPoint+FCR(newAnnuity)-consumption-newAnnuity) + (annPoint + newAnnuity)---> t+1 annuity payment
            #standard form of optimisation problems is to minimise. Minimising 2d function now.
            #We use vector x with first compoenent representing consumption, second representing optimal new annuitisation COST(i.e. how much ur paying).
            objective(x) = -(utility(x[1],ρ) + β*Φ(ageInPeriod+1)*value_tplus1(R*(cashPoint+fairCouponRate(x[2],ageInPeriod)-x[1]-x[2]) + annPoint+fairCouponRate(x[2],ageInPeriod),annPoint+fairCouponRate(x[2],ageInPeriod)))+
            9999999*max(0,x[1]+x[2]-cashPoint-fairCouponRate(x[2],ageInPeriod)) #We apply a liquidity constraint via the penalty method
            #lower and upper bounds  are 0 and consuming all cash on hand/buying annuties with all ur cash
            result = bboptimize(objective;SearchRange = [(0.0, cashPoint), (0.0, cashPoint*1.3)], NumDimensions = 2,TraceMode=:silent,Method = :probabilistic_descent,MaxTime = 0.060); #0.005 isn't bad
            #storing consumption comsumption policy
            consumptionPolicy_t[i,j] = (best_candidate(result)[1],best_candidate(result)[2])
            if(consumptionPolicy_t[i,j][1] < 0 || consumptionPolicy_t[i,j][2] < 0)
                println(consumptionPolicy_t[i,j]," ???")
            end
            #storing value function for period
            value_t[i,j] = -best_fitness(result)
        end
        if i%10 == 0
            println("We're at $ageInPeriod, coordinate i = $i out of $n. Don't give up!")
        end
    end
    #Does NOT update WalueFunctions
    return value_t, consumptionPolicy_t
end
