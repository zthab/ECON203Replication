

Download census data through IPUMS USA: https://usa.ipums.org/usa/index.shtml
Reference codebook for sample selection.

Each figure and table can be constructed in its namesake program. rep_clean_vars must be run before any other program is run; it only has to be run once. 
Any data cleaning or limitations that only apply to part of the following analysis will be conducted in those specific programs. All figure and table programs are built to be independent of one another, and thus can be run in any combination. 




Observation Specifications: 

Data specification references:
	
1960: "The Integrated Public Use Microdata Series (IPUMS) provides a 1 percent sample for 1960 (Ruggles et al. 2004)" (Almond 683).

1970: "For 1970, Form 1 data are used since they contain disability measures, welfare payments, and so forth. The state, neighborhood, and metro samples are combined, yielding a 3 percent sample" (684).

1980: "The IPUMS provides its largest samples, 5 percent, beginning with the 1980 Census" (684).

Birth Cohorts: The analysis performed in this paper has the widest set of birth cohorts in figure 8 (b. 1911-1924). (685, 687).

Quality Flags:
—“All persons born in the United States whose age was not allocated are included in the cohorts analysis sample of Section V" (683-684). This includes Tables 2, 3, 4, and Figures 3, 4, 5, 6, 8 analyzed below. It does not include Table 1, so this quality flag is specified within each of the programs to which it pertains.



Coding of Income Variables: 

In analyzing wage income, Almond says that he dropped observations with no wages, "so work-preventing disabilities per se cannot account for this effect" (694). The syntax leaves it unclear if those with no wages are dropped from the dataset as a whole, or if they are excluded from wage analysis. The situational context for this information suggests that these men are only excluded from wage analysis. I then coded $0 wages as null wages.

The author's consistency of coding for income variables is questionable. It is unclear if they drop people whose total income is 0 or not, as they indicate that they do to wage income. I chose to keep observations where total income is 0 coded as 0 because total income being 0 do not necessarily causally relate to wage income being 0. In order to use the justification that we are excluding wage income = 0, so we should exclude total income = 0, this causal relationship would have to stand. total income being 0 is less meaningful because while this could be caused by no income, it can also be a result of debt etc. So excluding it, to some extent, is a bit arbitrary. 

Almond's measurement of welfare and social security income clearly included observations where incwelfr = 0. However, I do not necessarily agree with this analysis as it leaves unknown if a change in welfare or social security income is attributable to the proportion of the population receiving these payments changing or the size of those payments themselves changing. I will include indicator variables indicating if an observation receives wages, welfare, and social security income in further regressions wherever wages, welfare, or social security is considered.

Almond fails to apply inflation measures to social security and welfare statistics and wage income collected in the 1970 census. I made the decision to uniformly adjust welfare and social security income for inflation throughout my analysis, as below Table 1, Almond indicates "All income figures are given in 2005 dollars" (685).



Coding of Disability Variables:

I do not incorporate new data as Almond does for the 1980 census. The data that he references, "The Econometrics Laboratory at the University of California, Berkeley maintains a 5 percent extract of the 1980 Census micro data without the questionable IPUMS recoding" is accompanied by a broken link (684). Therefore, I don't recode disability limiting work as Almond does, leading to a systematic underestimation of disability limiting work in any summary statistics or regression using data from the 1980 census.

Almond's for disability duration is unclear. As a result, I code each value at the midpoint of the range of durations that it represents. For disabdur == 6, the disability lasts for more than 10 years, I code this as 15 years. I chose this value because it brings disability duration most in line with the summary statistics pertaining to disability duration.




Table 1 Notes (in excel spreadsheet titled analysis): 

Standard deviation instead of the noted standard error are shown in the original article's table (685). I then calculated standard deviation instead of standard error in my replication. 
	
The standard deviation for the 1919 male cohort and the surrounding cohorts are switched for the age variable throughout all census years. I fixed this in my replication.
		
Almond uses different, unspecified methods for inflation than I do. This leads to a 2-3% variation in my outputs in 2005 dollars and his. I implement my inflation methods in rep_clean_vars using the Consumer Price Index: Total All Items for the United States (Organization for Economic Co-operation and Development).

Almond does not seem to apply his own measure to removing those who don't receive wage income from the cohort mean wage income. This causes a considerable difference between our means in 1980, when many people in the birth cohorts do not receive wages (31% in both cohorts). 




Table 2 Notes (in xml file titled table2): 

outreg2 takes an astonishingly long time to run.
		
per the paper's own instructions, I estimated the cohort trend for all income related variables in 1980 using a cubic function. However, it seems as though Almond used a squared trend estimation. 
	     1980 income variables
	  Variable   |  Thabet  | Almond
	  ------------------------------
Mean	  totinc_adj |-600.096  |-1,065
SD		     |(174.147) |[191]
P-Value		     |0.001     |<0.01
Mean	  incss_adj  |-301.301  |83
SD		     |(17.720)  |[19]
P-Value		     |<0.001    |<0.01
Mean	  incwelf_adj|7.405     |17
SD		     |(6.764)   |[7]
P-Value		     |0.274     |<0.05
	
Significant results from new binary variables (receives wage, welfare, or social security payments)
	
— in the 1970 census, members of the male cohort b. 1919 were 0.5% more likely to not receive wages than their surrounding year of birth cohorts (P-Value = 0.057).
		
— in the 1970 census, members of the male cohort b. 1919 were 0.2% more likely to receive welfare payments than their surrounding yob cohorts (P-Value = 0.040).
		
— in the 1980 census, members of the male cohort b. 1919 were 0.57% less likely to receive social security benefits than their surrounding yob cohorts (P-Value < 0.001). 
	
Almond unfortunately does not compute departure from trend in welfare and social security for the i1919 male cohort in inflated terms. Since I don't know what inflation measure he used, direct comparison isn't entirely possible. 




Table 3 Notes: 

Summary Statistics (in excel spreadsheet titled analysis):
	
— in 1980, Almond's mean wage income dramatically departs from my computation. This is mostly likely because of one of two factors : 1) Almond did not incorporate inflation into his calculation or 2) Almond includes observations where wage income is $0. The latter seems most plausible because 1) the standard deviation reported is much closer to my standard deviation, indicating that these values are adjusted for inflation.
						
Departure from Sample Mean (in xml titled table3):
	
— My departure from trend for total income in 1980 differs significantly from Almond’s. Similarly my wage departure from the sample mean in 1980 was significantly lower than Almond’s. This difference does not disappear when I calculate the trend as a squared rather than a cubed function of year of birth. 

Significant results from new binary variables (receives wage, welfare, or social security payments)

— in the 1980 census, the members of the female cohort born in 1919 were 0.8% more likely to receive wages than those in the surrounding cohorts (P=0.001).

— in the 1980 census, the members of the female cohort born in 1919 were 10.5% less likely to receive social security payments than their surrounding cohorts (P<0.01).

— in the 1970 and 1980 census, the members of the female cohort born in 1919 were 0.3% more likely than their surrounding cohorts to receive welfare payments (P=0.005 and P=0.004 respectively). 



Table 4 Notes:

Summary Statistics (in analysis excel sheet): 
—Almond reports median neighbor income in 1970 as 0 with a standard deviation of 0. This does not make sense logically, and my findings are consistent with this intuition (38583.48 [13979.30]).

Departure from Sample Mean (in table4 xml):

Significant results from new binary variables:
— the nonwhite cohort born in 1919 was 1.1% less likely to be employed in 1970 than surrounding nonwhite cohorts (P = 0.075).

— the nonwhite cohort born in 1919 was 5.3% less likely than the surrounding nonwhite cohorts to receive social security in 1980 (P<0.001). 

— the nonwhite cohort born in 1919 was 0.7% more likely to receive welfare that nonwhite cohorts born in the years surrounding 1919 (P = 0.059).



Table 5 Notes:

— Almond’s y-axis is not in percentage terms although it is labeled as such. I fixed this discrepancy in my results by scaling the high school graduation variable to out of 100.

— I believe that Almond is only graphing the male cohort, as the resultant graphs with this constraint are much more similar than when sex is not limited. 


Table 6 Notes: 

— Almond’s y-axis is not in percentage terms although it is labeled as such. I fixed this discrepancy in my results by scaling the disability rates to out of 100.


Table 8 notes:

I made two graphs for figure 8. One showing the mean welfare payment, and one showing the percent of observations receiving welfare. This is the beginning of an attempt to show the confounding nature of Almond's methodology. While welfare payments plateaus after 1916 as year of births progress, the percent of people receiving welfare continues to trend downwards. It’s also worth noting that another troubling aspect of this graph is that the categories that Almond groups by are non-exclusive. So, this is another source of how the variables tend to not be clear. 



Citations 
Almond, Douglas. “Is the 1918 Influenza Pandemic Over? Long‐Term Effects of In Utero Influenza Exposure in the Post‐1940 U.S. Population.” Journal of Political Economy, vol. 114, no. 4, Aug. 2006, pp. 672–712. DOI.org (Crossref), doi:10.1086/507154.

Organization for Economic Co-operation and Development, Consumer Price Index: Total All Items for the United States [CPALTT01USA657N], retrieved from FRED, Federal Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/CPALTT01USA657N, April 30, 2020.

Steven Ruggles, Sarah Flood, Ronald Goeken, Josiah Grover, Erin Meyer, Jose Pacas and Matthew Sobek. IPUMS USA: Version 10.0 [dataset]. Minneapolis, MN: IPUMS, 2020. https://doi.org/10.18128/D010.V10.0 
