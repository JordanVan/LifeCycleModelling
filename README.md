# LifeCycleModelling
A collection of lifecycle models written in Julia. The code is more or less complete, albeit unorganised. I am currently working on a report to complement the code between my other obligations. Once it is complete, I will look to update this readme. Contact me directly if you have any questions.

Model 1 - Consumption/Savings model  
Model 2 - Consumption/Savings/Initial Annuitisation model  
Model 4(3 in report)- Consumption/Savings/Arbitrary Annuitisation model  
Model 5(4 in report) - Consumption/Savings/Initial Annuitisation/Initial Cancer Insurance/Initial LTC Insurance model  

A quick note on tractability and run time.
----------------------------
Julia needs to precompile so the first time running any model will have an additional overhead. Other than that, the first two models run fairly quickly, taking a handful of seconds.

The third model is slow, because value function iteration requires optimisation. Furthermore, the objective function does not behave nicely meaning that the optimisation algorithms available to us are slower in convergence. On a modern desktop computer, expect at least 15 minutes to get an accurate result and upwards of 10 hours for maximum accuracy. This can be set by the optimiser's settings. Expect diminishing results after an hour or so of runtime.

The fourth model uses the same method as the first two models. While runtime is exponential in the number of variables, this is not the cause of its extended(10+ hour) runtime. Solving for the optimal policy given any initial state is quick, taking only 10 or so seconds. However, determining the optimal initial state requires many simulations due to the stochastic nature of health in the lifecycle. I advise against adding more stochastic components, such as investment returns, into the model unless an alternative method is used. Though I will note, since health states are limited to health, critical illness and long term care, there is significance variance between simluated lives. A investment return following a probability distribution will probably cause less drastic shifts in life quality, so fewer simulations are needed to capture an accurate portrait of the 'typical' life given some starting conditions.
