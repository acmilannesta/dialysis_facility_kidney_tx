/*Revised by: JGander			Version: 05/02/2018			
JGander moved data to her KP computer and remapped librarys: **********

options nofmterr;
libname usrds "G:\Investigators\Gander\USRDS data (2016 SAF)\core";
libname dfwl "C:\Users\D990753\Desktop\JGander\Abstracts_Manuscripts_Publications\ProfitStatus_WL\code";*/

/********	*********	************	*************	*************	************	*********/

/*proc contents data=jgdfwl.pat_usrds17 varnum; run;*/

/****MZ began revising the cohort selection 05/01/2018**** JGander further revised 05/02/2018*/

/*cleaning the facility*/

libname usrds "C:\Users\zhangxyu\Desktop\JAMA_paper_revision";
libname usrds15 "C:\Users\zhangxyu\Desktop\JAMA_paper_revision";
libname dfwl "C:\Users\zhangxyu\Desktop\JAMA_paper_revision";

/* Format Library	*/
libname library 'C:\Users\zhangxyu\Desktop\JAMA_paper_revision';

/**laptop desktop***
added by JGander on 11/10/2018
to use Emory University Laptop and update data
	updated data is USRDS 2017 (has full year of 2016 data)
	updated data is Dialysis Facility Report 2018 (has 2013-2016 data)
*/

libname dfwl "C:\Users\rpatzer\Desktop\ProfitStatus_WL";

libname jg "D:\"; /*JGander hardrive - - added 11/10/18*/
libname jgdfwl "D:\ProfitStatus_WL"; /*JGander hardrive's profit status Folder - - added 11/10/18*/
options nofmterr;

***********************************************
Revision on 10/15/2019 by Zhensheng Wang to use PROVUSRD from rxhist or from MEDEVID
CHANGES MADE
1. RENAME provusrd from Pat_usrds17 to provusrd_base
data dial200016
	merge 	rxhist16(keep=usrds_id dialysis_mod1 dialysis_mod2 begdate enddate provusrd rxdetail) 
			jama.Pat_usrds17 (in=a rename=provusrd=provusrd_base)
	by usrds_id
if a
run

2. For com_wl_tx ealier than all dialysis services, use the baseline PROVUSRD
data x3
set x31no
by usrds_id
if first.usrds_id
if startdate<com_wl_tx<BEGDATE
provusrd = provusrd_base
run

3. If subjects having no records in rxhist, using their baseline PROVUSRD (all subjects with missing baseline PROVUSRD will be dropped)
data facility_all
set x2 x3_all x41
if prvousrd=. then provusrd=provusrd_base
run
******************************************************;


/*JGander updated with 2017 USRDS data
Revised by: JGander			Version: 11/03/2018			*/
libname usrds "e:\python projects\usrds";
libname jama "e:\python projects\jama";


data rxhist16;
/*set dfwl.rxhist16; /*JGander revised to rxhist (version 11/03/2018)*/
set usrds.rxhist;
/*RXCATDT	1 Center hemo
			2 Center self hemo
			3 Home hemo
			4 Hemo Training
			5 CAPD
			6 CAPD Training
			7 CCPD
			8 CCPD Training
			9 Other peri
			A Uncertain
			B DISCONTINUED DIALYSIS
			D Death
			T Transplant
			X Lost to follow-up
			Z Recovered Function		*/
if rxdetail in ('1', '2', '3', '4', '5', '6', '7', '8', '9'); /*dialysis only*/
if .<enddate<mdy(1,1,2000)  then delete; 

/*dialysis modality** created by JGander 11/9/18  
	COLLAPSING [RXGROUP] from "rxhist" SAF
	RXGROUP 1 Hemodialysis
			2 Center self hemo
			3 Home hemo
			5 CAPD
			7 CCPD
			9 Other peri
			A Uncertain Dialysis
			B Discontinued Dialysis
			D Death
			T Transplant
			X Lost to follow-up
			Z Recovered Function	*/
/*modeled after the iChoose analysis....
			in-center hemo (includes hemodialysis and center self hemo)
			home hemo, 
			PD  (includes CAPD and CCPD)*/

/*dialysis modality: in-center Hemo, PD, home hemo*/
 	 if rxgroup='1' or rxgroup='2' 	then dialysis_mod1=0; /*in center hemodialysis*/
else if rxgroup='5' or rxgroup='7' or rxgroup='9' then dialysis_mod1=1; /*peritoneal dialysis*/
else if rxgroup='3'					then dialysis_mod1=2; /*home hemodialysis*/
else 							dialysis_mod1=.;

/*dialysis modality: in-center dialysis, home dilaysis (hemo or PD)*/
	 if rxgroup='1' or rxgroup='2' then 	dialysis_mod2=0; /*in-center dialysis*/
else if rxgroup='3' or rxgroup='5' or 
		rxgroup='7' or rxgroup='9' then 	dialysis_mod2=1; /*home dialysis modality (home hemo or PD)*/
else 							dialysis_mod2=.;

run;
/* 5130349 observations and 11 variables*/
proc freq data=rxhist16;
table dialysis_mod1 dialysis_mod2; run;


data dial200016;  /*JG updated 10/10/17
					changed 'enddate' to 2015
					Made sure ONLY patients in "dfwl.pat_usrds" were kept*/
	merge 	rxhist16(keep=usrds_id dialysis_mod1 dialysis_mod2 begdate enddate provusrd rxdetail) 
			jama.Pat_usrds17 (in=a rename=provusrd=provusrd_base); /*1723590 obsrvations*/
	by usrds_id;
if a;
/*deleting patient observations that ended before 1/1/00 or after 12/31/16, 
								since dfwl.pat_usrds2 stops f/u at 2016*/

run;
/* 4076542 observations and 321 variables*/
proc contents data=dial200016 varnum; run;

data dial1;
set dial200016;
keep USRDS_ID provusrd provusrd_base dialysis_mod1 dialysis_mod2 
begdate edate startdate tx1date 
enddate /*ldtxdate*/ died dod ;
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
run;
/*3978696 observations and 7 variables*/

proc sort data=dial2;
by usrds_id startdate;
run;

/*data x1 ;*/
/*set dial2;*/
/**/
/*run;*/
/**/
/**/
/*data xx;*/
/*set x1 ;*/
/*run;*/
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
/*by usrds_id;*/
/*if first.usrds_id;*/
if begdate<com_wl_tx<enddate;  **THE PROBLEM IS HERE;

run;   **144,672; **POTENTIALLY COULD BE 242,451;
proc sql;
create table x31no as select * from x3 a where a.usrds_id not in 
(select usrds_id from x31);
quit;

data x32;
set x31no;
by usrds_id;
if first.usrds_id;
if startdate<com_wl_tx<BEGDATE;
provusrd = provusrd_base;
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
/*267313 observations and 7 variables*/

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
if provusrd=. then provusrd=provusrd_base;
run;
/*1723545 observations and 7 variables*/

proc sort data=facility_all;
by  usrds_id ;run;
data work1;
set facility_all(where=(provusrd>.));
by usrds_id;
if first.usrds_id;
run; /*1723041 obs*/
/*proc sql;*/
/*create table test2 as select *, count(*) as count from facility_all1 group by usrds_id;*/
/*run;*/
/*data test22;*/
/*set test2;*/
/*if count>1;*/
/*run;*/

data work2;
  merge work1(in=a) jama.Pat_usrds17(drop=provusrd startdate);
  by usrds_id;
  if a;
run;

proc contents data=work2 varnum; run;
/*proc sort nodupkey data=work2;*/
/*by usrds_id;*/
/*run;*/

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
censordate= min(edate, ldtxdate, died, dod, MDY(12,31,2016));
format censordate ldtxdate mmddyy10.;
run; /* 1723041 observations and 325 variables*/

proc freq data=work3; table dialysis_mod1 race_new; run;

/*merging in Crosswalk File 2017 "xref_prv_17" */
proc sort data=work3; by provusrd; run;
libname xw "C:\Users\rpatzer\Desktop\USRDS data (2017 saf)\Crosswalk\crosswalk";
data xref_prv_17; 
	set usrds.xref_prv_2017; run;
proc sort data=xref_prv_17 FORCE; by provusrd; run;

data jama.work4 ; /*final patient-level USRDS file before merging with DFC_DFR*/
	merge	work3 (in=a)
			xref_prv_17;
	by provusrd;
if a; /*keeping ONLY observations within PATIENT-level file*/
ccn=provhcfa*1;
if ccn=. then ccn_miss=1; else ccn_miss=0;

/*proc freq; table ccn_miss;*/
run;   /*1723041  observations ... ccn_miss 11458 (0.66%) */


