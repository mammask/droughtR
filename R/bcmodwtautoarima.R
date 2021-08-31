#' bcmodwtautoarima
#'
#' Fits a bias-corrected auto.arima with Maximal Overlap Discrete Wavelet Transformation (MODWT) to forecast the standardized precipitation index
#'
#' @param x data.table
#' @param trainratio Numeric value represents the proportion of the training set
#' @param validationratio Numeric value represents the proportion of the validation set
#' @param testratio Numeric value represents the proportion of the test set
#' @param stationaryspi Logical when TRUE SPI is calculated; when FALSE NSPI is calculated
#' @param spiscale Numeric value that reflects the scale of the index
#' @param ... Additional arguments that relate to the inputs of forecast::auto.arima
#' @import data.table ggplot2 zoo MLmetrics wavelets
#' @importFrom utils sessionInfo
#' @importFrom data.table := .N set
#' @rawNamespace import(gamlss, except = CV)
#' @rawNamespace import(forecast, except = CV)
#' @importFrom forecast auto.arima gghistogram forecast autoplot Acf ggAcf CV
#' @return list with evaluation metrics and diagnostic plots
#' @export
#'
#' @examples x = dummyrainfall(start = 1950, end = 2020)
#' bcmodwtautoarima(x, 0.8, 0, 0.2, TRUE, 12, 'haar', 2)
bcmodwtautoarima = function(x, trainratio, validationratio = 0, testratio, stationaryspi, spiscale, modwtfilter, nlevels, ...){

  if ((trainratio+validationratio+testratio) != 1){
    stop("The dataset split ratio should add up to 1")
  }

  if (stationaryspi == TRUE){
    droughtId = 'SPI'
  } else {
    droughtId = 'NSPI'
  }

  if (is.null(modwtfilter)){
    stop("Define the number of MODWT filters")
  }

  # Perform out of sample validation
  rain = data.table::copy(oossplit(x, trainratio, validationratio = 0, testratio))

  # Compute (N)SPI
  print("Calculating the drought index")
  drought = computenspi(rain[Split == 'Train'], stationaryspi, spiscale)
  drought = drought[complete.cases(drought)]

  # Define the number of MODWT series
  modwtseries = c(paste0("W",1:nlevels), paste0("V",1:nlevels))

  # Perform modwt decomposition
  modwtmodel  = wavelets::modwt(X = drought[[droughtId]], filter = modwtfilter, n.levels = nlevels, boundary = "periodic", fast = TRUE)

  # Obtain number of records for modwt boundary correction
  trainboundary = (2^nlevels-1)*(length(modwtmodel@filter@h)-1)+1

  trainmodwt  = data.table::copy(modwtmodel)
  trainmodwtmodel = list()
  trainseries = list()
  trainfitted = list()

  print("Fitting an auto.arima model for every modwt signal in the training set")
  for (i in modwtseries){
    if (substr(i,1,1) == 'W'){
      trainmodwt@W[[i]][1:trainboundary] = NA
      trainseries[[i]] = ts(data = trainmodwt@W[[i]], frequency = 12)
    } else if (substr(i,1,1) == 'V') {
      # if (as.numeric(substr(i,2,2)) == nlevels){
      trainmodwt@V[[i]][1:trainboundary] = NA
      trainseries[[i]] = ts(data = trainmodwt@V[[i]], frequency = 12)
      # }
    }
    # Train a model for each decomposed signal
    trainmodwtmodel[[i]] = forecast::auto.arima(y = trainseries[[i]],
                                                method = 'CSS',
                                                ic = 'aic',
                                                stationary = TRUE,
                                                seasonal = TRUE)

    # Store the fitted values of every model in the training set
    trainfitted[[i]] = trainmodwtmodel[[i]]

    # Update wavelet object with the fitted values in the training set
    if (substr(i,1,1) == 'W'){
      trainmodwt@W[[i]] = as.matrix(as.numeric(trainfitted[[i]][['fitted']]), ncol = 1)
    } else if (substr(i,1,1) == 'V'){
      trainmodwt@V[[i]] = as.matrix(as.numeric(trainfitted[[i]][['fitted']]), ncol = 1)
    }
  }

  # Perform Inverse MODWT and reconstruct drought series
  nspitrainfitted = wavelets::imodwt(trainmodwt)

  # Compute performance metrics in the training set --------------
  diagResults = list()

  diagResults[['R2 Score Train']] = MLmetrics::R2_Score(y_pred = nspitrainfitted,
                                                        y_true = drought[(trainboundary+1):.N][[droughtId]])

  diagResults[['RMSE Train']] = MLmetrics::RMSE(y_pred = nspitrainfitted,
                                                y_true = drought[(trainboundary+1):.N][[droughtId]])

  drought = drought[(trainboundary+1):.N]
  drought[, Fitted := nspitrainfitted]
  drought[, Error := lapply(.SD, function(x){return(x-Fitted)}),.SDcols = droughtId]

  # Fit actual vs. predicted
  diagResults[['Actual vs Predicted Train']] = ggplot2::ggplot(data = drought) +
    geom_line(aes(x = Date, y = eval(parse(text = droughtId)), color = 'Actual')) +
    geom_line(aes(x = Date, y = Fitted, color = 'Fitted')) +
    scale_color_manual(values=c("#3DB2FF", "#FF2442")) +
    theme(legend.position="bottom") +
    labs(colour="") +
    ylab(paste0("Actual vs. Predicted ",droughtId)) +
    theme_light() +
    theme(legend.position="top")

  diagResults[['Residual Plot Train']] =  forecast::gghistogram(drought[,Error], add.normal = TRUE) +
    xlab("Residuals") +
    ylab("Count") +
    theme_light()

  # Generate acf plot of residuals
  diagResults[['Residuals ACF Train']] = forecast::ggAcf(drought[,Error]) +
    ggtitle("ACF of Residuals") +
    theme_light()

  # Evaluate model in the test set -----------------------------------------------------------
  # Index records and start sequentially SPI calculation, model update and forecasts storing
  rain[, id := 1:.N]
  idstart = rain[Split == 'Test', min(id)-1]
  idend   = rain[Split == 'Test', max(id)-1]

  testseries = c()
  predtest = c()
  actual = c()

  pb = utils::txtProgressBar(min = idstart, max = idend+1, style = 3, width = 100)
  print("Initiating sequential index calculation, mmodel update and prediction")
  for (idx in idstart:c(idend+1)){
    utils::setTxtProgressBar(pb, idx)

    testmodwtmodel = list()

    droughtupd = computenspi(monthlyRainfall = rain[id <= idx], stationaryspi, spiscale)
    droughtupd = droughtupd[complete.cases(droughtupd)]

    # Perform modwt decomposition
    testmodwt  = wavelets::modwt(X = droughtupd[[droughtId]],
                                 filter = modwtfilter,
                                 n.levels = nlevels,
                                 boundary = "periodic",
                                 fast = TRUE
    )
    testmodwtseries = testmodwt@series

    # Test boundary correction
    testboundary = (2^nlevels-1)*(length(testmodwt@filter@h)-1)+1
    for (j in modwtseries){
      if (substr(j,1,1) == 'W'){
        testseries[[j]] = ts(data = testmodwt@W[[j]], frequency = 12)
      } else if (substr(j,1,1) == 'V') {
        testseries[[j]] = ts(data = testmodwt@V[[j]], frequency = 12)
      }
      # Train a model for each decomposed signal
      testmodwtmodel[[j]] = forecast::Arima(model = trainmodwtmodel[[j]],
                                            y = testseries[[j]],
                                            method = "CSS", ic = "aic")

      # Forecast next observation in the test set
      pred = forecast::forecast(object = testmodwtmodel[[j]], h = 1)[['mean']][1]

      # Updating series of wavelet object
      testmodwt@series = as.matrix(c(testmodwtseries, rep(NA, 1)))


      # Update modwt objects with predicted values
      if (substring(j,1,1) == 'W'){
        testmodwt@W[[j]] = rbind(testmodwt@W[[j]], as.matrix(pred, ncol = 1))
      } else if (substring(j,1,1) == 'V'){
        testmodwt@V[[j]] = rbind(testmodwt@V[[j]], as.matrix(pred, ncol = 1))
      }
    }
    # Reconstruct the predictions from the updated modwt
    if (idx < c(idend+1)){
      predtest = c(predtest, utils::tail(imodwt(testmodwt),1))
    }
    if (idx > idstart){
      actual = c(actual, utils::tail(droughtupd[[droughtId]],1))
    }
  }

  # Obtain Model Forecasts in the test set
  evaltestset = data.table(Date = rain[Split == 'Test',Date],
                           Index = actual,
                           Fitted = predtest
  )
  evaltestset[, Error := Fitted - Index]

  diagResults[['R2 Score Test']] = MLmetrics::R2_Score(y_pred = predtest,
                                                       y_true = actual)

  diagResults[['RMSE Test']] = MLmetrics::RMSE(y_pred = predtest,
                                               y_true = actual)

  # Fit actual vs. predicted
  diagResults[['Actual vs Predicted Test']] = ggplot2::ggplot(data = evaltestset) +
    geom_line(aes(x = Date, y = Index, color = 'Actual')) +
    geom_line(aes(x = Date, y = Fitted, color = 'Fitted')) +
    scale_color_manual(values=c("#3DB2FF", "#FF2442")) +
    theme(legend.position="bottom") +
    labs(colour="") +
    ylab(paste0("Actual vs. Predicted ",droughtId)) +
    theme_light() +
    theme(legend.position="top")

  diagResults[['Residual Plot Test']] =  forecast::gghistogram(evaltestset[,Error], add.normal = TRUE) +
    xlab("Residuals") +
    ylab("Count") +
    theme_light()

  # Generate acf plot of residuals
  diagResults[['Residuals ACF Test']] = forecast::ggAcf(evaltestset[,Error]) +
    ggtitle("ACF of Residuals") +
    theme_light()

  return(list("Diagnostics" = diagResults, "Prediction Test Set" = evaltestset, "Model" = trainmodwtmodel))
}
