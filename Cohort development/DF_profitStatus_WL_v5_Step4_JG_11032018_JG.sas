/**laptop desktop***
added by JGander on 11/03/2018
to use Emory University Laptop and update data
	updated data is USRDS 2017 (has full year of 2016 data)
	updated data is Dialysis Facility Report 2018 (has 2013-2016 data)
*/
libname usrds "C:\Users\rpatzer\Desktop\USRDS data (2017 saf)\2017 Core\core";
libname dfwl "C:\Users\rpatzer\Desktop\ProfitStatus_WL";

libname jgdfwl "D:\ProfitStatus_WL";
libname jgmc "D:\ProfitStatus_WL\SAS_Code_dwnld from Box_11032018\mark_code\mark_11092018";
libname jg "D:\"; /*JGander hardrive - - added 11/10/18*/
options nofmterr;

/*
  __  __                                                               
 |  \/  |                            Merging 2000-2016 Patient-level USRDS data                                   
 | \  / | ___ _ __ __ _  ___           "work.work3" (n=1,702,820)	with                                
 | |\/| |/ _ \ '__/ _` |/ _ \        Facility-Level file "dfwl.usrdsfac0014rev_dfc" (n=10500) that contains                                  
 | |  | |  __/ | | (_| |  __/        1. aggregated USRDS Patient level data (for facility char)	                                   
 |_|  |_|\___|_|  \__, |\___|        2. Dialysis Facility Compare (DFC) for Profit status and ownership                                  
  _____      _   _ __/ |      _      3. USRDS Facility SAF (# staff data and USRDS PROFIT status)     
 |  __ \    | | (_)___/      | |    _  |  ____|       (_) (_) |        
 | |__) |_ _| |_ _  ___ _ __ | |_ _| |_| |__ __ _  ___ _| |_| |_ _   _ 
 |  ___/ _` | __| |/ _ \ '_ \| __|_   _|  __/ _` |/ __| | | | __| | | |
 | |  | (_| | |_| |  __/ | | | |_  |_| | | | (_| | (__| | | | |_| |_| |	JGander Updated
 |_|   \__,_|\__|_|\___|_| |_|\__|     |_|  \__,_|\___|_|_|_|\__|\__, |		11/10/18
                                                                  __/ |
/*Facility-level file*  DFC+DFR+crosswalk                          |__*/ 
proc contents data=dfwl.dfc_dfr_txc varnum; run; /*6524 obs*/
proc sort data=dfwl.dfc_dfr_txc; by ccn; run;
/*patient-level file*/
proc contents data= jg.work4 varnum; run; 	/*1722545 obs*/
										/* at this point we have already 
										   included ONLY last observation for facility designation
										**This file includes the USRSD 2017 crosswalk****/
/*counting how many dialysis facilities are in FINAL cohort
	11.18.18 (JG)*/
ods html close;
proc means data=jg.work4;
class ccn;
var sex_new;
output out=count;

run;
data test;
	set	count;
if _stat_='N';
run;
ods html;

proc sort data= jg.work4; by ccn; run;
/*MERGE***********************update 11/10/18 (JG) */
/*JGander hardrive - within Mark Code - mark_11092018**/
*libname jgmc "D:\ProfitStatus_WL\SAS_Code_dwnld from Box_11032018\mark_code\mark_11092018";
libname usrds "e:\python projects\usrds";
libname jama "e:\python projects\jama";

proc sort data= jama.work4 out=work4; by ccn; run;
proc sort data= jama.dfc_dfr_txc out=dfc_dfr_txc; by ccn; run;
data pat_facility_dfc17;
	merge	work4 (in=a) /*1,723,041 observations */
			dfc_dfr_txc ; /* 6524obs  these variables with patient-level file*/
	by ccn;
if a; /*keeping ONLY observations within PATIENT-level file**so some will have missing facility*/
run;		
proc freq data=pat_facility_dfc17; 
table dialysis_mod1 txc race_new chain_class2; run;
/*counting how many dialysis facilities are in USRDS that do NOT link 
	to DFC-DFR data (the [chain_class2] will be missing*/
ods html close;
proc means data=pat_facility_dfc17;
where chain_class2=.;
class ccn;
var sex_new;
output out=count;

run;
data test;
	set	count;
if _stat_='N';
run;
ods html;

proc print data=pat_facility_dfc17 (obs=100);
where provusrd ne .;
var usrds_id ccn chf bmi_35 stroke sex_new censordate;	/*from patient-level data*/
	/*provusrd pctrace_ethn_w pctpre_nephcare 		/*from aggregated USRDS data*/
	/*Facility_Name Five_Star Profit_or_Non_Profit	/*from DFC*/
	/*SW_N profit;	
/*from USRDS Facility SAF*/
where ccn ne .;
run;

/*data pat_facility_dfc_dfr17;
	set pat_facility_dfc17 ;
where startdate ne .;
*Coding event as composite, occured if waitlisted or LDKT, else censored;
*Note for future...we might want to do competing risks for manuscript w/ death;
	if edate ne ' ' then event = 1;
		else if ldtxdate ne ' ' then event = 1;
	else event = 0;
*Separating events for descriptive statistics; *LDKT set as first event;
	if edate ne ' ' and ldtxdate = ' ' then tri_event = 2; *Listed as first event;
		else if edate ne ' ' and edate < ldtxdate then tri_event = 2; 
	else if edate ne ' ' and edate = ldtxdate then tri_event = 1; *LDKT as first event;
		else if ldtxdate ne ' ' and edate = ' ' then tri_event = 1; 
		else if ldtxdate ne ' ' and ldtxdate < edate then tri_event = 1; 
	else tri_event = 0; *Neither or died;

*Creating a follow-up time variable;
	if startdate = . then survtime = .;
		else if censordate = . then survtime = .;
	else survtime = censordate - startdate;

run;*/
proc freq data=pat_facility_dfc_dfr17; table chain_class dialysis_mod1 txc race_new; run;
proc freq data=pat_facility_dfc_dfr17; 
where chain_class=.;
table  txc race_new; run;

/*1722545 observations and 502 variables*/
proc contents data=pat_facility_dfc_dfr17 varnum; run;

proc format;
value chain	1 = 'Fresnius'
			2 = 'Davita'
			3 = 'Small, for-profit'
			4 = 'Independent, for-profit'
			5 = 'Non-profit'
			. = 'Missing';
run;

/*excluding patient-level observations that are linked to a 
	transplant center (from DFC file)*/
data pat_facility_dfc_dfr17a;
	set pat_facility_dfc_dfr17;
where txc ne 1;
run;
proc freq data=pat_facility_dfc_dfr17a;
table chain_class dialysis_mod1;
run;

data jama.pat_facility_dfc17;
set pat_facility_dfc17;
where chain_class ne . ;
if edate ne '' then wl=1; else wl=0;
if ldtxdate ne '' then livingd=1; else livingd=0;
if wl=1 or livingd=1 then combine=1;  else combine=0;
if TX1DONOR='C' and TX1DATE ne . then deceasedt=1;else deceasedt=0;
if TX1DONOR='C' and TX1DATE ne . then dectime=TX1DATE;
wl_time=(min(edate,died,MDY(12,31,2016))-first_se+1)/30.4375;
wlist=(min(edate,died,MDY(12,31,2016))=edate); 

dec_time=(min(dectime,ldtxdate,died,MDY(12,31,2016))-first_se+1)/30.4375;
dec=(min(dectime,ldtxdate,died,MDY(12,31,2016))=dectime); 


ld_time=(min(ldtxdate,dectime, died,MDY(12,31,2016))-first_se+1)/30.4375;
ldtx=(min(ldtxdate,dectime, died,MDY(12,31,2016))=ldtxdate); 

wl_ld_time=(min(edate, ldtxdate,died,MDY(12,31,2016))-first_se+1)/30.4375;
wl_ldtx=(min(edate, ldtxdate,died,MDY(12,31,2016))=min (ldtxdate,edate));

run;/*1587949 obs*/
proc contents data=jgdfwl.pat_facility_dfc17 varnum;run;
proc freq data=jgdfwl.pat_facility_dfc17;
table wl livingd deceasedt chain_class dialysis_mod1
		(wl livingd deceasedt)*chain_class;
run;
/*1446278 obs*/

/*counting how many dialysis facilities are in FINAL cohort
	11.17.18 (JG)*/
ods html close;
proc means data=jgdfwl.pat_facility_dfc17;
class ccn;
var sex_new;
output out=count2;

run;
data test2;
	set	count2;
if _stat_='N';
run;
ods html;

