---
title: 'droughtR: An R package for estimating non-stationary meteorological droughts'
tags:
  - R
  - SPI
  - drought
  - environment
  - GAMLSS
authors:
  - name: Konstantinos Mammas
    orcid: 0000-0003-4972-1709
    equal-contrib: true
    affiliation: 1
affiliations:
 - name: University of the Aegean, Department of Environment, Greece
   index: 1
bibliography: references.bib
---

<img src="https://raw.githubusercontent.com/mammask/droughtR/main/man/figures/droughtR-2.png" align = "left" width = 160/>

<br><br><br><br><br><br><br><br><br>

### Summary

`droughtR` is a free open-source software provided as an R package that enables to compute a model-based non-stationary meteorological drought index (NSPI) using the GAMLSS framework. It includes multiple features such as:

1. The computation of a model-based meteorological drought index that incorporates the trend of accumulated precipitation at different time scales
2. Visualization support of the stationary and non-stationary meteorological drought indices
3. Comparison between model-based drought indices using statistical measures

### Statement of need

The standardized precipitation index (SPI) [@McKee1993], is a very well known drought index that defines and monitors meteorological drought events. The computation of SPI involves fitting a probability distribution function on accumulated rainfall series at different time scales (e.g., 3 month accumulation), with Gamma distribution being the most popular as it is simple and can very well describe the accumulated precipitation [@guenang2014computation; @wang2019assessment]. Positive SPI values indicate wet conditions with greater than the median precipitation, while negative SPI values indicate dry conditions with lower than the median precipitation.

In a changing climate where precipitation exhibits non-stationarity, traditional SPI calculation involves fitting the accumulated precipitation to a time-invariant probability density function, resulting to a trending SPI series that reflects the trend of accumulated precipitation [@shiau2020effects]. To avoid this limitation, different versions of a non-stationary standardized precipitation index (NSPI) have been proposed using a time-varying probability density function that models precipitation under climate change.  @wang2015time, developed a time-dependent SPI by fitting generalized additive models in location, scale, and shape (GAMLSS) [@stasinopoulos2007generalized] to monitor regional droughts during the summer period in the Luanhe River basin in China. Also, @mammas2021characterization computed, both, SPI and NSPI in 36.500 basins in Sweden and showed the limitations of SPI during out-of-sample validation in time series forecasting. Across studies, results suggest that under non-stationarity in precipitation, the use of the traditional SPI does not lead to accurate drought classification.

Some dedicated tools for monitoring SPI already exist: `spi` is an R package that computes SPI at different time scales [@neves2011package]. `SPEI` package is an additional R package that computes SPI and the standardized precipitation evapotranspiration index (SPEI) using various distributions, including, 'log-Logistic', 'Gamma' and 'PearsonIII'  [@begueria2017package]. In Python, `climate-indices` is a library that implements various climate index algorithms which provide a geographical and temporal picture of the severity of precipitation and temperature anomalies useful for climate monitoring and research [@climate_indices]. 

Although the aforementioned packages provide  great flexibility to compute SPI under stationarity, they are unable to characterize meteorological droughts efficiently in non-stationary environments. `droughtR` solves this limitation as it enables users with limited coding skills to compute NSPI at different time scales and make direct comparison with the stationary version of SPI. It computes NSPI using a very well known R package called, `GAMLSS`, that estimates the time-varying *location* and *scale* distribution parameters of various distributions, such as Gamma, Zero Inflated Gamma, Normal and Weibull, as a function of the increasing trend of accumulated precipitation. `droughtR` is available on [https://github.com/mammask/droughtR](https://github.com/mammask/droughtR) and can be downloaded through the R library `devtools`.

`droughtR` is designed to be used by hydrologists, environmentalists, researchers and data scientists that work with environmental data. It offers a simplistic coding interface that generates inputs for drought monitoring and drought forecasting applications. 

### Features

#### Computation of Stationary and Non-Stationary SPI

The main use of `droughtR` is for characterizing and monitoring meteorological drought events under stationary and non-stationary scenarios. In the following example, `droughtR` is used to generate a synthetic rainfall series and compute NSPI:

```{r}
# Load droughtR library
library(droughtR)

# Generate synthetic monthly rainfall data using the Gamma distribution
rain = dummyrainfall(startYear = 1950, endYear = 2010)

# Compute the non-stationary standardized precipitation index (NSPI) for scale 12 using GAMLSS
spi = computenspi(x = rain, stationaryspi = FALSE, spiScale = 12, dist = 'gamma')

# Plot NSPI
plot(spi)
```

![](../README_figs/README-unnamed-chunk-3-1.png){style="display: block; margin: 0 auto"}

Equivalently, the stationary version of SPI is computed as follows:

```{r}
# calculate NSPI
spi = computenspi(monthlyRainfall = rain, stationaryspi = TRUE, spiScale = 12)

# plot results
plot(spi)
```

![](../README_figs/README-unnamed-chunk-4-1.png){style="display: block; margin: 0 auto"}


#### Visualize drought events over time

The classification of drought events can be visualized over time:

```{r}
# Build a graph with drought events over time
indexClass = computeclass(mIndex)

plot(indexClass)
```
![](../README_figs/README-unnamed-chunk-5-1.png){style="display: block; margin: 0 auto"}


### References
