### prepare data for match run analysis ###

# From Daniel:
# For the match run analysis I basically only need a three column dataset (PX_ID, date, accompanying USCRS 2.0 score) that I will just left merge to the PTR data.

## Dataset to include the following:
# All rows for all PX_IDs by week from study start through Dec 2024
# (No rows after removal or duplicate rows for landmark modeling)

## For USCRS 2.0 score, need to include:
# Log first-week hazard = linear predictor without week adjustment

## Notes:
# Could have some misclassification re: actual values on match run due to possibility of covariates changing midweek
# Will probably have to do an inner join, not left join to PTR

# bring in mortality models
## from mortality_model_data.Rmd
load("mortality-model-options.Rdata")

# bring in discrete-time data before training/valid/test split
## from mortality_model_data.Rmd
load("discrete_data_preSplit.Rdata") # df_final

# # load the function to calculate predicted 1-week hazard from a binomial glm and also calculate 6-week predicted survival
# ## from mortality_model_data.Rmd
# load("mort-pred-fun.Rdata")

# reduce dataset to pre-Dec 2024
summary(df_final$current_date)
mrdat = df_final %>% filter(current_date < ymd("2025-01-01"))
summary(mrdat$current_date)

# rename variables for prediction
mrdat = mrdat %>% mutate(
  bilirubin_at_start = bilirubin,
  albumin_at_start = albumin,
  eGFR_at_start = eGFR,
  BNP_NT_Pro_at_start = ifelse(BNP_NT_Pro == 1, as.character(1), as.character(0)),
  BNP_at_start = BNP,
  sodium_at_start = sodium,
  durable_LVAD_at_start = durable_LVAD,
  short_mcs_ever_at_start = short_MCS_ever,
  cpo_at_start = cpo,
  api_at_start = api,
  papi_at_start = papi,
  lvad_years_at_start = lvad_years,
  impella_at_start = impella,
  iabp_at_start = iabp,
  iabp_ever_at_start = iabp_ever,
  impella_ever_at_start = impella_ever,
  diagnosis_at_start = diagnosis
)

# trim extreme values for prediction
# truncate at cutoffs from modeling data
trim=read.csv("trim_values.csv") %>%
  mutate(var=paste0(var,"_at_start"))
mrdat = mrdat %>%
  mutate(across(c(albumin_at_start,bilirubin_at_start,eGFR_at_start,sodium_at_start,cpo_at_start,api_at_start,papi_at_start), ~ {
    var <- cur_column()
    min_val <- trim$min[trim$var == var]
    max_val <- trim$max[trim$var == var]
    pmin(pmax(., min_val), max_val)
  })) %>%
  mutate(lvad_years_at_start = ifelse(lvad_years_at_start>10,10,lvad_years_at_start)) %>%
  mutate(BNP_at_start = case_when(
    BNP_NT_Pro_at_start==0 & BNP_at_start<trim$min[trim$var=="BNP_at_start" & trim$BNP_NT_Pro_at_start==0] ~ trim$min[trim$var=="BNP_at_start" & trim$BNP_NT_Pro_at_start==0],
    BNP_NT_Pro_at_start==0 & BNP_at_start>trim$max[trim$var=="BNP_at_start" & trim$BNP_NT_Pro_at_start==0] ~ trim$max[trim$var=="BNP_at_start" & trim$BNP_NT_Pro_at_start==0],
    BNP_NT_Pro_at_start==1 & BNP_at_start<trim$min[trim$var=="BNP_at_start" & trim$BNP_NT_Pro_at_start==1] ~ trim$min[trim$var=="BNP_at_start" & trim$BNP_NT_Pro_at_start==1],
    BNP_NT_Pro_at_start==1 & BNP_at_start>trim$max[trim$var=="BNP_at_start" & trim$BNP_NT_Pro_at_start==1] ~ trim$max[trim$var=="BNP_at_start" & trim$BNP_NT_Pro_at_start==1],
    T ~ BNP_at_start)
  )

# code up a new pred_data_fun - no need for full survival probabilities, just first-week hazard
pred_data_fun1 = function(newdata,mod,lasso=F) {
  # trim LVAD years to 10
  pred_data = newdata %>%
    ungroup() %>%
    mutate(lvad_years_at_start =
             ifelse(lvad_years_at_start>10,10,lvad_years_at_start),
           week_from_baseline = 1)
  
  if (lasso) {
    mf_pred_data <- model.frame(delete.response(lasso_orig_terms), data=pred_data)
    x_pred_data <- model.matrix(delete.response(lasso_orig_terms), data = mf_pred_data)[, -1]
    x_pred_data_selected <- x_pred_data[, lasso_selected_vars, drop = F]
    pred_data$haz_dth <- predict(mod,newdata=list(x_selected = x_pred_data_selected),type="response")
  } else {
    # predict hazard of death within the week
    pred_data$haz_dth = predict(mod,newdata=pred_data,type="response")
  }
  
  # calculate probability of surviving 6 weeks
  pred_data = pred_data %>%
    mutate(log_haz_dth = log(haz_dth))
  
  # return pred_data
  return(pred_data)
}

# calculate predicted probabilities
mrdat = pred_data_fun1(mrdat,mortality_modelC) %>%
  rename(haz_dth_modC = haz_dth, log_haz_dth_modC = log_haz_dth) %>%
  pred_data_fun1(.,mortality_modelE) %>%
  rename(haz_dth_modE = haz_dth, log_haz_dth_modE = log_haz_dth)

# select PX_ID, current_date, USCRS 2.0 log hazards
mrdat0 = mrdat %>%
  select(PX_ID,current_date,log_haz_dth_modC,log_haz_dth_modE)
summary(mrdat0$log_haz_dth_modC) # no missing, all negative bc probability
summary(mrdat0$log_haz_dth_modE) # no missing, all negative bc probability

# save data for match run analysis
mrdat = mrdat0
save(mrdat,file="mrdat.Rdata")
