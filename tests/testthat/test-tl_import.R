

test_that("tl_import", {

  path <- tl_import("itis_test")
  expect_true(all(file.exists(unlist(path))))

})

test_that("tl_import", {
  skip_on_cran()
  skip_if_offline()

  path <- tl_import("itis", version="22.12")
  expect_true(all(file.exists(unlist(path))))

})

