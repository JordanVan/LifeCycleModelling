#Define the functoin cNextPeriod(x)
#gets the next period consumption for the inputted savings/annuity pairs in statespace grid
#We can constuct C_t+1() by interpolating the values of it we found previously
#as we work backwards in time.

using Dierckx

#What is the type of x?
function cNextPeriod(stateGrid::Array{Tuple{Float64,Float64},2})
    #################
    xtplus1=copy(X[:,:,end])  # data for the next-period consumption function
    ctplus1=copy(C[:,:,end])  # data for the next-period consumption function
    #Consumption is monotonically increasing in cash on hand.
    consumptionValues = zeros(n,n)
    #looping over annuitisation
    for i in 1:n
        #generating the consumption function for annuitisation level i (annLev = i-1)
        interpolatedConsumption = Spline1D(xtplus1[i,:],ctplus1[i,:],k=1,bc="extrapolate")
        #looping over savings
        for j in 1:n
            consumptionValues[i,j] = interpolatedConsumption(fairCouponRate.(stateGrid[i,j][1]) + R*stateGrid[i,j][2])
            if isnan(consumptionValues[i,j])
                println("Oh boy")
                #println("$i $j")
            #    println("$j I should consume ", interpolatedConsumption(0.1))
            end
        end
    end

    #consumptionValues = interpolatedConsumption.(cashOnHandForGrid)

    return consumptionValues
end
#=
#LinInterp return the closest value for values outside the range so we turn to the
#Dierckx package instead.

xtplus1=copy(X[:,:,end])  # data for the next-period consumption function
ctplus1=copy(C[:,:,end])  # data for the next-period consumption function
#Consumption is monotonically increasing in cash on hand.
#xtplus1Vec = vec(sort(reshape(xtplus1,n*n,1),dims=1))
#ctplus1Vec = vec(sort(reshape(ctplus1,n*n,1),dims=1))


#Note we find the cash on hand so we need only 1d interpolation
interpolatedConsumption = Spline1D(xtplus1,ctplus1,k=1,bc="extrapolate")
println("I should consume ", interpolatedConsumption(0.01))
#find the associated cash on hand values for each grid point
cashOnHandForGrid = zeros(n,n)
for i in 1:n
    for j in 1:n
        #fairCouponRate(Annuities) + savings*R is what you will have at the beginning of next period
        cashOnHandForGrid[i,j] = fairCouponRate.(stateGrid[i,j][1]) + R*stateGrid[i,j][2]
    end
end

consumptionValues = interpolatedConsumption.(cashOnHandForGrid)
=#
