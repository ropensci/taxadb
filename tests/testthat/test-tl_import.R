

test_that("tl_import", {

  path <- tl_import("itis_test")
  expect_true(all(file.exists(path)))

})

test_that("tl_import", {

  expect_message({
    path <- tl_import("fb", version="2020")
  })
  expect_true(all(file.exists(path)))

})

