libname dfwl "C:\Users\rpatzer\Desktop\ProfitStatus_WL";
libname jgdfwl "D:\ProfitStatus_WL";
libname jgmc "D:\ProfitStatus_WL\SAS_Code_dwnld from Box_11032018\mark_code\mark_11092018";
options nofmterr;
PROC IMPORT OUT= df_nearest_fixed 
            DATAFILE= "E:\python projects\jama\df_nearest_fixed.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
/*data jgmc.df_nearest_fixed;*/
/*	set df_nearest_fixed ;*/
/*run;*/
/*proc contents data=jgmc.df_nearest_fixed varnum; run;*/


/*	Facility-level **** 6524 observations **
	use [near_dist] as the 'distance to transplant center' */
/* [ccn] is the variable that will be used to LINK to full cohort*/

PROC IMPORT OUT= pat_rural_urban 
            DATAFILE= "E:\python projects\jama\pat_rural_urban.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
/*data jgmc.pat_rural_urban;*/
/*	set pat_rural_urban ;*/
/*run;*/
/*proc contents data=jgmc.pat_rural_urban varnum; run;*/
/*	Patient-level **** 1477742 observations **
	use [RUCC_2013] as the 'distance to transplant center' */
/* [usrds_id] is the variable that will be used to LINK to full cohort*/

/*full cohort to link these new variables to***/
proc sort data=jgdfwl.pat_facility_dfc17; by ccn; run;

/*merge with distance from facility to transplant center[near_dist] "df_nearest_fixed" */
proc sort data=jgmc.df_nearest_fixed; by ccn; run;
data pat_facility_dfc17_dist;
	merge	jama.pat_facility_dfc17 (in=a)
			df_nearest_fixed (keep=ccn near_dist);
	by ccn;
if a;
run;


/*merge with urban/rural variable [RUCC_2013] from "pat_rural_urban" */
proc sort data=pat_rural_urban; by usrds_id; run;
proc sort data=pat_facility_dfc17_dist; by usrds_id; run;
data jama.pat_facility_dfc17_dist2;
	merge	pat_facility_dfc17_dist (in=a)
			pat_rural_urban (keep=usrds_id RUCC_2013);
	by usrds_id;
if a;

if chain_organization = "FRESENIUS MEDICAL CARE" or
	chain_organization = "DAVITA"  	or Profit_or_Non_Profit='Profit'
											then for_profit=1;
else if Profit_or_Non_Profit='Non-Profit' 	then for_profit=0;

if nephcare_cat=1	then nephcare_cat2=1;
else if nephcare_cat=2	then nephcare_cat2=0;
else if nephcare_cat=3	then nephcare_cat2=.;


run;

proc contents data=jgdfwl.pat_facility_dfc17_dist varnum; run;
proc freq data=jgdfwl.pat_facility_dfc17_dist;
table rucc_2013 for_profit chain_class2*for_profit 	; run;

/*determing the numbr of patients that start dialysis each year by chain_class*/
proc freq data=jgdfwl.pat_facility_dfc17_dist;
table year_entrydate (for_profit chain_class2)*year_entrydate 	; run;

/*determing the numbr of patients that start dialysis each year by chain_class*/
proc freq data=jgdfwl.pat_facility_dfc17_dist;
where 2014<year_entrydate<2017;
table year_entrydate (for_profit chain_class2 wl livingd deceasedt)*year_entrydate 	
		for_profit*(wl livingd deceasedt);
run;

/*How many people got transplanted in 2015-2016***(JG added 2.22.19)***/
data tx;
	set jgdfwl.pat_facility_dfc17_dist;

/*YEAR = WL*/
year_wl=year(edate);
/*YEAR = living donor KTx*/
year_ldtx=year(ldtxdate);
/*YEAR = deceased donor KTx*/
if deceasedt=1 then year_ddtx=year(tx1date);
run;
proc freq data=tx;
table 	wl*year_wl
		livingd*year_ldtx
		deceasedt*year_ddtx;
run;



proc means data=jgdfwl.pat_facility_dfc17_dist;
class chain_class2;
var near_dist;
run;

proc freq data=jgdfwl.pat_facility_dfc17_dist;
table wl*(deceasedt livingd);
run;

/*counting how many dialysis facilities are in FINAL cohort
	11.17.18 (JG)*/
ods html close;
proc means data=jgdfwl.pat_facility_dfc17_dist;
class ccn;
var sex_new;
output out=count;

run;
data test;
	set	count;
if _stat_='N';
run;
ods html;

proc means nmiss data=jgdfwl.pat_facility_dfc17_dist;
var sex_new	age_cat	esrd_cause	race_new	insurance_esrd	
dialysis_mod1
bmi_35 	ashd_new	chf	other_cardiac	cva_new	pvasc_new	
hypertension	diabetes copd_new	smoke_new	cancer_new	
nephcare_cat2 PATTXOP_MEDUNFITn network_us_region_dfr
Mortality_Rate_Facility Hospitalization_Rate_facility 
socialwkr_dfr survtime 
near_dist rucc_2013
;
run;


