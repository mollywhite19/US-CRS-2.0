## Background

This repo contains code to prepare a continuous time-varying dataset for adult heart candidates, convert to a discrete-time survival dataset with units of 1 week, and ultimately fit a marginal structural model of waitlist mortality, accounting for time-varying confounders that affect the probability of transplant (censoring).

## R scripts (run in order)

heart_pipeline_final.rmd

- Inputs: SRTR SAF
- Outputs: heart_post_policy.RData (continuous-time dataset called `df`)

discrete_data_prep.Rmd

- Inputs: heart_post_policy.RData
- Outputs: discrete_final_data.RData (1-week discrete-time dataset called `df_final`)

mortality_model_data.Rmd

- Inputs: discrete_final_data.RData
- Outputs: mortality_model_test_data.RData (hold-out 1-week discrete-time dataset called `test_data`), mortality_model_sweights (weighted glm object)
