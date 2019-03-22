### Read in raw data
raw_dat = read.csv("LoanStats3a.csv")
x = raw_dat     # so we can start over in the same session if necessary

dim(x)  # 42538 x 144


### Remove rows with missing loan_status (removes 3 rows)
x = x[-which(x$loan_status == ""),]


### Get the response variable
y = as.character(x$loan_status)

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

# Not sure which approach is more appropriate, but removing the rows containing
# "Does not meet the credit policy" in the loan status.

dim(x)  # 39786 x 144


### Remove unnecessary columns
# These variables were typically empty, or had too few non-empty values
# to be used in any meaningful way

# First, get the counts of the most frequently occurring class in each column.
# If count is too close to 42538, then that column is highly imbalanced and we
# should remove it. We use a cutoff of 98%.
max_counts = apply(x, 2,
    function(l){
        t = table(l, useNA = "ifany")
        max(as.numeric(t))
        })

x = x[,-which(as.numeric(max_counts) > NROW(x) * 0.98)]
dim(x)  # 39786 x 42
