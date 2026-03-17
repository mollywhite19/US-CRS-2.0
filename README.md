## Background

This repo contains code to prepare a continuous time-varying dataset for adult heart candidates, convert to a discrete-time survival dataset with units of 1 week, and ultimately fit a marginal structural model of waitlist mortality, accounting for time-varying confounders that affect the probability of transplant (censoring).

## R scripts (run in order)

heart_pipeline_final.rmd

- Inputs: SRTR SAF
- Output: heart_post_policy.RData (continuous-time dataset called `df`)

discrete_data_prep.Rmd

- Inputs: heart_post_policy.RData
- Output: discrete_final_data.RData (1-week discrete-time dataset called `df_final`)

mortality_model_data.Rmd

- Inputs: discrete_final_data.RData
- Output: discrete_data_preSplit.Rdata (1-week discrete-time dataset with a few updates and new variables for modeling, called `df_final`)
  - Use this dataset as basis for Table 1 and match run analysis
- Output: mortality_model_test_data.RData (hold-out 1-week discrete-time dataset called `test_data`)
- Output: mortality_model_train_data.Rdata (landmark model training dataset called `combined_df`)
- Output: mortality-model-options.Rdata (fitted glms for 1-week waitlist death hazard)
- Output: mort-pred-fun.Rdata (function to calculate predicted 6-week survival from a mortality glm on a new datast)

model-eval.Rmd

- Calculates time-dependent AUC in calendar cross-sections of validation set and test set
- Inputs: mortality-model-options.Rdata, mortality-model-lasso-options.Rdata, mortality_model_test_data.RData, mort-pred-fun.Rdata
- Output: eight-sets-valid.Rdata (8 calendar cross-sections in validation data with model predictions)

calib-plot.Rmd

- Calculates time-varying weighted calibration comparing observed and expected by prediction quantile, urgency status, and exception status
- Inputs: mortality_model_test_data.RData, eight-sets-valid.Rdata