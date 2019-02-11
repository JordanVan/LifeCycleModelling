#This plots things. Be very careful with the intepretation
#This files will be used to plot many things. Currently its the same as Caroll 06 rewrite.
#Julia version
using LaTeXStrings
using PyPlot
using Dierckx
@time begin
include("parameters.jl")
include("main.jl")
end
fig, ax = subplots(figsize=(9,6))
jset = ColorMap("jet")
#ax[:plot](MuVec,ChiVec, color = jet(0),lw = 5,label=L"Unemp Model")
ax[:plot](μVec,χVec,color=jset(0), lw=2,
          alpha=0.8, label="Consumption(CashOnHand) for Initial Period",marker = "*")
ax[:plot](X[1:7,1],C[1:7,1],color=jset(1), lw = 2, alpha = 0.3, label = "45 degree (Final Period Age 105)", marker = "o")

if PeriodsToAdd == 39
    ax[:plot](X[:,31],C[:,31],color=jset(0.75), lw = 2, alpha = 0.3, label = "10th Period Age 75")
    ax[:plot](X[:,21],C[:,21],color=jset(0.5), lw = 2, alpha = 0.3, label = "20th Period Age 85")
    ax[:plot](X[:,11],C[:,11],color=jset(0.25), lw = 2, alpha = 0.3, label = "30th Period Age 95")
    ax[:plot](X[:,6],C[:,6],color=jset(0.125), lw = 2, alpha = 0.3, label = "35th Period Age 100")
end


ax[:legend](loc="upper left")
totalPeriods = PeriodsToAdd+1
title("Consumption vs Cash on Hand with No Income. $totalPeriods periods")
xlabel("x - Cash on Hand")
ylabel("c - Consumption")
display(fig)
savefig("ConsumptionFunctions.png")
#savefig("RealMortalityRates.png")
close(fig)

#Plotting consumption throughout life given an initial starting wealth
function plotLifetimeConsumption(initialWealth::Float64)
    fig, ax = subplots(figsize=(9,6))
    totalUtility = 0.0
    probOfLiving = 1.0
    currentWealth = initialWealth
    consumed = zeros(PeriodsToAdd+1)
    wealthVec = zeros(PeriodsToAdd+1)
    totalConsumed = zeros(PeriodsToAdd+1)
    #We're going FORWARDS in time in this for loop. Note the end-i terms.
    for i in 0:PeriodsToAdd
        wealthVec[i+1] = currentWealth
        Xdata = X[:,end-i]
        Cdata = C[:,end-i]
        consumptionFunction = Spline1D(Xdata, Cdata,k=1,bc="extrapolate")
        consumed[i+1] = consumptionFunction(currentWealth)
        currentWealth -= consumed[i+1]
        totalConsumed[i+1] += consumed[i+1]
        if i != 0
            totalConsumed[i+1] += totalConsumed[i]
        end
        totalUtility += β^i*probOfLiving*(consumed[i+1])^(1-ρ)/(1-ρ)
        probOfLiving *= Φ(66+i+1)
        #accumulating Interest
        currentWealth *= R
    end
    ageVec = collect(66:(66+PeriodsToAdd))
    ax[:plot](ageVec,consumed,color=jset(0.5), lw = 2, alpha = 0.6, marker = ".")
    xlabel("Age")
    ylabel("Amount Consumed")
    title("Amount Consumed vs Age starting with $initialWealth units of money")
    grid("on")
    display(fig)
    savefig("ConsumptionVsTime.png")
    close(fig)
    fig, ax = subplots(figsize=(9,6))
    ax[:plot](ageVec, totalConsumed,color=jset(1), lw = 2, alpha = 0.6,label = "Cumulative Consumption")
    ax[:plot](ageVec, wealthVec,color=jset(0.25), lw = 2, alpha = 0.6, label = "Wealth Reserves")
    ax[:legend](loc="upper left")
    grid("on")
    xlabel("Age")
    ylabel("Cumulative Amount Consumed")
    title("Cumulative Amount Consumed vs Age starting with $initialWealth units of money")
    display(fig)
    display(wealthVec)
    savefig("CumulativeConsumption.png")
    #Print out total utility. Discounting for death actually INCREASES the expected utility.
    #This is a consequence of a strictly negative utility function. Is fine because you can't change mortality yourself.
    println("The total expected utility, discounted for time and risk of death, is $totalUtility.")
end

plotLifetimeConsumption(100.0)
