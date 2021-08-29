#' bcautoarimapred
#'
#' Fits or updates a forecast::autoarima model and predicts the next observation(s)
#'
#' @param x A data.table with two columns (Date, Rainfall)
#' @param model If NULL a new model is built, else a forecast::Arima model object is trained
#' @param stationaryspi Logical when TRUE SPI is calculated; when FALSE NSPI is calculated
#' @param spiscale Numeric value that reflects the scale of the index
#' @param timesteps Number of periods for forecasting
#' @param ... Additional arguments that relate to the inputs of forecast::auto.arima
#' @import data.table forecast zoo
#' @return numeric value with model predictions
#' @export
#'
#' @examples x = dummyrainfall(start = 1950, end = 2020)
#' bcautoarimapred(x, NULL, TRUE, 12, 1, seasonal = FALSE)
bcautoarimapred = function(x, model, stationaryspi, spiscale, timesteps, ...){

  if (stationaryspi == TRUE){
    droughtId = 'SPI'
  } else {
    droughtId = 'NSPI'
  }

  if (!"Rainfall" %in% names(x)){
    stop("x should contain a numeric column named as Rainfall")
  }

  # Convert x to data.table
  setDT(x)

  # Compute (N)SPI
  print("Calculating the drought index")
  drought = computenspi(x, stationaryspi, spiscale)
  drought = drought[complete.cases(drought)]

  # Transform (N)SPI into a ts object
  nspitrain = ts(data = drought[[droughtId]],
                 start = drought[, min(Date)],
                 frequency = 12
  )

  # Update an existing model or train a new model from scratch
  if (!is.null(model)){
    print("Updating existing Arima model")
    model = forecast::Arima(model = model, y = nspitrain)
  } else {
    print("Fitting a new Arima model")
    model = forecast::auto.arima(y = nspitrain, ...)
  }
  # Forecast the next observation
  pred = forecast::forecast(object = model, h = timesteps)[['mean']][1:timesteps]

  return(pred)
}
