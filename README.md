# Truth-Tracking in Explanatory Reasoning: Explanatory Power versus Explanatory Goodness

## WHAT IS IT?

This is an agent-based model designed to compare the truth-tracking features of two measures of explanatory reasoning: explanatory power, given by $`\mathcal{E}_{P}(e,h) = \log\left\lbrack \frac{P\left( e \middle| h \right)}{P(e)} \right\rbrack`$, and explanatory goodness, given by $`\mathcal{E}_{G}(e,h) = \mathcal{E}_{P}(e,h) - \frac{1}{2} \:I(h)`$ where $`I(h) = - \;\log P(h)`$ is the informational complexity of $`h`$. 

## HOW IT WORKS

The basic idea: agents are divided into two groups, *power-seekers* and *goodness-seekers*, which respectively do inferences using explanatory power and explanatory goodness based on the evidence available and on their prior degrees of belief. In each simulation a certain hypothesis is true. The model tests the extent that a certain measure correctly chooses the truth (truth-hit) and how accurately it does (Brier scores).

Here is the model procedure:

1. Assign prior degrees of belief for each of the mutually exclusive hypotheses $`h_1`$ and $`h_2`$ to agents from both groups (100 goodness-seekers and 100 power-seekers). $`P(h_1)`$ is drawn randomly from a normal distribution $`\mathcal{N}(\mu, 0.25^2)`$, where $`\mu`$ is fixed for each simulation with some value from the set $`\{0.01, 0.1, 0.2, \dots, 0.99\}`$, and $`P(h_2) = 1 - P(h_1)`$.
2. Set whether $`h_1`$ or $`h_2`$ is true.
  - Calibrated Condition: The objective chance of a hypothesis being true for any given run is set to be equal to the goodness-seekers' average prior belief in it. That objective chance determines the proportion of simulations in which each hypothesis will be true.
  - Stochastic Condition: The true hypothesis is randomly assigned from the uniform distribution over [0,1].

3. Distribute the evidence: each location $`k`$ has a fixed but distinct pair of likelihoods, $`[P(e_k \mid h_1), P(e_k \mid h_2)]`$. These likelihoods are randomly drawn from normal distributions $`\mathcal{N}(\mu, 0.2^2)`$, where $`\mu`$ is drawn from the set $`\{0.01, 0.1, 0.2, \dots, 1.0\}`$, with the restriction that the evidence overall favors the truth; i.e., $`P(e|\text{true}) - P(e|\text{false}) > 0`$, where $`P(e|\cdot)`$ is the average $`\mu`$ for each likelihood distribution.
4. Each time step:
  - Agents observe the likelihoods for each location and select the best hypothesis according to their group’s measure ($`\mathcal{E}_P`$ or $`\mathcal{E}_G`$).
  - Agents update their priors via Bayesian conditionalization using the evidence from their current location.
  - Record truth hit and Brier score.


## HOW TO USE IT

You can play with the different parameters, such as prior degrees of belief and standard deviation for h1, distribution of the evidence for the two hypotheses, and whether agents update.

## THINGS TO NOTICE

Notice how the truth-tracking reports, the truth hit and the Brier scores, change as a function of distinct combinations of parameters.


## CREDITS AND REFERENCES

This model is part of a research project in philosophy of science which focuses on Bayesian characterizations of explanatory virtues. To read the most recent draft discussing the model results and its significance to our understanding of explanatory reasoning, please, email me at [gesieldasilva@missouri.edu](mailto:gesieldasilva@missouri.edu).

You can check updated versions at the model [GitHub page](https://github.com/gesielbdasilva/abm-EP-EG-netlogo).

To get to know my work and other projects I've developed, please, email me at the address above or visit my webpage: [gesieldasilva.com](https://gesieldasilva.com)
