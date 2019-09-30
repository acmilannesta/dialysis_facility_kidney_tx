/*Revised by: JGander			Version: 05/02/2018			
JGander moved data to her KP computer and remapped librarys: ***********/

/*options nofmterr;*/
/*libname usrds "G:\Investigators\Gander\USRDS data (2016 SAF)\core";*/
/*libname dfwl "C:\Users\D990753\Desktop\JGander\Abstracts_Manuscripts_Publications\ProfitStatus_WL\code";*/

/********	*********	************	*************	*************	************	*********/

/*proc contents data=dfwl.pat_usrds2 varnum; run;*/

/****MZ began revising the cohort selection 05/01/2018**** JGander further revised 05/02/2018*/

/*cleaning the facility*/
libname usrds "\\nasn2ac.cc.emory.edu\surgery\SQOR\USRDS data (2016 SAF)\core";
libname usrds15 "\\nasn2ac.cc.emory.edu\surgery\SQOR\USRDS data (2015 saf)\Core";
libname dfwl "\\nasn2ac.cc.emory.edu\surgery\SQOR\ProfitStatus_WL";

/* Format Library	*/
libname library '\\nasn2ac.cc.emory.edu\surgery\SQOR\USRDS data (2016 SAF)\core';

/**laptop desktop***
added by JGander on 11/03/2018
to use Emory University Laptop and update data
	updated data is USRDS 2017 (has full year of 2016 data)
	updated data is Dialysis Facility Report 2018 (has 2013-2016 data)
*/
libname usrds "C:\Users\rpatzer\Desktop\USRDS data (2017 saf)\2017 Core\core";
libname dfwl "C:\Users\rpatzer\Desktop\ProfitStatus_WL";

options nofmterr;

/*JGander updated with 2017 USRDS data
Revised by: JGander			Version: 11/03/2018			*/

data rxhist16;
/*set dfwl.rxhist16; /*JGander revised to rxhist (version 11/03/2018)*/
set usrds.rxhist;
if rxdetail in ('1', '2', '3', '4', '5', '6', '7', '8', '9'); /*dialysis only*/
if .<enddate<mdy(1,1,2000)  then delete; 
run;
/* 5130349 observations and 9 variables*/


data dial200016;  /*JG updated 10/10/17
					changed 'enddate' to 2015
					Made sure ONLY patients in "dfwl.pat_usrds" were kept*/
	merge 	rxhist16(keep=usrds_id begdate enddate provusrd rxdetail) 
			dfwl.pat_usrds2 (in=a); /*1723590 obsrvations*/
	by usrds_id;
if a;
/*deleting patient observations that ended before 1/1/00 or after 12/31/16, 
								since dfwl.pat_usrds2 stops f/u at 2016*/

run;
/* 4076542 observations and 321 variables*/
proc contents data=dial200016 varnum; run;

data dial1;
set dial200016;
keep USRDS_ID provusrd begdate edate
startdate tx1date 
enddate ldtxdate died dod ;
run;
/*4076542 observations and 9 variables*/

data dial2;
set dial1;
com_death=min(DIED,dod);
com_wl_tx=min(EDATE,TX1DATE );
drop DIED dod EDATE TX1DATE;
format com_death ddmmyy10.;
format com_wl_tx ddmmyy10.;
/*if ENDDATE>'31dec2016'd and com_death>'31dec2016'd 
and com_wl_tx>'31dec2016'd then delete;*/
if BEGDATE>'31dec2016'd then delete;
/*if BEGDATE<'31dec2015'd and then delete;*/
if PROVUSRD =. then delete;
run;
/*3829134 observations and 7 variables*/

proc sort data=dial2;
by usrds_id startdate;
run;

data dfwl.x1 ;
set dial2;

run;


data xx;
set dfwl.x1 ;
run;
/**/
/*data xxx;*/
/*set xx;*/
/*by usrds_id;*/
/*/*if last.usrds_id;*/*/
/*keep usrds_id PROVUSRD;*/
/*run;*/
/**/
/*proc sort nodup data=xxx;*/
/*by usrds_id;*/
/*run;*/

/*proc sql;*/
/*create table x4 as select usrds_id, count(*) as count from xxx group by usrds_id;*/
/*quit;*/


/*if there is patient does not have any event, either death or wl or tx*/;
data x2;
set dial2;
by usrds_id;
if com_death =. and com_wl_tx = . ;
if last.usrds_id;
run;
/*if there is patient has the event of wl or tx*/
data x3;
set dial2;
by usrds_id;
if  com_wl_tx ne . ;
run;

data x31;
set x3;
if BEGDATE<com_wl_tx<ENDDATE;
by usrds_id;
if first.usrds_id;
run;
proc sql;
create table x31no as select * from x3 a where a.usrds_id not in 
(select usrds_id from x31);
quit; 
data x32;
set x31no;
by usrds_id;
if first.usrds_id;
if startdate<com_wl_tx<BEGDATE;
run;
proc sql;
create table x32no as select * from x31no a where a.usrds_id not in 
(select usrds_id from x32);
quit; 
data x33;
set x32no;
by usrds_id;
if last.usrds_id;
run;

data x3_all;
set x31 x32 x33;
run;
/*266689 observations and 7 variables*/

/*if there is patient has the event of death, but no wl or tx*/
data x4;
set dial2;
by usrds_id;
if  com_wl_tx = . and com_death ne .;
run;

data x41;
set x4;
by usrds_id;

if last.usrds_id;
run;

data facility_all;
set x2 x3_all x41;

run;
/*1722545 observations and 7 variables*/

proc sort data=facility_all;
by  usrds_id ;run;
data work1;
set facility_all;
by usrds_id;
if first.usrds_id;
run;
/*proc sql;*/
/*create table test2 as select *, count(*) as count from facility_all1 group by usrds_id;*/
/*run;*/
/*data test22;*/
/*set test2;*/
/*if count>1;*/
/*run;*/

proc sql;
create table work2 as select * from work1 a left join dfwl.Pat_usrds2 b 
on a.usrds_id=b.usrds_id;
quit;

proc sort nodupkey data=work2;
by usrds_id;
run;

data work3;
set work2;
/*Living Donor Transplant*/
if tx1donor = 'L' then livingdonor = 1;
		if livingdonor=1 then do;
				 if tx1date = ' ' and tdate ne ' ' then ldtxdate=tdate;
			else if tdate = ' ' and tx1date ne ' ' then ldtxdate=tx1date;
			else 										ldtxdate=tx1date;
		end;

/*Creating ONE variable that is the censor date 
  and is the MINIMUM of WL date, LDKTx date, death date, or end of study*/	
censordate= min(edate, ldtxdate, died, dod, MDY(12,31,2015));
format censordate ldtxdate mmddyy10.;
run; /* 1722545 observations and 325 variables*/

proc freq data=work3; table race_new; run;
