/**********************************************************************
/**	AGGREGATING PATIENT-LEVEL DATA  TO DIALYSIS FACILITY LEVEL DATA
	USRDS 2000-2010		

SAS COde file "DF_profitStatus_WL_KHR_v2" can be found 
								that created SAS dataset 'dfwl.usrdsfac0015rev_dfc'


**JGander removed this code 10/16/2017 because 
	we can obtain these variables from DFR ***	
/***************************************************************************************************/

/**laptop desktop***
added by JGander on 11/03/2018
to use Emory University Laptop and update data
	updated data is USRDS 2017 (has full year of 2016 data)
	updated data is Dialysis Facility Report 2018 (has 2013-2016 data)
*/
libname usrds "C:\Users\rpatzer\Desktop\USRDS data (2017 saf)\2017 Core\core";
libname dfwl "C:\Users\rpatzer\Desktop\ProfitStatus_WL";
/**Dialysis Facility Compare (DFC) code was NOT updated because DFC data already went through 2016

/*********MERGING DIALYSIS FACILITY COMPARE 
  _____  ____________
 |  __ \|  ____/ ____|   downladed from Dialysis Facility Compare (DFC)          
 | |  | | |__ | |        data: "dfwl.dfc2016"		n=6957          
 | |  | |  __|| |     STEPS:	1. Bring in Dialysis Facility Compare           
 | |__| | |   | |____         		Sort by CCN
 |_____/|_|    \_____| 			2. Bring in DIalysis Facility Report
									Sort by CCN
								3. 	Merge DFC and DFC by CCN
								4. Merge CROSSWALK file to get 'PROVUSRD' 
									to enable merge with patient-level USRDS
	
(JG revised 10/17/17 and removed USRDS-Facility-elvel data) 			********/

/* STEP 1
/*Dialysis Facility Compare (DFC) 2016*/
PROC IMPORT OUT= dfc2016 
            DATAFILE= "C:\Users\rpatzer\Desktop\ProfitStatus_WL\DFC_dwnld03152017_clean.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
proc contents data=dfc2016 varnum; run;
/*20250 observations*/
data dfwl.dfc2016;
	set dfc2016;
if facility_name = ' ' then delete; /*data cleaning*/

ccn_n=ccn*1; /*converting CCN to NUMERIC*/
drop ccn;
if ccn_n=. then delete; /*deleting 2 VA dialysis facilities in Detroit and Pittsburth*/

dfc=1; /*creating indicator variable to determine if data was merged 
		from DFC 2016*/

run; /*6748 observations*/

proc contents data=dfwl.dfc2016 varnum; run;  	/*6748 observations*/                             
proc sort data=dfwl.dfc2016 ; by ccn_n; run;

/*STEP 2
/* .--------------.  .----------------.  .----------------. Updated by JG 11/03/17
| .--------------. || .--------------. || .--------------. |
| |  ________    | || |  _________   | || |  _______     | |
| | |_   ___ `.  | || | |_   ___  |  | || | |_   __ \    | | Dialysis
| |   | |   `. \ | || |   | |_  \_|  | || |   | |__) |   | | Facility
| |   | |    | | | || |   |  _|      | || |   |  __ /    | | Report
| |  _| |___.' / | || |  _| |_       | || |  _| |  \ \_  | |
| | |________.'  | || | |_____|      | || | |____| |___| | | 2018
| |              | || |              | || |              | | (contains 2013-2016 data)
| '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------' 
For Additional Facility-level characteristics....
	Merge the created facility-level data set with the 2016 DFR	**/
libname dfr18 "C:\Users\rpatzer\Desktop\DFR 2018_data2013-16";
/*Dialysis Facility Report data has been cleaned with 
	SAS Code "DFR_DATA16" saved:[\\nasn2ac.cc.emory.edu\surgery\SQOR\DialysisFacilityReportData\DFR 2016_data2012-15]
*/
proc contents data=dfr18.demo_dfr1316 varnum; run;
/*6574 observations*/

data demo_dfr1316
		(RENAME=  
			(	state2=	state2_dfr
				smr=	smr_dfr
				pats=	pats_dfr
				profit=	profit_dfr
				totstats=	totstats_dfr
				black=	black_dfr
				white=	white_dfr
				asian=	asian_dfr
				nat_am=	nat_am_dfr
				hispanic=	hispanic_dfr
				age=	age_dfr
				no_nephcare=	no_nephcare_dfr
				cva=	cva_dfr
				diabetes=	diabetes_dfr
				vintage=	vintage_dfr
				waitlist=	waitlist_dfr
				waitlistAA=	waitlistAA_dfr
				waitlistNHW=	waitlistNHW_dfr
				waitlist_disp=	waitlist_disp_dfr
				wl_dispRatio=	wl_dispRatio_dfr
				waitlistfeml=	waitlistfeml_dfr
				waitlistmale=	waitlistmale_dfr
				waitlist_Gdisp=	waitlist_Gdisp_dfr
				wl_GdispRatio=	wl_GdispRatio_dfr
				pt_INFORMED=	pt_INFORMED_dfr
				pt_notinformed=	pt_notinformed_dfr
				pt_notinformed_MED=	pt_notinformed_MED_dfr
				pt_notinformed_AGE=	pt_notinformed_AGE_dfr
				pt_notinformed_PSYCH=	pt_notinformed_PSYCH_dfr
				pt_notinformed_DECLN=	pt_notinformed_DECLN_dfr
				pt_notinformed_NOASSESS=	pt_notinformed_NOASSESS_dfr
				insurance_emp=	insurance_emp_dfr
				insurance_mdcd=	insurance_mdcd_dfr
				insurance_none=	insurance_none_dfr
				employed=	employed_dfr
				unemployed=	unemployed_dfr
				HD=	HD_dfr
				PD=	PD_dfr
				fistula=	fistula_dfr
				graft=	graft_dfr
				catheter=	catheter_dfr
				avf=	avf_dfr
				hemoglobin=	hemoglobin_dfr
				albumin=	albumin_dfr
				creatinine=	creatinine_dfr
				esa=	esa_dfr
				HT=	HT_dfr
				smoker=	smoker_dfr
				cancer=	cancer_dfr
				alcohol=	alcohol_dfr
				drugs=	drugs_dfr
				ambulatory=	ambulatory_dfr
				comorbid=	comorbid_dfr
				readm_rate=	readm_rate_dfr
				obrery4_f=	obrery4_f_dfr
				obrery3_f=	obrery3_f_dfr
				obrery2_f=	obrery2_f_dfr
				obrery1_f=	obrery1_f_dfr
				shred=	shred_dfr
				staff=	staff_dfr
				socialwkr= socialwkr_dfr
				patients_n=	patients_n_dfr
				females=	females_dfr
				age_n=	age_n_dfr
				black_n=	black_n_dfr
				prevhd_n=	prevhd_n_dfr
				phdy4_n=	phdy4_n_dfr
				insurance_none_n=insurance_none_n_dfr ) );
		set dfr18.demo_dfr1316
			(KEEP=
				prov
				ccn1
				ccn
				state2
				smr
				pats
				profit
				totstats
				black
				white
				asian
				nat_am
				hispanic
				age
				no_nephcare
				cva
				diabetes
				vintage
				waitlist
				waitlistAA
				waitlistNHW
				waitlist_disp
				wl_dispRatio
				waitlistfeml
				waitlistmale
				waitlist_Gdisp
				wl_GdispRatio
				pt_INFORMED
				pt_notinformed
				pt_notinformed_MED
				pt_notinformed_AGE
				pt_notinformed_PSYCH
				pt_notinformed_DECLN
				pt_notinformed_NOASSESS
				insurance_emp
				insurance_mdcd
				insurance_none
				employed
				unemployed
				HD
				PD
				fistula
				graft
				catheter
				avf
				hemoglobin
				albumin
				creatinine
				esa
				HT
				smoker
				cancer
				alcohol
				drugs
				ambulatory
				comorbid
				readm_rate
				obrery4_f
				obrery3_f
				obrery2_f
				obrery1_f
				shred
				staff
				socialwkr
				patients_n
				females
				age_n
				black_n
				prevhd_n
				phdy4_n
				insurance_none_n 	);

		

run;
proc contents data=demo_dfr1316 varnum; run;
/* 6574 observations and 71 variables*/

proc sort data=demo_dfr1316; 
by ccn; /*CMS Certification Number...Facility ID*/
run;

/* STEP 3
MERGE DIALYSIS FACIITY COMPARE AND DIALYSIS FACILITY REPORT*/
proc contents data=dfwl.dfc2016 varnum; run; /*6748 obs*/
proc sort data=dfwl.dfc2016 ; by ccn_n; run;
proc sort data=demo_dfr1316; 
by ccn; /*CMS Certification Number...Facility ID*/
run;

data dfwl.dfc_dfr;
	merge	dfwl.dfc2016 (in=a rename =(ccn_n=ccn state=state_facility)) /*6748 observations*/
			demo_dfr1316 (in=b);					/*6574 observations*/
	by ccn;
	if a and b;


*Classifying chains;/***revised used DFC2016 variables exclusively (JGander -06/01/17)*/
	if chain_organization = "FRESENIUS MEDICAL CARE" then chain_class = 1; *Fresenius;
	else if chain_organization = "DAVITA" then chain_class = 2; *Davita;
	else if chain_owned = "TRUE" and Profit_or_Non_Profit = "Profit" then chain_class = 3; *Small, for-profit chains;
	else if chain_owned = "FALSE" and Profit_or_Non_Profit = "Profit" then chain_class = 4; *Independent for-profit;
	else if Profit_or_Non_Profit = "Non-Profit"  then chain_class = 5; *Non-profit;
	else chain_class = .;

/*JGander coding non-profit facilities 'Indep non-profit' vs 'chain owned-non-profit' per JAMA reviewers (11/3/18)*/
	if chain_organization = "FRESENIUS MEDICAL CARE" then chain_class2 = 1; *Fresenius;
	else if chain_organization = "DAVITA" then chain_class2 = 2; *Davita;
	else if chain_owned = "TRUE" and Profit_or_Non_Profit = "Profit" then chain_class2 = 3; *Small, for-profit chains;
	else if chain_owned = "FALSE" and Profit_or_Non_Profit = "Profit" then chain_class2 = 4; *Independent for-profit;
	else if chain_owned = "FALSE" and Profit_or_Non_Profit = "Non-Profit"  then chain_class2 = 5; *Independent Non-profit ;
	else if chain_owned = "TRUE" and Profit_or_Non_Profit = "Non-Profit"  then chain_class2 = 6; *chain owned Non-profit;
	else chain_class2 = .;


/***JGander coding for Classifying Chain Organization, profit vs non-profit*/
	if Chain_Owned='TRUE' then do; 
		/*Top 2 Chain-Owned Dialysis Facilities Listed...then Chain=3 is 'other'
			DaVita=34.05% of facilities and Fresenius=31.49%	...TOTAL 65.54%	*/
		 	 if Chain_Organization='DAVITA' 				then chain=1;	/*DaVita Dialysis*/
		else if Chain_Organization='FRESENIUS MEDICAL CARE' then chain=2;	/*Fresenius*/
		else													 chain=3;	/*all other CHAIN-Owned facilities*/
end;
if Chain_Owned='FALSE' and Chain_Organization='INDEPENDENT' then chain=0;

/*creating DaVita Indicator variable*/
	 if chain ne . and chain=1 		then DaVita=1;
else if chain ne . and chain ne 1	then DaVita=0;

/*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*/
run;
/**** 6524 observations**/
proc contents data=dfwl.dfc_dfr varnum; run;

proc freq data=dfwl.dfc_dfr;
table chain_organization chain_class chain_class2;
run;
/** CHAIN_ORGANIZATION - Davita and Fresenius have 2,000+ facilities
						'Independent chains' have ~700
						Make CUT-Point for 'chain_class' organization 1,000 facilities  ****/
proc means data=dfwl.dfc_dfr n min max mean std median q1 q3;
var socialwkr_dfr patients_n_dfr;
run;



/*STEP 4: 	Crosswalk to get [PROVUSRD]--> 6-digit [provhcfa]*/
/*JGander updated (11/3/18) using updated crosswalk from USRDS 2018 files*/
libname crsswlk "C:\Users\rpatzer\Desktop\USRDS data (2017 saf)\Crosswalk\crosswalk";
proc contents data=crsswlk.xref_prv_2017 varnum; run;

proc print data=crsswlk.xref_prv_2017 (obs=300);
var PROVUSRD PROVHCFA;
run;
data xref_prv_2017;
	set crsswlk.xref_prv_2017;  /**Contains the HCFA variabl and PROVUSRD variable*/

PROVHCFA_n=PROVHCFA*1; /*converting HCFA to NUMERIC*/
					   /*this coded the VA faciities where PROVHCFA=".....F" as missing
							which is fine because VA dialysis facilities are entirely diff
							than other dialysis facilities **/
run;
/*74601 observations*/

proc contents data=xref_prv_2017 varnum; run;/*CROSSWALK file between PROVUSRD and HCFA (6-digit facility ID (aka: CCN)) */
proc sort data=xref_prv_2017 FORCE; 	by PROVHCFA_n; run; /*70,471 observations*/
proc print data=xref_prv_2017 (obs=300);
where PROVHCFA_n ne . ;
var PROVUSRD PROVHCFA_n;
run;
/*Facility-Level dataset + (PROVUSRD and PROVHCFA) Crosswalk*/
proc contents data=dfwl.dfc_dfr varnum; run; /*n=6524*/ 
proc sort data=dfwl.dfc_dfr; by ccn; run;

data dfwl.dfc_dfr_crssw;
	merge	xref_prv_2017 		(in=a rename=(PROVHCFA_n=ccn))		/*70471 observations*/
			dfwl.dfc_dfr	(in=b);	/*6524 observations*/
	by ccn;
	if a and b; /*crosswalk will only contain dialysis facilities in BOTH
					DFC, DFR, and Crosswalk**/

if socialwkr_dfr ne 0 then do;
	social_patnt_ratio=socialwkr_dfr/patients_n_dfr; /*creating a Ratio of Patient-to-Social Workers  (JG created 10/26/17)*/
end;

run;
/*6524 observations and 178 variables*/
proc print data=dfwl.dfc_dfr_crssw  (obs=200);
var provhcfa provusrd ccn ;
run;
proc means data=dfwl.dfc_dfr_crssw n min max mean std median q1 q3;
var socialwkr_dfr patients_n_dfr social_patnt_ratio;
run;
proc print; var PROVHCFA ccn provusrd;
run;
/*6524 observations*/

proc contents data=dfwl.dfc_dfr_crssw varnum;
run;	/*6524 observations/facilities*/

proc means data=dfwl.dfc_dfr_crssw  n min max mean median q1 q3;
class chain_class;
var pt_notinformed_dfr pt_notinformed_MED_dfr;
run;
