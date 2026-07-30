## calculate number of outcomes in each set:

## training data
base::load("mortality_model_train_data.Rdata")
combined_df %>% ungroup %>% distinct(PX_ID,outcome,CAN_REM_CD) %>% count(outcome,CAN_REM_CD %in% 13)


## validation data cross-sections
base::load("eight-sets-valid.Rdata")
eight_sets_valid_modC %>% count(outcome) # ungroup %>% distinct(PX_ID,outcome) %>% count(outcome)

## test data cross-sections
base::load("eight-sets-test.Rdata")
eight_sets_test_modC %>% count(outcome) # ungroup %>% distinct(PX_ID,outcome) %>% count(outcome)
