#Main Function which calls and imports relevant functions.
include("parameters.jl")
include("bellmanOperator.jl")
#using .bellmanOperator
@time begin
ID = "aLiqCo"
AnID = "AnnuitiesAll"
if AnID == "Annuities0"
    println("Initial annuities allowed")
elseif AnID == "AnnuitiesAll"
    println("Purchase of annuities at arbitrary times allowed")
else
    println("No annuities in this model")
end

#Utility function is taken to be U(c) = c^(1-ρ)/(1-ρ). CRRA
function utility(consumption,RRA::Float64)
    return consumption.^(1-RRA)/(1-RRA)
end

#For the final period, the solution is to consume everything INCLUDING the annuities payment
#Cash on hand is available cash entering a time period including the latest annuities payment
#Consumption matrix is now policy or Choices matrix. First duple entry is consumption, second is optimal new annuities.
C = [(stateGrid[a,b][1],0.0) for a in 1:n, b in 1:n2,c in 1:1]
#The associated Value function W for the last period
#extract the consumption part of the policy matrix. Extra cat is to convert 2d array to flat 3d array.
W = cat(dims=3,utility.([C[i,j][1] for i in 1:n, j in 1:n2],ρ))

#Note that the first period is the last period of life. We recurse BACKWARDS through the problem
for i in 1:PeriodsToAdd
    global C
    global W
    ageInPeriod = 105 - i
    #Getting the value functions and consumption policy for the next period (which would be backwards in time)
    newValue,newConsumption = bellman(W,stateGrid,R,β,ρ,utility,ageInPeriod,Φ)
    #display(newConsumption)
    #adding new calculated data to matrices to be used for interpolation. C and X contain results for all periods.
    W = cat(dims=3,W,newValue)
    C = cat(dims=3,C,newConsumption)
    currentTime = Dates.Time(Dates.now())
    println("I made it to period $i. The time is $currentTime")
end

#=
if ID=="LiqCo"
    #I don't even think this serves a purpose anymore
    #I'm pretty sure if I interpolate over all points on the 2d grid, then there is no need for this.
    #I'll do it anyway becaues my grids are actually wrong at this point in time.
    #I'll arbitarily chooes to add the zeros on the left
    zero3d = [(0.0) for a in 1.0:n, b in 1:1,c in 1:(PeriodsToAdd+1)]  # produce a matrix of zeros
    println(size(zero3d))
    C=cat(dims=2,zero3d,C)  # zero is added to each period's interpolation data to handle liquidity constraints
    X=cat(dims=2,zero3d,X)  # zero is added to each period's interpolation data to handle liquidity constraints
end
=#

end
