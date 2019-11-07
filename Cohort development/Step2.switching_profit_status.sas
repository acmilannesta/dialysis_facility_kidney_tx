/***JG running code 2.11.19*/
libname dfwl "U:\JAMA_paper_revision";
/*JGander hardrive - within Mark Code - mark_11092018**/
libname jgmc "U:\JAMA_paper_revision";
libname jg "U:\JAMA_paper_revision"; /*JGander hardrive - - added 11/10/18*/
libname jgdfwl "U:\JAMA_paper_revision";
libname x 'U:\JAMA_paper_revision';
options nofmterr;
data fx;
set first last;  /*JG revised libname 2.11.19*/
run;
/*3446631 observations and 7 variables
2.11.19 (JG)#: 3446135 observations and 7 variables*/

proc sort nodupkey data=fx; /*removed duplicates - 
							will keep first (and last) 	facility (if switched)*/
by usrds_id PROVUSRD;
run;

data status;
set jama.dfc_dfr_crssw;
keep PROVUSRD chain_class chain_class2 Profit_or_Non_Profit profit for_profit;
if chain_class = . then delete;

if chain_class = 5 then profit=0;
if 1=<chain_class<=4 then profit=1;
if chain_organization = "FRESENIUS MEDICAL CARE" or
	chain_organization = "DAVITA"  	or Profit_or_Non_Profit='Profit'
											then for_profit=1;
else if Profit_or_Non_Profit='Non-Profit' 	then for_profit=0;

run;
/*6542 obs*/

proc sql;
create table chain_status as 
select * from fx a
left join status b 
on a.PROVUSRD=b.PROVUSRD ;
quit;
/*2339997 obs - - - -2.11.19 (JG)#:  2283474 obs*/

data chain_status1;
set chain_status;
if chain_class = . then delete;
run;
/*1915452 obs*/
/*freq table added 2.6.19 (JG) */
proc freq data=chain_status1;
table Profit_or_Non_Profit profit
		Profit_or_Non_Profit*(profit chain_class chain_class2)
		for_profit*( profit chain_class chain_class2)
		profit*(chain_class chain_class2);
run;

proc sort data=chain_status1;
by usrds_id BEGDATE;
run;
/** 		**		**		***/
/*	Calculating [switch_time]
	==> time in between first facility and last facility
			==> (begdate at last facility) - (begdate at first facility)	*/
proc sort data=chain_status1 ; 
by usrds_id begdate ;
run;

data chain_status2;
	set chain_status1;
by usrds_id ;
retain first_begdate;

if first.usrds_id then do;
	first_begdate = begdate;
end;
if last.usrds_id then do;
	if first_begdate ne begdate then switch_time= (begdate-first_begdate)/30.4375; /*months*/
	else switch_time = 0;
end;

format  first_begdate mmddyy10.;
run;


/*revised 2.6.19 (JG) and added [Profit_or_Non_Profit] and [for_profit] to determine the type of LAST facility*/
data chain_status3 (keep=usrds_id switch_time for_profit Profit_or_Non_Profit) ;
	set chain_status2;
by usrds_id;
if last.usrds_id;
run;
/*1562519 obs*/
/**	** merge this with final data below 
		so there is only 1 observation per person **/				
proc sql;			/*updated 2.6.19 (JG) to use variable [for_profit] instead of [profit]*/
create table change_status1a as select usrds_id, count(*) as count, sum(for_profit) as sum from chain_status1
group by usrds_id;
quit;
/*1625498 rows*/

/*added the following PROC SQL to add [Profit_or_Non_Profit] var from 
	"chain_status3" to the counts and sums from "change_status1a"	*/
proc sql;
create table change_status1b as select * from change_status1a a left join 
chain_status3 b on a.usrds_id=b.usrds_id ;
quit; 

/*Updated 2.6.19 (JG) to create a 4 level [change_status] variable
	0	=	no change
	1	=	facility change by remained within same profit-status group
	2	=	switched from profit to non-profit (last facility was non-profit)
	3	=	switched from non-profit to for profit (last facility was for profit)	*/
data jama.change_status1c;
set change_status1b; /*table created on 2.6.19 (JG) to contain counts, sums, [Profit_or_Non_Profit] */
if count=1 then change_status=0;
if count=2 and (sum=2 or sum=0) then change_status=1;
if count=2 and sum=1 and for_profit=0 then change_status=2; /*(JG revied 2.11.19)*/
if count=2 and sum=1 and for_profit=1 	   then change_status=3;/*(JG revied 2.11.19)*/
run;
/*1625498 observations and 6 variables (2.11.19 JG)*/


data patient_class (drop=for_profit); /*drop statement added 2.6.19 (JG) because
										[for_profit] variable is already in "change_status1c" */
set x.pat_facility_dfc17_dist; /*updated with 11.15.18 cohort with distance variables*/
keep usrds_id wl livingd deceasedt edate tx1date TX1DONOR FIRST_SE PROVUSRD;
run;

proc sql; /*this is the final step for [change_status] because 'switch time' added previously (jg 2.6.19)*/
create table change_status2 as select * from patient_class a left join 
change_status1c b /*data created 2.6.19 to include [for_profit] variable and 4-lvl [change_status]*/
on a.usrds_id=b.usrds_id ;
quit; 
/*1478564 rows and 6 columns (2.11.19 JG)*/


proc freq data=patient_class;
table change_status*(wl livingd deceasedt);
run;

