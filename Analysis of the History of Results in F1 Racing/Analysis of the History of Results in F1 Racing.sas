*Imorting 4 files (txt, csv, xlsx, and csv);
*Import constructors.txt;
PROC IMPORT DATAFILE='/home/u62123886/sasuser.v94/Project/constructors.txt'
	DBMS=DLM
	OUT=pr1.Constructors replace;
	DELIMITER="09"x;
	GETNAMES=YES;
RUN;

*Import drivers.csv;
PROC IMPORT DATAFILE='/home/u62123886/sasuser.v94/Project/drivers.csv'
	DBMS=CSV
	OUT=pr1.drivers replace;
	GETNAMES=YES;
RUN;

*Import races.xlsx;
PROC IMPORT DATAFILE='/home/u62123886/sasuser.v94/Project/races.xlsx'
	DBMS=XLSX
	OUT=pr1.races replace;
	GETNAMES=YES;
RUN;

*Import results.csv;
PROC IMPORT DATAFILE='/home/u62123886/sasuser.v94/Project/results.csv'
	DBMS=CSV
	OUT=pr1.results replace;
	GETNAMES=YES;
RUN;

*Merging all the tables;
*Merge constructors and results table;
proc sort data=PR1.CONSTRUCTORS out=work._tmpsort1_; by constructorId; run;
proc sort data=PR1.RESULTS out=work._tmpsort2_; by constructorId; run;

data pr1.merge_1;
	merge _tmpsort1_ _tmpsort2_;
	by constructorId;
	keep resultId grid positionorder points constructorId name driverId raceId;
run;
proc delete data=work._tmpsort1_ work._tmpsort2_;run;

*Merge Drivers table to existing merged table;
proc sort data=PR1.MERGE_1 out=work._tmpsort1_;by driverId;run;
proc sort data=PR1.DRIVERS out=work._tmpsort2_;by driverId;run;

data pr1.merge_2;
	merge _tmpsort1_ _tmpsort2_;
	by driverId;
	keep resultId grid positionorder points constructorId name driverId forename surname raceId;
run;
proc delete data=work._tmpsort1_ work._tmpsort2_;run;

*Merge Races table to existing merged table;
proc sort data=PR1.MERGE_2 out=work._tmpsort1_;by raceId;run;
proc sort data=PR1.RACES out=work._tmpsort2_;by raceId;run;

*Final_merge is our final table with all merged columns included;
data pr1.final_merged;
	merge _tmpsort1_ _tmpsort2_(rename=(name=circuit));
	by raceId;
	keep resultId grid positionorder points constructorId name driverId forename surname raceId circuit date;
run;
proc delete data=work._tmpsort1_ work._tmpsort2_;run;

*Reorder the columns of Final_merged;
data pr1.final_merged;
	retain resultId circuit date driverId forename surname name grid positionorder points;
	drop constructorId raceId;
	set pr1.final_merged;
run;

*sort table to create final finished table and drop missing results;
proc sort data=pr1.final_merged out=pr1.final_table;by resultId;run;
data pr1.final_table;
	set pr1.final_table;
	if resultID = '.' then delete;
run;

*Print the first 5 rows of our final table;
proc print data=pr1.final_table(obs=5);
	title "First 5 Rows of Data";
run;



**************************************************;
*   		 QUESTIONS PART                      *;
**************************************************;
*   1. What race winner started the furthest 	 *;
*	   back on the grid and what race and year   *;
*	   was it?  								 *;
*	2. What constructors have the highest 		 *;
*	   average points per race and include how   *;
*	   many races the constructor has raced?     *;
*	3. What drivers have the highest average 	 *;
*	   points per race and include how many 	 *;
*	   races the driver has raced?				 *;
*	4. Which constructors outperform their		 *; 
*	   starting position?						 *;
*	5. Which drivers outperform their starting   *; 
*	   position?								 *;
*												 *;
**************************************************;

*Question 1;
*What race winner started the furthest back on the grid and what race and year was it?;
data pr1.final_table;
	set pr1.final_table;
	if grid = 0 then grid = '.';
	PositionsGained = grid - positionorder;
	if circuit = 'Indianapolis 500' then delete;
	rename forename=FirstName
		   surname=LastName
		   name=Constructor;
run;

proc sort data=pr1.final_table out = pr1.Q1(drop=resultId driverId); by descending PositionsGained; run;

proc print data=pr1.Q1(obs=1);
	title "Most Positions Gained in 1 Race";
run;

*Question 2;
*What constructors have the best average finish and include how many races the constructor has raced?;
proc sort data=pr1.final_table out = pr1.Q2(drop=resultId driverId); by Constructor; run;

proc means data=pr1.Q2 order=freq noprint maxdec=1 n mean;
	var positionorder;
	class Constructor;
	output out=pr1.Q2_Results mean=AvgFinish N = Races;
run;

data pr1.Q2_Results;
	set pr1.Q2_RESULTS;
	where Races > 56;
run;

proc sort data=pr1.Q2_Results out=pr1.q2_results(drop=_Type_ _FREQ_); by AvgFinish; format AvgFinish 5.1;run;
proc print data=pr1.Q2_RESULTS(obs=5); 
	title "Top 5 Constructors with Best Avg Finish";
	title2 height=8pt "*56 Starts (2 Seasons)";
run;

*Question 3;
*What drivers have the best average finish and include how many races the driver has raced?;
proc sort data=pr1.final_table out = pr1.Q3(drop=resultId); by driverId; run;

proc means data=pr1.Q3 order=freq noprint maxdec=1 n mean;
	var positionorder;
	class driverId;
	output out=pr1.Q3_Results mean=AvgFinish N = Races;
run;

proc sort data=PR1.drivers out=work._tmpsort1_;by driverId;run;
proc sort data=PR1.Q3_Results out=work._tmpsort2_;by driverId;run;

data pr1.Q3_Results;
	merge _tmpsort1_ _tmpsort2_;
	by driverId;
	keep driverId forename surname AvgFinish Races;
	if AvgFinish = '.' then delete;
	
	rename forename = FirstName
		   surname = LastName;
run;
proc delete data=work._tmpsort1_ work._tmpsort2_;run;

data pr1.Q3_Results;
	set pr1.Q3_RESULTS;
	where Races > 28;
run;

proc sort data=pr1.Q3_Results out=pr1.q3_results; by AvgFinish; format AvgFinish 5.1;run;
proc print data=pr1.Q3_RESULTS(obs=5); 
	title "Top 5 Drivers with Best Avg Finish";
	title2 height=8pt "*28 Starts (2 Seasons)";
run;


*Question 4;
*Which constructors outperform their starting position?;
proc means data=pr1.Q2 order=freq noprint maxdec=1 n mean;
	var PositionsGained grid positionorder;
	class Constructor;
	output out=pr1.Q4_Results mean=AvgPositions Start N = Races;
run;

proc sort data=pr1.Q4_Results out=pr1.q4_results(drop=_Type_ _FREQ_); by descending AvgPositions; 
			where Races >84;
			format AvgPositions Start 5.1;run;
proc print data=pr1.Q4_RESULTS(obs=20);
	title "Top 20 Constructors Who on Average Outperformed Their Starting Position ";
	title2 height=8pt "*56 Starts (2 Seasons)";	 
run;
ods title;
proc print data=pr1.Q4_RESULTS; where Constructor ="Red Bull" or Constructor ="Mercedes"; run;

*Question 5;
*Which drivers outperform their starting position?;
proc means data=pr1.Q3 order=freq noprint maxdec=1 n mean;
	var PositionsGained grid;
	class driverId;
	output out=pr1.Q5_Results mean=AvgPositions Start N = Races;
run;

proc sort data=PR1.drivers out=work._tmpsort1_;by driverId;run;
proc sort data=PR1.Q5_Results out=work._tmpsort2_;by driverId;run;

data pr1.Q5_Results;
	merge _tmpsort1_ _tmpsort2_;
	by driverId;
	keep driverId forename surname AvgPositions Start Races;
	
	rename forename = FirstName
		   surname = LastName;
run;
proc delete data=work._tmpsort1_ work._tmpsort2_;run;

proc sort data=pr1.Q5_Results out=pr1.q5_results; by descending AvgPositions; 
			where Races >42;
			format AvgPositions Start 5.1;run;
			
proc print data=pr1.Q5_RESULTS(obs=20); 
	title "Top 20 Drivers Who on Average Outperformed Their Starting Position ";
	title2 height=8pt "*28 Starts (2 Seasons)";
run;
ods title;
proc print data=pr1.Q5_RESULTS; where driverId =1 or driverId =830; run;

**************************************************;
*   		  PLOTS AND MODELS                   *;
**************************************************;

*AvgPositions gained per season;

data pr1.Plot1;
	set pr1.Q1;
	PositionsGained = abs(PositionsGained);
	Season = Year(date);
	keep Season PositionsGained;
run;

proc means data=pr1.Plot1 order=freq noprint maxdec=1 n sum;
	var PositionsGained;
	class Season;
	output out=pr1.Plot1 sum=AvgPositions;
run;

proc sort data=PR1.PLOT1 out=PR1.PLOT1; by Season;run;

proc sgplot data=pr1.Plot1;
	title "Positions Difference Per Season";
	series x=Season y=AvgPositions /;
	xaxis grid label="Season";
	yaxis max=3500 grid label="Positions Difference";
run;


*Driver wins vs Avg Start for those wins;
data pr1.Plot2;
	set pr1.final_table;
	where positionorder = 1;
	keep driverId FirstName LastName grid positionorder;
run;

proc means data=pr1.PLOT2 order=freq noprint n;
	var positionorder;
	class driverId;
	output out = pr1.Plot2a N=Wins;
run;

proc means data=pr1.PLOT2 order=freq noprint maxdec=1 mean;
	var grid;
	class driverId;
	output out = pr1.Plot2b mean=AvgStart;
run;

proc sort data=PR1.Plot2 out=work._tmpsort1_;by driverId;run;
proc sort data=PR1.Plot2a out=work._tmpsort2_;by driverId;run;
proc sort data=PR1.Plot2b out=work._tmpsort3_;by driverId;run;

data pr1.PLOT2F;
	merge _tmpsort1_ _tmpsort2_ _tmpsort3_;
	by driverId;
	where driverId ne .;
	format AvgStart 5.2;
	keep driverId FirstName LastName Wins AvgStart;
run;

proc delete data=work._tmpsort1_ work._tmpsort2_ work._tmpsort3_;run;

proc sort data=pr1.PLOT2F out=pr1.PLOT2F nodupkey; by _all_; run;
proc sort data=pr1.PLOT2F out=pr1.PLOT2F; by descending Wins; run;

proc print data=pr1.PLOT2F(obs=10); title "Most Wins by Driver With AvgStart of Those Wins"; run;

proc sgplot data=PR1.PLOT2F;
	title height=14pt "Wins vs Grid by Driver";
	scatter x=Wins y=AvgStart /;
	xaxis grid label="Number of Wins per Driver";
	yaxis grid label="Avg Starting Position for Wins";
	refline 2.69 / axis=y lineattrs=(thickness=2 color=red) 
		label="2.69 - Avg Start for a win" labelattrs=(color=red);
run;


*Constuctor Positions Gained vs Starting Position;
proc sgplot data=PR1.Q4_RESULTS;
	title height=14pt "Avg Grid Start vs Avg Positions Gained per Constructor";
	reg x=AvgPositions y=Start / nomarkers;
	scatter x=AvgPositions y=Start /;
	xaxis grid label="Positions Gained";
	yaxis grid label="Starting Position";
run;


*Driver Positions Gained vs Starting Position;
proc sgplot data=PR1.Q5_RESULTS;
	title height=14pt "Avg Grid Start vs Avg Positions Gained per Driver";
	reg x=AvgPositions y=Start / nomarkers;
	scatter x=AvgPositions y=Start /;
	xaxis grid label="Positions Gained";
	yaxis grid label="Starting Position";
run;


*Where you start is more likely where you will finish;
data pr1.plot_last;
	set pr1.final_table;
	where grid le 20 and positionorder le 20;
run;

proc freq data=pr1.plot_last;
	title "Position Started vs Position Finished";
	tables grid*positionorder / nopercent nocum norow nocol plots=mosaicplot;
run;

proc sgplot data=PR1.FINAL_TABLE;
	title height=14pt "Starting Position vs Finishing Position";
	reg x=grid y=positionorder / nomarkers;
	scatter x=grid y=positionorder / markerattrs=(symbol=circlefilled) 
		transparency=0.98;
	xaxis grid label="Grid Start";
	yaxis grid label="Result Position";
run;

