#'Header' files with parameters and useful functions
using XLSX
#THESE ARE GLOBAL. SHOULD I CONST THEM? I THINK SO

PeriodsToAdd = 39 # number of extra periods to add onto initial C=Y solution.
β = 0.96    #time preference
ρ = 2.0       #coefficient of relative risk aversion
n = 101      #Number of grid points along savings dim. More grid points reduce errors from interpolation.
initialWealth = 100.0
#R is gross interest rate. Set to 1.04 per period(normally year). Replace with function to model economic circumstances.
R = 1.04
loading = 1.0
#I am using male mortality rate as reported by pension funds? IDK what this data is. I'll change it later
mortalityRates = XLSX.readdata(raw"CIRC Mortality.xlsx", "Sheet1", "F3:F108")
#Φ(t) is probability of being alive in period t given alive in t-1.
function Φ(age::Int64)
    return 1-mortalityRates[age]
end
#Useful Function.
function chanceToSurviveTo(age::Int64)
    chance = 1
    for i in 67:age
        chance *= Φ(i)
    end
    return chance
end
#The actuarially fair price of annuity,purchased at 66, paying from 66 to death or 105 inclusive.
function fairAnnuityFactor(coupon::Float64)
    PV = 0.0
    survivalChance = 1.0
    for (year,age) in enumerate(66:105)
        #Guaranteed Initial Value
        #Discount for death and interest.
        PV += survivalChance*(1/R)^(year-1)*coupon
        #survivalChance *= Φ(age+1)
        survivalChance = chanceToSurviveTo(age+1)
    end
    return PV*loading
end
const fairFactor = fairAnnuityFactor(1.0)
#The inverse of the above function. The coupon payment associated with an initial lump sum payment
function fairCouponRate(annuityPrice::Float64)
    #This inverse function only works for annuities where payment is ∝ cost.
    return annuityPrice/fairFactor
end

#superscript vectors are too hard
#Grid of saving points and annuities. It is multiexponential to increaes amount of grid points with low values.
#Values go up to 100 in each dimension
savGrid = exp.(exp.(exp.(range(0.00,stop = log(log(log(initialWealth+1)+1)+1),length =n )).-1).-1).-1

#savGrid = range(0.00,stop=100.0,length=n)
#cashGrid = range(0.00,stop = 120.0, length = n)
anuGrid = range(0.00,stop = 100.0,length=n)
stateGrid = [(a,b) for a in anuGrid, b in savGrid]
#stateGrid = [(a,b) for a in anuGrid, b in cashGrid]
