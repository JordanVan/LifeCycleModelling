#'Header' files with parameters and useful functions
using XLSX
using Dates

const PeriodsToAdd = 39 #Number of timer periods to add. default is 66-105
const retirementAge = 105-PeriodsToAdd
const β = 0.96    #time preference
const ρ = 2.0       #coefficient of relative risk aversion
const n = 20      #Number of grid points along savings dim. More grid points reduce errors from interpolation.
const n2 = 20      #Number of grid points along annuities dimension.
const R = 1.04
const initialWealth = 100.0
#testing 20% loading
const loading = 1.20

#Φ(t) is probability of being alive in period t given alive in t-1. Male pension data.
mortalityRates = XLSX.readdata(raw"CIRC Mortality.xlsx", "Sheet1", "F3:F108")
function Φ(age::Int64)
    return 1-mortalityRates[age]
end
#probabiility of surviving to goal age from current age.
function chanceToSurviveTo(currentAge::Int64, goalAge::Int64)
    @assert(goalAge>currentAge)
    chance = 1.0
    for i in (currentAge+1):goalAge
        chance *= Φ(i)
    end
    return chance
end
#The actuarially fair price of $1 annuity,purchased at purchaseAge, paying from purchaseAge to death.
#105 is taken as final period of life. No loading. No differential Mortality. Can add on request.
function fairAnnuityFactor(coupon::Float64, purchaseAge::Int64)
    @assert(purchaseAge >= retirementAge)
    PV = 0.0
    survivalChance = 1.0
    for (year,age) in enumerate(purchaseAge:105)
        #Guaranteed initial payment
        #Discount for death and interest. Pang/Warshawsky 2010 replace R with an discount factor reflective
        #of the investment portfolio of the issuing company which is typically 10% equity, 90% rf bonds.
        PV += survivalChance*(1/R)^(year-1)*coupon
        survivalChance *= Φ(age+1)
    end
    return PV*(loading)
end
#Precomputing for all ages.
const fairFactor = [fairAnnuityFactor(1.0,age) for age in retirementAge:(retirementAge+PeriodsToAdd)]
#The inverse of the above function. The coupon payment associated with an initial lump sum payment
function fairCouponRate(annuityPrice::Float64,purchaseAge::Int64)
    #This inverse function only works for annuities where payment is proportional to cost.
    return annuityPrice/fairFactor[purchaseAge-retirementAge+1]
    #return annuityPrice/fairAnnuityFactor(1.0,purchaseAge)
end

#Grid of saving points and annuities.
##Grid is structured so more points are near lower values. Allows for better accuracy for fewer points.
#const cashGrid = (range(0.00,stop = (1.1*initialWealth)^(1/2),length = n)).^2 .+ (1e-2)
const cashGrid = (range(0.00,stop = (1.1*initialWealth)^(1/1),length = n)).^1 .+ (1e-2)
#If someone saved up till the final period, they could theoretically purhcase an annuity paying >$100
#I set 20 as the upper bound because I expect annuitisation to happen fairly early.
const annGrid = (range(0.00,stop = (initialWealth/8)^(1/1),length = n2)).^1
const stateGrid = [(cashGrid[a],annGrid[b]) for a in 1:n, b in 1:n2]
