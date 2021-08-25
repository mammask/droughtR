droughtr
================

## Overview

droughtr is an R for package that enables drought monitoring and drought
forecasting. It computes the Standardized Precipitation Index (SPI) and
the Non-Standardized Precipitation Index (NSPI) using General Additive
Models for Location Scale and Shape (GAMLSS). It enables the generation
of drought forecasts for univariate time series and deals with the bias
introduced to drought forecasting applications when SPI and NSPI are
calculated incorrectly during out-of-sample (OOS) validation.

## Installation

``` r
# Install the development version on Github
devtools::install_github("mammask/droughtr")
```

## Usage

### Generate SPI and NSPI

``` r
# Load droughtr library
library(droughtr)

# Generate synthetic monthly rainfall data using the Gamma distribution
rain = dummyrainfall(startYear = 1950, endYear = 2010)

# Compute the non-stationary standardized precipitation index (NSPI) for scale 12 using GAMLSS
drought = computenspi(monthlyRainfall = rain, stationary = FALSE, spiScale = 12)
```

    ## GAMLSS-RS iteration 1: Global Deviance = 3490.23 
    ## GAMLSS-RS iteration 2: Global Deviance = 3489.835 
    ## GAMLSS-RS iteration 3: Global Deviance = 3489.835

``` r
# Plot NSPI
plot(drought)
```

![](README_figs/README-unnamed-chunk-3-1.png)<!-- -->

### Reduced-Bias forecasting framework

#### Data Split

Split the rainfall series into training validation and test set.

``` r
rain = oossplit(x = rain, trainratio = 0.6, validationratio = 0.2, testratio = 0.2)
print(rain)
```

    ##          Date  Rainfall AccumPrecip Trend       mu      sigma     ecdfm
    ##   1: Jan 1950  6.965374          NA    NA       NA         NA        NA
    ##   2: Feb 1950  8.866148          NA    NA       NA         NA        NA
    ##   3: Mar 1950  6.760097          NA    NA       NA         NA        NA
    ##   4: Apr 1950  9.586144          NA    NA       NA         NA        NA
    ##   5: May 1950 10.345658          NA    NA       NA         NA        NA
    ##  ---                                                                   
    ## 606: Jul 2010  8.310440    94.50662   595 96.78736 0.05924498 0.3515557
    ## 607: Aug 2010  8.015038    94.49980   596 96.78874 0.05929471 0.3511495
    ## 608: Sep 2010  9.802627    96.69054   597 96.79013 0.05934449 0.5009733
    ## 609: Oct 2010  6.603372    95.78891   598 96.79152 0.05939430 0.4383357
    ## 610: Nov 2010  5.848476    94.46632   599 96.79291 0.05944416 0.3490868
    ##              NSPI Split
    ##   1:           NA  <NA>
    ##   2:           NA  <NA>
    ##   3:           NA  <NA>
    ##   4:           NA  <NA>
    ##   5:           NA  <NA>
    ##  ---                   
    ## 606: -0.381123905  Test
    ## 607: -0.382218831  Test
    ## 608:  0.002439664  Test
    ## 609: -0.155190163  Test
    ## 610: -0.387787221  Test

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
bias = measurebias(x = rain, trainratio = 0.6, validationratio = 0.2, testratio = 0.2, stationary = TRUE, spiscale = 12)
bias
```

    ## $Transitions
    ##     Bias Corrected Class Bias Induced Class   N
    ##  1:       Moderately Wet        Near Normal   7
    ##  2:       Moderately Wet     Moderately Wet  38
    ##  3:             Very Wet     Moderately Wet  12
    ##  4:             Very Wet           Very Wet  12
    ##  5:        Extremely Wet           Very Wet   2
    ##  6:          Near Normal        Near Normal 219
    ##  7:       Moderately Dry     Moderately Dry  39
    ##  8:             Very Dry           Very Dry  13
    ##  9:       Moderately Dry        Near Normal   5
    ## 10:             Very Dry     Moderately Dry   3
    ## 11:        Extremely Dry      Extremely Dry   5
    ## 
    ## $`Impacted Records`
    ## [1] "8.17% of records changed drought class"
    ## 
    ## $Plot

![](README_figs/README-unnamed-chunk-5-1.png)<!-- -->
