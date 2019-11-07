/***JG running code 2.11.19*/
libname usrds "C:\Users\rpatzer\Desktop\USRDS data (2017 saf)\2017 Core\core";
libname dfwl "C:\Users\lteunis\Desktop\ProfitStatus_WL";
/*JGander hardrive - within Mark Code - mark_11092018**/
libname jgmc "D:\ProfitStatus_WL\SAS_Code_dwnld from Box_11032018\mark_code\mark_11092018";
libname jg "D:\"; /*JGander hardrive - - added 11/10/18*/
libname jgdfwl "D:\ProfitStatus_WL";
options nofmterr;
/*JGander updated with 2017 USRDS data
Revised by: JGander			Version: 11/03/2018			*/

data rxhist16;
 set jg.rxhist17saf; /*JGander (2.11.19) revised to rxhist (version 11/03/2018)*/
*set usrds.rxhist17saf ; /*(MZ)*/
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

data dial200016;  /*JG updated 10/10/17
					changed 'enddate' to 2015
					Made sure ONLY patients in "dfwl.pat_usrds" were kept*/
	merge 	rxhist16(keep=usrds_id dialysis_mod1 dialysis_mod2 begdate enddate provusrd rxdetail) 
			/*jgdfwl.pat_usrds2 (in=a); /*1723590 obsrvations   (MZ)*/
			jgdfwl.pat_usrds17 (in=a rename=provusrd=provusrd_base); 		/*(JG)*/
	by usrds_id;
if a;
/*deleting patient observations that ended before 1/1/00 or after 12/31/16, 
								since dfwl.pat_usrds2 stops f/u at 2016*/

run;

data dial1;
set dial200016;
keep USRDS_ID provusrd provusrd_base dialysis_mod1 dialysis_mod2 
begdate edate startdate tx1date 
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
run;
/*3829134 observations and 7 variables*/

proc sort data=dial2;
by usrds_id startdate;
run;

data x1 ;
set dial2;
run;


data xx;
set x1 ;
run;


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
/*by usrds_id;*/
/*if first.usrds_id;*/
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
if provusrd=. then provusrd=provusrd_base;
run;
/*1722545 observations and 7 variables*/

proc sort data=facility_all;
by  usrds_id ;run;
data work1;
set facility_all(where=(provusrd>.));
by usrds_id;
if first.usrds_id;
run;


data last; /*JG modified libname*/
set work1;
keep BEGDATE ENDDATE USRDS_ID PROVUSRD dialysis_mod1 dialysis_mod2 startdate ;

run;

data first; /*JG modified libname*/
set dial200016;
by usrds_id;
if first.usrds_id;
if provusrd=. then provusrd=provusrd_base;/*Jason added*/
keep BEGDATE ENDDATE USRDS_ID PROVUSRD dialysis_mod1 dialysis_mod2 startdate ;
run;
/*1723590 observations and 7 variables*/



