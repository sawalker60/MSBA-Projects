#-----------------------------------------------------------------------
#Loading Dataset

library(readr)
df <- read.csv("DB/final_dataset.csv")
attach(df)
dim(df)

hist(salary)

#-----------------------------------------------------------------------
#LASSO

library(glmnet)
x=model.matrix(log(salary)~.-1 - playerID - throws - Name, data=df)
y=log(salary)
fit.lasso=glmnet(x,y)
plot(fit.lasso,xvar="lambda", label=TRUE)
cv.lasso=cv.glmnet(x,y)
plot(cv.lasso)
coef(cv.lasso)

#----------------------------------------------------------------------
#Stepwise Selection

library(car)
n <- length(df$salary)
intercept_only <- lm(log(salary) ~ 1, data=df)
m.full <- lm(log(salary) ~. - playerID - throws - Name, data=df)
summary(m.full)

#AIC
hybridAIC <- step(m.full, direction='both', data=df)
backAIC <- step(m.full, direction='backward', data=df)
forwardAIC <- step(intercept_only, direction='forward', scope=formula(m.full), trace=0)  

#BIC
hybridBIC <- step(m.full, direction='both', data=df, k=log(n))
backBIC <- step(m.full, direction='backward', data=df, k=log(n))
forwardBIC <- step(intercept_only, direction='forward', scope=formula(m.full), trace=0, k=log(n))  

#Check coefficients
hybridAIC$coefficients
backAIC$coefficients
forwardAIC$coefficients

hybridBIC$coefficients
backBIC$coefficients
forwardBIC$coefficients


#--------------------------------------------------------------------
#Five Models
#Model 1
Lasso_model = lm(log(salary) ~ All_star + BB + BK + CG + G + Gold_Glove + 
                    L + Post_G + Post_GS +
                    Post_SH + SH + SO + SV + W + WP + yearID, data=df)
summary(Lasso_model)
#Not significant = Post_IPouts, Post_H, Post_ER, Post_L

#Model 2
HybridAIC_model = lm(log(salary) ~ All_star + BB +  BK + 
                       G +  GIDP + Gold_Glove + L + 
                       Post_SH +  
                       SF + SH + SO + W + WP + 
                       yearID, data=df)
summary(HybridAIC_model)
#Not significant = SHO, ER, Post_L, Post_SV, Post_G, Post_R, Post_ER

#Model 3
ForwardAIC_model = lm(log(salary) ~ All_star + BB + BK + 
                        G + GIDP + Gold_Glove + L + Post_BK +
                        Post_SH + Post_SO + Post_GS +
                        SF + SH + SO + W + WP + yearID +
                        Post_G, data=df)
summary(ForwardAIC_model)
#Not significant = Post_SV, Post_H, SHO, ER, Post_CG

#Model 4
HybridBIC_model = lm(log(salary) ~  BK + CG + ERA + G +
                 GIDP + Gold_Glove + Post_IPouts + Post_SH + SO +
                 SV + W + yearID, data=df)
summary(HybridBIC_model)
#Not significant = none

#Model 5
ForwardBIC_model = lm(log(salary) ~ All_star + BB + BK + G + GIDP + 
                        Gold_Glove + L + Post_H + Post_SH +
                        SO + SV + W + yearID, data=df)
summary(ForwardBIC_model)
#Not significant = IPouts


#--------------------------------------------------------------------
#After building and running the models, we want to check the assumptions of the models to make sure they hold.
#We also want to check the VIF values for any collinearity issues among the predictors.



#Examining the Lasso Model
par(mfrow=c(2,2))
plot(Lasso_model)
vif(Lasso_model)

#All the assumptions held, even after removing some variables.
#Based off VIF findings GS, H, and IPouts have a great deal of collinearity so we went back and took them out of the model.




#Examining the HybridAIC model
plot(HybridAIC_model)
vif(HybridAIC_model)

#We checked for assumptions first with the plot function of the model and did not see any assumptions be violated.
# Based off the VIF findings for the hybrid AIC model, we removed BFP, GF, GS, IPouts, Post_IPouts, Post_SO, R, and SV

#Once we ran the model again we noticed that CG, ERA, Post_BK, and Post_CG were all statistically insignificant so we removed them as well and reran the model.



#Examining the ForwardAIC model
plot(ForwardAIC_model)
vif(ForwardAIC_model)

#Once again all the assumptions held true
#We removed BFP, GF, GS, IPouts, R, and SV and reran the model after running vif to check for collinearity.
#We also removed CG and ERA due to statistical insignificance.



#Examining the HybridBIC model

plot(HybridBIC_model)
vif(HybridBIC_model)

#We reviewed the model to make sure no assumptions were violated.
#After examining the VIF values we removed GF and GS from the model. 
#Once we ran the model again we noticed that All Star and BB were not significant predictors so we eliminated those as well.

#Examining the ForwardBIC model

plot(ForwardBIC_model)
vif(ForwardBIC_model)

#All of the assumptions plots seem to follow the rules for each.
#We also removed GS from the model due to a VIF value greater than 10.


#We wanted to see the R squared value solely for each model

summary(Lasso_model)$r.squared
summary(HybridAIC_model)$r.squared
summary(ForwardAIC_model)$r.squared
summary(HybridBIC_model)$r.squared
summary(ForwardBIC_model)$r.squared

#We wanted to see the Adj R squared value solely for each model

summary(Lasso_model)$adj.r.squared
summary(HybridAIC_model)$adj.r.squared
summary(ForwardAIC_model)$adj.r.squared
summary(HybridBIC_model)$adj.r.squared
summary(ForwardBIC_model)$adj.r.squared

#Getting the MSE for each model

#First we need to get the MSE for the models with the log transformation for price.

MSE1 <- mean(Lasso_model$residuals^2)
MSE2 <- mean(HybridAIC_model$residuals^2)
MSE3 <- mean(ForwardAIC_model$residuals^2)
MSE4 <- mean(HybridBIC_model$residuals^2)
MSE5 <- mean(ForwardBIC_model$residuals^2)


#---------------------------------------------------------------------------------------
#CROSS VALIDATION FOR MODELS
library(caret)
library(mltools)
set.seed(18)

random <- createDataPartition(df$salary,p=0.75, list=FALSE)
training <- df[random, ]
testing <- df[-random, ]

#LASSO
Lasso_model_2 = lm(log(salary) ~ All_star + BB + BK + CG + G + Gold_Glove + 
                                L + Post_G + Post_GS +
                                Post_SH + SH + SO + SV + W + WP + yearID, data=training)
Lasso_predictions <- predict(Lasso_model_2, testing)

df_metric_1 <- data.frame( Model = 'Lasso',
            R2 = R2(Lasso_predictions, log(testing$salary)),
            RMSE = RMSE(Lasso_predictions, log(testing$salary)),
            MAE = MAE(Lasso_predictions, log(testing$salary)),
            MSE = mse(Lasso_predictions, log(testing$salary)))
#HybridAIC
HybridAIC_model_2 = lm(log(salary) ~ All_star + BB +  BK + 
                       G +  GIDP + Gold_Glove + L + 
                       Post_SH +  
                       SF + SH + SO + W + WP + 
                       yearID, data=training)
HyrbridAIC_predictions <- predict(HybridAIC_model_2, testing)

df_metric_2 <- data.frame( Model = 'HybridAIC',
            R2 = R2(HyrbridAIC_predictions, log(testing$salary)),
            RMSE = RMSE(HyrbridAIC_predictions, log(testing$salary)),
            MAE = MAE(HyrbridAIC_predictions, log(testing$salary)),
            MSE = mse(HyrbridAIC_predictions, log(testing$salary)))

#ForwardAIC
ForwardAIC_model_2 = lm(log(salary) ~ All_star + BB + BK + 
                        G + GIDP + Gold_Glove + L + Post_BK +
                        Post_SH + Post_SO + Post_GS +
                        SF + SH + SO + W + WP + yearID +
                        Post_G, data=training)
ForwardAIC_predictions <- predict(ForwardAIC_model_2, testing)

df_metric_3 <- data.frame( Model = 'ForwardAIC',
            R2 = R2(ForwardAIC_predictions, log(testing$salary)),
            RMSE = RMSE(ForwardAIC_predictions, log(testing$salary)),
            MAE = MAE(ForwardAIC_predictions, log(testing$salary)),
            MSE = mse(ForwardAIC_predictions, log(testing$salary)))

#HyrbidBIC
HybridBIC_model_2 = lm(log(salary) ~  BK + CG + ERA + G +
                       GIDP + Gold_Glove + Post_IPouts + Post_SH + SO +
                       SV + W + yearID, data=training)
HyrbidBIC_predictions <- predict(HybridBIC_model_2, testing)

df_metric_4 <- data.frame( Model = 'HybridBIC',
            R2 = R2(HyrbidBIC_predictions, log(testing$salary)),
            RMSE = RMSE(HyrbidBIC_predictions, log(testing$salary)),
            MAE = MAE(HyrbidBIC_predictions, log(testing$salary)),
            MSE = mse(HyrbidBIC_predictions, log(testing$salary)))


#ForwardBIC
ForwardBIC_model_2 = lm(log(salary) ~ All_star + BB + BK + G + GIDP + 
                        Gold_Glove + L + Post_H + Post_SH +
                        SO + SV + W + yearID, data=training)
ForwardBIC_predictions <- predict(ForwardBIC_model_2, testing)

df_metric_5 <- data.frame( Model = 'ForwardBIC',
            R2 = R2(ForwardBIC_predictions, log(testing$salary)),
            RMSE = RMSE(ForwardBIC_predictions, log(testing$salary)),
            MAE = MAE(ForwardBIC_predictions, log(testing$salary)),
            MSE = mse(ForwardBIC_predictions, log(testing$salary)))

model_metrics <- rbind.data.frame(df_metric_1,df_metric_2,df_metric_3,df_metric_4,df_metric_5)
model_metrics

#---------------------------------------------------------------------------------------
#Conclusion

par(mfrow=c(1,1))
plot(exp(Lasso_predictions),testing$salary)
plot(exp(ForwardBIC_predictions),testing$salary)

random <- testing[c(18,285,1455),]
random$salary

random_look <- data.frame(exp(predict(Lasso_model_2,interval='confidence',random)))
rownames(random_look) <- NULL 
Salary_random <- data.frame(Salary_Next_Year= random$salary)
random_name <- data.frame(Name = random$Name, Year = random$yearID)
Lasso_random <- cbind.data.frame(random_name,Salary_random,random_look)

random_look <- data.frame(exp(predict(ForwardBIC_model_2,interval='confidence',random)))
rownames(random_look) <- NULL 
Salary_random <- data.frame(Salary_Next_Year= random$salary)
random_name <- data.frame(Name = random$Name, Year = random$yearID)
ForwardBIC_random <- cbind.data.frame(random_name,Salary_random,random_look)

Lasso_random
ForwardBIC_random
