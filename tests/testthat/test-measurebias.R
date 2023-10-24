test_that("check measurebias", {
  rainfall = dummyrainfall(1950, 2000)
  mbias = measurebias(rainfall, 0.6, 0.2, 0.2, TRUE, 12, "normal")

  if (inherits(mbias, 'list')){
    succeed()
  } else {
    fail('object class should be list')
  }

  if (nrow(mbias[['Transitions']]) != 0){
    succeed()
  } else {
    fail('no transitions have been')
  }

})
