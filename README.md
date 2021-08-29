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
#> Loading required package: forecast
#> Registered S3 method overwritten by 'quantmod':
#>   method            from
#>   as.zoo.data.frame zoo
#> Loading required package: gamlss
#> Loading required package: splines
#> Loading required package: gamlss.data
#> 
#> Attaching package: 'gamlss.data'
#> The following object is masked from 'package:datasets':
#> 
#>     sleep
#> Loading required package: gamlss.dist
#> Loading required package: MASS
#> Loading required package: nlme
#> 
#> Attaching package: 'nlme'
#> The following object is masked from 'package:forecast':
#> 
#>     getResponse
#> Loading required package: parallel
#>  **********   GAMLSS Version 5.3-4  **********
#> For more on GAMLSS look at https://www.gamlss.com/
#> Type gamlssNews() to see new features/changes/bug fixes.
#> 
#> Attaching package: 'gamlss'
#> The following object is masked from 'package:forecast':
#> 
#>     CV
#> Warning: replacing previous import 'gamlss::CV' by 'forecast::CV' when loading
#> 'droughtr'

# Generate synthetic monthly rainfall data using the Gamma distribution
rain = dummyrainfall(startYear = 1950, endYear = 2010)

# Compute the non-stationary standardized precipitation index (NSPI) for scale 12 using GAMLSS
drought = computenspi(monthlyRainfall = rain, stationaryspi = FALSE, spiScale = 12)
#> GAMLSS-RS iteration 1: Global Deviance = 3489.324 
#> GAMLSS-RS iteration 2: Global Deviance = 3489.324

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
#>   1: Jan 1950 9.372963          NA    NA       NA         NA        NA
#>   2: Feb 1950 8.060669          NA    NA       NA         NA        NA
#>   3: Mar 1950 6.756219          NA    NA       NA         NA        NA
#>   4: Apr 1950 6.349572          NA    NA       NA         NA        NA
#>   5: May 1950 8.143089          NA    NA       NA         NA        NA
#>  ---                                                                  
#> 606: Jul 2010 7.891918    93.28343   595 94.58332 0.04507753 0.3854315
#> 607: Aug 2010 7.468841    91.64829   596 94.57910 0.04507277 0.2483538
#> 608: Sep 2010 9.133362    93.27572   597 94.57489 0.04506802 0.3854603
#> 609: Oct 2010 8.899333    95.50150   598 94.57067 0.04506326 0.5920092
#> 610: Nov 2010 6.380941    92.58544   599 94.56645 0.04505850 0.3252193
#>            NSPI Split
#>   1:         NA  <NA>
#>   2:         NA  <NA>
#>   3:         NA  <NA>
#>   4:         NA  <NA>
#>   5:         NA  <NA>
#>  ---                 
#> 606: -0.2912462  Test
#> 607: -0.6796792  Test
#> 608: -0.2911708  Test
#> 609:  0.2327165  Test
#> 610: -0.4531531  Test
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
#>  1:             Very Wet     Moderately Wet   9
#>  2:             Very Wet           Very Wet  10
#>  3:       Moderately Wet        Near Normal  10
#>  4:       Moderately Wet     Moderately Wet  20
#>  5:          Near Normal        Near Normal 230
#>  6:       Moderately Dry     Moderately Dry  39
#>  7:        Extremely Wet           Very Wet   6
#>  8:        Extremely Wet      Extremely Wet   3
#>  9:             Very Dry           Very Dry  19
#> 10:        Extremely Dry           Very Dry   2
#> 11:        Extremely Dry      Extremely Dry   6
#> 12:       Moderately Dry        Near Normal   1
#> 
#> $`Impacted Records`
#> [1] "7.89% of records changed drought class"
#> 
#> $Plot
```

![](README_figs/README-unnamed-chunk-5-1.png)<!-- -->

#### Bias Corrected auto.arima

In this section, we perform out-of-sample validation using a bias
corrected auto.arima to forecast the Standardized Precipitation Index
(SPI).

``` r
# out-of-sample validation using a bias corrected auto.arima
model = bcoosautoarima(x = rain,
                       trainratio = 0.8,
                       validationratio = 0.0,
                       testratio = 0.2,
                       stationaryspi = TRUE,
                       spiscale = 12,
                       seasonal = FALSE)
#>   |                                                                                                            |                                                                                                    |   0%  |                                                                                                            |=                                                                                                   |   1%  |                                                                                                            |==                                                                                                  |   2%  |                                                                                                            |===                                                                                                 |   3%  |                                                                                                            |====                                                                                                |   4%  |                                                                                                            |=====                                                                                               |   5%  |                                                                                                            |======                                                                                              |   6%  |                                                                                                            |=======                                                                                             |   7%  |                                                                                                            |========                                                                                            |   8%  |                                                                                                            |=========                                                                                           |   9%  |                                                                                                            |==========                                                                                          |  10%  |                                                                                                            |===========                                                                                         |  11%  |                                                                                                            |============                                                                                        |  12%  |                                                                                                            |=============                                                                                       |  13%  |                                                                                                            |==============                                                                                      |  14%  |                                                                                                            |===============                                                                                     |  15%  |                                                                                                            |================                                                                                    |  16%  |                                                                                                            |=================                                                                                   |  17%  |                                                                                                            |==================                                                                                  |  18%  |                                                                                                            |===================                                                                                 |  19%  |                                                                                                            |====================                                                                                |  20%  |                                                                                                            |=====================                                                                               |  21%  |                                                                                                            |======================                                                                              |  22%  |                                                                                                            |=======================                                                                             |  23%  |                                                                                                            |========================                                                                            |  24%  |                                                                                                            |=========================                                                                           |  25%  |                                                                                                            |==========================                                                                          |  26%  |                                                                                                            |===========================                                                                         |  27%  |                                                                                                            |============================                                                                        |  28%  |                                                                                                            |=============================                                                                       |  29%  |                                                                                                            |==============================                                                                      |  30%  |                                                                                                            |===============================                                                                     |  31%  |                                                                                                            |================================                                                                    |  32%  |                                                                                                            |=================================                                                                   |  33%  |                                                                                                            |==================================                                                                  |  34%  |                                                                                                            |===================================                                                                 |  35%  |                                                                                                            |====================================                                                                |  36%  |                                                                                                            |=====================================                                                               |  37%  |                                                                                                            |======================================                                                              |  38%  |                                                                                                            |=======================================                                                             |  39%  |                                                                                                            |========================================                                                            |  40%  |                                                                                                            |=========================================                                                           |  41%  |                                                                                                            |==========================================                                                          |  42%  |                                                                                                            |===========================================                                                         |  43%  |                                                                                                            |============================================                                                        |  44%  |                                                                                                            |=============================================                                                       |  45%  |                                                                                                            |==============================================                                                      |  46%  |                                                                                                            |===============================================                                                     |  47%  |                                                                                                            |================================================                                                    |  48%  |                                                                                                            |=================================================                                                   |  49%  |                                                                                                            |==================================================                                                  |  50%  |                                                                                                            |===================================================                                                 |  51%  |                                                                                                            |====================================================                                                |  52%  |                                                                                                            |=====================================================                                               |  53%  |                                                                                                            |======================================================                                              |  54%  |                                                                                                            |=======================================================                                             |  55%  |                                                                                                            |========================================================                                            |  56%  |                                                                                                            |=========================================================                                           |  57%  |                                                                                                            |==========================================================                                          |  58%  |                                                                                                            |===========================================================                                         |  59%  |                                                                                                            |============================================================                                        |  60%  |                                                                                                            |=============================================================                                       |  61%  |                                                                                                            |==============================================================                                      |  62%  |                                                                                                            |===============================================================                                     |  63%  |                                                                                                            |================================================================                                    |  64%  |                                                                                                            |=================================================================                                   |  65%  |                                                                                                            |==================================================================                                  |  66%  |                                                                                                            |===================================================================                                 |  67%  |                                                                                                            |====================================================================                                |  68%  |                                                                                                            |=====================================================================                               |  69%  |                                                                                                            |======================================================================                              |  70%  |                                                                                                            |=======================================================================                             |  71%  |                                                                                                            |========================================================================                            |  72%  |                                                                                                            |=========================================================================                           |  73%  |                                                                                                            |==========================================================================                          |  74%  |                                                                                                            |===========================================================================                         |  75%  |                                                                                                            |============================================================================                        |  76%  |                                                                                                            |=============================================================================                       |  77%  |                                                                                                            |==============================================================================                      |  78%  |                                                                                                            |===============================================================================                     |  79%  |                                                                                                            |================================================================================                    |  80%  |                                                                                                            |=================================================================================                   |  81%  |                                                                                                            |==================================================================================                  |  82%  |                                                                                                            |===================================================================================                 |  83%  |                                                                                                            |====================================================================================                |  84%  |                                                                                                            |=====================================================================================               |  85%  |                                                                                                            |======================================================================================              |  86%  |                                                                                                            |=======================================================================================             |  87%  |                                                                                                            |========================================================================================            |  88%  |                                                                                                            |=========================================================================================           |  89%  |                                                                                                            |==========================================================================================          |  90%  |                                                                                                            |===========================================================================================         |  91%  |                                                                                                            |============================================================================================        |  92%  |                                                                                                            |=============================================================================================       |  93%  |                                                                                                            |==============================================================================================      |  94%  |                                                                                                            |===============================================================================================     |  95%  |                                                                                                            |================================================================================================    |  96%  |                                                                                                            |=================================================================================================   |  97%  |                                                                                                            |==================================================================================================  |  98%  |                                                                                                            |=================================================================================================== |  99%  |                                                                                                            |====================================================================================================| 100%
```

The model returns a set of diagnostics and analytical outcomes,
including the model description, diagnostics plots and actual
vs. predicted forecasts.

``` r
# Return the model description
model[['Diagnostics']][['Model Description']]
#> [1] "ARIMA(2,0,2)(2,0,0)[12] with non-zero mean"
```

Actual vs. predicted SPI in the test set

``` r
model[['Diagnostics']][['Actual vs Predicted Test']]
```

![](README_figs/README-unnamed-chunk-8-1.png)<!-- -->

Additional models are developed and can be found here:

-   Bias corrected modwt auto.arima
-   Bias corrected Support Vector Regression
-   Bias corrected modwt support vector regression
