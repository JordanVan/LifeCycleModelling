#NTS: Read Julia performance tips. I should use Git.
#GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL

#Runs the main calculations. Needs parameters, GothVP and Cnextp julia files.
#Implements Endogenous Grid Method for one choice variable, consumption.
#Anything not consumed is saved in a money market account paying a RF rate.
#No Income and so no risk of unemployment. Also no mortality
#As of now, no stochastic component.
@time begin
ID = "LiqCo"
AnID = "Annuities0"
OptID = "optim"
if AnID == "Annuities0"
    println("Initial annuities allowed")
elseif AnID == "AnnuitiesAll"
    println("Purchase of annuities at arbitrary times allowed")
else
    println("No annuities in this model")
end


include("parameters.jl")
include("GothicVPrime.jl")
include("cNextPeriod.jl")
include("findOptimalStart.jl")

#Utility function is taken to be U(c) = c^(1-ρ)/(1-ρ). CRRA
#Defining derivative of utility and the corresponding inverse.
function UPrime(c,ρ::Float64)
    return c.^(-ρ)
end
function inverseUPrime(c,p::Float64)
    return c.^(-1/ρ)
end
function utilityFunction(c,ρ::Float64)
    return c.^(1-ρ)/(1-ρ)
end

#Our policy is a 6D tensors. 5D for any particular time period. The 5 dimensions are the state variables
#i.e. annuitisation, savings, healthState, cancerInsurance cover, LTC cover.
#For the final period, the solution is to consume everything
#C is consumption
C = [fairCouponRate(stateGrid[a,b,c,d,e][1])+stateGrid[a,b,c,d,e][2] for a in 1:n2,b in 1:n,c in 1:4,d in 1:n3,e in 1:n3]
#X is cash on hand. This equals beginning of period wealth(R*s) + annuity income.
if ID == "LiqCo"
    X = [fairCouponRate(stateGrid[a,b,c,d,e][1])+stateGrid[a,b,c,d,e][2] for a in 1:n2,b in 1:n,c in 1:4,d in 1:n3,e in 1:n3]
    zeroVec = [0.0 for a in 1:n2,b in 1:1, c in 1:4,d in 1:n3,e in 1:n3] #P.s. It's not a vector.
    C = cat(zeroVec,C,dims=2)
    X = cat(zeroVec,X,dims=2)
end


#Note that the first period is the last period of life. We recurse BACKWARDS through the problem
for i in 1:PeriodsToAdd
    global C
    global X
    global μTens
    global χTens #DON'T CONFUSE χ (Chi) with X.
    # Taking the Euler Equation and applying inverseUPrime to each side gives and expression for consumption
    # For each grid point, we find the corresponding consumption
    χTens = inverseUPrime(GothicVPrime(stateGrid,106-i),ρ)
    #μVec is cash on hand at the beginning of the period. cash on hand_t = c_t + s_t
    #μMat = χMat + [fairCouponRate(stateGrid[a,b][1])+stateGrid[a,b][2] for a in 1:n,b in 1:n]
    μTens = χTens + [stateGrid[a,b,c,d,e][2] for a in 1:n2,b in 1:n,c in 1:4,d in 1:n3,e in 1:n3]
    #The columns of the matrix going from left to right correspond to travelling back in time. Note in final period, eat all.
    #Unnecesary if you interpolate over all points?
    if ID == "LiqCo"
        zeroVec = [0.0 for a in 1:n2,b in 1:1, c in 1:4,d in 1:n3,e in 1:n3]
        χTens = cat(zeroVec,χTens,dims=2)
        μTens = cat(zeroVec,μTens,dims=2)
    end
    println("I made it to period $i")
    #adding new calculated data to matrices to be used for interpolation. C and X contain results for all periods.
    C = cat(dims=6,C,χTens)
    X = cat(dims=6,X,μTens)

end
optimalStart,bestUtility = findOptimalStart(initialWealth,numSims2);
println("Best utility is $bestUtility. Given by annuitising ",optimalStart[1]-1,"/100 cancering ", optimalStart[2]-1, "/5 LTCing ", optimalStart[3]-1, "/5")

end
