#' biautoarima
#'
#' Fits a bias-induced auto.arima to forecast the standardized precipitation index
#'
#' @param x data.table
#' @param trainratio Numeric value represents the proportion of the training set
#' @param validationratio Numeric value represents the proportion of the validation set
#' @param testratio Numeric value represents the proportion of the test set
#' @param stationaryspi Logical when TRUE SPI is calculated; when FALSE NSPI is calculated
#' @param spiscale Numeric value that reflects the scale of the index
#' @param ... Additional arguments that relate to the inputs of forecast::auto.arima
#' @import data.table ggplot2 zoo MLmetrics
#' @importFrom utils sessionInfo
#' @importFrom data.table := .N set
#' @rawNamespace import(gamlss, except = CV)
#' @rawNamespace import(forecast, except = CV)
#' @importFrom forecast auto.arima gghistogram forecast autoplot Acf ggAcf CV
#' @return list with evaluation metrics and diagnostic plots
#' @export
#'
#' @examples x = dummyrainfall(start = 1950, end = 2020)
#' biautoarima(x, 0.8, 0, 0.2, TRUE, 12, seasonal = FALSE)
biautoarima = function(x, trainratio, validationratio = 0, testratio, stationaryspi, spiscale, ...){

  if ((trainratio+validationratio+testratio) != 1){
    stop("The dataset split ratio should add up to 1")
  }

  if (stationaryspi == TRUE){
    droughtId = 'SPI'
  } else {
    droughtId = 'NSPI'
  }

  # Perform out of sample validation
  rain = copy(oossplit(x, trainratio, validationratio = 0, testratio))

  # Compute (N)SPI
  print("Calculating the drought index")
  drought = computenspi(rain, stationaryspi, spiscale)
  drought = drought[complete.cases(drought)]

  # Transform (N)SPI into a ts object
  nspitrain = ts(data = drought[Split == 'Train'][[droughtId]],
                 start = drought[Split == 'Train', min(Date)],
                 frequency = 12
  )

  # Fit an auto.arima in the training set
  print("Training and selecting the best model in the training set...")
  modeltrain = forecast::auto.arima(y = nspitrain, ...)

  # Obtain fitted values in the training set
  drought[Split == 'Train', Fitted := modeltrain[['fitted']]]

  # Generate model diagnostics ----------------------------------------------------------------------------
  diagResults = list()

  # Obtain model description
  diagResults[['Model Description']] = forecast::forecast(modeltrain)[['method']]

  # Plot actual versus fitted
  diagResults[['Actual vs Predicted Train']] = ggplot2::ggplot(data = drought[Split == 'Train']) +
    geom_line(aes(x = Date, y = eval(parse(text = droughtId)), color = 'Actual')) +
    geom_line(aes(x = Date, y = Fitted, color = 'Fitted')) +
    scale_color_manual(values=c("#3DB2FF", "#FF2442")) +
    theme(legend.position="bottom") +
    labs(colour="") +
    ylab(paste0("Actual vs. Predicted ",droughtId)) +
    theme_light() +
    theme(legend.position="top")

  # Obtain performance metrics measures in the training set ---------------------------------
  diagResults[['R2 Score Train']] = drought[Split == 'Train',
                                            MLmetrics::R2_Score(y_pred = Fitted,
                                                                y_true = eval(parse(text = droughtId)))
  ]

  diagResults[['RMSE Score Train']] = drought[Split == 'Train',
                                              MLmetrics::RMSE(y_pred = Fitted,
                                                              y_true = eval(parse(text = droughtId)))
  ]

  # Generate histogram of residuals
  diagResults[['Residuals Plot Train']] = forecast::gghistogram(modeltrain$residuals, add.normal = TRUE) +
    xlab("Residuals") +
    ylab("Count") +
    theme_light()


  # Generate acf plot of residuals
  diagResults[['Residuals ACF Train']] =  forecast::ggAcf(modeltrain$residuals) +
    ggtitle("ACF of Residuals") +
    theme_light()

  # Model diagnostics of residuals
  diagResults[['Residuals Density Train']] =  forecast::autoplot(modeltrain$residuals) +
    ylab("Residuals") + xlab("Date") + theme_light()

  # Evaluate model in the test set -----------------------------------------------------------
  # Index records and start sequentially SPI calculation, model update and forecasts storing
  drought[, id := 1:.N]
  idstart = drought[Split == 'Test', min(id)-1]
  idend   = drought[Split == 'Test', max(id)-1]

  actual = c()
  pred   = c()
  pb = utils::txtProgressBar(min = idstart, max = idend+1, style = 3, width = 100)
  print("Initiating sequential index calculation, model update and prediction")
  for (idx in idstart:c(idend+1)){
    utils::setTxtProgressBar(pb, idx)
    droughtupd = copy(drought[id <= idx])

    nspitest   = ts(data = droughtupd[[droughtId]],
                    start = droughtupd[, min(Date)],
                    frequency = 12
    )
    # Update model
    modeltest  = forecast::Arima(model = modeltrain, y = nspitest)

    # Obtain model forecast
    if (idx < (idend+1))
      pred = c(pred, forecast::forecast(object = modeltest, h = 1)[['mean']][1])

    if (idx > idstart){
      actual = c(actual, utils::tail(nspitest,1))
    }
  }
  close(pb)
  print("Model evaluation in test set complete")

  # Obtain Model Forecasts in the test set
  evaltestset = data.table(Date = drought[Split == 'Test',Date],
                           Index = actual,
                           Fitted = pred
  )
  setnames(evaltestset, "Index", droughtId)

  # Compute model evaluation metrics
  # Obtain performance metrics measures in the training set ---------------------------------
  diagResults[['R2 Score Test']] = evaltestset[, MLmetrics::R2_Score(y_pred = Fitted,
                                                                     y_true = eval(parse(text = droughtId)))
  ]

  diagResults[['RMSE Score Test']] = evaltestset[, MLmetrics::RMSE(y_pred = Fitted,
                                                                   y_true = eval(parse(text = droughtId)))
  ]

  # Plot actual versus fitted
  diagResults[['Actual vs Predicted Test']] = ggplot2::ggplot(data = evaltestset) +
    geom_line(aes(x = Date, y = eval(parse(text = droughtId)), color = 'Actual')) +
    geom_line(aes(x = Date, y = Fitted, color = 'Fitted')) +
    scale_color_manual(values=c("#3DB2FF", "#FF2442")) +
    theme(legend.position="bottom") +
    labs(colour="") +
    ylab(paste0("Actual vs. Predicted ",droughtId)) +
    theme_light() +
    theme(legend.position="top")

  # Generate histogram of residuals
  diagResults[['Residual Plot Test']] =  forecast::gghistogram(modeltest$residuals, add.normal = TRUE) +
    xlab("Residuals") +
    ylab("Count") +
    theme_light()


  # Generate acf plot of residuals
  diagResults[['Residuals ACF Test']] = forecast::ggAcf(modeltest$residuals) +
    ggtitle("ACF of Residuals") +
    theme_light()

  # Model diagnostics of residuals
  diagResults[['Residuals Density Test']] = forecast::autoplot(modeltest$residuals) +
    ylab("Residuals") + xlab("Date") + theme_light()

  return(list("Diagnostics" = diagResults, "Prediction Test Set" = evaltestset, "Model" = modeltrain))
}
