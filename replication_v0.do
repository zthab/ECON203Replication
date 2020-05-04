#delimit ;

cd "/Users/zahrathabet/Desktop/replication/";

*run below line if program fails;
*ssc install outreg2, replace; 


capture log close;

log using replication.log, replace;

use census.dta, clear;
/*
Samples selected:
	1960 1%

	1970 Form 1 State 1%

	1970 Form 1 Metro 1%

	1970 Form 1 Neighborhood 1%
		
	1980 5%
		
	In each of these samples, age and birthplace were restricted to these 
	specifications:
	
	AGE: 038-068
		Note: contains the desired 1911-1924 birth cohort for all census years.
		
	BPL: 001-120
		Note: limits selection of birthplace to the U.S.	
		
More information available in codebook.cbk file
*/



capture program drop rep_clean_vars;
program define rep_clean_vars;
/*
cleans variables to be used in rest of analysis.
*/



*generating age-related statistics;


qui gen 	yob 	= year - age; 

la var 		yob 	"year of birth";

qui replace yob 	= year - age - 1 if inlist(birthqtr, 2, 3, 4);
/*
	"			year of birth = :

	census year-age-1 	if born April to December
	census year-age 	if born January to March	
	
	"(Almond 683)
*/
	
qui keep if ((yob <= 1924) & (yob >= 1911)); 
*keeps observations that were born 1911-1924; 

qui gen i1919 	= (yob == 1919);

la var 	i1919 	"born in 1919";



*generating education-related statistics; 

qui replace higrade = 21 if ((higrade == 22) | (higrade == 23)); 
*high school graduation indicator. codes >=7 years of post-secondary 
*education (higrade = 22-23) as >=6 years of P-S education (higrade = 21) 
*because the data for 7-8 years of p-s education is unavailable in the 1960 and
*1970 censuses;

qui gen 	yrsofeduc 	= . ;

la var 		yrsofeduc 	"years of education";

qui replace yrsofeduc 	= 0 if inlist(higrade, 0, 1, 2, 3);
*codes pre 1st-grade education as 0 years of education;
	
qui replace yrsofeduc 	= higrade - 3 if ((higrade >= 4) & (higrade <= 99));
*transforms yrsofeduc so that 1st grade is coded as one year of education;

*high school graduate stats;

qui gen 	hsgrad 		= (yrsofeduc >= 12);

la var 		hsgrad 		"graduated high school";

qui replace hsgrad 		= . if (yrsofeduc == .);
*when years of education is not available, codes hsgrad as unavailable rather
*than as 0;



*generating wage and income statistics;

*imports CPI data to inflate USD to 2005 dollar levels;
preserve;	*keeps census data set;

	qui import delimited using CPI.csv, clear;
	/*
	Consumer Price Index: Total All Items for the United States
		Units: Growth Rate Previous Period, Not Seasonally Adjusted
		Frequency: Annual 
		
	Source:
		Organization for Economic Co-operation and Development, Consumer Price 
		Index: Total All Items for the United States [CPALTT01USA657N], 
		retrieved from FRED, Federal Reserve Bank of St. Louis; 
		https://fred.stlouisfed.org/series/CPALTT01USA657N, April 30, 2020.
	*/

	qui su 		cpi 		if (year == 2005);

	qui gen 	adj_factor 	= r(mean) / cpi; 
	*adj factor that can be multiplied by dollar amt to give it in 2005 terms;
	
	la var 	 	adj_factor "2005 inflation factor";

	qui save 	cpi.dta, 	replace;

restore;

sort year; 	*sorts the census data by year, makes it marginally faster to merge;

qui merge m:1 year using cpi.dta;	*adds inflation factor to census data;

qui keep if _merge == 3;
*keeps data that is matched, and gets rid of cpi data that isn't from 1960;
*1970, 1980;

qui gen 	incwage_adj 	= incwage * adj_factor;	

la var 		incwage_adj 	"wage and salary income (2005 dollars)";

qui replace incwage_adj 	= . if (incwage == 0);
*codes wage income as null if it is 0, explained in readme;

qui gen 	iemp			= (incwage_adj != .);	
*there are no negative values of wage in this dataset, so this indicates if the
*observation receives a wage or not (proxy for employment);

la var 	iemp 			"receives wages";
 
qui gen inctot_adj 		= inctot * adj_factor;

la var 	inctot_adj 		"total personal income (2005 dollars)";

qui gen nmedinc_adj 	= nmedinc * adj_factor * 1000;
*originally in thousands of dollars, multiplying by 1000 gets rid of adjustment;

la var 	nmedinc_adj 	"median family income (2005 dollars)";

qui gen incwelfr_adj 	= incwelfr * adj_factor;	

la var 	incwelfr_adj 	"welfare (public assistance) income (2005 dollars)";

qui gen irecwelf 		= (incwelfr_adj != 0 & incwelfr_adj !=.);

la var 	irecwelf 		"receives welfare (public assistance) income";

qui gen incss_adj 		= incss * adj_factor;

la var 	incss_adj 		"social security income (2005 dollars)";

qui gen irecss 			= (incss_adj != 0 & incss_adj != .);

la var 	irecss 			"receives social security income";

qui gen ipoverty 		= (poverty < 150); 
* `poor' is defined by Almond as "below 150% of the poverty level" (688);

la var 	ipoverty 		"below 150% of the poverty level";



*generating disability statistics;

qui gen idislimwrk 		= (disabwrk == 2);	

la var 	idislimwrk 		"disability limits but does not prevent work";

qui gen idisprevwrk 	= (disabwrk == 3);

la var 	idisprevwrk 	"disability prevents work";

qui gen idisaffwrk 		= (idislimwrk | idisprevwrk);

la var 	idisaffwrk 		"disability limits or prevents work";

gen 	disabduradj 	= 0; 

la var 	disabduradj 	"duration of  work disability in years";

qui replace disabduradj = 0.25 	if (disabdur == 1);
qui replace disabduradj = 0.75 	if (disabdur == 2);
qui replace disabduradj = 2 	if (disabdur == 3);
qui replace disabduradj = 4 	if (disabdur == 4);
qui replace disabduradj = 7.5 	if (disabdur == 5);
qui replace disabduradj = 15 	if (disabdur == 6);

qui replace idislimwrk 	= . 	if (disabwrk == .);
qui replace idisprevwrk = . 	if (disabwrk == .);
qui replace idisaffwrk 	= . 	if (disabwrk == .);
qui replace disabduradj = . 	if ((disabwrk == .) | (year == 1980)); 
*codes disability variables as null in census years when it does not exist;

end;
rep_clean_vars;



capture program drop table_1;
program define table_1;
/*
Table 1: male outcome means replication;
*/ 

putexcel set analysis.xlsx, sheet(table 1) modify;

foreach y in 1 0{;
*loops through born in 1919 status;

	tabstat age hsgrad yrsofeduc inctot_adj incwage_adj iemp ipoverty 
		nmedinc_adj sei idislimwrk idisprevwrk disabduradj incss_adj irecss 
		incwelfr_adj irecwelf 
		if (i1919 == `y') & (sex == 1) & (yob >= 1918) & (yob <= 1920), 
		by(year) stat(mean sd co) nototal save;
	*summary statistics for 1919 and surrounding cohort of males born 1918-1920;
		
	mat table1_`y'			= [r(Stat1)\r(Stat2)\r(Stat3)];
	*matrix of summary statistics;
	
	if `y'{; *if cohort of men born in 1919;
		
		qui putexcel A1 	= "1919 Male Cohort";
		
		qui putexcel A3 	= 1960;
		
		qui putexcel A6 	= 1970;
		
		qui putexcel A9 	= 1980;
		
		qui putexcel B2 	= matrix(table1_`y'), names nformat(number_d2);
		
	};
	
	else{; *if cohort of men born 1918 and 1920;
	
		qui putexcel A12 	= "Surrounding Male Cohort";
		
		qui putexcel A14 	= 1960;
		
		qui putexcel A17	= 1970;
		
		qui putexcel A20 	= 1980;

		qui putexcel B13	= matrix(table1_`y'), names nformat(number_d2);
	};
	*transfers summary statistics to excel spreadsheet titled "analysis";
};

end; 
*table_1;



capture program drop figure_2;
program define figure_2;
*Figure 2: percent of cohort disabled by birth quarter replication; 

preserve;



*observation limitation for regression;

qui keep if ((yob <= 1920 & yob >= 1918) | (yob == 1917 & birthqtr == 4 )) & 
	(sex == 1) & (qage == 0 | qage == .) & (qage2 == 0 | qage2 == .);
*keeps men born 1918-1920 and men born in the last quarter of 1917. All
*observations with allocated ages are removed from the following analysis;



*program variable creation;

qui egen time  	= group(yob birthqtr);

la var 	 time 	"birth quarter, year of birth cohorts";

qui bys  time: 	gen f_time = (_n == 1);

la var 	 f_time "first observation in each birth quarter, year of birth cohort";

qui su 	 time;

local max_time 	= r(max);

qui gen  dis80  = .;

la var 	 dis80 	"proportion of birth qtr, yob cohort disabled in 1980 census";



*regression and coefficient assignment;

qui reg idisprevwrk ibn.time if year == 1980, noconstant; 
*coefficients are mean disability rates for each birth quarter cohort in 1980 
*census;

forv i = 1 / `max_time' {;
*loops through each cohort;

	qui replace dis80 = _b[`i'.time] if time == `i';
	*locates disability rate coefficients for each cohort from
	*regression, assigns value to every observation in the same cohort;
	
};



*graphing of regression coefficients;

set graphics off;	*disables graphics from popping up;

scatter dis80 time if f_time == 1, 
	scheme(s1color) mcolor(black)
	ytitle("Percent of Cohort Disabled") 
	xtitle("Quarter of Birth") 
	xlabel( 1 " " 2 "1918 Q1" 3 " " 4 "1918 Q3" 5 " " 6 "1919 Q1" 7 " " 8 
			"1919 Q3" 9 " " 10 "1920 Q1" 11 " " 12 "1920 Q3" 13 " ") 
	xline(6, lcolor(black) lwidth(thin) lpattern(dash))
	note(Fig. 2. — 1980 male disability rates by quarter of birth: prevented 
		from work by a physical disability.);					
*scatter plot of percent disabled by quarter of birth and year of birth;

qui gr save 	Figure2, replace;		*saves scatter plot as a gph;

qui gr export 	Figure2.pdf, replace; 	*saves scatter plot as a pdf;

restore;

end;
*figure_2;



capture program drop table_2;
program define table_2;
/*
Table 2: Departure of 1919 Male Birth Cohort Outcomes from 1912–22 Trend 
replication.
*/
		
preserve;



*observation limitation implementation for summary statistics; 

qui keep if sex == 1 & (qage == 0 | qage == .) & (qage2 == 0 | qage2 == .) & 
	yob >= 1912 & yob <= 1922;
*keeps male observations with non allocated ages born 1912-1922;



*program variable creation;

*terms for regression to be performed that involve income;

qui gen yob_square 		= c.yob^2;

la var 	yob_square 		"year of birth squared";
				
qui gen yob_cube 		= c.yob^3;
				
la var 	yob_cube 		"year of birth cubed";



*regression and coefficient output;

qui reg hsgrad i1919 c.yob##c.yob if year == 1960 & sex == 1, 
	depname("hsgrad 1960") nocons vce(robust);
*first result from regression to export to xml titled table2 (notice, the
*dependent variable is the first variable in the following foreach loop);

qui outreg2 using table2, se replace excel bdec(3) noaster keep(i1919) 
	stat(coef se pval);  
*export of first result;

foreach y in hsgrad yrsofeduc inctot_adj incwage_adj iemp ipoverty nmedinc_adj 
	sei idislimwrk idisprevwrk disabduradj incss_adj irecss incwelfr_adj 
	irecwelf {;
	
	foreach t in 1960 1970 1980{;	
		
		qui cou if year ==`t' & `y' != .;
		*counts number of variables that arent null in the census year;

		if (!("`y'" == "hsgrad" & `t' == 1960)) & (r(N) != 0) {;
		*skipping what is already done outside of loop;
		*if there are any non null values, continues to perform regression
		*will output error if regression performed on variable with only nulls;
		
			if `t' == 1980 & (`y' == inctot_adj | `y' == incwage_adj | `y' == 
				iemp | `y' == incss_adj | `y' == irecss | `y' == incwelfr_adj | 
				`y' == irecwelf) {;
			/*
			"For 1980 income measures only, the cohort trend is estimated as a
			cubic function to attempt to account for retirement at age 62" (696)
			*/
				
				qui reg `y' i1919 c.yob yob_square yob_cube if year == `t' & 
					sex == 1, depname("`y' `t'") vce(robust);
				* use of robust se: "Robust standard errors are in brackets" 
				*(688). coefficient of i1919 measures departure from trend of
				*variable `y' for men born in 1919;
					
			};
			
			else {;
			
				qui reg `y' i1919 c.yob##c.yob if year == `t' & sex == 1, 
					depname("`y' `t'") vce(robust);
					
				/*
				Model specifications outlined on p.687. Coefficient of i1919 
				measures departure from trend of variable `y' for men born in 
				1919. Variable name changed so as to easily identify census year
				of variable in output.
				*/
			
			};

		qui outreg2 using table2, se append excel bdec(3) keep(i1919) 
			stat(coef se pval) nocons noaster; 
		*outputs i1919 coefficient to xml named table 2;
		
		};
			
	};
	
};

restore;

end;
*table_2;



capture program drop table_3;
program define table_3;
/*
Table 3: 1912–22 Census Outcomes among Women (Census Years 1960, 1970, and 1980)
Replication
*/

preserve;



*observation limitation implementation for summary statistics; 

keep if yob >= 1912 & yob <= 1922;	*keeps observations born 1912-1922;

putexcel set analysis.xlsx, sheet(table 3) modify;



*summary statistics and summary statistics outputs; 

tabstat hsgrad yrsofeduc inctot_adj incwage_adj iemp ipoverty nmedinc_adj sei 
	idislimwrk idisprevwrk disabduradj incss_adj irecss incwelfr_adj irecwelf 
	if i1919 == 0 & sex == 2, by (year) stat(mean sd co) nototal save;
	*summary statistics for women not born in 1919; 
		
mat table3_0 = [r(Stat1)\r(Stat2)\r(Stat3)];
	
putexcel A1  = "Female Sample Mean";
		
putexcel A3  = 1960;
		
putexcel A6  = 1970;
		
putexcel A9	 = 1980;
		
putexcel B2  = matrix(table3_0), names nformat(number_d2);
*puts summary statistics in analysis.xlsx in a sheet labeled table 4; 



*observation limitation for departure from mean regression; 

keep if ((qage == 0) | (qage == .)) & ((qage2 == 0) | (qage2 == .));
*keeps observations with non-allocated ages;



*departure from mean regression variable creation; 

*terms for regression to be performed that involve income; 

qui gen yob_square 		= c.yob^2;

la var 	yob_square 		"year of birth squared";
				
qui gen yob_cube 		= c.yob^3;
				
la var 	yob_cube 		"year of birth cubed";



*regression and coefficient output;

qui reg hsgrad i1919 c.yob##c.yob if year == 1960 & sex == 2, vce(robust) 
	depname("hsgrad 1960");
*first result from regression to start exporting to xml titled table2;

qui outreg2 using table3, se replace excel bdec(3) keep(i1919) nocons noaster
	stat(coef se pval); 

foreach y in hsgrad yrsofeduc inctot_adj incwage_adj iemp ipoverty nmedinc_adj 
	sei idislimwrk idisprevwrk disabduradj incss_adj irecss incwelfr_adj 
	irecwelf {;
	
	foreach t in 1960 1970 1980 {;
	
		qui cou if year == `t' & `y' != .;
		*counts number of variables that arent null in the census year;

		if (!("`y'" == "hsgrad" & `t' == 1960)) & r(N){;
		*skipping what is already done outside of loop;
		*if there are any non null values, continues to perform regression
		*will output error if regression performed on variable with only nulls;
			
			if `t' == 1980 & ("`y'" == "inctot_adj" | "`y'" == "incwage_adj" | 
				"`y'" == "iemp" | "`y'" == "incss_adj" | "`y'" == "irecss" | 
				"`y'" == "incwelfr_adj" | "`y'" == "irecwelf") {;
			/*
			"For 1980 income measures only, the cohort trend is estimated as a
			cubic function to attempt to account for retirement at age 62" (696)
			*/
				
				qui reg `y' i1919 c.yob yob_square yob_cube if year == `t' & 
					sex == 2, depname("`y' `t'") vce(robust);
				*use of robust se: "Robust standard errors are in brackets" 
				*(688). coefficient of i1919 measures departure from trend of
				*variable `y' for women born in 1919.;
		
			};
			
			else {;
			
			
				qui reg `y' i1919 c.yob##c.yob if year == `t' & sex == 2, 
					vce(robust) depname("`y' `t'");
				/*
				Model specifications outlined on p.687. Coefficient of i1919 
				measures departure from trend of variable `y' for those born in 
				1919. Name is changed in output to easily identify census year 
				of variable in output.
				*/
			
			};
		
			qui outreg2 using table3, se append excel bdec(3) keep(i1919) 
				stat(coef se pval) nocons noaster; 	
			*outputs i1919 coefficient to xml file titled table3;
			
		};
		
	};
	
};

restore;

end;
table_3;



capture program drop table_4;
program define table_4;
*Table 4: 1912–22 Census Outcomes among Nonwhites (Census Years 1960, 1970, and;
*1980) Replication;

preserve;



*observation limitation implementation for summary statistics and regression; 

keep if (qage == 0 | qage == .) & (qage2 == 0 | qage2 == .) & yob >= 1912 & 
	yob <= 1922;
*keeps observations with non-allocated ages born 1912-1922;



*summary statistics and summary statistics outputs: 

putexcel set analysis.xlsx, sheet(table 4) modify;

tabstat hsgrad yrsofeduc inctot_adj incwage_adj iemp ipoverty nmedinc_adj sei 
	idislimwrk idisprevwrk disabduradj incss_adj irecss incwelfr_adj irecwelf 
	if i1919 == 0 & race != 1, by (year) stat(mean sd co) nototal save;
*summary statistics for nonwhite observations not born in 1919;
		
mat table4_0 = [r(Stat1)\r(Stat2)\r(Stat3)];
	
putexcel A1  = "Nonwhite Sample Mean";
		
putexcel A3  = 1960;
		
putexcel A6  = 1970;
		
putexcel A9	 = 1980;
		
putexcel B2  = matrix(table4_0), names nformat(number_d2);
*puts summary statistics in analysis.xlsx in a sheet labeled table 4;



*regression variable creation;

*terms for regression to be performed that involve income; 

qui gen yob_square 		= c.yob^2;

la var 	yob_square 		"year of birth squared";
				
qui gen yob_cube 		= c.yob^3;
				
la var 	yob_cube 		"year of birth cubed";



*regression and coefficient output;

qui reg hsgrad i1919 c.yob##c.yob if year == 1960 & race != 1, vce(robust) 
	depname("hsgrad 1960");
*first result from regression to start exporting to xml titled table2;

qui outreg2 using table4, se replace excel bdec(3) noaster nocons keep(i1919) 
	stat(coef se pval); 

foreach y in hsgrad yrsofeduc inctot_adj incwage_adj iemp ipoverty nmedinc_adj
	sei idislimwrk idisprevwrk disabduradj incss_adj irecss incwelfr_adj
	irecwelf {;
	
	foreach t in 1960 1970 1980 {;
	
		qui cou if year == `t' & `y' != .;
		*counts number of variables that arent null in the census year;
		
		if ((!("`y'" == "hsgrad" & `t' == 1960)) & r(N)){;
		*skipping what is already done outside of loop;
		*if there are any non null values, continues to perform regression
		*will output error if regression performed on variable with only nulls;
			
			if `t' == 1980 & ("`y'" == "inctot_adj" | "`y'" == "incwage_adj" | 
				"`y'" == "iemp" | "`y'" == "incss_adj" | "`y'" == "irecss" | 
				"`y'" == "incwelfr_adj" | "`y'" == "irecwelf") {;
			/*
			"For 1980 income measures only, the cohort trend is estimated as a
			cubic function to attempt to account for retirement at age 62" (696)
			*/
				
				qui reg `y' i1919 c.yob yob_square yob_cube if year == `t' & 
					race != 1, depname("`y' `t'") vce(robust);
				*robust se: "Robust standard errors are in brackets"(688);
		
			};
			
			else {;
			
				qui reg `y' i1919 c.yob##c.yob if year == `t' & race != 1, 
					vce(robust) depname("`y' `t'");
				*Model specifications outlined on p.687;
			
			};
		
			qui outreg2 using table4, se append excel bdec(3) keep(i1919) 
				stat(coef se pval) nocons noaster; 	
			*outputs i1919 coefficient to xml file titled table4;
					
		};
		
	};
	
};

restore;

end;
table_4;



capture program drop figure_3;
program define figure_3;
/*
Figure 3: 1960 average years of schooling: men and women born in the United 
States Replication
*/

preserve;



*observation limitation for regression;

qui keep if (qage == 0 | qage == .) & (qage2 == 0 | qage2 == .) & yob >= 1912 
	& yob <= 1922;
*keeps observations where age is not allocated;



*variable creation for regression;

qui egen time3 		= group(yob);

la var 	time3 		"year of birth cohorts";

qui bys time3: 		gen f_time3 = (_n == 1);

la var 	f_time3 	"first observation in each time3 cohort";

qui su 	time3;

local 	max_time3 	= r(max); 	*counts number of years of birth;

qui gen avgeduc		= .;

la var 	avgeduc 	"average years of education for each time3 cohort";



*regression and coefficient output;

qui reg yrsofeduc ibn.time3 if year == 1960, noconstant; 
*coefficients are mean years of education for each yob cohort in 1960 census;

forv i = 1 / `max_time3' {;
*loops through each cohort;

	qui replace avgeduc = _b[`i'.time3] if time3 == `i';
	*locates mean years of education coefficient for each cohort from; 
	*regression, assigns this value to every observation in the same cohort;
	
};



*graphing of regression coefficients;

set graphics off;	*disables graphics from popping up;

scatter avgeduc time3 if f_time3 == 1, 
	scheme(s1color) mcolor(black)
	ytitle("Years of Schooling") 
	xtitle("Year of Birth") 
	xlabel( 1 "1912" 2 " " 3 "1914" 4 " " 5 "1916" 6 " " 7 "1918" 8 " " 9 
		"1920" 10 " " 11 "1922") 
	xline(8, lcolor(black) lwidth(thin) lpattern(dash)) 
	note(Fig. 3. — 1960 average years of schooling: men and women born in the 
		United States);					
*scatter plot of years of education by year of birth in 1960 census;

qui gr 	save Figure3, replace;			*saves scatter plot as a gph;

qui gr 	export Figure3.pdf, replace; 	*saves scatter plot as a pdf;
	
restore;

end;
figure_3;



capture program drop figure_4;
program define figure_4;
*Figure 4: 1970 high school graduation: by year of birth replication;

preserve;



*observation limitations for regression;

qui keep if (qage == 0 | qage == .) & (qage2 == 0 | qage2 == .) & yob >= 1912 & 
	yob <= 1922;
*keeps observations if their age is not allocated and they are born 1912-1922;



*variable creation for regression;

qui egen time4 		= group(yob);

la var 	 time4 		"year of birth cohorts";

qui egen time41 	= group(yob sex);

la var 	 time41 	"year of birth by sex cohorts";

qui bys  time41: 	gen f_time4 = (_n == 1); 	

la var 	 f_time4 	"first observation in time41 cohorts";

qui su   time4;

local 	 max_time4 	= r(max); 	*counts number of years of birth;

qui gen  pergrad 	= .;

la var 	 pergrad 	"Percent of Men Graduating";

qui gen  pergradb 	= .;

la var 	 pergradb	"Percent of Women Graduating";



*regression and coefficient output;

qui replace hsgrad 	= hsgrad * 100;	*puts hsgrad in percent terms;

qui reg hsgrad ibn.time4 if year == 1970 & sex == 1, noconstant; 
*coeffs are mean graduation rate for men by year of birth in the 1970 census;

forv i = 1 / `max_time4' {;

	qui replace pergrad = _b[`i'.time4] if time4 == `i' & sex == 1;
	*assigns mean graduation rate for the part of the `i'th time4 cohort that is
	*men to each of the male observations in that cohort;

};

qui reg hsgrad ibn.time4 if year == 1970 & sex == 2, noconstant; 
*coeffs are mean graduation rate for women by year of birth in the 1970 census;

forv i = 1 / `max_time4' {;

	qui replace pergradb = _b[`i'.time4] if time4 == `i' & sex == 2;
	*assigns mean graduation rate for the part of the `i'th time4 cohort that is
	*women to each of the female observations in that cohort;

};



*graphing of regression coefficients;

set graphics off;	*disables gr from popping up;

scatter pergrad pergradb time4 if f_time4 == 1, 
	sort(sex) legend() scheme(s1color) mcolor(black) 
	ytitle("Percent Graduating") 
	xtitle("Year of Birth") 
	msymbol(O D)
	xlabel( 1 "1912" 2 " " 3 "1914" 4 " " 5 "1916" 6 " " 7 "1918" 8 " " 9 "1920"
			10 " " 11 "1922") 
	xline(8, lcolor(black) lwidth(thin) lpattern(dash)) 
	note(Fig. 4. — 1970 high school graduation: by year of birth);				
*scatter plots mean graduation rate for each time41 cohort (year of birth and 
*sex cohorts) by year of birth;

qui gr 	save Figure4, replace;			*saves scatter plot as a gph;

qui gr 	export Figure4.pdf, replace; 	*saves scatter plot as a pdf;

restore;

end;
figure_4;



capture program drop figure_5;
program define figure_5;
/*
Figure 5: a) 1980 high school graduation rate by quarter of birth. b) Regression
-adjusted 1980 high school graduation rate by quarter of birth replication.
*/

preserve;



*observation limitations for regression;

qui keep if (qage == 0 | qage == .) & (qage2 == 0 | qage2 == .) & yob >= 1916 & 
	yob <= 1920 & sex == 1;
*keeps male observations that do not have allocated ages and are born 1916-1920;



*regression variable creation;

qui egen yobqtrc 		= group(yob birthqtr); 		

la var 	 yobqtrc 		"birth quarter by year of birth cohorts";

qui bys  yobqtrc: 		gen f_yobqtrc = (_n == 1);

la var 	 f_yobqtrc 		"first observation in time5 cohorts";

qui su 	 yobqtrc;

local 	 max_yobqtrc 	= r(max);	*counts number of years of birth;

qui gen  pergrad5a		= .;

la var 	 pergrad5a		"high school graduation rate of each birth quarter";

replace  hsgrad 		= hsgrad * 100;
*replaced to be in percentage points;



*regression and coefficient output;

qui reg hsgrad ibn.yobqtrc if year == 1980, noconstant; 
*coefficients are mean high school graduation rate by birth quarter and year of;
*birth as reported in the 1980 census;

forv i = 1 / `max_yobqtrc' {;

	qui replace pergrad5a = _b[`i'.yobqtrc] if yobqtrc == `i';
	*assigns mean graduation rate for the part of the `i'th time5 cohort to;
	*each of the in that cohort;
	
};



*graphing of regression coefficients;

scatter pergrad5a yobqtrc if f_yobqtrc == 1, 
	scheme(s1color) mcolor(black)
	ytitle("Percent Graduating") xtitle("Quarter of Birth")
	xlabel( 1 "1916 Q1" 2 " " 3 " " 4 " " 5 "1917 Q1" 6 " " 7 " " 8 " " 9 
		"1918 Q1" 10 " " 11 " " 12 " " 13 "1919 Q1" 14 " " 15 " " 16 " " 17 
		"1920 Q1" 18 " " 19 " " 20 " ") 
	xline(13, lcolor(black) lwidth(thin) lpattern(dash))
	note(Fig. 5a - 1980 high school graduation rate by quarter of birth);
	
*scatter plots mean graduation rate for each time5 cohort (year of birth and 
*birth quarter cohorts) by their birth quarter and year of birth;

qui gr 	save Figure5a, replace;			*saves scatter plot as a gph;

qui gr 	export Figure5a.pdf, replace; 	*saves scatter plot as a pdf;



*regression variable creation;

qui gen pergrad5b = .;

la var pergrad5b "high school graduation rates of each birth quarter cohort 
	(regression adjusted)";

	
	
*regression and coefficient output;

qui reg hsgrad c.yobqtrc ibn.birthqtr  if year == 1980, nocons;
*regression of high school graduation rates from the 1980 census on the 
*continuous years and quarters of birth 1916-1920 and binary birth quarter; 
*variables;

predict rhsgrad, r;
*extracts the residual of high school graduation rates - the change in high; 
*school graduation rates that is not explained by the linear trend of time nor; 
*seasonality of birth quarter;

qui reg rhsgrad ibn.yobqtrc if year == 1980, nocons;
*regression of the residual of the high school graduation rate on the birth; 


forv i = 1 / `max_yobqtrc' {;

	qui replace pergrad5b = _b[`i'.yobqtrc] if yobqtrc == `i';
	*assigns mean graduation rate for the part of the `i'th time5 cohort to;
	*each of the in that cohort;
	
};



*graphing of regression coefficients;

set graphics off;	*disables graphics from popping up;

scatter pergrad5b yobqtrc if f_yobqtrc == 1, 
	scheme(s1color) mcolor(black)
	ytitle("Percent Graduating") xtitle("Quarter of Birth")
	xlabel( 1 "1916 Q1" 2 " " 3 " " 4 " " 5 "1917 Q1" 6 " " 7 " " 8 " " 9 
		"1918 Q1" 10 " " 11 " " 12 " " 13 "1919 Q1" 14 " " 15 " " 16 " " 17 
		"1920 Q1" 18 " " 19 " " 20 " ") 
	xline(13, lcolor(black) lwidth(thin) lpattern(dash))
	note(Fig. 5b - Regression-adjusted 1980 high school graduation rate by 
		quarter of birth);					
*scatter plot of percent disabled by quarter of birth;
*reg take out trend and control seasonality ;

qui gr 	save Figure5b, replace;			*saves scatter plot as a gph;

qui gr 	export Figure5b.pdf, replace; 	*saves scatter plot as a pdf;

restore;

end;
figure_5;



capture program drop figure_6;
program define figure_6;
*Figure 6: 1970 male disability rate: physical disability limits or prevents 
*work replication.;

preserve;



*observation limitations for regression;

qui keep if sex == 1 & (qage == 0 | qage == .) & (qage2 == 0 | qage2 ==.) & 
	yob >= 1912 & yob <= 1922;
*keeps male observations that do not have their age allocated born 1912-1922;



*variable creation for regression;

qui egen time6 		= group(yob); 		

la var 	 time6 		"male year of birth cohorts";

qui bys  time6: 	gen f_time6 = (_n == 1);

la var 	 f_time6 	"first observation of each time6 cohort";

qui su 	 time6;

local 	 max_time6 	= r(max); 	*counts birth quarters;

qui gen  perdis		= .;

la var 	 perdis		"percent of observations that have a disability that affects
					their work";

qui replace idisaffwrk = idisaffwrk * 100;
*scales it as percentage points;					
	


*regression and coefficient output;

qui reg idisaffwrk ibn.time6 if year == 1970, noconstant; 
*coefficients are the time6 cohort's proportion disabled in the 1970 census;

forv i = 1 / `max_time6' {;

	qui replace perdis = _b[`i'.time6] if time6 == `i';
	*assigns the cohort's proportion disabled to perdis for that cohort;

};



*graphing regression coefficients;

set graphics off;	*disables graph from popping up;

scatter perdis time6 if f_time6 ==1, 
	scheme(s1color) mcolor(black)
	ytitle("Percent with a Disability") 
	xtitle("Year of Birth")
	xlabel( 1 "1912" 2 " " 3 "1914" 4 " " 5 "1916" 6 " " 7 "1918" 8 " " 9 "1920"
			10 " " 11 "1922")
	xline(8, lcolor(black) lwidth(thin) lpattern(dash)) 
	note(Fig. 6. — 1970 male disability rate: physical disability limits or 
		 prevents work);					
*scatter plot of percent disabled by year of birth;

qui gr 	save Figure6, replace;			*saves scatter plot as a gph;

qui gr 	export Figure6.pdf, replace; 	*saves scatter plot as a pdf;

restore;

end;
figure_6;



capture program drop figure_8;
program define figure_8;
*Figure 8: Average welfare payments for women and nonwhites: by year of birth
*replication.;

preserve;



*observation limitation for regression;

keep if (qage == 0 | qage == .) & (qage2 == 0 | qage2 == .);
*keeps observations with unallocated ages;



*variable creation for regressions;

*replace incwelfr_adj		= 0 if incwelfr_adj == .;

qui egen 	yobc			= group(yob);

la var 		yobc			"year of birth cohorts";

qui egen 	yobsexc 		= group(yob sex);*year of birth and sex cohorts;

la var 		yobsexc			"year of birth and sex cohorts";

gen 		nonwhite 		= race != 1;

la var 		nonwhite		"non-white race";

qui egen 	yobracec 		= group(yob nonwhite);

la var 		yobracec		"year of birth and white/nonwhite cohorts";

qui egen 	yobracesexc		= group(yob nonwhite sex);

la var 		yobracesexc		"year of birth, sex, and white/nonwhite cohorts";

qui bys 	yobracesexc: 	gen f_nonwhiteman = (_n == 1) if nonwhite & sex == 1;

la var 		f_nonwhiteman	"first observation from each cohort of nonwhite men 
							out of all cohorts of observations grouped by year 
							of birth, sex, and race";

qui bys 	yobracesexc: 	gen f_whitewomn = (_n == 1) if (!nonwhite) & 
							sex == 2;

la var 		f_whitewomn		"first observation from each cohort of white women 
							out of all cohorts of observations grouped by year 
							of birth, sex, and race";

qui su 		yobsexc;

local 		max_yobsexc 	= r(max);	*number of year of birth, sex cohorts;

*calculations for mean welfare for women and non-white people;

qui gen 	meanwelfsex 	= .;

la var 		meanwelfsex		"Payments to Women";

qui su 		yobracec;

local 		max_yobracec 	= r(max); 	*number of year of birth, race cohorts;

qui gen 	meanwelfrace 	= .;

la var 		meanwelfrace 	"Payements to Non-White Persons";

*calculations for percent of women and nonwhite people receiving welfare;

qui gen 	perwelfsex 		= .;

la var 		perwelfsex		"Payments to Women";

replace 	irecwelf 		= irecwelf *100 ;
*scales indicator variable for if someone receives welfare to out of 100;

qui gen 	perwelfrace 	= .;

la var 		perwelfrace 	"Payments to Non-White Persons";




*regression and coefficient output;

qui reg incwelfr_adj ibn.yobsexc, noconstant; 
*coefficients are mean welfare by year of birth and sex;

forv i = 1 / `max_yobsexc' {;

	qui replace meanwelfsex = _b[`i'.yobsexc] if yobsexc == `i' & sex == 2;
	*assigns coefficients to mean welfare variable for women;
	*(if assigned to both women and men, all cohorts would be graphed);
};

qui reg incwelfr_adj ibn.yobracec, noconstant; 
*coefficients are mean welfare by year of birth and race;

forv i = 1 / `max_yobracec' {;

	qui replace meanwelfrace = _b[`i'.yobracec] if yobracec == `i' & nonwhite;
	*assigns coefficients to mean welfare variable for nonwhite people
	*(if assigned to both nonwhite and white, all cohorts would be graphed);
	
};


qui reg irecwelf ibn.yobsexc, noconstant; 
*coefficients are percent of cohort receiving welfare by year of birth and sex;

forv i = 1 / `max_yobsexc' {;

	qui replace perwelfsex = _b[`i'.yobsexc] if yobsexc == `i' & sex == 2;
	*assigns coefficients to the percent of cohort that receives welfare 
	*variable for women cohorts. 
	*(if assigned to both women and men, all cohorts would be graphed);
};

qui reg irecwelf ibn.yobracec, noconstant; 
*coefficients are percent of cohort receiving welfare by year of birth and race;

forv i = 1 / `max_yobracec' {;

	qui replace perwelfrace = _b[`i'.yobracec] if yobracec == `i' & nonwhite;
	*assigns coefficients to the percent of cohort that receives welfare 
	*variable for nonwhite cohorts;
	*(if assigned to both nonwhite and white, all cohorts would be graphed);
};



*graphing of coefficients;

scatter meanwelfsex meanwelfrace yobc if (f_whitewomn == 1 | 
	f_nonwhiteman == 1), 
	scheme(s1color) mcolor(black)
	ytitle("Mean Welfare Payement (2005 Dollars)") 
	xtitle("Year of Birth")
	xlabel( 1 "1911" 2 " " 3 "1913" 4 " " 5 "1915" 6 " " 7 "1917" 8 " " 9 "1919"
			10 " " 11 "1921" 12 " " 13 "1923" 14 " ")
	xline(9, lcolor(black) lwidth(thin) lpattern(dash)) 
	note(Fig. 8a. - Average welfare payments for women and non-white persons: by 
		year of birth);  			
*scatter plot of mean welfare for women and nonwhite people by year of birth;

qui gr 	save Figure8a, replace;			*saves scatter plot as a gph;

qui gr	export Figure8a.pdf, replace; 	*saves scatter plot as a pdf;


scatter perwelfsex perwelfrace yobc if (f_whitewomn == 1 | f_nonwhiteman == 1),
	scheme(s1color) mcolor(black)
	ytitle("Percent Receiving Welfare") 
	xtitle("Year of Birth")
	xlabel( 1 "1911" 2 " " 3 "1913" 4 " " 5 "1915" 6 " " 7 "1917" 8 " " 9 "1919"
			10 " " 11 "1921" 12 " " 13 "1923" 14 " ")
	xline(9, lcolor(black) lwidth(thin) lpattern(dash)) 
	note(Fig. 8b. - Percent of women and non-white persons who receive welfare 
		payments: by year of birth);
*scatter plot of percent of women and non-white people who receive welfare by 
*year of birth;

qui gr 	save Figure8b, replace;			*saves scatter plot as a gph;

qui gr	export Figure8b.pdf, replace; 	*saves scatter plot as a pdf;

restore;

end;
figure_8;
