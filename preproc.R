### Read in raw data
raw_dat = read.csv("LoanStats3a.csv")
x = raw_dat     # so we can start over in the same session if necessary

dim(x)  # 42538 x 144


### Remove rows with missing loan_status (removes 3 rows)
x = x[-which(x$loan_status == ""),]


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
    "last_pymnt_d", "last_pymnt_amnt", "funded_amnt", "funded_amnt_inv"))]

# Removing the "funded" columns, since I figure the amount that is actually
# funded wouldn't be known when deciding whether to approve a loan.

dim(x)  # 39786 x 23


### General clean up 
# Remove the "%"
x$int_rate = as.numeric(unlist(strsplit(as.character(x$int_rate), "%")))

# Make employment length useful
table(x$emp_length)

# Will need to combine the lower frequency classes into an "Other" category.
# We want to have a minimum count in each class that is workable, a bare
# minimum might be something like 2%-5%, otherwise we won't get great estimates
# for our model coefficients.

# Zip codes might pose a problem since there are so many different classes,
# States should be fine
sort(as.numeric(table(x$zip_code)))
sort(as.numeric(table(x$addr_state)))

# Keep month of issued date, may be able to pick up some cyclical pattern
issue_month = unlist(lapply(strsplit(as.character(x$issue_d), "-"), tail, 1))
issue_year = unlist(lapply(strsplit(as.character(x$issue_d), "-"), head, 1))



### One-hot encode categorical variables
# Might not need to one-hot encode some these if doing the logistic regression
# in R which easily handles factors
x$term
x$installment
x$home_ownership
table(x$verification_status)
issue_month
issue_year
table(x$purpose)

