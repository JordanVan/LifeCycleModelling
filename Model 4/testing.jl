include("parameters.jl")

totalUtility = 0.0
probOfLiving = 1.0
for i in 0:PeriodsToAdd
    global totalUtility
    global probOfLiving
    totalUtility += β^i*probOfLiving*(fairCouponRate(initialWealth,retirementAge))^(1-ρ)/(1-ρ)
    probOfLiving *= Φ(retirementAge+i+1)
end
idealPayment = fairCouponRate(initialWealth,retirementAge)
println("Total expected utility is $totalUtility. If 100% of wealth is annuitised, the payment is $idealPayment")
