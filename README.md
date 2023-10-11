droughtR
================

<img src="https://raw.githubusercontent.com/mammask/droughtr/main/man/figures/droughtR.png" align = "right" width = 120/>

droughtR is an R for package that enables drought monitoring. It computes the Standardized Precipitation Index (SPI) and
the Non-Standardized Precipitation Index (NSPI) using General Additive
Models for Location Scale and Shape (GAMLSS). It enables the generation
of drought forecasts for univariate time series and deals with the bias
introduced to drought forecasting applications when SPI and NSPI are
calculated incorrectly during out-of-sample (OOS) validation.

## Installation

``` r
# Install the development version on Github
devtools::install_github("mammask/droughtR")
```

## Usage

### Generate SPI and NSPI

``` r
# Load droughtr library
library(droughtR)
#> Warning: package 'droughtR' was built under R version 4.1.1
#> Registered S3 method overwritten by 'quantmod':
#>   method            from
#>   as.zoo.data.frame zoo

# Generate synthetic monthly rainfall data using the Gamma distribution
rain = dummyrainfall(startYear = 1950, endYear = 2010)

# Compute the non-stationary standardized precipitation index (NSPI) for scale 12 using GAMLSS
drought = computenspi(monthlyRainfall = rain, stationaryspi = FALSE, spiScale = 12)
#> GAMLSS-RS iteration 1: Global Deviance = 3332.032 
#> GAMLSS-RS iteration 2: Global Deviance = 3332.024 
#> GAMLSS-RS iteration 3: Global Deviance = 3332.024

# Plot NSPI
plot(drought)
```

![](README_figs/README-unnamed-chunk-3-1.png)<!-- -->

### Reduced-Bias forecasting framework

#### Data Split

Split the rainfall series into training validation and test set:

``` r
rain = oossplit(x = rain, trainratio = 0.6, validationratio = 0.2, testratio = 0.2)
print(rain)
#>          Date Rainfall AccumPrecip Trend       mu      sigma      ecdfm
#>   1: Jan 1950 7.169193          NA    NA       NA         NA         NA
#>   2: Feb 1950 7.385852          NA    NA       NA         NA         NA
#>   3: Mar 1950 7.267958          NA    NA       NA         NA         NA
#>   4: Apr 1950 7.063678          NA    NA       NA         NA         NA
#>   5: May 1950 9.926310          NA    NA       NA         NA         NA
#>  ---                                                                   
#> 606: Jul 2010 6.319853    94.97598   595 96.14484 0.04308050 0.39397432
#> 607: Aug 2010 6.375332    93.32642   596 96.14188 0.04309033 0.25080640
#> 608: Sep 2010 6.293398    92.04507   597 96.13891 0.04310017 0.16158741
#> 609: Oct 2010 6.792034    89.09337   598 96.13595 0.04311001 0.04197682
#> 610: Nov 2010 7.124064    89.28355   599 96.13298 0.04311985 0.04658958
#>            NSPI Split
#>   1:         NA  <NA>
#>   2:         NA  <NA>
#>   3:         NA  <NA>
#>   4:         NA  <NA>
#>   5:         NA  <NA>
#>  ---                 
#> 606: -0.2689754  Test
#> 607: -0.6719543  Test
#> 608: -0.9879547  Test
#> 609: -1.7281929  Test
#> 610: -1.6788609  Test
```

#### Bias measurement

When the Standardized Precipitation Index is calculated as part of a
forecasting task it can potentially introduce biases in the training
data. This is mainly because in many cases the index is computed using
the entire data, prior to model validation, and this violates some of
the fundamental principles of time series forecasting theory.

In this section, we compute the amount of bias introduced to the
training set by measuring the number of miss-classifications in the
training data. Two computational approaches are presented: 1) SPI is
computed using the training data only; we call this as “Bias Corrected”
computation and 2) SPI is computed using the entire data; we call this
as “Bias Induced” computation.

We measure bias by computing the number of miss-classifications in the
training set due to the incorrect computation of the index. We also
measure the number of records impacted and share a plot of the two
computational approaches.

``` r
# Generate synthetic monthly rainfall data using the Gamma distribution
rain = dummyrainfall(startYear = 1950, endYear = 2010)

# Compute bias
bias = measurebias(x = rain, trainratio = 0.6, validationratio = 0.2, testratio = 0.2, stationaryspi = TRUE, spiscale = 12)
bias
#> $Transitions
#>     Bias Corrected Class Bias Induced Class   N
#>  1:          Near Normal        Near Normal 239
#>  2:          Near Normal     Moderately Dry  13
#>  3:       Moderately Dry     Moderately Dry  26
#>  4:             Very Dry           Very Dry  12
#>  5:        Extremely Dry      Extremely Dry  10
#>  6:       Moderately Dry           Very Dry   3
#>  7:       Moderately Wet     Moderately Wet  13
#>  8:        Extremely Wet      Extremely Wet  14
#>  9:       Moderately Wet        Near Normal  14
#> 10:             Very Wet     Moderately Wet   7
#> 11:        Extremely Wet           Very Wet   2
#> 12:             Very Wet           Very Wet   2
#> 
#> $`Impacted Records`
#> [1] "10.99% of records changed drought class"
#> 
#> $Plot
```

![](README_figs/README-unnamed-chunk-5-1.png)<!-- -->

