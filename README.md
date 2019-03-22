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

#### Response variable

The response variable was chosen from the `loan_status` column.
If the value in that column contained the phrase "Does not meet the credit policy", we threw out that row, regardless of whether the loan was fully paid or charged off.
We set 0 to mean Charged Off and 1 to mean Fully Paid, so low scores would indicative of a high chance of defaulting.

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

We'll keep the variables having importance measure greater than 100.

### Logistic model

Code is found at [`logistic.R`](logistic.R).

We fit a logistic model using the importance variables we kept from the random forest.
As before, we fit the model to 80% of the data to make sure we aren't doing some terrible overfitting. (Given more time, we might consider doing a *k*-fold cross-validation, but for our purposes now, an 80/20 split for train/test should suffice.)

Below is a summary of the coefficients from the model.

Coefficients | Estimate | Std. Error | z value | Pr(>z) | How significant?
--- | --- | --- | --- | --- | ---
(Intercept)                | -1.580e+02 |  4.184e+01 |  -3.777 | 0.000159 | \*\*\*
int_rate                   | -1.198e-01 |  6.441e-03 | -18.592 |  < 2e-16 | \*\*\*
revol_util                 | -3.008e-03 |  7.636e-04 |  -3.939 | 8.18e-05 | \*\*\*
annual_inc                 |  6.539e-06 |  5.939e-07 |  11.009 |  < 2e-16 | \*\*\*
revol_bal                  | -1.756e-06 |  1.416e-06 |  -1.240 | 0.214871 |
dti                        | -1.529e-03 |  2.909e-03 |  -0.526 | 0.599177 |
loan_amnt                  |  7.308e-07 |  2.710e-06 |   0.270 | 0.787422 |
earliest_cr_line           |  6.630e-03 |  2.736e-03 |   2.423 | 0.015389 | \*
open_acc                   |  4.639e-03 |  4.282e-03 |   1.083 | 0.278641 |
mths_since_last_delinq     | -5.792e-04 |  1.249e-03 |  -0.464 | 0.642763 |
mths_since_last_delinq_ind | -7.871e-02 |  5.940e-02 |  -1.325 | 0.185102 |
inq_last_6mths             | -1.560e-01 |  1.493e-02 | -10.446 |  < 2e-16 | \*\*\*
issue_year                 |  7.371e-02 |  2.080e-02 |   3.544 | 0.000394 | \*\*\*
term                       | -4.781e-01 |  4.291e-02 | -11.143 |  < 2e-16 | \*\*\*

Note that these coefficients are based on the untransformed output (described next).
So they should be interpreted in terms of probability (as opposed to the "credit score") in the context of logistic regression.
For example, for every increase in `earliest_cr_line`, which is in years, we can expect an increase in log-odds by `0.00663`.

#### Score card

We compute a "credit score" by multiplying the predicted values by 998 and adding 1.
This gives us values between 1 and 999.
Again, a low value indicates high chance of default, and a high value means lower chance of default.

We bin the scores (from the test set data) based on the the quintiles, so each bin is roughly the same size.

Status      | [1, 802] | (802, 857] | (857, 894] | (894, 927] | (927, 999]
--- | --- | --- | --- | --- | ---
n           | 1592  | 1614  | 1595  | 1584  | 1552
Charged Off | 0.266 | 0.190 | 0.126 | 0.080 | 0.048
Fully Paid  | 0.733 | 0.809 | 0.873 | 0.919 | 0.951
