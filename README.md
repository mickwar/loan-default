## Probability of loan default

Downloaded data set, converted from \*.xlsx to \*.csv.
Removed last four lines (two were blank, two were some kind of summary).

The raw data file is found at [`LoanStats3a.csv`](LoanStats3a.csv).


### Data processing

Code for this section is found within [`preproc.R`](preproc.R).

#### Column removal

We start by removing some obviously useless columns.
Any column that is made up of nearly 99% of a single value (or missing) won't be of any use.
On the other hand, any column that is made up of many unique, categorical values will likewise be unhelpful (this would include columns such as strings for user input or zip codes).

We also remove any variables that wouldn't be avaiable at the time of issuing a loan, such payments on that.
The goal is get the training data to look like the available data at the time of making the decision regarding a loan.

#### Clean up and transformations

We clean the data by removing certain characters from numerical values, such %.

For the loan issue date, we kept the month and year of issuance.
For earliest credit line date, we kept only the year.

Some indicator variables were made.
For example, the `pub_rec_bankruptcies_ind` has the value 1 for no bankcruptcies and 0 otherwise.
Also, `term` has a value 1 for a 60 month contract and 0 for a 36 month contract.

Importantly, categorical variables which had a mix of low frequency and high frequency classes were handled.
Low frequency classes were combined into an other category.
This allows us to use as much information as we can from the data without having any troubles fitting a model (i.e. due to some singularity).

#### Remaining variables

After processing, the variables we kept were:

Variables | Variables | Variables
--- | --- | ---
loan_amnt                  | term                     | int_rate
emp_length                 | home_ownership           | annual_inc
verification_status        | purpose                  | addr_state
dti                        | delinq_2yrs              | earliest_cr_line
inq_last_6mths             | mths_since_last_delinq   | mths_since_last_record
open_acc                   | pub_rec                  | revol_bal
revol_util                 | pub_rec_bankruptcies     | mths_since_last_delinq_ind
mths_since_last_record_ind | pub_rec_bankruptcies_ind | issue_month
issue_year                 |                          | 

The processed data files are found at [`full_x.csv`](full_x.csv) and [`full_y.csv`](full_y.csv).


### Variable importance

Code is found at [`rf.R`](rf.R).

We do a rough variable selection using the importance measure from a random forest.
We're not trying to be fancy here, we just want to understand which variables have the greatest impact on model performance.

We fit a random forest to training data which made up 80% of the data.
The top 15 most importance variables were found to be:

Variable | Importance
--- | ---
int_rate                   | 784.177319580578
revol_util                 | 708.09586210842 
annual_inc                 | 698.521824361002
revol_bal                  | 675.005735742592
dti                        | 674.661313230924
loan_amnt                  | 587.852285415713
earliest_cr_line           | 520.100301127575
open_acc                   | 479.049138513662
mths_since_last_delinq     | 299.194272493596
inq_last_6mths             | 240.910916799728
issue_year                 | 173.448891593523
term                       | 159.749508702452
addr_state_Other           | 98.0965410181687
purpose_debt_consolidation | 95.4723875279358
emp_length_10+ years       | 93.3308049637641

### Logistic model
