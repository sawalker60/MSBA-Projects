library(readr)
train <- read_csv("new train.csv")
test <- read_csv("new test.csv")
df <- rbind(train, test)
attach(df)
boxplot(age~y)
boxplot(balance~y)
boxplot(campaign~y)
boxplot((duration/60)~y)
boxplot(pdays~y)
boxplot(previous~y)

train.full <- glm(y ~ age + factor(job) + factor(marital) + factor(education) + 
                    factor(default) + balance + factor(housing) + 
                    factor(loan) + factor(contact) + duration + campaign + 
                    pdays + previous + factor(poutcome),
                family=binomial, data=train)

summary(train.full)

train.step <- step(train.full)
summary(train.step)

train.final <- glm(formula = y ~ factor(job) + factor(marital) + factor(education) + 
      balance + factor(housing) + factor(loan) + factor(contact) + 
      duration + campaign + factor(poutcome), family = binomial, 
    data = train)

summary(train.final)

(1 - exp(train.final$coefficients))*100

(1 - exp(confint(train.final, level=0.9,type="LR")))*100

Deviance = anova(train.final, test="Chisq")
Deviance


R2 = data.frame(R2 = 22609/32631)
R2

pred <- predict(train.final, type="response")
class.train <- data.frame(response = train$y, predicted = round(pred,0))
xtabs(~predicted+response,data=class.train)

Miss_Class_Rate = data.frame(Miss_Class_Rate = (3587 + 913)/(45211))
Miss_Class_Rate

par(mfrow=c(1,1))
library(pROC)
train.roc <- roc(train$y ~ pred, plot = TRUE, print.auc = TRUE)

pred_test <- predict(train.final, test, type="response")
class.test <- data.frame(response = test$y, predicted = round(pred_test,0))
xtabs(~predicted+response,data=class.test)

Miss_Class_Rate = data.frame(Miss_Class_Rate = (81+362)/(4521))
Miss_Class_Rate
test.roc <- roc(test$y ~ pred_test, plot = TRUE, print.auc = TRUE)
