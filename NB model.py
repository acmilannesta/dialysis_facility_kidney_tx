import pandas as pd, numpy as np, re
from numpy import exp, mean
from fancyimpute import IterativeImputer
from matplotlib import pyplot as plt
from sklearn.ensemble import RandomForestClassifier
from lifelines import CoxPHFitter, AalenJohansenFitter
from resample.bootstrap import bootstrap_ci, bootstrap

# whole cohort (N=1,478,506)
d = pd.read_csv('data//Fortable3mi_ld_dec_censored.csv')
d['rucc_rural'] = np.where(d.RUCC_2013.isin([1, 2, 3]), 0, (np.where(d.RUCC_2013.isna(), np.nan, 1)))
d.drop(['RUCC_2013'], axis=1, inplace=True)
d.loc[d['wl_time']>24, 'wl']=0
d.loc[d['wl_time']>24, 'wl_time']=24
d.loc[d['ld_time']>24, 'livingd']=0
d.loc[d['ld_time']>24, 'ld_time']=24
d.loc[d['dec_time']>24, 'deceasedt']=0
d.loc[d['dec_time']>24, 'dec_time']=24


# ideal cohort (N=454,726)
d = d[(d.INC_AGE < 66) &
      (d.pvasc_new == 0) &
      (d.chf == 0) &
      (d.cva_new == 0) &
      (d.PATTXOP_MEDUNFITn == 0)].reset_index(drop=True)

# WL only cohort (N=87,238)
d = d[d.wl == 1].reset_index(drop=True)


# Missing %
e = d[d.wl_time <= 24]
for col in d.columns.values:
    m = d[col].isna().sum()
    m_pct = m/len(d)*100
    if m_pct > 0:
        print('%s: %g, %.2f%%' %(col, m, m_pct))

# dialysis_mod1: 0.53
# insurance_esrd: 7.80
# Mortality_Rate_Facility: 1.30
# Hospitalization_Rate_facility: 1.09
# NEAR_DIST: 21.58
# nephcare_cat2: 36.99
# rucc_metro: 0.90


# Random forest imputation for categorical
for var in ['dialysis_mod1', 'insurance_esrd', 'rucc_rural', 'nephcare_cat2']:
    pred = ['sex_new', 'age_cat', 'race_new', var]
    imputer = IterativeImputer(n_iter=1, random_state=7, predictor=RandomForestClassifier(n_estimators=10))
    imputed = pd.DataFrame(imputer.fit_transform(d[pred]), columns=pred)
    d = d.drop(var, axis=1).join(imputed[var])

# Bayesian Ridge linear imputation for continuous
for var in ['Hospitalization_Rate_facility', 'Mortality_Rate_Facility', 'NEAR_DIST']:
    completed = []
    for i in range(5):
        pred = ['sex_new', 'age_cat', 'race_new', var]
        imputer = IterativeImputer(n_iter=5, sample_posterior=True, random_state=i)
        completed.append(imputer.fit_transform(d[pred]))
    completed_mean = np.mean(completed, axis=0)
    imputed = pd.DataFrame(completed_mean, columns=pred)
    if var == 'NEAR_DIST':
        m = imputed[imputed.NEAR_DIST > 0].NEAR_DIST.mean()
        imputed.NEAR_DIST = np.where(imputed.NEAR_DIST < 0, m, imputed.NEAR_DIST)
    d = d.drop(var, axis=1).join(imputed[var])

# d.to_csv('table3_imputed.csv', index=False)

##Cox model
PH_data = d[['PROVUSRD', 'chain_class2', 'for_profit', 'sex_new', 'age_cat', 'race_new', 'dialysis_mod1', 'esrd_cause', 'bmi_35',
                 'ashd_new', 'chf',	'other_cardiac', 'cva_new',	'pvasc_new', 'hypertension', 'diabetes', 'copd_new',
                 'smoke_new', 'cancer_new', 'insurance_esrd', 'PATTXOP_MEDUNFITn',
                 'network_us_region_dfr', 'NEAR_DIST', 'rucc_metro', 'wlist', 'wl_time', 'ldtx', 'ld_time', 'dec', 'dec_time']]
PH_data = PH_data.join(pd.get_dummies(PH_data.dialysis_mod1, prefix='dialysis_mod1', drop_first=True))
PH_data = PH_data.join(pd.get_dummies(PH_data.insurance_esrd, prefix='insurance_esrd', drop_first=True))
PH_data = PH_data.join(pd.get_dummies(pd.Categorical(PH_data.age_cat, [6, 1, 2, 3, 4, 5], True), prefix='age_cat', drop_first=True))
PH_data = PH_data.join(pd.get_dummies(pd.Categorical(PH_data.race_new, [4, 1, 2, 3], True),prefix='race_new', drop_first=True))
PH_data = PH_data.join(pd.get_dummies(PH_data.esrd_cause, prefix='esrd_cause', drop_first=True))
PH_data = PH_data.join(pd.get_dummies(PH_data.network_us_region_dfr, prefix='network_us_region_dfr', drop_first=True))
PH_data = PH_data.join(pd.get_dummies(pd.Categorical(PH_data.chain_class2, [6, 5, 2, 1, 3, 4], True), prefix='chain_class2', drop_first=True))
PH_data = PH_data.drop(['dialysis_mod1', 'esrd_cause', 'age_cat', 'race_new', 'chain_class2', 'insurance_esrd', 'network_us_region_dfr'], axis=1)

crude = 'profit|wlist|wl_time'
model1 = crude + '|sex_new|age_cat|race_new'
model2 = model1 + '|dialysis_mod1|esrd_cause|bmi_35|ashd_new|other_cardiac|hypertension|diabetes|'\
                  'copd_new|smoke_new|cancer_new|chf|cva_new|pvasc_new' #chf|cva_new|pvasc_new'
model3 = model2 + '|insurance_esrd|network_us_region_dfr|NEAR_DIST|rucc_metro|PATTXOP_MEDUNFITn' #PATTXOP_MEDUNFITn'

cph = CoxPHFitter()
cph.fit(PH_data.filter(regex=model3), duration_col='wl_time', event_col='wlist', step_size=0.5)
exp(cph.hazards_).T.join(exp(cph.confidence_intervals_).T).round(2)
d[d.dec_time <= 24].groupby('for_profit')['dec'].sum()
d[d.dec_time <= 24].groupby('for_profit')['dec_time'].sum()/12

# CIF curve
time = 'wl_time'        # options: 'ld_time', 'dec_time', 'wl_time'
status1 = 'wlist'        # options: 'ldtx', 'dec', 'wlist'
status2 = 'death_wl'    # options: 'death_ld', 'death_dec', 'death_wl'
wl_rows = ['WL_profit', 'Death_profit', 'WL_nonprofit', 'Death_nonprofit']
dec_rows = ['DDKT_profit', 'Death_profit', 'DDKT_nonprofit', 'Death_nonprofit']
ld_rows = ['LDKT_profit', 'Death_profit', 'LDKT_nonprofit', 'Death_nonprofit']
rows = wl_rows
title = 'Cumulative incidence of waitlisting \n by facility profit status'
output = 'output\\cif_wl.png'

cif = pd.read_csv('Data\\Fortable3mi_ld_dec_censored.csv')
cif.loc[cif['death_wl'] == 1, 'wlist'] = 2
cif.loc[cif['death_dec'] == 1, 'dec'] = 2
cif.loc[cif['death_ld'] == 1, 'ldtx'] = 2
cif_p = cif[cif.for_profit == 1]
cif_np = cif[cif.for_profit == 0]

ajf1 = AalenJohansenFitter(calculate_variance=False)
ajf1.fit(cif_p[time]/12, cif_p[status1], 1)
ajf2 = AalenJohansenFitter(calculate_variance=False)
ajf2.fit(cif_np[time]/12, cif_np[status1], 1)
ajf3 = AalenJohansenFitter(calculate_variance=False)
ajf3.fit(cif_p[time]/12, cif_p[status2], 1)
ajf4 = AalenJohansenFitter(calculate_variance=False)
ajf4.fit(cif_np[time]/12, cif_np[status2], 1)
status1_p = [float(ajf1.cumulative_density_.loc[slice(2*i)].tail(1).values.round(3)) for i in range(0, 6)]
status1_np = [float(ajf2.cumulative_density_.loc[slice(2*i)].tail(1).values.round(3)) for i in range(0, 6)]
status2_p = [float(ajf3.cumulative_density_.loc[slice(2*i)].tail(1).values.round(3)) for i in range(0, 6)]
status2_np = [float(ajf4.cumulative_density_.loc[slice(2*i)].tail(1).values.round(3)) for i in range(0, 6)]

fig, ax = plt.subplots()
ax.plot(ajf1.cumulative_density_.loc[slice(0, 10)], label='profit', linestyle='--')
ax.plot(ajf2.cumulative_density_.loc[slice(0, 10)], label='non-profit',  linestyle=':')
ax.set_xlabel('Years')
ax.set_ylabel('Cumulative incidence')
ax.set_title(title)
plt.legend()
table = plt.table(cellText=np.array([status1_p, status2_p, status1_np, status2_np]), rowLabels=rows, bbox=[-0.05, -0.35, 1.1, 0.2], cellLoc='center')
for key, cell in table.get_celld().items():
    cell.set_linewidth(0)
plt.tight_layout()
plt.savefig(output)
# plt.cla()
plt.close()


# Poisson model
work = d[['chain_class2', 'sex_new', 'age_cat', 'race_new', 'wlist', 'wl_time', 'ld_time', 'dec_time', 'ldtx', 'dec']]
groupby_var = ['chain_class2', 'sex_new', 'age_cat', 'race_new']
groupby_sum = ['wl', 'wl_time', 'ld_time', 'dec_time', 'livingd', 'deceasedt']
a = work.groupby(groupby_var, as_index=False)[groupby_sum].sum()
a['wl_time'] = np.log(a['wl_time']/12)
a['dec_time'] = np.log(a['dec_time']/12)
a['ld_time'] = np.log(a['ld_time']/12)
a = a.join(pd.get_dummies(pd.Categorical(a['chain_class2'], ordered=True, categories=[5, 1, 2, 3, 4, 6]), drop_first=True, prefix='chain_class2'))
a = a.join(pd.get_dummies(pd.Categorical(a['age_cat'], ordered=True, categories=[6, 1, 2, 3, 4, 5]), drop_first=True, prefix='age_cat'))
a = a.join(pd.get_dummies(pd.Categorical(a['race_new'], ordered=True, categories=[4, 1, 2, 3]), drop_first=True, prefix='race_new'))
a = a.join(pd.get_dummies(pd.Categorical(a['sex_new']), drop_first=True, prefix='sex_new'))
a = a.drop(['chain_class2', 'age_cat', 'race_new', 'sex_new'], axis=1)

b = a.filter(regex='dec|chain|age|race|sex').values
b.T[[0, 1]] = b.T[[1, 0]]
for i in range(1, 6):
    def btf(data, idx=i):
        nb_model = sm.GLM(data[:, 0],
                          sm.tools.tools.add_constant(data[:, 2:]).astype(float),
                          family=sm.families.Poisson(),
                          offset=data[:, 1]).fit(method='newton')
        effect = exp(nb_model.params[0]+nb_model.params[idx])-exp(nb_model.params[0])
        return effect*100

    boot_effect = mean(bootstrap(a=b, f=btf, b=500))
    boot_ci = bootstrap_ci(a=b, f=btf, b=500, ci_method='bca')
    colname = a.filter(regex='chain').columns
    print('%s: %.3f, 95%%CI: (%.3f, %.3f)' %(colname[i-1], boot_effect, boot_ci[0], boot_ci[1]))

# deltamethod
import os
os.environ['R_HOME'] = 'E:\\R-3.5.2'
os.environ['R_USER'] = 'E:\\Python 3.6\\Lib\\site-packages\\rpy2'
import rpy2.robjects as ro
from rpy2.robjects.packages import importr
from rpy2.robjects.vectors import FloatVector
import statsmodels.formula.api as smf
import statsmodels.api as sm
import rpy2.robjects.numpy2ri
rpy2.robjects.numpy2ri.activate()
#
#


def truncate(t):
    e = d.copy()
    e.loc[e['wl_time'] > t, 'wl']=0
    e.loc[e['wl_time'] > t, 'wl_time']=t
    e.loc[e['ld_time'] > t, 'livingd']=0
    e.loc[e['ld_time'] > t, 'ld_time']=t
    e.loc[e['dec_time'] > t, 'deceasedt']=0
    e.loc[e['dec_time'] > t, 'dec_time']=t
    return e
msm = importr('msm')


poissonset = truncate(36).groupby(['for_profit', 'age_cat', 'sex_new', 'race_new'], as_index=False)[['wl', 'wl_time', 'livingd', 'ld_time', 'dec_time', 'deceasedt']].sum()
# poissonset['chain_class2'] = pd.Categorical(poissonset['chain_class2'], ordered=True, categories=[6, 5, 2, 1, 3, 4])
poissonset['age_cat'] = pd.Categorical(poissonset['age_cat'], ordered=True, categories=[5, 1, 2, 3, 4, 6])
poissonset['race_new'] = pd.Categorical(poissonset['race_new'], ordered=True, categories=[1, 2, 3, 4])
poisson_model = smf.glm('deceasedt~for_profit+sex_new+age_cat+race_new',
                        data=poissonset,
                        family=sm.families.Poisson(),
                        offset=np.log(poissonset['dec_time']/12)).fit(method='newton')
poisson_model.summary()
# chain class 2
for i in range(1, 6):
    b0 = poisson_model.params['Intercept']
    b1 = poisson_model.params['chain_class2[T.'+str(i)+']']
    effect = np.exp(b0 + b1) - np.exp(b0)
    vcov = poisson_model.cov_params().loc[['Intercept', 'chain_class2[T.'+str(i)+']'], ['Intercept', 'chain_class2[T.'+str(i)+']']]
    se = msm.deltamethod(ro.Formula('~exp(x1+x2)-exp(x1)'), FloatVector([b0, b1]), ro.r.matrix(vcov.values, nrow=2, ncol=2))
    print("chain_%g: %.2f (%.2f, %.2f) " %(i, effect*100, (effect-1.96*float(np.array(se)))*100, (effect+1.96*float(np.array(se)))*100))
# for profit
b0 = poisson_model.params['Intercept']
b1 = poisson_model.params['for_profit']
effect = np.exp(b0 + b1) - np.exp(b0)
vcov = poisson_model.cov_params().loc[['Intercept', 'for_profit'], ['Intercept', 'for_profit']]
se = msm.deltamethod(ro.Formula('~exp(x1+x2)-exp(x1)'), FloatVector([b0, b1]), ro.r.matrix(vcov.values, nrow=2, ncol=2))
print("for_profit vs. non_profit: %.2f (%.2f, %.2f) " %(effect*100, (effect-1.96*float(np.array(se)))*100, (effect+1.96*float(np.array(se)))*100))

a = poissonset.groupby('chain_class2')[['wl', 'wl_time']].sum()
a['wl'].map('{:,.0f}/'.format)+(a['wl_time']/12).map('{:,.0f}'.format)

b = poissonset.groupby('chain_class2')[['livingd', 'ld_time']].sum()
b['livingd'].map('{:,.0f}/'.format)+(b['ld_time']/12).map('{:,.0f}'.format)

c = poissonset.groupby('chain_class2')[['deceasedt', 'dec_time']].sum()
c['deceasedt'].map('{:,.0f}/'.format)+(c['dec_time']/12).map('{:,.0f}'.format)

# rate for reference
pd.concat([(np.exp(poisson_model.params)*100).map('{:.2f}'.format), (np.exp(poisson_model.conf_int())*100).applymap('{:.2f}'.format)], 1)