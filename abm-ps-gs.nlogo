breed [power-seekers power-seeker]
breed [goodness-seekers goodness-seeker]


globals [
  truth-freq-h1
  current-truth
  truth-likelihood
  falsity-likelihood
  truth-prior-ps
  truth-prior-gs
  prop-truth-ps
  prop-truth-gs
  stopping-tick
  falsity-prior-ps
  falsity-prior-gs

  agg-brier-ps
  agg-brier-gs
  agg-truth-hit-ps
  agg-truth-hit-gs
  agg-brier-sd-ps
  agg-brier-sd-gs
  agg-truth-hit-sd-ps
  agg-truth-hit-sd-gs
]

turtles-own [
  count-h1 ; number of times h1 is better than h2
  count-h2 ; number of times h2 is better than h1
  prior-h1 ; prior credence in h1
  prior-h2 ; prior credence in h2
  prop-h1 ; prop of times h1 is the best explanation (prop-h1 = count-h1/[count-h1 + count-h2])
  prop-h2 ; prop of times h2 is the best explanation (prop-h2 = count-h2/[count-h1 + count-h2])
  strategy ; update strategy
  truth-alignment ; tracks whether the agent aligns with the ground truth
  k1 ; variable to make calculations of EG_1 and EG_2 simpler
  k2 ; variable to make calculations of EG_1 and EG_2 simpler
  EP_1 ; value of power for h1
  EP_2 ; value of power for h2
  EG_1 ; value of goodness for h1
  EG_2 ; value of goodness for h2
  preferred-hypothesis ; truth-alignment variable
  truth-hit?
  p-h1
  p-h2
  brier
  logscore
]

patches-own [
  likelihood-h1 ; represents strength of evidence for h2 on this patch – i.e., P(e|h1)
  likelihood-h2 ; represents strength of evidence for h2 on this patch – i.e., P(e|h2)
]

; Truth-alignment reporter
to-report alignment-of [ agset ]
  report mean [ truth-hit? ] of agset   ;; simple average of 0/1
end

to-report brier-of-ps
  report mean [brier] of power-seekers
end

to-report brier-of-gs
  report mean [brier] of goodness-seekers
end

; initialize the world
to setup
  clear-turtles
  clear-patches
  ; clear-all-plots (This is already in 'go', so it's not needed here)
  ; clear-drawing (If you draw on the world)
  setup-patches
  setup-turtles
; set up truth-freq according to a condition
  if condition = "cal"  [set truth-freq-h1 round (avg-prior-h1-goodness-seekers * 100)]
  if condition = "sto"  [set truth-freq-h1 round (random 100)]
  if condition = "nor" [
  let raw-freq random-normal (avg-prior-h1-goodness-seekers * 100) 25
  let rounded-freq round raw-freq
  set truth-freq-h1 max list 0 min list 100 rounded-freq
  ]
;  set the ground truth for the entire run.
  ifelse random 100 <= truth-freq-h1 [ set current-truth "h1"][ set current-truth "h2"]
  reset-ticks
end

; create evidence patches
to setup-patches
  ask patches [
    set likelihood-h1 max list 0 min list 1 (random-normal avg-likelihood-h1 0.2)   ; each patch has P(e|h1) between 0.001 and the number assigned by the slider
    if likelihood-h1 < 0.001 [ set likelihood-h1 0.001 ] ; ensures NetLogo doesn't go crazy with logarithms of small numbers

    set likelihood-h2 max list 0 min list 1 (random-normal avg-likelihood-h2 0.2)  ; each patch has P(e|h2) between 0.001 and the number assigned by the slider
    if likelihood-h2 < 0.001 [ set likelihood-h2 0.001 ] ; ensures NetLogo's doesn't go crazy with logarithms of small numbers

    ; calculate set color based on the dominant likelihood
    let likelihood-diff likelihood-h1 - likelihood-h2
    if likelihood-diff > 1 [
      set pcolor scale-color green likelihood-diff 0 1  ; darker green as likelihood-diff increases
    ]
    if likelihood-diff < 1 [
      set pcolor scale-color green (1 - likelihood-diff) 0 1  ; lighter green as likelihood-diff decreases
    ]
    if likelihood-diff = 0 [
      set pcolor green  ; set to pure green when the likelihoods are the same
    ]
  ]
end

; create agents
to setup-turtles
  create-power-seekers number-of-turtles-each [
    set color red
    set  count-h1 0
    set  count-h2 0
    set  prop-h1 0
    set  prop-h2 0
    set prior-h1 max list 0 min list 1 (random-normal avg-prior-h1-power-seekers sd-priors-ps)
    if prior-h1 > 1 [set prior-h1 1]
    set  prior-h2 (1 - prior-h1)
    if prior-h1 > 1 [set prior-h1 1]
      set strategy "power"
      setxy random-xcor random-ycor
  ]
  create-goodness-seekers number-of-turtles-each [
    set color blue
    set  count-h1 0
    set  count-h2 0
    set  prop-h1 0
    set  prop-h2 0
    set prior-h1 max list 0 min list 1 (random-normal avg-prior-h1-goodness-seekers sd-priors-gs)
    if prior-h1 > 1 [set prior-h1 1]
    set  prior-h2 (1 - prior-h1)
    if prior-h1 > 1 [set prior-h1 1]
    set strategy "goodness" ; strategy type
    setxy random-xcor random-ycor ; place them randomly in the world
  ]
end

; main update loop
; --- 1. This procedure runs the logic for a single tick ---
to run-one-tick
  ask turtles [
    move
    update
  ]
  tick
end

to go

  clear-all-plots

  let num-ticks (total-ticks + 1)
  set agg-brier-ps n-values num-ticks [0]
  set agg-brier-gs n-values num-ticks [0]
  set agg-truth-hit-ps n-values num-ticks [0]
  set agg-truth-hit-gs n-values num-ticks [0]

  set agg-brier-sd-ps n-values num-ticks [0]
  set agg-brier-sd-gs n-values num-ticks [0]
  set agg-truth-hit-sd-ps n-values num-ticks [0]
  set agg-truth-hit-sd-gs n-values num-ticks [0]

  repeat num-simulations [
    setup

    while [ticks < total-ticks] [
      run-one-tick

      let b-ps mean [brier] of power-seekers
      let b-gs mean [brier] of goodness-seekers
      let th-ps mean [truth-hit?] of power-seekers
      let th-gs mean [truth-hit?] of goodness-seekers

      let sd-b-ps standard-deviation [brier] of power-seekers
      let sd-b-gs standard-deviation [brier] of goodness-seekers
      let sd-th-ps standard-deviation [truth-hit?] of power-seekers
      let sd-th-gs standard-deviation [truth-hit?] of goodness-seekers

      ; add the current value to the aggregate lis
      set agg-brier-ps (replace-item ticks agg-brier-ps (item ticks agg-brier-ps + b-ps))
      set agg-brier-gs (replace-item ticks agg-brier-gs (item ticks agg-brier-gs + b-gs))
      set agg-truth-hit-ps (replace-item ticks agg-truth-hit-ps (item ticks agg-truth-hit-ps + th-ps))
      set agg-truth-hit-gs (replace-item ticks agg-truth-hit-gs (item ticks agg-truth-hit-gs + th-gs))

      set agg-brier-sd-ps (replace-item ticks agg-brier-sd-ps (item ticks agg-brier-sd-ps + sd-b-ps))
      set agg-brier-sd-gs (replace-item ticks agg-brier-sd-gs (item ticks agg-brier-sd-gs + sd-b-gs))
      set agg-truth-hit-sd-ps (replace-item ticks agg-truth-hit-sd-ps (item ticks agg-truth-hit-sd-ps + sd-th-ps))
      set agg-truth-hit-sd-gs (replace-item ticks agg-truth-hit-sd-gs (item ticks agg-truth-hit-sd-gs + sd-th-gs))
    ]
  ]

  plot-aggregate-results

  update-prior-dist
end

; turtles move randomly
to move
  rt random 360
  fd 1
end

;;;;;;;;;;;;;;;;;;;;;;;;STRATEGIES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; set "strategies"
to update
  let evidence-here-h1 [likelihood-h1] of patch-here
  let evidence-here-h2 [likelihood-h2] of patch-here
  if current-truth = "h1" [
    set truth-prior-ps avg-prior-h1-power-seekers
    set falsity-prior-ps 1 - avg-prior-h1-power-seekers
    set truth-prior-gs avg-prior-h1-goodness-seekers
    set falsity-prior-gs 1 - avg-prior-h1-goodness-seekers
    set truth-likelihood avg-likelihood-h1
    set falsity-likelihood avg-likelihood-h2
    set prop-truth-ps mean [prop-h1] of power-seekers
    set prop-truth-gs mean [prop-h1] of goodness-seekers]
  if current-truth = "h2" [
    set truth-prior-ps 1 - avg-prior-h1-power-seekers
    set falsity-prior-ps avg-prior-h1-power-seekers
    set truth-prior-gs 1 - avg-prior-h1-goodness-seekers
    set falsity-prior-gs avg-prior-h1-goodness-seekers
    set truth-likelihood avg-likelihood-h2
    set falsity-likelihood avg-likelihood-h1
    set prop-truth-ps mean [prop-h2] of power-seekers
    set prop-truth-gs mean [prop-h2] of goodness-seekers
  ]
  if strategy = "power" [ ;power-seekers strategy
    let P_e (evidence-here-h1 * prior-h1 + evidence-here-h2 * prior-h2) ; computes P(e) using the rule of total probability
    ;explanatory power
    set EP_1 (log evidence-here-h1 10) - (log P_e 10)
    set EP_2 (log evidence-here-h2 10) - (log P_e 10)
    ;comparison procedure
    if EP_1 > EP_2 [set count-h1 count-h1 + 1]
    if EP_2 > EP_1 [set count-h2 count-h2 + 1]
    ;updating procedure
    if p-s-bayes-updating? [
      set prior-h1 (evidence-here-h1 * prior-h1 / P_e)
      set prior-h2 (evidence-here-h2 * prior-h2 / P_e)
      if prior-h1 > 1 [set prior-h1 1] ; to avoid anomalous priors
      if prior-h2 > 1 [set prior-h2 1] ; to avoid anomalous priors
    ]

    ifelse (count-h1 + count-h2) > 0 [ ;ensures NetLogo will be able to calculate the fraction below
      set prop-h1 (count-h1 / (count-h1 + count-h2)) ; prop. h1 is the best
      set prop-h2 (count-h2 / (count-h1 + count-h2)) ; prop. h2 is the best
      set prop-h1 max list 0 min list 1 prop-h1 ; clamp values
      set prop-h2 max list 0 min list 1 prop-h2 ; clamp values
    ] [
      set prop-h1 0
      set prop-h2 0
    ]

  ; truth-alignment procedure for power-seekers
  set preferred-hypothesis ifelse-value (EP_1 > EP_2) ["h1"] ["h2"] ;picks out the selected hypothesis
  ifelse preferred-hypothesis = current-truth [ set truth-hit? 1 ] [ set truth-hit? 0 ]

;; ---------- Truth scores for EP ----------

let w1 10 ^ EP_1     ;; for power‑seekers
let w2 10 ^ EP_2

set p-h1 w1 / (w1 + w2)
set p-h2 w2 / (w1 + w2)

ifelse current-truth = "h1" [set brier (1 - p-h1) ^ 2] [set brier (1 - p-h2) ^ 2]

;set logscore - log (ifelse outcome = 1 [p-h1 10] [(1 - p-h1) 10])



;  ifelse preferred-hypothesis = current-truth [set truth-alignment truth-alignment + 1] [set truth-alignment truth-alignment - 1] ;truth alignment counting
;  if truth-alignment > ticks [set truth-alignment ticks]  ; clamp values
  ]

  if strategy = "goodness" [;goodness-seekers strategy
    let P_e (evidence-here-h1 * prior-h1 + evidence-here-h2 * prior-h2); computes P(e) using the rule of total probability

    ifelse prior-h1 < (10 ^ -300) [set k1 -300] [set k1 log prior-h1 10] ; k1 facilitates NetLogo's handling the log of very low numbers
    ifelse prior-h2 < (10 ^ -300) [set k2 -300] [set k2 log prior-h2 10]; k1 facilitates NetLogo's handling the log of very low numbers

    set EG_1 (log evidence-here-h1 10) - log P_e 10 + (0.5 * k1) ; explanatory goodness for h1
    set EG_2 (log evidence-here-h2 10) - log P_e 10 + (0.5 * k2) ; explanatory goodness for h2

    if EG_1 > EG_2 [set count-h1 count-h1 + 1] ;comparison procedure
    if EG_2 > EG_1 [set count-h2 count-h2 + 1] ;comparison procedure

    if g-s-bayes-updating? [ ;updating procedure
      set prior-h1 (evidence-here-h1 * prior-h1 / P_e) ; updating P(h1)
      set prior-h2 (evidence-here-h2 * prior-h2 / P_e) ; updating P(h2)
      if prior-h1 > 1 [set prior-h1 1] ; to avoid anomalous priors
      if prior-h2 > 1 [set prior-h2 1] ; to avoid anomalous priors
    ]


    ifelse (count-h1 + count-h2) > 0 [ ;ensures NetLogo will be able to calculate the fraction below
      set prop-h1 (count-h1 / (count-h1 + count-h2)) ; prop. h1 is the best
      set prop-h2 (count-h2 / (count-h1 + count-h2)) ; prop. h2 is the best
      set prop-h1 max list 0 min list 1 prop-h1  ; clamp values
      set prop-h2 max list 0 min list 1 prop-h2  ; clamp values
    ] [
      set prop-h1 0
      set prop-h2 0
    ]

  ; truth-alignment procedure for goodness-seekers
  set preferred-hypothesis ifelse-value (EG_1 > EG_2) ["h1"] ["h2"] ;picks out the selected hypothesis
  ifelse preferred-hypothesis = current-truth [ set truth-hit? 1 ] [ set truth-hit? 0 ]

;  ifelse preferred-hypothesis = current-truth [set truth-alignment truth-alignment + 1] [set truth-alignment truth-alignment - 1] ;truth alignment counting
;  if truth-alignment > ticks [set truth-alignment ticks]  ; clamp values

;; ---------- Truth scores for EG ----------

let w1 10 ^ EG_1
let w2 10 ^ EG_2
set p-h1 w1 / (w1 + w2)
set p-h2 w2 / (w1 + w2)
ifelse current-truth = "h1" [set brier (1 - p-h1) ^ 2] [set brier (1 - p-h2) ^ 2]

;set logscore - ln (if outcome = 1 [p-h1] [1 - p-h1])



  ]

end

;:::::::::::::::::::::::::::::PLOTS:::::::::::::::::::::::::::::::::::

; update plot for prop(h1)

; plotting procedure
to plot-aggregate-results
  plot-aggregate-brier-means
  plot-aggregate-truth-hit-means
  plot-aggregate-brier-sds
  plot-aggregate-truth-hit-sds
end

; Plots the average Brier scores
to plot-aggregate-brier-means
  ; Calculate the average by dividing each item in the sum list by num-simulations
  let avg-b-ps (map [ x -> x / num-simulations ] agg-brier-ps)
  let avg-b-gs (map [ x -> x / num-simulations ] agg-brier-gs)

  set-current-plot "Brier over Time"

  set-current-plot-pen "PS"
  plot-pen-reset ; Start pen at x=0
  foreach avg-b-ps [ y-val ->
    plot y-val ; Plot each value in the list
  ]

  set-current-plot-pen "GS"
  plot-pen-reset ; Start pen at x=0
  foreach avg-b-gs [ y-val ->
    plot y-val ; Plot each value in the list
  ]
end

; Plots the average Truth-Hit rate
to plot-aggregate-truth-hit-means
  let avg-th-ps (map [ x -> x / num-simulations ] agg-truth-hit-ps)
  let avg-th-gs (map [ x -> x / num-simulations ] agg-truth-hit-gs)

  set-current-plot "Truth Hit over Time"

  set-current-plot-pen "PS"
  plot-pen-reset
  foreach avg-th-ps [ y-val ->
    plot y-val
  ]

  set-current-plot-pen "GS"
  plot-pen-reset
  foreach avg-th-gs [ y-val ->
    plot y-val
  ]
end

; Plots the average Brier SD (SD among agents
to plot-aggregate-brier-sds
  let avg-sd-b-ps (map [ x -> x / num-simulations ] agg-brier-sd-ps)
  let avg-sd-b-gs (map [ x -> x / num-simulations ] agg-brier-sd-gs)

  set-current-plot "Brier SD"

  set-current-plot-pen "PS"
  plot-pen-reset
  foreach avg-sd-b-ps [ y-val ->
    plot y-val
  ]

  set-current-plot-pen "GS"
  plot-pen-reset
  foreach avg-sd-b-gs [ y-val ->
    plot y-val
  ]
end

; Plots the average Truth-Hit SD (SD among agents
to plot-aggregate-truth-hit-sds
  let avg-sd-th-ps (map [ x -> x / num-simulations ] agg-truth-hit-sd-ps)
  let avg-sd-th-gs (map [ x -> x / num-simulations ] agg-truth-hit-sd-gs)

  set-current-plot "Truth hit SD"

  set-current-plot-pen "PS"
  plot-pen-reset
  foreach avg-sd-th-ps [ y-val ->
    plot y-val
  ]

  set-current-plot-pen "GS"
  plot-pen-reset
  foreach avg-sd-th-gs [ y-val ->
    plot y-val
  ]
end

; update priors distribution histogram
to update-prior-dist
  set-current-plot "P(h1) Distribution"
  clear-plot
  set-current-plot-pen "PS"
  histogram [prior-h1] of power-seekers
  set-current-plot-pen "GS"
  histogram [prior-h1] of goodness-seekers
end


;##################################################################################################
@#$#@#$#@
GRAPHICS-WINDOW
253
10
531
289
-1
-1
8.2
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
0
10
63
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
0
495
172
528
avg-likelihood-h2
avg-likelihood-h2
0.01
1
0.5
0.001
1
NIL
HORIZONTAL

BUTTON
79
10
142
43
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
0
161
215
194
avg-prior-h1-power-seekers
avg-prior-h1-power-seekers
0.001
0.999
0.5
0.001
1
NIL
HORIZONTAL

SLIDER
0
79
214
112
number-of-turtles-each
number-of-turtles-each
2
500
10.0
1
1
NIL
HORIZONTAL

SLIDER
0
454
172
487
avg-likelihood-h1
avg-likelihood-h1
0.01
1
1.0
0.001
1
NIL
HORIZONTAL

SWITCH
0
660
171
693
g-s-bayes-updating?
g-s-bayes-updating?
0
1
-1000

PLOT
951
10
1276
287
Truth Hit over Time
time steps
Truth hit (average)
0.0
1.0
0.0
1.0
true
true
"set-current-plot \"Truth Hit over Time\"" ""
PENS
"PS" 1.0 0 -2674135 true "" ""
"GS" 1.0 0 -13345367 true "" ""

PLOT
252
325
532
521
P(h1) Distribution
NIL
NIL
0.0
1.01
0.0
100.0
true
true
"set-current-plot \"P(h1) Distribution\"" ""
PENS
"PS" 0.01 0 -955883 true "" ""
"GS" 0.01 0 -11221820 true "" ""

SLIDER
0
207
215
240
avg-prior-h1-goodness-seekers
avg-prior-h1-goodness-seekers
0.001
0.999
0.5
0.001
1
NIL
HORIZONTAL

MONITOR
247
544
382
589
mean [prior-h1] of p-s
mean [prior-h1] of power-seekers
4
1
11

MONITOR
393
545
528
590
mean [prior-h1] of g-s
mean [prior-h1] of goodness-seekers
4
1
11

SWITCH
0
618
170
651
p-s-bayes-updating?
p-s-bayes-updating?
0
1
-1000

PLOT
949
342
1276
554
Truth hit SD
time steps
Truth hit SD
0.0
1.0
0.0
0.5
true
true
"set-current-plot \"Truth hit SD\"" ""
PENS
"PS" 1.0 0 -955883 true "set-current-plot-pen \"PS\"" ""
"GS" 1.0 0 -11221820 true "set-current-plot-pen \"GS\"" ""

SLIDER
0
255
173
288
sd-priors-ps
sd-priors-ps
0
0.5
0.25
.01
1
NIL
HORIZONTAL

SLIDER
0
298
172
331
sd-priors-gs
sd-priors-gs
0
0.5
0.25
0.01
1
NIL
HORIZONTAL

TEXTBOX
0
142
63
160
Priors setup
11
0.0
1

TEXTBOX
0
434
150
452
Likelihoods setup
11
0.0
0

PLOT
580
10
905
289
Brier over Time
time steps
Brier score (average)
0.0
1.0
0.0
1.0
true
true
"set-current-plot \"Brier over Time\"" ""
PENS
"PS" 1.0 0 -2674135 true "set-current-plot-pen \"PS\"" ""
"GS" 1.0 0 -13345367 true "set-current-plot-pen \"GS\"" ""

SLIDER
0
346
172
379
total-ticks
total-ticks
0
100
10.0
1
1
NIL
HORIZONTAL

CHOOSER
0
733
138
778
condition
condition
"cal" "sto" "nor"
0

MONITOR
248
615
353
660
NIL
current-truth
17
1
11

PLOT
576
343
906
555
Brier SD
time steps
Brier SD
0.0
1.0
0.0
0.5
true
true
"set-current-plot \"Brier SD\"" ""
PENS
"PS" 1.0 0 -955883 true "set-current-plot-pen \"PS\"" ""
"GS" 1.0 0 -8990512 true "set-current-plot-pen \"GS\"" ""

SLIDER
0
395
172
428
num-simulations
num-simulations
1
10000
100.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
# Truth-Tracking in Explanatory Reasoning: Explanatory Power versus Explanatory Goodness

## WHAT IS IT?

This is an agent-based model designed to compare the truth-tracking features of two measures of explanatory reasoning: explanatory power, given by **EP(e,h) = log [Pr(e|h)/Pr(e)]**, and explanatory goodness, given by **EG(e,h) = EP - I(h)** where **I(h) = - log Pr(h)** is the informational complexity of **h**. 


## HOW IT WORKS

The basic idea: agents are divided into two groups, *power-seekers* and *goodness-seekers*, which respectively do inferences using explanatory power and explanatory goodness based on the evidence available and on their prior degrees of belief. In each simulation a certain hypothesis is true. The model tests the extent that a certain measure correctly chooses the truth (truth-hit) and how accurately it does (Brier scores).

Here is the model procedure:

1. Assign prior degrees of belief for each of the mutually exclusive hypotheses h1 and h2 to agents from both groups (100 goodness-seekers and 100 power-seekers). P (h1) is drawn randomly from a normal distribution N (μ, 0.252), where μ is fixed for each simulation with some value from the set {0.01, 0.1, 0.2, . . . , 0.99}, and P (h2) = 1 − P (h1).
2. Set whether h1 or h2 is true.
- Calibrated Condition: The objective chance of a hypothesis being true for any given
run is set to be equal to the goodness-seekers’ average prior belief in it. That objective
chance determines the proportion of simulations in which each hypothesis will be true.
- Stochastic Condition: The true hypothesis is randomly assigned from the uniform
distribution over [0,1].
3. Distribute the evidence: each location k has a fixed but distinct pair of likelihoods,
[P (ek|h1), P (ek|h2)]. These likelihoods are randomly drawn from normal distributions N(μ, 0.22), where μ is drawn from the set {0.01, 0.1, 0.2, . . . , 1.0}, with the restriction
that the evidence overall favors the truth; i.e., P (e|true) − P (e|false) > 0, where P(e|·) is the average μ for each likelihood distribution.
4. Each time step:
- Agents observe the likelihoods for each location and select the best hypothesis accord-
ing to their group’s measure (EP or EG).
- Agents update their priors via Bayesian conditionalization using the evidence from
their current location.
- Record truth hit and Brier score.


## HOW TO USE IT

You can play with the different parameters, such as prior degrees of belief and priors standard deviation, distribution of the evidence for the two hypotheses, and whether agents update. You can also change the number of simulations in each batch. Observe how the truth-tracking scores change for each parameters combination you choose.

## THINGS TO NOTICE

Notice how the truth-tracking reports, the truth hit and the Brier scores, change as a function of distinct combinations of parameters.


## CREDITS AND REFERENCES

This model is part of a research project in philosophy of science which focuses on Bayesian characterizations of explanatory virtues. To read the most recent draft discussing the model results and its significance to our understanding of explanatory reasoning, please, email me at [gesieldasilva@missouri.edu](mailto:gesieldasilva@missouri.edu).

You can check updated versions at the model [GitHub page](https://github.com/gesielbdasilva/abm-EP-EG-netlogo).

To get to know my work and other projects I've developed, please, email me at the address above or visit my webpage: [gesieldasilva.com](https://gesieldasilva.com)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Paper Data Experiment TH per run (Jul 2025)" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 100</exitCondition>
    <metric>truth-likelihood</metric>
    <metric>falsity-likelihood</metric>
    <metric>truth-prior-ps</metric>
    <metric>truth-prior-gs</metric>
    <metric>falsity-prior-ps</metric>
    <metric>falsity-prior-gs</metric>
    <metric>alignment-of power-seekers</metric>
    <metric>alignment-of goodness-seekers</metric>
    <metric>mean [brier] of power-seekers</metric>
    <metric>mean [brier] of goodness-seekers</metric>
    <enumeratedValueSet variable="sd-priors-ps">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-priors-gs">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="truth-freq-h1">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-prior-h1-power-seekers">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="0.99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-prior-h1-goodness-seekers">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="0.99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-likelihood-h2">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-likelihood-h1">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="g-s-bayes-updating?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-s-bayes-updating?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-turtles-each">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Paper Data Experiment (Oct 2025)" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 20</exitCondition>
    <metric>truth-likelihood</metric>
    <metric>falsity-likelihood</metric>
    <metric>truth-prior-ps</metric>
    <metric>truth-prior-gs</metric>
    <metric>falsity-prior-ps</metric>
    <metric>falsity-prior-gs</metric>
    <metric>alignment-of power-seekers</metric>
    <metric>alignment-of goodness-seekers</metric>
    <metric>mean [brier] of power-seekers</metric>
    <metric>mean [brier] of goodness-seekers</metric>
    <enumeratedValueSet variable="condition">
      <value value="&quot;nor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-priors-ps">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-priors-gs">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-prior-h1-power-seekers">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="0.99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-prior-h1-goodness-seekers">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="0.99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-likelihood-h2">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-likelihood-h1">
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="g-s-bayes-updating?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-s-bayes-updating?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-turtles-each">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
