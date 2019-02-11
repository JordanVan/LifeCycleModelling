#'Header' files with parameters and useful functions
#Consult mechanics.txt for clarifications.
using XLSX
using Statistics

const PeriodsToAdd = 39 #Number of timer periods to add. default is 66-105
const retirementAge = 105-PeriodsToAdd
const β = 0.96    #time preference
const ρ = 2.0       #coefficient of relative risk aversion
const n = 21      #Number of grid points along savings dim. More grid points reduce errors from interpolation.
const n2 = 101     #Number of grid points in anu dimension
const n3 = 6        #Number of grid points in the insuarance dimensions
const R = 1.04        #Real interest
const initialWealth = 100.0 #Initial Wealth.
const cancerCost = 10.0 #10.0 One off health shock on contraction of cancer
const LTCCost = 1.0 #1.0 Ongoing health cost associated with requiring LTC
const cancerMortalityMultiplier = 4.0#4.0
const postCancerMortalityMultiplier = 1.1#1.1
const LTCMortalityMultiplier = 1.5#1.5
const loading = 1.0
const cancerLoading = 2.0
const LTCLoading = 2.0
const insuranceFee = 0.0 #597.31 Mainly for testing. Chosen to be non round number.
#I am using male mortality rate as reported by pension funds
const mortalityRates = XLSX.readdata(raw"CIRC Mortality.xlsx", "Sheet1", "F3:F108")
const LTCRates = XLSX.readdata(raw"CIRC Incidence Rates.xlsx", "Males", "C2:C107")
const cancerRates = XLSX.readdata(raw"CIRC Incidence Rates.xlsx", "Males", "D2:D107")
const numSims = 3000000 #3000000 Chosen such that results are numerically stable.<0.4% error for all 3 products.
const numSims2 = 200 #40000 good. Number of simulations to find optimal start.
#Chances of contracting cancer/LTC conditional on being healthy in the previous period.
#The two events are NOT independent. Getting one p  rohibits getting the other.
function cancerChance(age::Int64)
    return (cancerRates[age])
end
function LTCChance(age::Int64)
    return (LTCRates[age])
end

#Transition matrix between health states entering 'age'.
function transitionMatrix(age::Int64)
    transMat = zeros(4,4)
    #Indices are off by one.
    transMat[1,1] = 1 - cancerChance(age) - LTCChance(age)
    transMat[1,2] = cancerChance(age)
    transMat[1,3] = LTCChance(age)
    transMat[2,4] = 1 #Guaranteed transition into post cancer state from cancer.
    transMat[3,3] = 1 #You can never leave LTC
    transMat[4,4] = 1 #Post cancer state stays in post cancer state.
    return transMat
end

#Φ(t) is probability of being alive in period t given a health state in t-1.
#Always at least a 10% chance of surviving.
function Φ(age::Int64, sicknessState::Int64)
    if age >= 106
        return 0.0
    end
    #0 = healthy, 1 = cancer, 2 = LTC, 3 = postcancer.
    if sicknessState == 0
        return max(0.10,1-mortalityRates[age])
    elseif sicknessState == 1
        #Cancer in t-1, makes survival into period t difficult.
        return max(0.10,1-cancerMortalityMultiplier*mortalityRates[age])
    elseif sicknessState == 2
        return max(0.10,1-LTCMortalityMultiplier*mortalityRates[age])
    elseif sicknessState == 3
        return max(0.10,1-postCancerMortalityMultiplier*mortalityRates[age])
    else
        println("This shouldn't happen???????")
    end
end
#rolls for new health state entering 'age'.
function newHealthState(oldHealthState::Int64, age::Int64)
    roll = rand(1)[1]
    transMat = transitionMatrix(age)
    healthRoll = rand(1)[1]
    if healthRoll <= transMat[oldHealthState+1,1]
        healthState = 0
    elseif healthRoll <= transMat[oldHealthState+1,1]+transMat[oldHealthState+1,2]
        healthState = 1
    elseif healthRoll <= transMat[oldHealthState+1,1]+transMat[oldHealthState+1,2]+transMat[oldHealthState+1,3]
        healthState = 2
    else
        healthState = 3
    end
end
#roll for death entering 'age'. This occurs before rolling for health.
function newAliveState(oldAliveState::Int64, oldHealthState::Int64, age::Int64)
    if oldAliveState == 0
        return 0
    end
    roll = rand(1)[1]
    aliveState = Int(roll<=Φ(age,oldHealthState))
    return aliveState
end

#We now simulate the fair price of cancer insurance.
#Cancer insurance pays a fixed amount ON the contraction of cancer. If someone
#contracts cancer, it is assured that they will live at least one year, during
#which they have access to the insurance payout to do as they wish.

function simulateCancerInsurancePrice(claimAmount::Float64)
    PV = zeros(numSims)
    for i in 1:numSims
        #start off alive and healthy
        aliveState = 1
        healthState = 0
        for (year,age) in enumerate(retirementAge:retirementAge+PeriodsToAdd)
            if healthState == 1
                #Pay on cancer
                PV[i] += claimAmount*(1/R)^(year-1)
                #No need to roll for death because nothing more can be payed out.
                #Guaranteed transition to postcancer
                healthState = newHealthState(healthState,age+1)
            elseif healthState == 0
                #roll for death
                aliveRoll = rand(1)[1]
                aliveState = Int(aliveRoll<=Φ(age+1,healthState))
                #roll for health status
                healthState = newHealthState(healthState,age+1)
                #end on death or LTC or postcancer
                if aliveState == 0 || healthState == 2 || healthState == 3
                    break
                end
            else
                break
            end
        end
    end
    return mean(PV)*cancerLoading+insuranceFee
end
#Precomputing so we don't waste time computing again.
isdefined(Main,:fairCancerPrice) || (const fairCancerPrice = simulateCancerInsurancePrice(1.0))
#LTC insurance pays during any period where the individual is under LTC
function simulateLTCInsurancePrice(claimAmount::Float64)
    PV = zeros(numSims)
    for i in 1:numSims
        #start off alive and healthy
        aliveState = 1
        healthState = 0
        for (year,age) in enumerate(retirementAge:retirementAge+PeriodsToAdd)
            if healthState == 2
                #Pay on LTC until death.
                PV[i] += claimAmount*(1/R)^(year-1)
                #roll for death
                aliveRoll = rand(1)[1]
                aliveState = Int(aliveRoll<=Φ(age+1,healthState))
                if aliveState == 0
                    break
                end
                healthState = newHealthState(healthState,age+1)
            elseif healthState == 0
                #roll for death
                aliveRoll = rand(1)[1]
                aliveState = Int(aliveRoll<=Φ(age+1,healthState))
                #roll for health status
                healthState = newHealthState(healthState,age+1)
                #end on death or cancer or postcancer
                if aliveState == 0 || healthState == 1 || healthState == 3
                    break
                end
            else
                break
            end
        end
    end
    return mean(PV)*LTCLoading+insuranceFee
end
#const fairLTCPrice = 5.0
isdefined(Main,:fairLTCPrice) || (const fairLTCPrice = simulateLTCInsurancePrice(1.0))
#The annuity pays from purchase to death.
function simulateAnnuityFactor(coupon::Float64)
    PV = zeros(numSims)
    for i in 1:numSims
        #start off alive and healthy
        aliveState = 1
        healthState = 0
        for (year,age) in enumerate(retirementAge:retirementAge+PeriodsToAdd)
            #Annuities pay until death
            PV[i] += coupon*(1/R)^(year-1)
            aliveRoll = rand(1)[1]
            aliveState = Int(aliveRoll<=Φ(age+1,healthState))
            if aliveState == 0
                break
            end
            healthState = newHealthState(healthState,age+1)
        end
    end
    return mean(PV)*loading
end
#const fairAnnuityFactor = simulateAnnuityFactor(1.0)
isdefined(Main,:fairAnnuityFactor) || (const fairAnnuityFactor = simulateAnnuityFactor(1.0))
function fairCouponRate(annuityPrice::Float64)
    #Inverse function. With annuityPrice dollars, how much is my coupon?
    return annuityPrice/fairAnnuityFactor
end
#Some functions to test the spread of simulated values.
function testSimulateLTC()
    price = zeros(10)
    for i in 1:10
        price[i] = simulateLTCInsurancePrice(1.0)
    end
    println((maximum(price)-minimum(price))/mean(price))
end
function testSimulateCancer()
    price = zeros(10)
    for i in 1:10
        price[i] = simulateCancerInsurancePrice(1.0)
    end
    println((maximum(price)-minimum(price))/mean(price))
end
function testSimulateAnnuity()
    price = zeros(10)
    for i in 1:10
        price[i] = simulateAnnuityFactor(1.0)
    end
    println((maximum(price)-minimum(price))/mean(price))
end

#Grid of saving points and annuities. It is multiexponential to increaes amount of grid points with low values.
const savGrid = exp.(exp.(exp.(range(0.00,stop = log(log(log(initialWealth+1)+1)+1),length =n )).-1).-1).-1
#const savGrid = collect(range(9.62,stop = initialWealth, length = n))
const anuGrid = range(0.00,stop = initialWealth,length=n2)
const healthGrid = [0,1,2,3]
#Maximum insurance is the one which covers all costs.
const cancerInsuranceGrid = range(0.00,stop = cancerCost,length=n3)
const LTCInsuranceGrid = range(0.00,stop = LTCCost,length=n3)
const stateGrid = [(a,b,c,d,e) for a in anuGrid, b in savGrid,c in healthGrid, d in cancerInsuranceGrid, e in LTCInsuranceGrid]
