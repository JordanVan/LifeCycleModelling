function findOptimalStart(initialWealth::Float64,simulations::Int64)
    #A 3d array storing every possible starting combination of annuitisation and insurance
    #This indexes refer to annutisation, cancer insurance and LTC insurance respectively
    #The utility here is the average utilty run over 1000 simulations each.
    utilityTens = zeros(n2,n3,n3)
    for annLevel in 1:n2
        for cancerLevel in 1:n3
            for LTCLevel in 1:n3
                utilityVec = zeros(simulations)
                for i in 1:simulations
                    aliveState = 1
                    healthState = 0
                    #Buy Annuities and Insurance
                    cashOnHand = initialWealth-anuGrid[annLevel]-fairCancerPrice*cancerInsuranceGrid[cancerLevel]-
                    fairLTCPrice*LTCInsuranceGrid[LTCLevel]
                    if cashOnHand < 0
                        #Unviable strategy
                        utilityVec[i] = -100.0
                        continue
                    end
                    for (year,age) in enumerate(retirementAge:retirementAge+PeriodsToAdd)
                        #check for death
                        if aliveState == 0
                            break
                        end
                        #Pay out annuities
                        cashOnHand += fairCouponRate(anuGrid[annLevel])
                        nonCancerWealth = cashOnHand
                        #Pay out health insurance and deduct health costs
                        if healthState == 1
                            cashOnHand += cancerInsuranceGrid[cancerLevel]
                            cashOnHand -= cancerCost
                        elseif healthState == 2
                            cashOnHand += LTCInsuranceGrid[LTCLevel]
                            cashOnHand -= LTCCost
                        end
                        #Subsidising health costs if you have negative cash on hand.
                        #In this case, it costs 70% of your cash on hand excluding cancer insurance.
                        cashOnHand = max(cashOnHand,0.3*nonCancerWealth)
                        #Constructing the interpolated conusmptoin function based on state
                        Xdata = X[annLevel,:,healthState+1,cancerLevel,LTCLevel,end-(year-1)]
                        Cdata = C[annLevel,:,healthState+1,cancerLevel,LTCLevel,end-(year-1)]
                        consumptionFunction = Spline1D(Xdata, Cdata, k=1, bc="extrapolate")
                        #Consuming and contributing to utility
                        consumed = consumptionFunction(cashOnHand)
                        if consumed < 0
                            println("Negative consumption")
                        end
                        if consumed == 0
                            println("zero consumption $cashOnHand $healthState $cancerLevel $LTCLevel")
                        end
                        utilityVec[i] += β^(year-1)*utilityFunction(consumed,ρ)
                        #Withdrawing from cashOnHand and compounding interest
                        cashOnHand -= consumed
                        if abs(cashOnHand) < 0.001
                            cashOnHand = 0.0
                        end
                        if cashOnHand <= -0.001
                            println("Overconsumption")
                        end
                        cashOnHand *= R
                        #Roll for next period
                        #Roll for death
                        aliveState = newAliveState(aliveState,healthState,age+1)
                        #Roll for health
                        healthState = newHealthState(healthState,age+1)
                    end
                end
                utilityTens[annLevel,cancerLevel,LTCLevel] = mean(utilityVec)
            end
        end
        println("I'm on annLevel $annLevel")
    end
    maxUtility = maximum(utilityTens)
    bestStart = argmax(utilityTens)
    return bestStart, maxUtility
end
