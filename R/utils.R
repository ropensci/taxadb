
suppress_msg <- function(expr, pattern = c("reserved SQL", "not overwriting")){
withCallingHandlers(expr,
                    message = function(e){
                      if(any(vapply(pattern, grepl, logical(1), e$message)))
                        invokeRestart("muffleMessage")
                    })
}
