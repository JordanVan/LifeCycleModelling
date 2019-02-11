#Testing github

#NTS: Read Julia performance tips. I should use Git.
#GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL

#Runs the main calculations. Needs parameters, GothVP and Cnextp julia files.
#Implements Endogenous Grid Method for one choice variable, consumption.
#Anything not consumed is saved in a money market account paying a RF rate.
#No Income and so no risk of unemployment. Also no mortality
#As of now, no stochastic component.
ID = "LiqCoafds"
AnID = "Annuities0"
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

#Utility function is taken to be U(c) = c^(1-ρ)/(1-ρ). CRRA
#Defining derivative of utility and the corresponding inverse.
function UPrime(c::Array{Float64,1},ρ::Float64)
    return c.^(-ρ)
end
function inverseUPrime(c::Array{Float64,1},p::Float64)
    return c.^(-1/ρ)
end

#39 periods to add. Ages 66 to 105. 105 is the final period of life.
PeriodsToAdd = 39 # number of extra periods to add onto initial C=Y solution.
#Note the C=Y solution arises from consuming all of savings in the final periods and relies on no bequest.

#C is consumption
C = collect(0:n-1)
#X is cash on hand. With no income, this is synonomous wiht
X = collect(0:n-1)

#Note that the first period is the last period of life. We recurse backwards through the problem
for i in 1:PeriodsToAdd
    #Gloval variables are bad. Will need to deal with scope soon.
    global C
    global X
    global μVec
    global χVec #DON'T CONFUSE χ (Chi) with X.
    # Taking the Euler Equation and applying inverseUPrime to each side gives and expression for consumption
    # For each saving grid point define in αVec, we find the corresponding consumption such that the saving is optimal.
    χVec = inverseUPrime(GothicVPrime(αVec,106-i),ρ)
    μVec = αVec + χVec #μVec is cash on hand at the beginning of the period. cash on hand_t = c_t + s_t

    #adding new calculated data to matrices to be used for interpolation. C and χ contain results for all periods.
    #The columns of the matrix going from left to right correspond to travelling back in time. Note in final period, eat all.
    #= Unnecessary
    if ID == "LiqCo"
        #Add the liquidity constraint now not later becaues future periods may depend on it.
        #literally the number 0 in a 1 element array
        zero = [0]
        χVec = vcat(zero,χVec)
        μVec = vcat(zero,μVec)
    end
    =#
    C = hcat(C,χVec)
    X = hcat(X,μVec)

end


if ID=="LiqCo"
    zerov=collect(range(0,stop = 0,length = PeriodsToAdd+1))'  # produce a vector that is made up of zeroes
    C=vcat(zerov,C)  # zero is added to each period's interpolation data to handle liquidity constraints
    X=vcat(zerov,X)  # zero is added to each period's interpolation data to handle liquidity constraints
end
