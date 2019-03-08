
suppress_msg <- function(expr, pattern = "reserved SQL"){
withCallingHandlers(expr,
                    message = function(e){
                      if(grepl(pattern, e$message))
                        invokeRestart("muffleMessage")
                    })
}
