#'Header' files with parameters and useful functions
using XLSX

#THESE ARE GLOBAL. SHOULD I CONST THEM? I THINK SO


β = 0.96    #time preference
ρ = 2.0       #coefficient of relative risk aversion
n = 20    #Number of grid points. More grid points reduce errors from interpolation.

#R is gross interest rate. Set to 1.04 per period(normally year). Replace with function to model economic circumstances.
R = 1.04
#Φ(t) is probability of being alive in period t given alive in t-1.
#I am using male mortality rate as reported by pension funds? IDK what this data is. I'll change it later
mortalityRates = XLSX.readdata(raw"CIRC Mortality.xlsx", "Sheet1", "F3:F108")
function Φ(age::Int64)

    return 1-mortalityRates[age]
end
#The actuarially fair price of annuity,purchased at 66, paying from 67 to death or 105 inclusive.
function fairAnnuityFactor(coupon::Float64)
    PV = 0.0
    survivalChance = 1.0
    for (year,age) in enumerate(67:105)
        #Guaranteed Initial Value
        #multiply by chance of living into age given that you are alive at age-1.
        survivalChance *= Φ(age)
        #Discount for death and interest.
        PV += survivalChance*(1/R)^(year)*coupon
    end
    return PV
end
#The inverse of the above function. The coupon payment associated with an initial lump sum payment
function fairCouponRate(annuityPrice::Float64)
    #This inverse function only works for annuities where payment is ∝ cost.
    return annuityPrice/fairAnnuityFactor(1.0)
end

#superscript vectors are too hard
#Grid of saving points. It is multiexponential to increaes amount of grid points with low values.
#Values go up to 10.
αVec = exp.(exp.(exp.(range(0.00,stop = log(log(log(10+1)+1)+1),length =n )).-1).-1).-1
