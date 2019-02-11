#This plots things. Be very careful with the intepretation
#This files will be used to plot many things. Currently its the same as Caroll 06 rewrite.

#Julia version
using LaTeXStrings
using PyPlot
using Dierckx
include("parameters.jl")
include("main.jl")
include("findOptimalAnnuitisation.jl")

if OptID == "UserChoice"
    println("What annuitisation level(Integer) consumption functions would you like to view?")
    annLev = parse(Int64,readline(stdin))+1
else
    annLev = findOptimalAnn(initialWealth)+1;
end

fig, ax = subplots(figsize=(9,6))
jset = ColorMap("jet")
#ax[:plot](MuVec,ChiVec, color = jet(0),lw = 5,label=L"Unemp Model")
ax[:plot](X[annLev,:,end],C[annLev,:,end],color=jset(0), lw=2,
          alpha=0.3, label="Consumption(CashOnHand) for Initial Period")
ax[:plot](X[annLev,:,1],C[annLev,:,1],color=jset(1), lw = 2, alpha = 0.3, label = "45 degree (Final Period Age 105)")

if PeriodsToAdd == 39
    ax[:plot](X[annLev,:,31],C[annLev,:,31],color=jset(0.75), lw = 2, alpha = 0.3, label = "10th Period Age 75")
    ax[:plot](X[annLev,:,21],C[annLev,:,21],color=jset(0.5), lw = 2, alpha = 0.3, label = "20th Period Age 85")
    ax[:plot](X[annLev,:,11],C[annLev,:,11],color=jset(0.25), lw = 2, alpha = 0.3, label = "30th Period Age 95")
    ax[:plot](X[annLev,:,6],C[annLev,:,6],color=jset(0.125), lw = 2, alpha = 0.3, label = "35th Period Age 100")
end


ax[:legend](loc="upper left")
totalPeriods = PeriodsToAdd+1
title("Consumption vs Cash on Hand with No Income. $totalPeriods periods")
xlabel("x - Cash on Hand")
ylabel("c - Consumption")
#display(fig)
#savefig("77ConsumptionFunctions.png")
grid("on")
minorticks_on()
grid(which="minor")
savefig("qqRealMortalityRates.png")
#close(fig)

#Plotting consumption throughout life given an initial starting wealth
#We only deal with 100 starting wealth. Can think of as percentage thanks to CRRA.
jset = ColorMap("jet")
function plotLifetimeConsumption(initialWealth::Float64,annuitizationLevel::Float64;noisy::Bool=true)
    fig, ax = subplots(figsize=(9,6))
    totalUtility = 0.0
    probOfLiving = 1.0
    currentWealth = initialWealth-annuitizationLevel
    consumed = zeros(PeriodsToAdd+1)
    wealthVec = zeros(PeriodsToAdd+1)
    savVec = zeros(PeriodsToAdd+1)
    totalConsumed = zeros(PeriodsToAdd+1)
    anuVec = [fairCouponRate(annuitizationLevel) for i in 0:PeriodsToAdd]
    #We're going FORWARDS in time in this for loop. Note the end-i terms.
    for i in 0:PeriodsToAdd
        wealthVec[i+1] = currentWealth
        Xdata = X[Int(annuitizationLevel+1),:,end-i]
        Cdata = C[Int(annuitizationLevel+1),:,end-i]
        #println(size(X),size(C))
        #interpolate consumption as a function of cash on hand
        consumptionFunction = Spline1D(Xdata, Cdata,k=1,bc="extrapolate")
        currentAge = 66+i
        availableFunds = currentWealth + fairCouponRate(annuitizationLevel)
        consumed[i+1] = consumptionFunction(currentWealth+fairCouponRate(annuitizationLevel))
        #consumed[i+1] = fairCouponRate(annuitizationLevel)
        if (noisy == true)
            print("I am $currentAge and have $availableFunds. ")
        end
        savVec[i+1] = currentWealth + fairCouponRate(annuitizationLevel) - consumed[i+1]
        currentWealth = currentWealth + fairCouponRate(annuitizationLevel) - consumed[i+1]
        totalConsumed[i+1] += consumed[i+1]
        if i != 0
            totalConsumed[i+1] += totalConsumed[i]
        end
        ss = consumed[i+1]
        tt = β^i*probOfLiving*(consumed[i+1])^(1-ρ)/(1-ρ)
        if (noisy == true)
            println("I am consuming $ss, it is contributing $tt utility")
        end
        totalUtility += β^i*probOfLiving*(consumed[i+1])^(1-ρ)/(1-ρ)
        probOfLiving *= Φ(66+i+1)
        #accumulating wealth. Note Wealth does not contain annuities
        currentWealth = currentWealth*R
    end
    display(totalConsumed[end])
    ageVec = collect(66:(66+PeriodsToAdd))
    ax[:plot](ageVec,consumed,color=jset(0.5), lw = 2, alpha = 0.6, marker = ".",label = "Consumed")
    ax[:plot](ageVec,anuVec,color=jset(0.25), lw = 2, alpha = 0.6, label = "Annuity payment")
    #ax[:plot](ageVec,savVec,color=jset(0.125), lw = 2, alpha = 0.6, label = "Savings")
    ax[:legend](loc="upper right")
    xlabel("Age")
    ylabel("Amount Consumed")
    title("Annuities! Amount Consumed vs Age starting with $initialWealth units of money. Utility $totalUtility")
    grid("on")
    #display(fig)
    savefig("qqConsumptionVsTime.png")
    close(fig)
    fig, ax = subplots(figsize=(9,6))
    ax[:plot](ageVec, totalConsumed,color=jset(1), lw = 2, alpha = 0.6,label="Cumulative Consumption")
    ax[:plot](ageVec, wealthVec,color=jset(0.5), lw = 2, alpha = 0.6, label = "Wealth Reserves")
    ax[:plot](ageVec,anuVec.+wealthVec,color=jset(0.25), lw = 2, alpha = 0.6, label = "Cash on Hand")

    ax[:legend](loc="upper left")
    grid("on")
    xlabel("Age")
    ylabel("Cumulative Amount Consumed")
    title("Annuities! Cumulative Amount Consumed vs Age starting with $initialWealth units of money")
    #display(fig)
    savefig("qqCumulativeConsumption.png")
    #Print out total utility. Discounting for death actually INCREASES the expected utility.
    #This is a consequence of a strictly negative utility function. Is fine because you can't change mortality yourself.
    println("The total expected utility, discounted for time and risk of death, is $totalUtility.")
end

plotLifetimeConsumption(initialWealth,Float64(annLev-1),noisy = false)
