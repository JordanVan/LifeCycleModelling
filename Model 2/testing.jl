include("parameters.jl")
using Statistics
utilityVec = zeros(10000000)
for i in 1:10000000
    global utilityVec
    for (year,age) in enumerate(66:105)
        utilityVec[i] += β^(year-1)*-fairCouponRate(100.0)^(-1)
        #roll for death
        roll = rand(1)[1]
        if roll > Φ(age+1)
            break
        end
    end
end
println(mean(utilityVec))
