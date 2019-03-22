# Function for doing one-hot encoding
one_hot = function(df, col_label){
    z = unlist(df[col_label])
    n = NROW(df)
    var_labels = sort(unique(z))
    mat = matrix(0, n, length(var_labels))
    for (j in 1:length(var_labels))
        mat[z %in% var_labels[j], j] = 1
    colnames(mat) = paste0(col_label, '_', var_labels)
    df = cbind(df[,!(names(df) %in% col_label)], mat)
    return (df)
    }

raw = read.csv("full_x.csv")
x = raw
y = as.factor(read.csv("full_y.csv")[,1])

# Do one-hot encoding for factor variables
x = one_hot(x, "emp_length")
x = one_hot(x, "home_ownership")
x = one_hot(x, "verification_status")
x = one_hot(x, "purpose")
x = one_hot(x, "addr_state")
x = one_hot(x, "issue_month")
x = as.matrix(x)

keep_ind = c(grep("int_rate", colnames(x)),
    grep("revol_util", colnames(x)),
    grep("annual_inc", colnames(x)),
    grep("revol_bal", colnames(x)),
    grep("dti", colnames(x)),
    grep("loan_amnt", colnames(x)),
    grep("earliest_cr_line", colnames(x)),
    grep("open_acc", colnames(x)),
    grep("mths_since_last_delinq", colnames(x)),
    grep("inq_last_6mths", colnames(x)),
    grep("issue_year", colnames(x)),
    grep("term", colnames(x)))

x = x[,keep_ind]

# Fit a random forest on training data (randomly split at 80%)
set.seed(1)
n = nrow(x)
train_ind = sample(n)[1:round(n * 0.8)]

trainx = x[train_ind,]
trainy = y[train_ind]

testx = x[-train_ind,]
testy = y[-train_ind]

mod = glm(trainy ~ ., data = as.data.frame(trainx), family = "binomial")
summary(mod)

# Predict on test data
yhat = as.numeric(predict(mod, newdata = as.data.frame(testx), type = "response"))

# Score card
score = round(yhat * 1000) - 1
quantile(score, c(0.2, 0.4, 0.6, 0.8))


# Accuracy
cutoff = 0.5
y01 = 1*(yhat > cutoff)
mean(ytest[y01 == 0] == 0) # about 46.6%, baseline 14.3%
mean(ytest[y01 == 1] == 1) # about 85.7%, baseline 85.6%

mean(y01[ytest == 0] == 0) # about 00.6%, not good, but can be improved by increasing cutoff
mean(y01[ytest == 1] == 1) # about 99.8%

# Error
mean(ytest[y01 == 0] == 1)
mean(ytest[y01 == 1] == 0)

# Note that the cutoff should be changed to some optimal value which
# weights the accuracies/errors by some desired outcome


