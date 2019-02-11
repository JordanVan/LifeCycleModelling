function findOptimalAnn(initialWealth::Float64)
    utilityVec = zeros(101)
    for g in 0:100
        annuitizationLevel = Float64(g)
        totalUtility = 0.0
        probOfLiving = 1.0
        currentWealth = initialWealth-annuitizationLevel
        consumed = zeros(PeriodsToAdd+1)
        wealthVec = zeros(PeriodsToAdd+1)
        #savVec = zeros(PeriodsToAdd+1)
        #totalConsumed = zeros(PeriodsToAdd+1)
        anuVec = [fairCouponRate(annuitizationLevel) for i in 0:PeriodsToAdd]
        #We're going FORWARDS in time in this for loop. Note the end-i terms.
        for i in 0:PeriodsToAdd
            wealthVec[i+1] = currentWealth
            Xdata = X[Int(annuitizationLevel+1),:,end-i]
            Cdata = C[Int(annuitizationLevel+1),:,end-i]
            consumptionFunction = Spline1D(Xdata, Cdata,k=1,bc="extrapolate")
            currentAge = 66+i
            #availableFunds = currentWealth + fairCouponRate(annuitizationLevel)
            consumed[i+1] = consumptionFunction(currentWealth+fairCouponRate(annuitizationLevel))
            #savVec[i+1] = currentWealth + fairCouponRate(annuitizationLevel) - consumed[i+1]
            currentWealth = currentWealth + fairCouponRate(annuitizationLevel) - consumed[i+1]
            #totalConsumed[i+1] += consumed[i+1]
            #if i != 0
            #    totalConsumed[i+1] += totalConsumed[i]
            #end
            totalUtility += β^i*probOfLiving*(consumed[i+1])^(1-ρ)/(1-ρ)
            probOfLiving *= Φ(66+i+1)
            currentWealth = currentWealth*R
        end
        utilityVec[g+1] = totalUtility
    end
    maxUtility = maximum(utilityVec)
    bestAnn = findall(a->a==maxUtility,utilityVec)[1] - 1
    println("The highest achievable utility is $maxUtility by annuitising $bestAnn% of initial wealth.")
    return bestAnn
end
