libname jama 'E:\Python projects\JAMA';
options nofmterr;


data final(keep=PROVUSRD	dialysis_mod1	INC_AGE	sex_new	bmi_35	insurance_esrd	chf	ashd_new	copd_new	pvasc_new	
cva_new	hypertension	diabetes	smoke_new	cancer_new	race_new	age_cat	other_cardiac	esrd_cause	PATTXOP_MEDUNFITn	
Mortality_Rate_Facility	Hospitalization_Rate_facility	socialwkr_dfr	network_us_region_dfr smr_dfr pt_notinformed_MED_dfr
chain_class	chain_class2	patients_n_dfr socialwkr_dfr staff_dfr
NEAR_DIST	RUCC_2013	nephcare_cat2	for_profit wl wlist wl_time livingd ldtx ld_time deceasedt dec dec_time 
death_wl death_dec death_ld death_time  usrds_id sex_new	age_cat race_new profit_hosp profit_txc first_se);
  set jama.Pat_facility_dfc17_dist2;
  death_time = (died - first_se +1) / 30.4375;
death_wl = (min(died, edate, MDY(12,31,2016))=died); 
death_dec = (min(dectime, died, MDY(12,31,2016))=died); 
death_ld = (min(ldtxdate, died, MDY(12,31,2016))=died); 

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

data final;
  merge final(in=a) jama.Change_status1c(keep=usrds_id change_status switch_time);
  by usrds_id;
  if a;
run;


proc export data=two
outfile='E:\Python projects\JAMA\Fortable3mi_ld_dec_censored2.csv' dbms=csv replace;
run;
