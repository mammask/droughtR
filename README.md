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
#> GAMLSS-RS iteration 1: Global Deviance = 3705.162 
#> GAMLSS-RS iteration 2: Global Deviance = 3704.874 
#> GAMLSS-RS iteration 3: Global Deviance = 3704.872 
#> GAMLSS-RS iteration 4: Global Deviance = 3704.871

# Plot NSPI
plot(drought)
```

<img src="README_figs/README-unnamed-chunk-3-1.png" style="display: block; margin: auto;" />

### Reduced-Bias forecasting framework

#### Data Split

You can simply split the data into train, validation and test using
`oossplit`:

<img src="./README_figs/data split.png" width="400px" style="display: block; margin: auto;" />

``` r
# Split the rainfall series into training validation and test set:
rain = oossplit(x = rain, trainratio = 0.6, validationratio = 0.2, testratio = 0.2)
print(rain)
#>          Date Rainfall Split
#>   1: Jan 1950 9.020967 Train
#>   2: Feb 1950 7.814959 Train
#>   3: Mar 1950 8.027403 Train
#>   4: Apr 1950 5.616300 Train
#>   5: May 1950 8.916673 Train
#>  ---                        
#> 606: Jul 2010 6.601038  Test
#> 607: Aug 2010 6.824187  Test
#> 608: Sep 2010 8.352428  Test
#> 609: Oct 2010 7.650165  Test
#> 610: Nov 2010 7.943304  Test
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
#> GAMLSS-RS iteration 1: Global Deviance = 1892.624 
#> GAMLSS-RS iteration 2: Global Deviance = 1892.624 
#> GAMLSS-RS iteration 1: Global Deviance = 3384.516 
#> GAMLSS-RS iteration 2: Global Deviance = 3384.516
bias
#> $Transitions
#>     Bias Corrected Class Bias Induced Class   N
#>  1:       Moderately Dry     Moderately Dry  18
#>  2:          Near Normal        Near Normal 231
#>  3:       Moderately Wet     Moderately Wet  19
#>  4:       Moderately Wet        Near Normal  15
#>  5:             Very Wet     Moderately Wet  14
#>  6:        Extremely Dry           Very Dry  11
#>  7:             Very Dry           Very Dry   4
#>  8:       Moderately Dry        Near Normal  15
#>  9:             Very Dry     Moderately Dry  12
#> 10:             Very Wet           Very Wet   9
#> 11:        Extremely Dry      Extremely Dry   2
#> 12:        Extremely Wet           Very Wet   1
#> 13:        Extremely Wet      Extremely Wet   3
#> 14:          Near Normal     Moderately Wet   1
#> 
#> $`Impacted Records`
#> [1] "19.44% of records changed drought class"
#> 
#> $Plot
```

<img src="README_figs/README-unnamed-chunk-6-1.png" style="display: block; margin: auto;" />

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
