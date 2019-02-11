#NTS: Read Julia performance tips. I should use Git.
#GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL GLOBAL

#Runs the main calculations. Needs parameters, GothVP and Cnextp julia files.
#Implements Endogenous Grid Method for one choice variable, consumption.
#Anything not consumed is saved in a money market account paying a RF rate.
#No Income and so no risk of unemployment. Also no mortality
#As of now, no stochastic component.

ID = "LiqCo"
AnID = "Annuities0"
OptID = "Optim"
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
function UPrime(c::Array{Float64,2},ρ::Float64)
    return c.^(-ρ)
end
function inverseUPrime(c::Array{Float64,2},p::Float64)
    return c.^(-1/ρ)
end

#39 periods to add. Ages 66 to 105. 105 is the final period of life.
#Note the C=Y solution arises from consuming all of savings in the final periods and relies on no bequest.

#For the final period, the solution is to consume everything
#C is consumption
C = [fairCouponRate(stateGrid[a,b][1])+stateGrid[a,b][2] for a in 1:n,b in 1:n]
#X is cash on hand. This equals beginning of period wealth(R*s) + annuity income.
X = [fairCouponRate(stateGrid[a,b][1])+stateGrid[a,b][2] for a in 1:n,b in 1:n]
zeroVec = [0 for i in 1:n]
C = hcat(zeroVec,C)
X = hcat(zeroVec,X)

#Note that the first period is the last period of life. We recurse BACKWARDS through the problem
for i in 1:PeriodsToAdd
    #Gloval variables are bad. Will need to deal with scope soon.
    global C
    global X
    global μMat

    global χMat #DON'T CONFUSE χ (Chi) with X.
    # Taking the Euler Equation and applying inverseUPrime to each side gives and expression for consumption
    # For each saving grid point define in αVec, we find the corresponding consumption such that the saving is optimal.
    χMat = inverseUPrime(GothicVPrime(stateGrid,106-i),ρ)
    #μVec is cash on hand at the beginning of the period. cash on hand_t = c_t + s_t + annuities?
    #μMat = χMat + [fairCouponRate(stateGrid[a,b][1])+stateGrid[a,b][2] for a in 1:n,b in 1:n]
    μMat = χMat + [stateGrid[a,b][2] for a in 1:n,b in 1:n]
    #The columns of the matrix going from left to right correspond to travelling back in time. Note in final period, eat all.
    #Unnecesary if you interpolate over all points?
    if ID == "LiqCo"
        zeroVec = [0 for i in 1:n]
        χMat = hcat(zeroVec,χMat)
        μMat = hcat(zeroVec,μMat)
    end
    println("I made it to period $i")
    #adding new calculated data to matrices to be used for interpolation. C and X contain results for all periods.
    C = cat(dims=3,C,χMat)
    X = cat(dims=3,X,μMat)

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
