options nofmterr; 
libname core_cd 'e:/python projects/usrds';
libname library "\\nasn2ac.cc.emory.edu\surgery\SQOR\USRDS data (2017 saf)\2017 Core\core";

/**laptop desktop***
added by JGander on 11/03/2018
to use Emory University Laptop and update data
	updated data is USRDS 2017 (has full year of 2016 data)
	updated data is Dialysis Facility Report 2018 (has 2013-2016 data)
*/
libname core_cd 'C:\Users\rpatzer\Desktop\USRDS data (2017 saf)\2017 Core\core';
libname usrds "C:\Users\rpatzer\Desktop\USRDS data (2017 saf)\2017 Core\core";
libname dfwl "C:\Users\rpatzer\Desktop\ProfitStatus_WL";

***********************************************
Revision on 10/15/2019 by Zhensheng Wang to remove PROVUSRD from wlist file when merging with master file
CHANGES MADE
data work.ptwtlist
	merge work.ptmedevid (in=a) 
		  work.waitlist (in=b keep = keep = usrds_id abo adate age_listing cal_pra cpra ctr_ty dialysis
		donation edate hisp hr_tx inact_reason_cd inidiadt in_tx ki_tx li_tx lu_tx on_expand_donor 
		pa_tx pi_tx ppra prevtx /*provusrd*/ ra1 ra2 rb1 rb2 rdr1 rdr2 rdr51 rdr52 rdr53 remcode remdate tdate unossdt
		unosstat  wait_stat  rename=(tdate=tdatewtki))
	by usrds_id
	if a
run
************************************************;

*Main source population is the Patient File from USRDS;
data work.patients;
	set core_cd.patients;
run;
*3,081,768 observations;

*Sort by patient and date so we get the first patient form and first service date;

proc sort data=work.patients;
	by usrds_id first_se;
run;

proc sort data=work.patients ;
	by usrds_id ;
run;
*Note: there are no duplicates in the patient file;


**Merge medical evidence forms together to see if anyone has both forms;
data work.medevid;
	set core_cd.medevid;
	rename dialtyp=dialtyp_me;
run;


*Sort by id and dialysis start date, remove duplicates (that are later in time), and then merge;

proc sort data=work.medevid;
	by usrds_id dialdat;
run;

proc sort data=work.medevid;
	by usrds_id;
run;


proc sort data=work.medevid nodupkey;
	by usrds_id dialdat;
run;
* 2556 duplicate ids removed;

*Merge with Patient (source) file - but because we only want patients who have 
	a medical evidence form filled out, make the medevid combined the main source file here;

data work.ptmedevid;	
	merge work.medevid (in=a) work.patients (in=b);
		by usrds_id;
		if a;
run;
*3069627 obs      ;


***Now merge with waitlist file - not this is not the waitlist sequence file,
	so we are just getting information about the first (active or inactive) listing event
	rather than information about active or inactive time. Can always come back and add inactive
	time waiting to this;

data work.waitlist;
	set core_cd.waitlist_ki;
run;
*762,500 observations ;


*** Sort by USRDS patient id;
*** Merge by USRDS patient id;

*Just interested in first waitlisting event;
proc sort data=work.waitlist;
	by usrds_id edate;
run;

proc sort data=work.waitlist nodupkey;
	by usrds_id;
run;
* 197,504 waitlisting events deleted bc duplicates;
*total of 564,996 waitlisted patients;

proc sort data=work.ptmedevid;
	by usrds_id;
run;


data work.ptwtlist;
	merge work.ptmedevid (in=a) work.waitlist (in=b keep =  usrds_id abo adate age_listing cal_pra cpra ctr_ty dialysis
		donation edate hisp hr_tx inact_reason_cd inidiadt in_tx ki_tx li_tx lu_tx on_expand_donor 
		pa_tx pi_tx ppra prevtx /*provusrd*/ ra1 ra2 rb1 rb2 rdr1 rdr2 rdr51 rdr52 rdr53 remcode remdate tdate unossdt
		unosstat  wait_stat  rename=(tdate=tdatewtki));
	by usrds_id;
	if a;
run;
* Combined dataset;
*N= 3,069,627


**Update data with death file;
data work.death (keep=usrds_id cause_other causeprim causesec1 causesec2 causesec3 causesec4 
	dod kidneyfunc placedeath hospice modality_type);
	set core_cd.death;
run;
/* 2033508 observations*/

proc sort data=work.death ;
	by usrds_id;
run;

**Merge back with master dataset;
proc sort data=work.ptwtlist;
	by usrds_id;
run;

data work.ptwtmeddeath;
	merge work.ptwtlist (in=a) work.death (in=b);
		by usrds_id;
			if a;
run;
*N= 3,069,627;

**Merge with transplant file;

data work.transplant (keep= usrds_id dabo dage dabo dhisp donrel drace dsex dtype 
	faildate inccount provusrd rabo rage race rhisp tdate tottx rename=(race=rec_race provusrd=provusrd_tx));
	set core_cd.tx;
run;
*512,290 transplants;

proc contents data=work.transplant;
run;

*We are only interested in first transplants only;
proc sort data=work.transplant ;
	by usrds_id tdate;
run;

*We are only interested in first transplants only;
proc sort data=work.transplant nodupkey;
	by usrds_id ;
run;
* 64,252 duplicate observations deleted;
*N=448,038 total transplants;


proc sort data=work.ptwtmeddeath;
	by usrds_id;
run;

*Merge transplant file with patient master file;
*Create permanent merged source dataset;
data jama.USRDS_Source2017;
	merge work.ptwtmeddeath (in=a) work.transplant (in=b);
		by usrds_id;
		if a;

		startdate = MIN (FIRST_SE, DIALDAT, FACSTD);
		format startdate MMDDYY10.;
run;
* 3,069,627;

proc contents data=dfwl.USRDS_Source2017;
run;
proc freq data=dfwl.USRDS_Source2017;
table race;
run;
