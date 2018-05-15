# http://tinyurl.com/y7ltbmjm

library(jqr)
library(magrittr)
readLines("examples/taxa-top-down.json") %>% 
  jq(".. |  .name? // empty ")

readLines("examples/taxa-top-down.json") %>% 
  jq(".. | {rank: .rank?, name: .name?} ")
