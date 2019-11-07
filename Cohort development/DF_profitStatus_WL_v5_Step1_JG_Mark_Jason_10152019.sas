/*Clean the patient files*/

libname usrds "C:\Users\zhangxyu\Desktop\JAMA_paper_revision";
libname usrds15 "C:\Users\zhangxyu\Desktop\JAMA_paper_revision";
libname dfwl "C:\Users\zhangxyu\Desktop\JAMA_paper_revision";

/* Format Library	*/
libname library 'C:\Users\zhangxyu\Desktop\JAMA_paper_revision';
options nofmterr;


/**laptop desktop***
added by JGander on 11/03/2018
to use Emory University Laptop and update data
	updated data is USRDS 2017 (has full year of 2016 data)
	updated data is Dialysis Facility Report 2018 (has 2013-2016 data)
*/
libname usrds "C:\Users\rpatzer\Desktop\USRDS data (2017 saf)\2017 Core\core";
libname dfwl "C:\Users\rpatzer\Desktop\ProfitStatus_WL";

libname jg "D:\"; /*JGander hardrive - - added 11/10/18*/
libname jgdfwl "D:\ProfitStatus_WL"; /*JGander hardrive's profit status Folder - - added 11/10/18*/
options nofmterr;


/*proc contents data=usrds.patients varnum; run;*/
/*run;*/


/*****The Following Exlcusion Criteria was applied to obtain the
Patient-Level USRDS data 2000-2016 (full years of data)
JGander updated with 2017 USRDS data
Revised by: JGander			Version: 11/03/2018			
	
JGander moved data to her KP computer and remapped librarys: ***********/

/*libname usrds "G:\Investigators\Gander\USRDS data (2016 SAF)\core";*/
/*libname dfwl "C:\Users\D990753\Desktop\JGander\Abstracts_Manuscripts_Publications\ProfitStatus_WL\code";*/

/********	*********	************	*************	*************	************	*********/

/****MZ began revising the cohort selection 05/01/2018**** JGander further revised 05/02/2018
JGander updated cohort with 2017 data - did not change code*/
/*proc contents data=dfwl.USRDS_Source2017 varnum; run;*/
/*3069627 obs*/
libname jama "e:\python projects\jama";

data work.one;
set jama.usrds_source2017;
month_entrydate=month(crdate);
year_entrydate=year(crdate);
if startdate < MDY(1,1,2000) then delete;	/*limiting data to January 1, 2000 and Dec 31, 2015 */
if startdate>mdy(12,31,2016) then delete;
run;
/* 1920583 observations and 246 variables*/
proc contents data=one varnum; run;


data work.two;
set one;
by usrds_id;
if first.usrds_id;
run;
/*1865462 observations and 246 variables*/

proc sql;
select count(*) from two where inc_age<18; 
quit;
proc sql;
select count(*) from two where inc_age>100; 
quit;

data work.three;
	set work.two;
		if inc_age < 18 then delete; *n=15559;
		if inc_age > 100 then delete; *n=67;
run;
/*  1849836 observations and 246 variables*/

/*deleted previous other organ transplants*/
data work.four;
	set work.three;
		if li_tx = 1 then delete; 
		if hr_tx = 1 then delete; 
		if in_tx = 1 then delete;	
		if pa_tx = 1 then delete;
		if pi_tx = 1 then delete;

run;
/* 1845064 observations and 246 variables.*/

data five;
set four;
		if bmi ge 0 and bmi < 18.5 then bmi_cat = 1;
			else if bmi	>= 18.5 and bmi < 25 then bmi_cat = 2;
				else if bmi >= 25 and bmi < 30 then bmi_cat = 3;
					else if bmi >= 30 then bmi_cat = 4;

		*Categorize Sex;  /*updated 10/10/17 (JG)*/
				 	 if sex='1' then sex_new=0; 	/*male*/
				else if sex='2' then sex_new=1; 	/*female*/
				else if sex='M' then sex_new=0; 	/*male*/
				else if sex='F' then sex_new=1; 	/*female*/
				else				 sex_new=.;

		*Categorize BMI into > 35; /*updated 10/10/17 (JG)*/
				if bmi ne . and bmi> 35 then bmi_35 = 1;
					else bmi_35 = 0;

		*Categorize Epo;
		if epo = 'Y' then epo_cat = 1;
			else epo_cat = 0;

		*Categorize albumin;
		if album ne . and album < 3.5 then album_low = 1;
			else album_low = 0;

		*Categorize hemoglobin;
		if heglb ne . and heglb < 11 then heglb_low = 1;
			else heglb_low = 0;


*Categorize insurance;
		if medicalcoverage = '1' then insurance_esrd = 1; *Medicaid;
		else if medicalcoverage = '2' then insurance_esrd=4;  *DVA = Other coverage;
		else if medicalcoverage='3' then insurance_esrd=2;  *Medicare;
		else if medicalcoverage='4' then insurance_esrd = 2;	*Med Advantage;
		else if medicalcoverage='5' then insurance_esrd=3;  *Employer ;
		else if medicalcoverage='6' then insurance_esrd=4; *Other = other;
		else if medicalcoverage='7' then insurance_esrd=5; *No insurance;
		else if medicalcoverage='1,2' then insurance_esrd=1; *Medicaid and DVA is Medicaid;
		else if medicalcoverage='1,3' then insurance_esrd=1; *Medicaid and Medicare is Medicaid;
		else if medicalcoverage='1,3,4' then insurance_esrd=1; *Medicaid, Medicare, Med Advantage = medicaid;
		else if medicalcoverage='1,3,5' then insurance_esrd=3; *Medicaid, Medicare, and Employer counts as employer;
		else if medicalcoverage='1,3,5,6' then insurance_esrd=3; *Medicaid, Medicare, Employer, and Other = employer;
		else if medicalcoverage='1,3,6' then insurance_esrd=1; *Medicaid, Medicare, and Other = Medicaid;
		else if medicalcoverage='1,4' then insurance_esrd=1; *Medicaid and Medicare Advantage = Medicaid;
		else if medicalcoverage='1,4,5' then insurance_esrd=3; *Medicaid, Medicare Advantage, and Employer = employer;
		else if medicalcoverage='1,5' then insurance_esrd=3; *Medicaid and Employer = employer;
		else if medicalcoverage='1,5,6' then insurance_esrd=3; *Medicaid, Employer, and Other = employer;
		else if medicalcoverage='1,6' then insurance_esrd=1; *Medicaid and Other = medicaid;
		else if medicalcoverage='2,5' then insurance_esrd=3; *DVA and Employer = employer;
		else if medicalcoverage='2,6' then insurance_esrd=4; *DVA and Other = other;
		else if medicalcoverage='3,4' then insurance_esrd=2; *Medicare and Medicare Advantage = medicare;
		else if medicalcoverage='3,5' then insurance_esrd=3; *Medicare and Employer = employer;
		else if medicalcoverage='3,5,6' then insurance_esrd=3; *Medicare, Employer, and Other' = employer;
		else if medicalcoverage='3,6' then insurance_esrd=2; *Medicare and Other = medicare;
		else if medicalcoverage='5,6' then insurance_esrd=3; *Employer and Other = employer;

		***For medical evidence 1995;
		if empgrp='Y' then insurance_esrd=3; *Employer ;
		if mdcd='Y' and empgrp='N' then insurance_esrd=1; *Medicaid = public;
		if mdcr='Y' and empgrp = 'N' then insurance_esrd=2; *Medicare = public;
		if dva='Y' and empgrp = 'N' then insurance_esrd=4; *DVA = other insurance;
		if othcov='Y' and empgrp = 'N' and mdcd='N' and mdcr='N' and dva='N' then insurance_esrd=4; *Other;
		if nocov='Y' and othcov='N' and empgrp='N' and mdcd='N' and mdcr='N' then insurance_esrd=5; *No insurance;
			else if mdcd='Y' and mdcr='Y' then insurance_esrd=1;	 *Medicaid;
			else if mdcd='Y' and othcov='Y' then insurance_esrd=1; *Medicaid;
			else if mdcd='Y' and empgrp='Y' then insurance_esrd=3; *Employer;
			else if mdcr='Y' and othcov='Y' then insurance_esrd=2; *Medicare;
			else if mdcr='Y' and empgrp='Y' then insurance_esrd=3; *Employer;

		if insurance_esrd = 5 then no_insurance = 1;
			else no_insurance = 0;
		
		**Define time (in days) spent on dialysis as 'ESRD_duration';
			ESRD_duration = min(tdate, dod, died, MDY(9,30,2011))-startdate;  *Censor at end of study;
			if ESRD_duration ne . and esrd_duration < 0 then esrd_duration = 0; *categorize preemptive as 0 time on dialysis;
			
		***Categorize ESRD_duration;
			if ESRD_duration <= 0 then dialysis_cat = 1;	*No dialysis;
				else if ESRD_duration >= 1 and ESRD_duration <=180 then dialysis_cat = 2;	**0-6 months;
						else if ESRD_duration >= 181 and ESRD_duration <365 then dialysis_cat = 3; *6mos-1 year;
							else if ESRD_duration >=365  then dialysis_cat = 4; *1 yr or more;

			if dialysis_cat = 4 then dialysis_1yr = 1;
				else dialysis_1yr = 0;

		if carfail='Y' or como_chf='Y' then chf = 1;
			else chf = 0;

		*Ischemic heart disease, cardiac arrest, and MI are all now
				categorized as atherosclerotic heart disease in 2005
				med evidence form;		
		if cararr = 'Y' or mi = 'Y' or ihd = 'Y' or como_ashd = 'Y' then 
			ashd_new = 1;
		else ashd_new = 0;	

		if como_copd = 'Y' or pulmon = 'Y' then copd_new = 1;
			else copd_new = 0;
	
		if pvasc = 'Y' or como_pvd = 'Y' then pvasc_new = 1;
			else pvasc_new = 0;

		if cva = 'Y' or COMO_CVATIA = 'Y' then cva_new = 1;
			else cva_new = 0;
		
		*Combine cardiac diseases (and other cardiac) to create an indicator variable of CVD;
		if chf = 1 or ashd_new = 1 or pvasc_new = 1 or cva_new = 1 or copd_new = 1 or COMO_OTHCARD='Y'
			then CVD = 1;
			else CVD = 0;

		if hyper = 'Y' or como_htn = 'Y' then hypertension = 1;
			else hypertension = 0;

		if diabins = 'Y' or diabprim = 'Y' or COMO_DM_INS = 'Y' or COMO_DM_NOMEDS = 'Y'
			or COMO_DM_ORAL = 'Y' or COMO_DM_RET = 'Y' then diabetes = 1;
			else diabetes = 0;
		
		if smoke = 'Y' or COMO_TOBAC = 'Y' then smoke_new = 1;
			else smoke_new = 0;
			if drug = 'Y' or como_drug = 'Y' then drug_new = 1;
				else drug_new = 0;

		if cancer = 'Y' or como_canc='Y' then cancer_new=1;
			else cancer_new=0;

			*Exclude patients from islands like PR, Guam, Samoan Islands;
	*Create 4 regions -  West, Midwest, South, East;
	if state='53' or state='41' or state='16' or state='30' or state='56' or state='05'
		or state='06' or state='32' or state='49' or state='08' or state='04'
		or state='35' or state='02' or state='15' then region=1; *West;
	else if state='38' or state='46' or state='31' or state='20' or state='27' 
		or state='19' or state='29' or state='55' or state='17' or state='26' 
		or state='18' or state='39' then region = 2; *Midwest;
	else if state='48' or state='40' or state='04' or state='22' or state='28'
		or state='01' or state = '47' or state='21' or state='37' or state='45' or state='13'
		or state='12' then region = 3; *South;
	else if state='09' or state='10' or state='11' or state='23' or state='24'
		or state='25' or state='33' or state='34' or state='36' or state='42' 
		or state='44' or state='50' or state='51' or state='54' then region = 4; *Remaining states are Eastern states;
	else region = .;
	if region = . then delete;
run;
/*1817130 observations and 288 variables*/
proc freq data=five;
table race sex_new;
run;
data six;
set five;

/*coding for 'race variable changed in the 2017 USRDS SAF* *** JGander updated code 11/3/18*/
	if race=1 and ethn=3 then race_new=1;*White Non Hispanic;
	if race=2 then race_new=2;*Black;
	if race=1 and ethn=1 then race_new=3; *White Hispanic;
	if race=1 and ethn=2 then race_new=3; *White Hispanic;
	if race=1 and ethn=5 then race_new=3; *White Hispanic;
	if race=11 then race_new=4;*Other - MidEast;
	if race=3 then race_new=4; *Other - American Indian/Alaskan Native;
	if race=4 then race_new=4;*Other - Asian;
	if race=41 then race_new=4;*Other - Indian SubCo;
	if race=5 then race_new=4; *Other - Pacific Islander;
	if race=6 then race_new=4;*Other - Other/Multi-racial;
	if race=9 then race_new=9;*Unknown				;

		*exclude patients whose race is unknown;
	if race_new = 9 or race_new=. then race_delete=1; /*n=1546*/  
	if sex_new = ' ' then sex_delete=1;  /*n=222*/
RUN;
proc freq; table race_delete sex_delete;
run;

data seven;
	set six;

if race_delete=1 then delete; /*1546 obs*/
if sex_delete=1 then delete; /*222 obs*/
run;
/* 1815362 observations and 291 variables*/


data pat_usrds;
	set seven;

/**CREATING  COUNTS for each variable for Faciliy Level Info**/
/*number of Observations (maybe 1 patient with multple obs)*/
patient_n=1;

		if inc_age >= 18 and inc_age < 30 then age_cat = 1;
			else if inc_age >= 30 and inc_age < 40 then age_cat = 2;
			else if inc_age >= 40 and inc_age < 50 then age_cat = 3;
			else if inc_age >= 50 and inc_age < 60 then age_cat = 4;
			else if inc_age >= 60 and inc_age < 70 then age_cat = 5;
			else if inc_age >= 70 then age_cat = 6;

/********************************************************************	
	/*COMORBIDITY COUNT - to get AVERAGE count of Comorbidity per facility*
	**********************Need to have variables that are coded 0,1
							to calculate the Comorbidity COunt****************/
/* comorbidity code (variable names) have changed for 2017 USRDS SAF * * JGander updted 11/3/18 */
		if carfail = 'Y' or como_chf = 'Y' then chf = 1;
		else chf = 0;
		/*indicator Variable*/	if chf = 1 then chf_y = 1;

		if como_ashd = 'Y' or como_ihd = 'Y' then ashd = 1; /*[como_ihd] revised in 2017*/
		else ashd = 0;	
		/*indicator Variable*/	if ashd = 1 then ashd_y = 1;

		if como_othcard = 'Y' or mi = 'Y' or dysrhyt = 'Y' or pericar = 'Y'
			then other_cardiac = 1;
		else other_cardiac = 0;
		/*indicator Variable*/	if other_cardiac = 1 then other_cardiac_y = 1;

		if como_cvatia = 'Y' or cva = 'Y' then stroke = 1;
			else stroke = 0;
		/*indicator Variable*/	if stroke = 1 then stroke_y = 1;

		if como_pvd = 'Y' or pvasc = 'Y' then pvd = 1;
			else pvd = 0;
		/*indicator Variable*/	if pvd = 1 then pvd_y = 1;

		if como_copd = 'Y' or pulmon = 'Y' then copd = 1;
			else copd = 0;
		/*indicator Variable*/	if copd = 1 then copd_y = 1;

		if hyper = 'Y' or como_htn = 'Y' then hypertension = 1;
			else hypertension = 0;
		/*indicator Variable*/	if hypertension = 1 then hypertension_y = 1;

		if diabins = 'Y' or COMO_DM_INS = 'Y' or COMO_DM_NOMEDS = 'Y'
			or COMO_DM_ORAL = 'Y' or COMO_DM_RET = 'Y' then diabetes = 1;
			else diabetes = 0;
		/*indicator Variable*/	if diabetes = 1 then diabetes_y = 1;
		
		if smoke = 'Y' or COMO_TOBAC = 'Y' then smoke_new = 1;
			else smoke_new = 0;
		/*indicator Variable*/	if smoke_new = 1 then smoke_new_y = 1;

		if drug = 'Y' or como_drug = 'Y' then drug_new = 1;
				else drug_new = 0;
		/*indicator Variable*/	if drug_new = 1 then drug_new_y = 1;

		if cancer = 'Y' or como_canc='Y' then cancer_new=1;
			else cancer_new=0;
		/*indicator Variable*/	if cancer_new = 1 then cancer_new_y = 1;

		
	/*COMORBIDITY COUNT - to get AVERAGE count of Comorbidity per facility*/
	  	comorbdity_cnt=chf+ashd+other_cardiac+stroke+pvd+copd+hypertension+diabetes+cancer_new;
/**********************************************************/

***Categorize Etiology of ESRD;
	 if disgrpc = 1 then esrd_cause = 1;	*Diabetes;
else if disgrpc = 2 then esrd_cause = 2; *HT;
else if disgrpc = 3 then esrd_cause = 3; *GN;
else					 esrd_cause = 4; *Other;


/*Was patient under care of a nephrologist? (y/n/Unk) [nephcare]*/
if nephcare = 1 then nephcare_cat = 1;		/*yes*/
else if nephcare = 2 then nephcare_cat = 2;	/*no*/
else nephcare_cat = 3; *missing - note we need to use multiple imputation for this;
		/*indicator Variable*/	if nephcare_cat = 1 then preesrdcare = 1;


/*PATIENT NOT INFORMED: because of Medical reasons * * coding as numeric*/
if PATTXOP_MEDUNFIT='Y' then 	PATTXOP_MEDUNFITn=1;
else  							PATTXOP_MEDUNFITn=0;

run;
/*1815362 observations and 316 variables*/


/*removing preemptively waitlisted and peemptively transplanted patients*/
data pat_usrds1;
	set pat_usrds;

if startdate ne . and edate ne .
	then do;
		if startdate>=edate then remove_wl=1;
		else					 remove_wl=0;
	end;

if startdate ne . and tx1date ne .
	then do;
		if startdate>=tx1date then remove_tx=1;
		else					 remove_tx=0;
	end;

run;
/*1815362  observations and 318 variables*/
proc freq data=pat_usrds1; 
table remove_wl remove_tx race_new;
run;


data jama.pat_usrds17;
	set pat_usrds1;
if remove_wl=1  then delete; /*84211 obs*/
if remove_tx=1 then delete; /*33848 obs*/

run;
/*  1723590  observations and 318 variables*/

proc contents data=jgdfwl.pat_usrds17 varnum; run;

/*data x;*/
/*set  dfwl.pat_usrds2;*/
/*keep usrds_id;*/
/*run;*/
/**/
/*proc sort nodupkey data=x;*/
/*by usrds_id;*/
/*run;*/
