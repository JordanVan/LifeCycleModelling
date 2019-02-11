#Define the functoin cNextPeriod(x)
#gets the next period consumption for the inputted cash on hand values, X_t+1
#We can constuct C_t+1() by interpolating the values of it we found previously
#as we work backwards in time.

using Dierckx

#What is the type of x?
function cNextPeriod(x)
    #x is a vector of cash on hand values at time t+1. This function returns
    #the value of the interpolated conusmption function for each value in x.

    #LinInterp return the closest value for values outside the range so we turn to the
    #Dierckx package instead.

    xtplus1=copy(X[:,end])  # data for the next-period consumption function
    ctplus1=copy(C[:,end])  # data for the next-period consumption function

    interpolatedConsumption = Spline1D(xtplus1,ctplus1,k=1,bc="extrapolate")

    consumptionValues = interpolatedConsumption(x)

    return consumptionValues
end
