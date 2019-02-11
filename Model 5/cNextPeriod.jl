#Define the functoin cNextPeriod(x)
#gets the next period consumption for the inputted savings/annuity pairs in statespace grid
#We can constuct C_t+1() by interpolating the values of it we found previously
#as we work backwards in time.

using Dierckx

#What is the type of x?
function cNextPeriod(stateGrid::Array{Tuple{Float64,Float64,Int64,Float64,Float64},5})
    xtplus1=copy(X[:,:,:,:,:,end])  # data for the next-period consumption function
    ctplus1=copy(C[:,:,:,:,:,end])  # data for the next-period consumption function

    consumptionValues = zeros(n2,n,4,n3,n3)
    #looping over everything but savings.
    #We interpolate 4 next period consumption functions corresponding to the next health state
    #The consumption at any point in time depends on the current health state. A individual who
    #has LTC care for the 6th period in a row should consume the same as someone who has it for
    #the first time if their financial situation(savings/ann/insurance) is identical.
    #So, instead of returning a consumption array whose health index corresponds to the old
    #health state, the health index instead refers to the NEW health state. Because, the choice
    #to buy insurance/annuities is restricted to the beginning, old and new ann/ins states are the same.
    #Besides health, only the savings health state changes but the savings index refers to the old
    #savings as in previous simpler models of consumptions/savings/initial annuitisation.
    counter = 0
    for i in 1:n2
        for j in 1:4 #looping over 4 health states. Alternatively remove this loop and spline1d 4 times.
        #This j refers to NEW health state.
            for k in 1:n3
                for l in 1:n3
                    #for item in xtplus1[i,:,j,k,l]
                    #    println(item)
                    #end
                    #for item in ctplus1[i,:,j,k,l]
                    #    println(item)
                    #end
                    #if k == 2
                    #    display(xtplus1[i,:,j,k,l])
                    #    display(ctplus1[i,:,j,k,l])
                    #end
                    interpolatedConsumption = Spline1D(xtplus1[i,:,j,k,l],ctplus1[i,:,j,k,l],k=1,bc="extrapolate",w=ones(length(xtplus1[i,:,j,k,l])))
                    counter += 1
                    #if counter%61 == 0
                    #    println(interpolatedConsumption(0.0))
                    #end
                    #println("I interpolated correctly for i,j,k,l = $i,$j,$k,$l")
                    #looping over savings. j==2 is cancer.  j==3 is LTC. j==4 is post cancer.
                    for m in 1:n
                        cashOnHand = fairCouponRate.(stateGrid[i,m,j,k,l][1]) + R*stateGrid[i,m,j,k,l][2] +
                        (j==2)*(stateGrid[i,m,j,k,l][4]-cancerCost) + (j==3)*(stateGrid[i,m,j,k,l][5]-LTCCost)
                        #If you can't afford the health cost even with insurance, pay 70% of net worth.
                        cashOnHand = max(cashOnHand, 0.3*(fairCouponRate.(stateGrid[i,m,j,k,l][1]) + R*stateGrid[i,m,j,k,l][2]))
                        consumptionValues[i,m,j,k,l] = interpolatedConsumption(cashOnHand)

                        if consumptionValues[i,m,j,k,l] < 0
                            println("$i $m $j $k $l NEGATIVE")
                        end
                        if consumptionValues[i,m,j,k,l] > cashOnHand*1.0000001
                            println("$i $m $j $k $l Overconsumption")
                        end
                        if consumptionValues[i,m,j,k,l] == 0 && m != 1
                            println("$i $m $j $k $l ZERO")
                        end
                        if (cashOnHand) < 0
                            println("??")
                        end
                        if isnan(consumptionValues[i,m,j,k,l])
                            println("$i $m $j $k $l NaN")
                            println(cashOnHand)
                        end
                    end
                end
            end
        end
    end
    #Again, I stress that index j refers to next period health state.
    return consumptionValues
end
