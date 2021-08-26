droughtR
================

<img src="https://raw.githubusercontent.com/mammask/droughtr/main/man/figures/droughtR.png" align = "right" width = 120/>

droughtR is an R for package that enables drought monitoring and drought
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
#> GAMLSS-RS iteration 1: Global Deviance = 3356.335 
#> GAMLSS-RS iteration 2: Global Deviance = 3356.316 
#> GAMLSS-RS iteration 3: Global Deviance = 3356.316

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
#>          Date Rainfall AccumPrecip Trend       mu      sigma     ecdfm
#>   1: Jan 1950 8.606435          NA    NA       NA         NA        NA
#>   2: Feb 1950 7.007302          NA    NA       NA         NA        NA
#>   3: Mar 1950 7.553642          NA    NA       NA         NA        NA
#>   4: Apr 1950 8.688838          NA    NA       NA         NA        NA
#>   5: May 1950 8.791670          NA    NA       NA         NA        NA
#>  ---                                                                  
#> 606: Jul 2010 7.793293   102.33008   595 95.42024 0.04463164 0.9451676
#> 607: Aug 2010 7.637143   100.08056   596 95.41565 0.04464373 0.8627134
#> 608: Sep 2010 6.864667    98.78185   597 95.41107 0.04465583 0.7872322
#> 609: Oct 2010 8.133400    98.75750   598 95.40648 0.04466792 0.7858641
#> 610: Nov 2010 9.913634    99.91013   599 95.40190 0.04468003 0.8545747
#>           NSPI Split
#>   1:        NA  <NA>
#>   2:        NA  <NA>
#>   3:        NA  <NA>
#>   4:        NA  <NA>
#>   5:        NA  <NA>
#>  ---                
#> 606: 1.5997014  Test
#> 607: 1.0925915  Test
#> 608: 0.7968544  Test
#> 609: 0.7921525  Test
#> 610: 1.0562575  Test
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
bias = measurebias(x = rain, trainratio = 0.6, validationratio = 0.2, testratio = 0.2, stationary = TRUE, spiscale = 12)
bias
#> $Transitions
#>     Bias Corrected Class Bias Induced Class   N
#>  1:          Near Normal        Near Normal 218
#>  2:       Moderately Dry     Moderately Dry  15
#>  3:       Moderately Dry        Near Normal  17
#>  4:             Very Dry     Moderately Dry  12
#>  5:        Extremely Dry           Very Dry   9
#>  6:          Near Normal     Moderately Wet  17
#>  7:        Extremely Wet      Extremely Wet   7
#>  8:             Very Wet           Very Wet  20
#>  9:       Moderately Wet     Moderately Wet  26
#> 10:       Moderately Wet           Very Wet   6
#> 11:             Very Wet      Extremely Wet   3
#> 12:             Very Dry           Very Dry   2
#> 13:        Extremely Dry      Extremely Dry   3
#> 
#> $`Impacted Records`
#> [1] "18.03% of records changed drought class"
#> 
#> $Plot
```

![](README_figs/README-unnamed-chunk-5-1.png)<!-- -->
