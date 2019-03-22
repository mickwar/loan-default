### Read in raw data
raw_dat = read.csv("LoanStats3a.csv")
x = raw_dat     # so we can start over in the same session if necessary

dim(x)  # 42538 x 144


### Remove rows with missing loan_status or bad class (removes about 100 rows)
x = x[-which(x$loan_status == ""),]
x = x[-which(x$home_ownership %in% c("NONE", "OTHER")),]


### Get the response variable
y = as.character(x$loan_status)
x = x[,-which(names(x) == "loan_status")]

# Good / Fully Paid = 1
# Bad / Charged Off = 0

# This approach removes the rows with "Does not meet the credit policy"
ind = grep("Does not meet", y)
x = x[-ind,]
y = y[-ind]
y[grep("Fully Paid", y)] = "1"
y[grep("Charged Off", y)] = "0"
y = as.numeric(y)

# This approach ignores the "Does not meet the credit policy" statement in some
# loan statuses.
#y[grep("Fully Paid", y)] = "1"
#y[grep("Charged Off", y)] = "0"
#y = as.numeric(y)

# Hold on to loan grade for comparisons later
# all(substr(x$sub_grade, 1, 1) == x$grade) == TRUE, so only need sub_gade
grade = x$sub_grade
x = x[,-grep("grade", names(x))]

# Not sure which approach is more appropriate, but removing the rows containing
# "Does not meet the credit policy" in the loan status.

dim(x)  # 39786 x 141


### Remove unnecessary columns
# These variables were typically empty, had too few non-empty values, or
# had too many unique classes to be used in any meaningful way

# First, get the counts of the most frequently occurring class in each column.
# If count is too close to 42538, then that column is highly imbalanced and we
# should remove it. We use a cutoff of 98%.
max_counts = apply(x, 2,
    function(l){
        t = table(l, useNA = "ifany")
        max(as.numeric(t))
        })

x = x[,-which(as.numeric(max_counts) > NROW(x) * 0.98)]
dim(x)  # 39786 x 39

x = x[,-which(names(x) %in% c("emp_title", "title", "desc",
    "last_credit_pull_d"))]


### Remove columns we wouldn't have in a pre-loan setting
x = x[,-grep("total", names(x))]
x = x[,-which(names(x) %in% c("recoveries", "collection_recovery_fee",
    "last_pymnt_d", "last_pymnt_amnt", "funded_amnt", "funded_amnt_inv",
    "installment"))]

# Removing the "funded" columns, since I figure the amount that is actually
# funded wouldn't be known when deciding whether to approve a loan.
# "installment" is removed since it is highly correlated with "loan_amnt".
# (see plot(x$installment, x$loan_amnt))

dim(x)  # 39786 x 22


### General clean up 
# Remove the "%"
x$int_rate = as.numeric(unlist(strsplit(as.character(x$int_rate), "%")))
x$revol_util[x$revol_util == ""] = "0%" # Set empty utilization to zero
x$revol_util = as.numeric(unlist(strsplit(as.character(x$revol_util), "%")))

# Will need to combine the lower frequency classes into an "Other" category.
# We want to have a minimum count in each class that is workable, a bare
# minimum might be something like 2%-5%, otherwise we won't get great estimates
# for our model coefficients.

# Zip codes might pose a problem since there are so many different classes, so
# going to remove (if we had more data, we could probably keep).
# States should be fine
x = x[,-which(names(x) == "zip_code")]

state = as.character(x$addr_state)
tmp = table(state)
state[state %in% names(tmp[tmp < nrow(x) * 0.02])] = "Other"
x$addr_state = state

# Do the same for "purpose", put low frequency classes in the already
# existing "other" category
purpose = as.character(x$purpose)
tmp = table(purpose)
purpose[purpose %in% names(tmp[tmp < nrow(x) * 0.02])] = "other"
x$purpose = purpose

# Keep month of issued date, may be able to pick up some cyclical pattern
issue_month = unlist(lapply(strsplit(as.character(x$issue_d), "-"), tail, 1))
issue_year = unlist(lapply(strsplit(as.character(x$issue_d), "-"), head, 1))
issue_year = as.numeric(issue_year) + 2000

# Earliest credit line is weird: looks like if before 2001, then the format
# is MMM-YY, if 2001 or later then the format is Y-MMM. So we just need to
# find the position of "-". Only going to take the year.
pos = unlist(lapply(gregexpr("-", x$earliest_cr_line), head, 1))
ecl = as.character(x$earliest_cr_line)
ecl[pos == 2] = as.numeric(substr(ecl[pos == 2], 1, 1)) + 2000
ecl[pos == 4] = as.numeric(substr(ecl[pos == 4], 5, 6)) + 1900
ecl[ecl == "1900"] = "2000"
ecl = as.numeric(ecl)
x$earliest_cr_line = ecl

# Set NA to -1, use later for encoding an indicator variable. The NA could mean
# there has never been a deliquency, so it would be inappropriate to set this
# value to zero, which could mean there was a recent deliquency.
x$mths_since_last_delinq[is.na(x$mths_since_last_delinq)] = -1
x$mths_since_last_record[is.na(x$mths_since_last_record)] = -1


dim(x)      # 39685 x 21
length(y)   # 39685


### Make indicator variables
x$mths_since_last_delinq_ind = ifelse(x$mths_since_last_delinq == -1, 1, 0)
x$mths_since_last_record_ind = ifelse(x$mths_since_last_record == -1, 1, 0)
x$mths_since_last_delinq[x$mths_since_last_delinq == -1] = 0
x$mths_since_last_record[x$mths_since_last_record == -1] = 0

x$pub_rec_bankruptcies_ind = ifelse(is.na(x$pub_rec_bankruptcies), 1, 0)
x$pub_rec_bankruptcies[is.na(x$pub_rec_bankruptcies)] = 0

x$term = ifelse(x$term == " 36 months", 0, 1)   # 0 for 36, 1 for 60

x$issue_month = issue_month
x$issue_year = issue_year

x = x[,-which(names(x) == "issue_d")]

### Output processed data for later usage
write.table(x, "full_x.csv", sep = ",", quote = FALSE, row.names = FALSE)
write.table(y, "full_y.csv", sep = ",", quote = FALSE, row.names = FALSE)


# ### Factor variables
# # Might not need to one-hot encode some these if doing the logistic regression
# # in R which easily handles factors
# #table(x$term)
# table(x$home_ownership)
# table(x$verification_status)
# table(issue_month)
# table(issue_year)
# table(x$emp_length)
# table(x$addr_state)
# table(x$purpose)
# 
# ### Continuous
# hist(x$loan_amnt)
# hist(x$int_rate)
# hist(log(x$annual_inc)) # Strictly positive, so we could safely do log
# plot(table(x$delinq_2yrs))
# hist(x$revol_bal)
# hist(x$revol_util)
# hist(x$dti)
# plot(table(x$earliest_cr_line))
# plot(table(x$inq_last_6mths))
# #plot(table(x$mths_since_last_delinq))
# #plot(table(x$mths_since_last_record))
# plot(table(x$open_acc))
# plot(table(x$pub_rec))
# plot(table(x$pub_rec_bankruptcies))

