ECO 395 Homework 3: Taylor Neal
================

## 1) What Causes What?

##### Why can’t I just get data from a few different cities and run the regression of “Crime” on “Police” to understand how more cops in the streets affect crime? (“Crime” refers to some measure of crime rate and “Police” measures the number of cops in a city.)

The approached suggested above would not account for the underlying
levels of crime associated with different cities. Cities with higher
rates of crime (due to demographics, regional characteristics, etc.)
could reasonably be expected to hire larger police forces in attempt to
address crime issues. Thus, the suggested simple regression would (by
not accounting for differences in underlying crime levels) not tell us
anything about the causal impact of police on crime rates.

##### How were the researchers from UPenn able to isolate this effect? Briefly describe their approach and discuss their result in the “Table 2”, from the researchers’ paper.

The researchers from UPenn were able to isolate the impact of police on
crime by observing different levels of policing activity in the same
city (Washington, D.C.). This increased police activity (associated with
a higher terrorism alert level) was unrelated to crime levels in the
city and so these high-alert days could be compared to non-alert days to
tease out the causal impact of policing activity on crime levels. In
Table 2, they found that the regression coefficient on the high-alert
indicator variable was negative (and statistically significant at a 5%
level) which indicates that the higher level of policing activity for
high-alert days did reduce total daily crimes.

##### Why did they have to control for Metro ridership? What was that trying to capture?

Controlling for Metro ridership served as a way of ensuring that the
high-alert days were not generally lowering activity levels in the city
(and thereby causing crime rates to fall). In this way, they were able
to control for the impact of high-alert days dissuading residents and
tourists from moving about the city as usual. So, controlling for Metro
ridership allowed the researchers to more accurately capture the causal
impact of policing activity itself on crime levels.

##### Below I am showing you “Table 4” from the researchers’ paper. Just focus on the first column of the table. Can you describe the model being estimated here? What is the conclusion?

In Table 4, the researchers are continuing to model total daily number
of crimes in Washington, D.C.; however, they are separating those crimes
reported in district 1 (the National Mall - area near many of the most
important federal government buildings) and those reported in the rest
of the city. The high-alert days increase police activity generally
throughout the city, but with a greater focus/increase in the National
Mall district. Thus, the finding that crime decreases are greatest in
magnitude in district 1 (coefficient of -2.621) on high-alert days (and
statistically significant at a 1% level) provides additional support to
the conclusion that higher levels of policing activity cause crime rates
to fall. For crimes reported in the rest of the city, the regression
still finds that high-alert days decrease crimes reported, but at a much
lower magnitude (coefficient of -0.571) that is not statistically
significant at a 5% level.

## 2) Tree Modeling: Dengue Cases

TBU

## 3) Predictive Model Building: Green Certification

TBU

## 4) Predictive Model Building: California Housing

TBU
