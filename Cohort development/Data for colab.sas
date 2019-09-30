libname zwang 'E:\Python projects\JAMA';
options nofmterr;

data one/*(keep=PROVUSRD	dialysis_mod1	INC_AGE	sex_new	bmi_35	insurance_esrd	chf	ashd_new	copd_new	pvasc_new	
cva_new	hypertension	diabetes	smoke_new	cancer_new	race_new	age_cat	other_cardiac	esrd_cause	PATTXOP_MEDUNFITn	
Mortality_Rate_Facility	Hospitalization_Rate_facility	socialwkr_dfr	network_us_region_dfr	chain_class	chain_class2	
NEAR_DIST	RUCC_2013	nephcare_cat2	for_profit wl wlist wl_time livingd ldtx ld_time deceasedt dec dec_time 
death_wl death_dec death_ld death_time  usrds_id sex_new	age_cat race_new profit_hosp profit_txc first_se)*/;
set zwang.Pat_facility_dfc17_dist;
if edate ne '' then wl=1; else wl=0;
if ldtxdate ne '' then livingd=1; else livingd=0;
if wl=1 or livingd=1 then combine=1;  else combine=0;
if TX1DONOR='C' and TX1DATE ne . then deceasedt=1;else deceasedt=0;
if TX1DONOR='C' and TX1DATE ne . then dectime=TX1DATE;
wl_time=(min(edate,died,MDY(12,31,2016))-first_se+1)/30.4375;
wlist=(min(edate,died,MDY(12,31,2016))=edate); 

dec_time=(min(dectime,ldtxdate, died,MDY(12,31,2016))-first_se+1)/30.4375;
dec=(min(dectime,ldtxdate, died,MDY(12,31,2016))=dectime); 

ld_time=(min(dectime, ldtxdate,died,MDY(12,31,2016))-first_se+1)/30.4375;
ldtx=(min(dectime, ldtxdate,died,MDY(12,31,2016))=ldtxdate); 

death_time = (died - first_se +1) / 30.4375;
death_wl = (min(died, edate, MDY(12,31,2016))=died); 
death_dec = (min(dectime, died, MDY(12,31,2016))=died); 
death_ld = (min(ldtxdate, died, MDY(12,31,2016))=died); 
*if inc_age<66 and pvasc_new=0 and chf=0 and cva_new=0 and PATTXOP_MEDUNFITn=0;

/*for sensitivity analysis*/
if substr(PROVHCFA,3,2)='00' or  substr(PROVHCFA,3,2)='01' or  substr(PROVHCFA,3,2)='02' or
	 substr(PROVHCFA,3,2)='03' or  substr(PROVHCFA,3,2)='04' or  substr(PROVHCFA,3,2)='05' or
	  substr(PROVHCFA,3,2)='06' or  substr(PROVHCFA,3,2)='07' or  substr(PROVHCFA,3,2)='08' then df_hospit=1;
else 	df_hospit=0;

/*hospital-affiliation by profit status*/
	 if for_profit=0 and df_hospit=1 then profit_hosp=0; /*non-profit, hospital based*/
else if for_profit=0 and df_hospit=0 then profit_hosp=1; /*non-profit, not hospital based*/
else if for_profit=1 and df_hospit=1 then profit_hosp=2; /*for-profit,  hospital based*/
else if for_profit=1 and df_hospit=0 then profit_hosp=3; /*for-profit, not hospital based*/

/*transplant-affiliation by profit status*/
	 if for_profit=0 and txc=1 then profit_txc=0; /*non-profit, transplant center based*/
else if for_profit=0 and txc=0 then profit_txc=1; /*non-profit, not transplant centerd*/
else if for_profit=1 and txc=1 then profit_txc=2; /*for-profit,  transplant center*/
else if for_profit=1 and txc=0 then profit_txc=3; /*for-profit, not transplant center*/

run;

proc export data=one
outfile='E:\Python projects\JAMA\Fortable3mi_ld_dec_censored.csv' dbms=csv replace;
run;

%macro wl_2yr(b, e);
proc sql noprint;
  select sum(wl) into :count0
  from one
  where MDY(1,1,&b.)<=edate<=MDY(12,31,&e.) and MDY(1,1,&b.)<=first_se<=MDY(12,31,&e.) and for_profit=0;
  select sum((min(edate, died,MDY(12,31,&e.))-first_se+1)/365.25) into :py0
  from one
  where MDY(1,1,&b.)<=first_se<=MDY(12,31,&e.) and for_profit=0;
  select sum(wl) into :count1
  from one
  where MDY(1,1,&b.)<=edate<=MDY(12,31,&e.) and MDY(1,1,&b.)<=first_se<=MDY(12,31,&e.) and for_profit=1;
  select sum((min(edate, died,MDY(12,31,&e.))-first_se+1)/365.25) into :py1
  from one
  where MDY(1,1,&b.)<=first_se<=MDY(12,31,&e.) and for_profit=1;
quit;
%put %sysfunc(round(%sysevalf(&count0./&py0.*100), .01)), 
	 %sysfunc(round(%sysevalf(&count1./&py1.*100), .01));
%mend;

%wl_2yr(2001, 2002);
%wl_2yr(2003, 2004);
%wl_2yr(2005, 2006);
%wl_2yr(2007, 2008);
%wl_2yr(2009, 2010);
%wl_2yr(2011, 2012);
%wl_2yr(2013, 2014);
%wl_2yr(2015, 2016);
