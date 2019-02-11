#'Header' files with parameters and useful functions
#Consult mechanics.txt for clarifications.
using XLSX

const PeriodsToAdd = 39 #Number of timer periods to add. default is 66-105
const retirementAge = 105-PeriodsToAdd
const β = 0.96    #time preference
const ρ = 2.0       #coefficient of relative risk aversion
const n = 21      #Number of grid points along savings dim. More grid points reduce errors from interpolation.
const n2 = 101     #Number of grid points in anu dimension
const R = 1.04        #Real interest
const initialWealth = 100.0
const cancerCost = 1.0
const LTCCost = 1.0
const cancerMortalityMultiplier = 2.0#1.1
const LTCMortalityMultiplier = 2.0#1.2
const loading = 1.0
#I am using male mortality rate as reported by pension funds? IDK what this data is. I'll change it later
const mortalityRates = XLSX.readdata(raw"CIRC Mortality.xlsx", "Sheet1", "F3:F108")
const LTCRates = XLSX.readdata(raw"CIRC Incidence Rates.xlsx", "Males", "C2:C107")
const cancerRates = XLSX.readdata(raw"CIRC Incidence Rates.xlsx", "Males", "D2:D107")
#Φ(t) is probability of being alive in period t given alive in t-1.
function Φ(age::Int64, sicknessState::Int64)
    #0 = healthy, 1 = cancer, 2 = LTC
    if sicknessState == 0
        return 1-mortalityRates[age]
    elseif sicknessState == 1
        return max(0.0,1-cancerMortalityMultiplier*mortalityRates[age])
    elseif sicknessState == 2
        return max(0.0,1-LTCMortalityMultiplier*mortalityRates[age])
    else
        println("This shouldn't happen???????")
    end
end

#cancerChance(t) is probability of NOT having cancer in t given no cancer in t-1
#Technically it's the probability when entering age t.
#Assuming independence between cancer and LTC, the highest possible probability
#of contracting both at the same time is 2%. If this is the case, 50/50 split cancer/LTC.
#This is done to preserve the odds of not getting sick as being identical to treating the two illnesses as independent
#Consequently, by definition, you can not contract cancer and LTC at the same time.
function cancerChance(age::Int64)
    return (cancerRates[age]-cancerRates[age]*LTCRates[age]/2)
end
#Same thing but for LTC
function LTCChance(age::Int64)
    return (LTCRates[age]-cancerRates[age]*LTCRates[age]/2)
end
#Transition matrix between sickness states
function transitionMatrix(age::Int64)
    transMat = zeros(3,3)
    #Indices are off by one.
    transMat[2,2] = 1
    transMat[3,3] = 1
    transMat[1,1] = 1 - cancerChance(age) - LTCChance(age)
    transMat[1,2] = cancerChance(age)
    transMat[1,3] = LTCChance(age)
end

#Cancer and LTC data questionable. Rates drop and raise so they'er not cumulative incidence rates.
#The incidence rates are likely % of people who have cancer/LTC at that age NOT chance of contracting.
#We assume recovery so the interpretation is different. Oh well. The model's illustrative not practical
#both of the following functions are conditional on being alive
function chanceToHaveCancer(currentAge::Int64, goalAge::Int64)
    chance = 0.0
    noSickness = 1.0
    for i in currentAge+1:goalAge
        #Contract chance * no cancer * not LTC
        chance += (cancerChance(i)) * noSickness
        noSickness *= (1-cancerChance(i)-LTCChance(i))
    end
    return chance
end
function chanceToHaveLTC(currentAge::Int64, goalAge::Int64)
    chance = 0.0
    noSickness = 1.0
    for i in currentAge+1:goalAge
        #Contract chance * no cancer * not LTC
        chance += (LTCChance(i)) * noSickness
        noSickness *= (1-cancerChance(i)-LTCChance(i))
    end
    return chance
end
#This is conditional on no previous sickness. Don't take it too literally.
function chanceToBeAlive(goalAge::Int64)
    chance = 1.0
    for i in retirementAge+1:goalAge
        chance *= Φ(i,0)
    end
    return chance
end


#The actuarially fair price of annuity,purchased at retirementAge, paying to 105 inclusive.
function fairAnnuityFactor(coupon::Float64)
    PV = 0.0
    survivalChance = 1.0
    for (year,age) in enumerate(retirementAge:105)
        #Guaranteed Initial Value
        #Discount for death and interest.
        PV += survivalChance*(1/R)^(year-1)*coupon
        #survivalChance *= Φ(age+1,0)
        #This survival chance augments the traditional chance (in the line above) by incorporating sickness and the associated increased mortality.
        survivalChance = survivalChance*(Φ(age+1,0)*(1-chanceToHaveCancer(retirementAge,age+1)-chanceToHaveLTC(retirementAge,age+1)) +
                                                Φ(age+1,1)*chanceToHaveCancer(retirementAge,age+1) + Φ(age+1,2)*chanceToHaveLTC(retirementAge,age+1))
    end
    return PV*loading
end
#Precomputing the fair Annuity Factor because that is constant since only purchased at 66 and healthy state = 0.
const fairFactor = fairAnnuityFactor(1.0)
#The inverse of the above function. The coupon payment associated with an initial lump sum payment
function fairCouponRate(annuityPrice::Float64)
    #This inverse function only works for annuities where payment is ∝ cost.
    return annuityPrice/fairFactor
end

#Functions to calculate the actuarially prices of insurances. Pay once on sickness.
function fairCancerInsurance(claimAmount::Float64)
    PV = 0.0
    #With R = 1.0, the price of an insurance paying $1 is the chance of contracting cancer during your lifetime.
    #Need to adjust for death because a dead individual cannot contract any sickness. Note that we don't need to
    #worry about sickness altering mortality rates here as this is a one off payment at contraction of sickness.
    #all chances to have sickness are conditional on being alive in that period.
    #Sickness comes first. If you get sick entering period t, chance of dying entering period t is incresed.
    for (year,age) in enumerate(retirementAge+1:105)
        #Chance of contracting cancer that year, hence chance of getting payed that year, then discount.
        #Have to multiply by chance of not having cancer before that year
        #Assume cancer free at retirement age
        #Alive and sickness free are independent
        PV += claimAmount*(1-chanceToHaveCancer(retirementAge,age-1)-chanceToHaveLTC(retirementAge,age-1))*(cancerChance(age))*(1/R)^(year)*chanceToBeAlive(age-1)*Φ(age,1)
    end
    return PV
end
#LTC pays in every period where the individual is alive and afflicted with LTC
function fairLTCInsurance(claimAmount::Float64)
    PV = 0.0
    for (year,age) in enumerate(retirementAge+1:105)
        PV += claimAmount*(1-chanceToHaveCancer(retirementAge,age-1)-chanceToHaveLTC(retirementAge,age-1))*(LTCChance(age))*(1/R)^(year)*chanceToBeAlive(age-1)*Φ(age,2)
    end
    return PV
end

#Grid of saving points and annuities. It is multiexponential to increaes amount of grid points with low values.
#Values go up to 100 in each dimension
const savGrid = exp.(exp.(exp.(range(0.00,stop = log(log(log(initialWealth+1)+1)+1),length =n )).-1).-1).-1
#savGrid = range(0.00,stop=100.0,length=n)
#cashGrid = range(0.00,stop = 120.0, length = n)
const anuGrid = range(0.00,stop = initialWealth,length=n2)
#dummy variables for having cancer ( = 1), LTC ( = 2). You can not have both
#const sicknessGrid = [0,1,2]
#const cancerInsurance = [dsaf]
#stateGrid = [(a,b,c) for a in anuGrid, b in savGrid, c in sicknessGrid]
const stateGrid = [(a,b) for a in anuGrid, b in savGrid]
