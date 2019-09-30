/**laptop desktop***
added by JGander on 11/03/2018
to use Emory University Laptop and update data
	updated data is USRDS 2017 (has full year of 2016 data)
	updated data is Dialysis Facility Report 2018 (has 2013-2016 data)
*/
libname usrds "C:\Users\rpatzer\Desktop\USRDS data (2017 saf)\2017 Core\core";
libname dfwl "C:\Users\rpatzer\Desktop\ProfitStatus_WL";
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
 |_|   \__,_|\__|_|\___|_| |_|\__|     |_|  \__,_|\___|_|_|_|\__|\__, |		11/03/18
                                                                  __/ |
/*Facility-level file*  DFC+DFR+crosswalk                          |__*/ 
proc contents data=dfwl.dfc_dfr_crssw varnum; run; /*6524 obs*/
proc sort data=dfwl.dfc_dfr_crssw; by provusrd; run;
/*patient-level file*/
proc contents data= work3 varnum; run; 	/*1722545 obs*/
										/* at this point we have already 
										   included ONLY last observation for facility designation*/
proc sort data= work3; by provusrd; run;
/*MERGE***********************update 11/03/18 (JG) */
data dfwl.pat_facility_dfc2;
	merge	work3 (in=a) /*1,722,545 observations */
			dfwl.dfc_dfr_crssw ; /* 6524obs  these variables with patient-level file*/
	by provusrd;
if a; /*keeping ONLY observations within PATIENT-level file*/
run;		/*1722545 observations and 500 variables.*/
proc freq data=dfwl.pat_facility_dfc2; table race_new; run;


proc print data=dfwl.pat_facility_dfc2 (obs=100);
where provusrd ne .;
var usrds_id ccn chf bmi_35 stroke sex_new censordate;	/*from patient-level data*/
	/*provusrd pctrace_ethn_w pctpre_nephcare 		/*from aggregated USRDS data*/
	/*Facility_Name Five_Star Profit_or_Non_Profit	/*from DFC*/
	/*SW_N profit;	
/*from USRDS Facility SAF*/
where ccn ne .;
run;

data pat_facility_dfc_dfr;
	set dfwl.pat_facility_dfc2 ;
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

run;
proc freq data=pat_facility_dfc_dfr; table race_new; run;

/*1722545 observations and 502 variables*/
proc contents data=pat_facility_dfc_dfr2 varnum; run;

proc format;
value chain	1 = 'Fresnius'
			2 = 'Davita'
			3 = 'Small, for-profit'
			4 = 'Independent, for-profit'
			5 = 'Non-profit'
			. = 'Missing';
run;


data dfwl.pat_facility_dfc_dfr2;
set pat_facility_dfc_dfr;
where chain_class ne . ;
run;
/*1,478,564 observations*/
proc freq data=dfwl.pat_facility_dfc_dfr2;
table chain_class chain_class2 event race_new;
run;
