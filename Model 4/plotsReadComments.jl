using LaTeXStrings
using PyPlot
using Dierckx
include("parameters.jl")
include("main.jl")

jset = ColorMap("jet")
function plotLifetimeConsumption(initialWealth::Float64;noisy::Bool=true)
    fig, ax = subplots(figsize=(9,6))
    totalUtility = 0.0
    probOfLiving = 1.0
    #The actual state variables I use as I stepforwards through this
    currentCashonHand = initialWealth
    currentAnnuitization = 0.0
    #Known vector at the beginning of each period.
    cashonHandVec = zeros(PeriodsToAdd+1)
    #Calculated vectors via policy
    consumed = zeros(PeriodsToAdd+1)
    newAnnVec = zeros(PeriodsToAdd+1) #This is the cost NOT the payment of the new annuity.
    newAnnPayVec = zeros(PeriodsToAdd+1) #This is the payment of the new annuity.
    #Vectors constructed after to represent the information better
    savVec = zeros(PeriodsToAdd+1)
    totalConsumed = zeros(PeriodsToAdd+1)
    totalAnnVec = zeros(PeriodsToAdd+1)
    #We're going FORWARDS in time in this for loop. Note the end-i terms.
    for i in 0:PeriodsToAdd
        cashonHandVec[i+1] = currentCashonHand
        consumptionPolicyData = [C[a,b,end-i][1] for a in 1:n,b in 1:n2]
        annuityPolicyData = [C[a,b,end-i][2] for a in 1:n,b in 1:n2]
        #interpolate consumption as a function of cash on hand and current annuitisation
        consumptionFunction = Spline2D(cashGrid,annGrid, consumptionPolicyData,kx=1,ky=1)
        annuityFunction = Spline2D(cashGrid,annGrid, annuityPolicyData,kx=1,ky=1)
        currentAge = retirementAge+i
        consumed[i+1] = consumptionFunction(currentCashonHand,currentAnnuitization)
        newAnnVec[i+1] = annuityFunction(currentCashonHand,currentAnnuitization)
        if (noisy == true)
            print("I am $currentAge and have $availableFunds. ")
        end
        #Note that by construction, currentCashonHand already includes the current annuitisation level's payment
        #Also note that savVec does NOT include  + (currentAnnuitization + fairCouponRate(newAnnVec[i+1])).
        #When you add that, then it becomes next period's cash on hand, thus coming full circle to my first note.
        savVec[i+1] = currentCashonHand + fairCouponRate(newAnnVec[i+1],currentAge) - consumed[i+1] - newAnnVec[i+1]
        totalConsumed[i+1] += consumed[i+1]
        totalAnnVec[i+1] += fairCouponRate(newAnnVec[i+1],currentAge)
        newAnnPayVec[i+1] = fairCouponRate(newAnnVec[i+1],currentAge)
        if i != 0
            totalConsumed[i+1] += totalConsumed[i]
            totalAnnVec[i+1] += totalAnnVec[i]
        end
        if (noisy == true)
            ss = consumed[i+1]
            tt = β^i*probOfLiving*(consumed[i+1])^(1-ρ)/(1-ρ)
            println("I am consuming $ss, it is contributing $tt utility")
        end
        totalUtility += β^i*probOfLiving*(consumed[i+1])^(1-ρ)/(1-ρ)
        probOfLiving *= Φ(retirementAge+i+1)
        #updating our state variables of current cash on hand and current annuitisation
        currentCashonHand = R*savVec[i+1] + (currentAnnuitization + fairCouponRate(newAnnVec[i+1],currentAge))
        #Important that updating current annuitisation comes after updating cash on hand.
        currentAnnuitization += fairCouponRate(newAnnVec[i+1],currentAge)
    end
    display(consumed)
    display(newAnnPayVec)
    display(totalAnnVec)
    println("Copy paste this into a txt. Might be useful.")
    ageVec = collect(retirementAge:(retirementAge+PeriodsToAdd))
    ax[:plot](ageVec,consumed,color=jset(0.5), lw = 2, alpha = 0.6, marker = ".",label = "Consumed")
    ax[:plot](ageVec,totalAnnVec,color=jset(0.25), lw = 2, alpha = 0.6, label = "Cumulative Annuity payment midway through period")
    ax[:plot](ageVec,savVec,color=jset(0.125), lw = 2, alpha = 0.6, label = "Savings exiting period")
    ax[:legend](loc="upper right")
    xlabel("Age")
    ylabel("Amount in units")
    title("Annuities! Amount Consumed vs Age starting with $initialWealth units of money. Utility $totalUtility")
    grid("on")
    #savefig("test15DistributionVsTime.png")

    fig, ax = subplots(figsize=(9,6))
    ax[:plot](ageVec, totalConsumed,color=jset(1), lw = 2, alpha = 0.6,label="Cumulative Consumption")
    ax[:plot](ageVec, cashonHandVec-(totalAnnVec-newAnnPayVec),color=jset(0.5), lw = 2, alpha = 0.6, label = "Non annuitised wealth entering period")
    ax[:plot](ageVec, cashonHandVec,color=jset(0.25), lw = 2, alpha = 0.6, label = "Cash on Hand entering period")

    ax[:legend](loc="upper left")
    grid("on")
    xlabel("Age")
    ylabel("Amount in units")
    title("Annuities! Cumulative Amount Consumed vs Age starting with $initialWealth units of money")
    #display(fig)
    #savefig("test15CumulativeConsumption.png")
    #Print out total utility. Discounting for death actually INCREASES the expected utility.
    #This is a consequence of a strictly negative utility function. Is fine because you can't change mortality yourself.
    println("The total expected utility, discounted for time and risk of death, is $totalUtility.")
end

plotLifetimeConsumption(initialWealth,noisy = false)
