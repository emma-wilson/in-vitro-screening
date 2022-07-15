#---------- Helpers Aiding analyze -------------------------------------------------
# Created by Jing Liao
# Created on May 31 2017
#-------------------------------------------------------------------------

require(caret)
require(e1071)
require(epiR)

CalcualteCM <- function(mergedResult, threshold)
{
  options(warn=-1)
  data <- factor(mergedResult$Score > threshold, levels = c("TRUE", "FALSE"))
  ref <- factor(mergedResult$HumanDecision == 1, levels = c("TRUE", "FALSE"))
  confusionMatrix(data
                  , ref
                  , positive = "TRUE")
}

Analysis <- function(outputFilenameResult, outputFilenameTestDecisions, AnalysisFileName, minimumSensitivity = 0.95)
{
  n <- 100
  thresholds <- 0+0.01*(1:n)
  utility <- array(NA,n)
  Sensitivity <- array(NA,n)
  Specificity <- array(NA,n)
  Precision <- array(NA,n)
  
  mlResult <- read.csv(outputFilenameResult, header = F, col.names = c("Score", "ID", "ProjectID"))
  testResult <- read.csv(outputFilenameTestDecisions, header = T,col.names = c("ProjectID", "ID", "HumanDecision"))
  
  mergedResult <- merge(mlResult, testResult)
  print(dim(mergedResult))
  mergedResult <- mergedResult[which(!is.na(mergedResult$HumanDecision) & !is.na(mergedResult$Score) ),]

  for(i in 1:n)
  {
    threshold <- thresholds[i]
    
    cm <- CalcualteCM(mergedResult, threshold)
    utility[i] <-  (5*cm[4]$byClass["Sensitivity"] + cm[4]$byClass["Specificity"])/(1+5)
    Specificity[i] <- cm[4]$byClass["Specificity"]
    Sensitivity[i] <- cm[4]$byClass["Sensitivity"]
    Precision[i] <- cm[4]$byClass["Precision"]
  }
  
  index <- which( Specificity == max(Specificity[which(Sensitivity >= minimumSensitivity)]))
  
  finalThreshold <- thresholds[index[1]]
  chosen <- rep(FALSE, length(thresholds))
  chosen[index[1]] <- TRUE
  
  print(paste0("best treshold is: ", finalThreshold))
  
  finalCM <- CalcualteCM(mergedResult, finalThreshold)
  print(finalCM)
  
  finalStats <- epi.tests(finalCM$table)
  print(finalStats)
  
  results <- data.frame(Thresholds = thresholds, Specificity = Specificity
                        , Sensitivity =Sensitivity, Precision = Precision
                        , Chosen = chosen)
  
  write.csv(results, file = AnalysisFileName)
  capture.output(finalCM, file = AnalysisFileName,  type = c("output", "message"), append = T)
  
  results$FPR <- (1 - results$Specificity)
  
  
  return(results)
}



FindBestPerformance <- function(outputFilenameResult, outputFilenameTestDecisions, AnalysisFileName, optimizeMetrics = "Specificity", satisfactionMetrics = "Sensitivity", satisfactionMetricsValue = 0.95){  
  CalculatePerformance <- function(mergedResult, threshold){
    cm <- CalcualteCM(mergedResult, threshold)
    
    result <- data.frame(Threshold = threshold
                         , Utility = (5*cm[4]$byClass["Sensitivity"] + cm[4]$byClass["Specificity"])/(1+5)
                         , Specificity = cm[4]$byClass["Specificity"]
                         , Sensitivity = cm[4]$byClass["Sensitivity"]
                         , Precision = cm[4]$byClass["Precision"]
                         , F1 = cm[4]$byClass["F1"]
                         , 'Balanced Accuracy' = cm[4]$byClass["Balanced Accuracy"]
                         , Chosen = FALSE)
    return(result)
  }
  
  n <- 100
  thresholds <- 0+0.01*(1:n)
  
  mlResult <- read.csv(outputFilenameResult, header = F, col.names = c("Score", "ID", "ProjectID"))
  testResult <- read.csv(outputFilenameTestDecisions, header = T,col.names = c("ProjectID", "ID", "HumanDecision"))
  
  mergedResult <- merge(mlResult, testResult)
  mergedResult <- mergedResult[which(!is.na(mergedResult$HumanDecision) & !is.na(mergedResult$Score) ),]
  # print(dim(mergedResult))
  
  myResults <- as.data.frame(t(as.matrix(sapply(thresholds, CalculatePerformance, mergedResult = mergedResult))))
  myResults <- apply(myResults , 2 , as.numeric)
  
  index <- which( myResults[, optimizeMetrics] == max(unlist(myResults[which(myResults[,satisfactionMetrics] > satisfactionMetricsValue),optimizeMetrics])))
  index <- index[which(myResults[index, satisfactionMetrics] == max(myResults[index, satisfactionMetrics]))]
  
  myResults[index,"Chosen"] <- TRUE
  
  print(paste0("best treshold is: ", myResults[index, "Threshold"]))
  finalCM <- CalcualteCM(mergedResult, myResults[index, "Threshold"])
  print(finalCM)
  
  write.csv(myResults, file = AnalysisFileName)
  capture.output(finalCM, file = AnalysisFileName,  type = c("output", "message"), append = T)
  
  return(myResults)
}
