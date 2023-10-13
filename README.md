droughtR
================

[![DOI](https://zenodo.org/badge/398032827.svg)](https://zenodo.org/badge/latestdoi/398032827)

<img src="https://raw.githubusercontent.com/mammask/droughtr/main/man/figures/droughtR.png" align = "right" width = 120/>

The goal of `droughtR` is to enable meteorological drought monitoring by
generating non-stationary drought indices under various distributional
assumptions (Normal, Gamma, Zero Inflated Gamma and Weibull). It
computes the stationary (SPI) and the non-stationary (NSPI) Standardized
Precipitation Indices using General Additive Models for Location Scale
and Shape (GAMLSS).

<!-- Since drought indices are mainly used in forecasting applications, `droughtR` computes potential biases introduced during the model building process due to incorrect computation of the index. -->

## Installation

``` r
# Install the development version on Github
devtools::install_github("mammask/droughtR")
```

## Usage

### Generate SPI and NSPI

The function `computenspi` creates stationary and non-stationary
meteorological drought indices at different time scales. By default,
droughtR uses the gamma distribution:

``` r
# Load droughtR library
library(droughtR)
#> Registered S3 method overwritten by 'quantmod':
#>   method            from
#>   as.zoo.data.frame zoo

# Generate synthetic monthly rainfall data using the Gamma distribution
rain = dummyrainfall(startYear = 1950, endYear = 2010)

# Compute the non-stationary standardized precipitation index (NSPI) for scale 12 using GAMLSS
drought = computenspi(x = rain, stationaryspi = FALSE, spiScale = 12, dist = 'gamma')
#> GAMLSS-RS iteration 1: Global Deviance = 3310.748 
#> GAMLSS-RS iteration 2: Global Deviance = 3310.49 
#> GAMLSS-RS iteration 3: Global Deviance = 3310.49

# Plot NSPI
plot(drought)
```

<img src="README_figs/README-unnamed-chunk-3-1.png" style="display: block; margin: auto;" />

#### Model-Based Comparison of Drought Indices

Using droughtR, we can compute indices under various distribution
assumptions and then compare their fit according to how well they
describe the data. In the following example, we generated synthetic
rainfall data using the gamma distribution and then we created two
non-stationary drought indices using the gamma and weibull distributions
accordingly.

``` r
# Generate a synthetic rainfall dataset
rainfall = dummyrainfall(startYear = 1950, endYear = 2023)

# Create a non-stationary meteorological index under the gamma distribution assumption
gammaIndex = computenspi(x = rainfall, stationaryspi = FALSE, spiScale = 12, dist = 'gamma')[["model"]]
#> GAMLSS-RS iteration 1: Global Deviance = 4220.338 
#> GAMLSS-RS iteration 2: Global Deviance = 4219.897 
#> GAMLSS-RS iteration 3: Global Deviance = 4219.894 
#> GAMLSS-RS iteration 4: Global Deviance = 4219.894

# Plot the model diagnostics 
plot(gammaIndex)
```

<img src="README_figs/README-unnamed-chunk-4-1.png" style="display: block; margin: auto;" />

    #> ******************************************************************
    #>        Summary of the Quantile Residuals
    #>                            mean   =  0.0004645257 
    #>                        variance   =  1.001428 
    #>                coef. of skewness  =  -0.3648898 
    #>                coef. of kurtosis  =  2.836916 
    #> Filliben correlation coefficient  =  0.9942522 
    #> ******************************************************************

    # Create a non-stationary meteorological index under the weibull distribution assumption
    weibullIndex = computenspi(x = rainfall, stationaryspi = FALSE, spiScale = 12, dist = 'weibull')$model
    #> GAMLSS-RS iteration 1: Global Deviance = 4228.044 
    #> GAMLSS-RS iteration 2: Global Deviance = 4225.758 
    #> GAMLSS-RS iteration 3: Global Deviance = 4225.714 
    #> GAMLSS-RS iteration 4: Global Deviance = 4225.712 
    #> GAMLSS-RS iteration 5: Global Deviance = 4225.712

    plot(weibullIndex)

<img src="README_figs/README-unnamed-chunk-4-2.png" style="display: block; margin: auto;" />

    #> ******************************************************************
    #>        Summary of the Quantile Residuals
    #>                            mean   =  0.005663939 
    #>                        variance   =  0.9404692 
    #>                coef. of skewness  =  0.4193841 
    #>                coef. of kurtosis  =  2.961977 
    #> Filliben correlation coefficient  =  0.9932369 
    #> ******************************************************************

As presented in the diagnostic charts, the Normal Q-Q plot of the GAMLSS
model residuals suggest that the non-stationary index under the gamma
distribution has a better fit.

In this example, `GAIC()` is used to compare the two model-based drought
indices using the AIC:

``` r
library(gamlss)
#> Loading required package: splines
#> Loading required package: gamlss.data
#> 
#> Attaching package: 'gamlss.data'
#> The following object is masked from 'package:datasets':
#> 
#>     sleep
#> Loading required package: gamlss.dist
#> Loading required package: nlme
#> Loading required package: parallel
#>  **********   GAMLSS Version 5.4-20  **********
#> For more on GAMLSS look at https://www.gamlss.com/
#> Type gamlssNews() to see new features/changes/bug fixes.

# Compare the two model based implementations using AIC
GAIC(gammaIndex, weibullIndex)
#>              df      AIC
#> gammaIndex    4 4227.894
#> weibullIndex  4 4233.712
```

#### Data Split

The `oossplit` function splits the data into train, validation and test
sets:

``` r
# Split the rainfall series into training validation and test set:
rain = oossplit(x = rain, trainratio = 0.6, validationratio = 0.2, testratio = 0.2)
print(rain)
#>          Date Rainfall Split
#>   1: Jan 1950 9.138443 Train
#>   2: Feb 1950 7.098604 Train
#>   3: Mar 1950 9.025275 Train
#>   4: Apr 1950 6.285809 Train
#>   5: May 1950 9.120874 Train
#>  ---                        
#> 606: Jul 2010 8.220249  Test
#> 607: Aug 2010 7.782283  Test
#> 608: Sep 2010 7.153345  Test
#> 609: Oct 2010 8.361481  Test
#> 610: Nov 2010 7.915945  Test
```

#### Bias measurement

When the Standardized Precipitation Index is calculated as part of a
forecasting task it introduces biases in the training data. This is
mainly observed when the index is computed using the entire data, prior
to model validation, and this violates some of the fundamental
principles of time series forecasting theory ([Mammas and Lekkas
2021](#ref-mammas2021characterization)).

In this section, the amount of bias introduced to the training data is
quantified by measuring the number of miss-classifications when two
computational approaches are followed: 1) SPI is computed using the
training data only; this is called a “Bias Corrected” computation and 2)
SPI is computed using the entire data; this is called a “Bias Induced”
computation.

Bias is measured by computing the number of miss-classifications in the
training data due to the incorrect computation of the index.

``` r
# Generate synthetic monthly rainfall data using the Gamma distribution
rain = dummyrainfall(startYear = 1950, endYear = 2010)

# Compute bias
bias = measurebias(x = rain, trainratio = 0.6, validationratio = 0.2, testratio = 0.2, stationaryspi = TRUE, spiscale = 12, dist = 'normal')
#> GAMLSS-RS iteration 1: Global Deviance = 2100.173 
#> GAMLSS-RS iteration 2: Global Deviance = 2100.173 
#> GAMLSS-RS iteration 1: Global Deviance = 3511.566 
#> GAMLSS-RS iteration 2: Global Deviance = 3511.566
bias
#> $Transitions
#>    Bias Corrected Class Bias Induced Class   N
#> 1:          Near Normal        Near Normal 238
#> 2:       Moderately Dry     Moderately Dry  26
#> 3:             Very Dry           Very Dry  19
#> 4:             Very Wet           Very Wet  19
#> 5:       Moderately Wet     Moderately Wet  24
#> 6:        Extremely Dry      Extremely Dry   6
#> 7:          Near Normal     Moderately Wet   4
#> 8:       Moderately Wet           Very Wet   5
#> 9:        Extremely Wet      Extremely Wet  14
#> 
#> $`Impacted Records`
#> [1] "2.54% of records changed drought class"
#> 
#> $Plot
```

<img src="README_figs/README-unnamed-chunk-7-1.png" style="display: block; margin: auto;" />

### References

<!-- #### Bias Corrected auto.arima -->
<!-- In this section, we perform out-of-sample validation using a bias corrected auto.arima to forecast the Standardized Precipitation Index (SPI). An additional parameter is introduced to forecast::auto.arima and requires fitting a S-ARIMA model: -->
<!-- ```{r, eval=TRUE, fig.height=3, fig.width=5} -->
<!-- # out-of-sample validation using a bias corrected auto.arima -->
<!-- model = bcautoarima(x = rain, -->
<!--                     trainratio = 0.8, -->
<!--                     validationratio = 0.0, -->
<!--                     testratio = 0.2, -->
<!--                     stationaryspi = TRUE, -->
<!--                     spiscale = 12, -->
<!--                     seasonal = TRUE) -->
<!-- ``` -->
<!-- The model returns a set of diagnostics and analytical outcomes, including the model description, diagnostics plots and actual vs. predicted forecasts: -->
<!-- ```{r, eval=TRUE, fig.height=3, fig.width=5, echo = TRUE} -->
<!-- # Return the model description -->
<!-- model[['Diagnostics']][['Model Description']] -->
<!-- # Return R2 score in the test set -->
<!-- model[['Diagnostics']][['R2 Score Test']] -->
<!-- ``` -->
<!-- Actual vs. predicted SPI in the test set: -->
<!-- ```{r, eval=TRUE, fig.height=3, fig.width=5, echo = TRUE} -->
<!-- model[['Diagnostics']][['Actual vs Predicted Test']] -->
<!-- ``` -->
<!-- Additional models are developed and can be found here: -->
<!-- * Bias induced auto.arima -->
<!-- * Bias corrected modwt auto.arima -->

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-mammas2021characterization" class="csl-entry">

Mammas, Konstantinos, and Demetris F Lekkas. 2021. “Characterization of
Bias During Meteorological Drought Calculation in Time Series
Out-of-Sample Validation.” *Water* 13 (18): 2531.

</div>

</div>
