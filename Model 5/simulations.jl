#We test the pricing of our insurance products.
include("parameters.jl")
using Statistics
numSims = 1000000
#Fair value of an annuity policy with no sickness mechanism.(i.e. no mortality multiplier)
#=
PV1 = zeros(numSims)
for i in 1:numSims
    global PV1
    R = 1.04
    aliveState = 1
    for (year,age) in enumerate(66:105)
        if aliveState == 0
            break
        end
        #1 dollar coupon discounted
        PV1[i] += 1*(1/R)^(year-1)
        #roll for death
        aliveState = Int(rand(1)[1]<=Φ(age+1,0))
    end
end
println(mean(PV1)) #Should equal fairAnnuityFactor(1.0) with mortality set to 1.0x - Which it does

#Fair value of cancer and LTC insurance.
PV2 = zeros(numSims)
for i in 1:numSims
    global PV2
    R = 1.04
    healthState = 0
    aliveState = 1
    for (year,age) in enumerate(66:105)
        if aliveState == 0
            break
        end
        if healthState == 1
            #Pays only on cancer. One off payment.
            PV2[i] += 1*(1/R)^(year-1)
            break
        elseif healthState == 2
            break
        end
        #roll for cancer and LTC / alive or not. Contract sickness + die = get nothing.
        healthRoll = rand(1)[1]
        aliveRoll = rand(1)[1]
        if healthRoll < cancerChance(age+1)
            healthState = 1
        elseif healthRoll < (cancerChance(age+1) + LTCChance(age+1))
            healthState = 2
        end
        aliveState = Int(aliveRoll<=Φ(age+1,healthState))
    end
end
println(mean(PV2)) #Should equal fairCancerInsurance(1.0) with 1.0 mortality- Which it does

PV3 = zeros(numSims)
for i in 1:numSims
    global PV3
    R = 1.04
    healthState = 0
    aliveState = 1
    for (year,age) in enumerate(66:105)
        if aliveState == 0
            break
        end
        if healthState == 2
            #Pays only on LTC. One off payment.
            PV3[i] += 1*(1/R)^(year-1)
            break
        elseif healthState == 1
            break
        end
        #roll for cancer and LTC / alive or not. Contract sickness + die = get nothing.
        healthRoll = rand(1)[1]
        aliveRoll = rand(1)[1]
        if healthRoll < cancerChance(age+1)
            healthState = 1
        elseif healthRoll < (cancerChance(age+1) + LTCChance(age+1))
            healthState = 2
        end
        aliveState = Int(aliveRoll<=Φ(age+1,healthState))
    end
end
println(mean(PV3)) #Should equal fairCancerInsurance(1.0) with 1.0x mortality- Which it does
=#
#Fair value of annuities when there is a chance of getting sick (mortality multipliers on)
PV4 = zeros(numSims)
for i in 1:numSims
    global PV4
    R = 1.04
    aliveState = 1
    healthState = 0
    for (year,age) in enumerate(66:105)
        if aliveState == 0
            break
        end
        #1 dollar coupon discounted
        PV4[i] += 1*(1/R)^(year-1)
        #roll for death
        if healthState == 0
            healthRoll = rand(1)[1]
            aliveRoll = rand(1)[1]
            if healthRoll < cancerChance(age+1)
                healthState = 1
            elseif healthRoll < (cancerChance(age+1) + LTCChance(age+1))
                healthState = 2
            end
        end
        aliveState = Int(rand(1)[1]<=Φ(age+1,healthState))
    end
end
println(mean(PV4)) #Should equal fairAnnuityFactor(1.0) Which it does

#Fair value of insurance with mortality multipliers on
PV5 = zeros(numSims)
for i in 1:numSims
    global PV5
    R = 1.04
    healthState = 0
    aliveState = 1
    for (year,age) in enumerate(66:105)
        if aliveState == 0
            break
        end
        if healthState == 1
            #Pays only on cancer. One off payment.
            PV5[i] += 1*(1/R)^(year-1)
            break
        elseif healthState == 2
            break
        end
        #roll for cancer and LTC / alive or not. Contract sickness + die = get nothing.
        healthRoll = rand(1)[1]
        aliveRoll = rand(1)[1]
        if healthRoll < cancerChance(age+1)
            healthState = 1
        elseif healthRoll < (cancerChance(age+1) + LTCChance(age+1))
            healthState = 2
        end
        aliveState = Int(aliveRoll<=Φ(age+1,healthState))
    end
end
println(mean(PV5)) #Should equal fairCancerInsurance(1.0) with 1.0 mortality- Which it does

PV6 = zeros(numSims)
for i in 1:numSims
    global PV6
    R = 1.04
    healthState = 0
    aliveState = 1
    for (year,age) in enumerate(66:105)
        if aliveState == 0
            break
        end
        if healthState == 2
            #Pays only on LTC. One off payment.
            PV6[i] += 1*(1/R)^(year-1)
            break
        elseif healthState == 1
            break
        end
        #roll for cancer and LTC / alive or not. Contract sickness + die = get nothing.
        healthRoll = rand(1)[1]
        aliveRoll = rand(1)[1]
        if healthRoll < cancerChance(age+1)
            healthState = 1
        elseif healthRoll < (cancerChance(age+1) + LTCChance(age+1))
            healthState = 2
        end
        aliveState = Int(aliveRoll<=Φ(age+1,healthState))
    end
end
println(mean(PV6)) #Should equal fairLTCInsurance(1.0) with 1.0 mortality- Which it does
