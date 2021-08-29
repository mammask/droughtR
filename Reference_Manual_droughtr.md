<!-- toc -->

August 29, 2021

# DESCRIPTION

```
Package: droughtr
Title: Reduced Bias Drought Forecasting Framework
Version: 0.0.1
Authors@R: 
    person(given = "Konstantinos",
           family = "Mammas",
           role = c("aut", "cre"),
           email = "mammas_k@live.com",
           comment = c(ORCID = "0000-0003-4972-1709"))
Description: This package reduces the bias due to incorrect calculation of the Standardized Precipitation Index (SPI) in drought forecasting applications.
License: MIT + file LICENSE
Encoding: UTF-8
LazyData: true
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.1.1
Imports:
    data.table,
    zoo,
    gamlss.dist,
    SPEI,
    ggplot2,
    MLmetrics
Depends:
    forecast,
    gamlss
Suggests: 
    testthat (>= 3.0.0)
Config/testthat/edition: 3```


# `bcautoarimapred`

bcautoarimapred


## Description

Fits or updates a forecast::autoarima model and predicts the next observation(s)


## Usage

```r
bcautoarimapred(x, model, stationaryspi, spiscale, timesteps, ...)
```


## Arguments

Argument      |Description
------------- |----------------
`x`     |     A data.table with two columns (Date, Rainfall)
`model`     |     If NULL a new model is built, else a forecast::Arima model object is trained
`stationaryspi`     |     Logical when TRUE SPI is calculated; when FALSE NSPI is calculated
`spiscale`     |     Numeric value that reflects the scale of the index
`timesteps`     |     Number of periods for forecasting
`...`     |     Additional arguments that relate to the inputs of forecast::auto.arima


## Value

numeric value with model predictions


## Examples

```r
x = dummyrainfall(start = 1950, end = 2020)
bcautoarimapred(x, NULL, TRUE, 12, 1, seasonal = FALSE)
```


# `bcoosautoarima`

bcoosautoarima


## Description

Fits a bias-corrected auto.arima to forecast the standardized precipitation index


## Usage

```r
bcoosautoarima(
  x,
  trainratio,
  validationratio = 0,
  testratio,
  stationaryspi,
  spiscale,
  ...
)
```


## Arguments

Argument      |Description
------------- |----------------
`x`     |     data.table
`trainratio`     |     Numeric value represents the proportion of the training set
`validationratio`     |     Numeric value represents the proportion of the validation set
`testratio`     |     Numeric value represents the proportion of the test set
`stationaryspi`     |     Logical when TRUE SPI is calculated; when FALSE NSPI is calculated
`spiscale`     |     Numeric value that reflects the scale of the index
`...`     |     Additional arguments that relate to the inputs of forecast::auto.arima


## Value

list with evaluation metrics and diagnostic plots


## Examples

```r
x = dummyrainfall(start = 1950, end = 2020)
bcoosautoarima(x, 0.8, 0, 0.2, TRUE, 12, seasonal = FALSE)
```


# `computenspi`

computenspi


## Description

Computes the stationary and non-stationary version of the Standardized Precipitation Index.
 The non-stationary version uses GAMLSS and models the parameters of a Gamma distribution
 by incorporating the trend of accumulated precipitation.


## Usage

```r
computenspi(monthlyRainfall, stationaryspi, spiScale)
```


## Arguments

Argument      |Description
------------- |----------------
`monthlyRainfall`     |     data.table
`stationaryspi`     |     logical
`spiScale`     |     numeric


## Value

data.table


## Examples

```r
computenspi(monthlyRainfall = dummyrainfall(1950, 2000), stationaryspi = TRUE, spiScale = 12)
```


# `droughtclass`

droughtclass


## Description

Assigns classes to various ranges of the standardized precipitation index (SPI)


## Usage

```r
droughtclass(x)
```


## Arguments

Argument      |Description
------------- |----------------
`x`     |     numeric


## Value

numeric


## Examples

```r
droughtclass(1.5)
```


# `dummyrainfall`

Generate synthetic monthly rainfall data


## Description

Create a data.table with synthetic rainfall data generated from a Gamma distribution


## Usage

```r
dummyrainfall(startYear, endYear)
```


## Arguments

Argument      |Description
------------- |----------------
`startYear`     |     numeric
`endYear`     |     numeric


## Value

data.table


## Examples

```r
dummyrainfall(1950, 2021)
```


