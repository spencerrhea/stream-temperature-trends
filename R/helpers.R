### ---------------------------
##
## Title: helpers.R
##
## Purpose: this script contains functions of general use for this project
##
## Author: WS
##
## Date Created: 2022-04-11
##
## ---------------------------

stateRetrievalLoop <- function(readpath, writepath, varid = "00010", svc = "dv", type="ST") {
  print(paste("USGS data retrieval:", varid))

  for (state in state.abb) {
    print(paste("-- attempting data pull", state))

    tryCatch(
      expr = {
        rp <- paste0(readpath, state, ".csv")
        wp <- paste0(writepath, state, "_", varid, "_", svc, ".csv")

        # read in CSV
        df <- fread(rp,
                    colClasses=c("character"))

        df <- df %>%
          filter(data_type_cd %in% svc) %>%
          filter(site_tp_cd %in% type)


        if(nrow(df) == 0) {
          print(paste("---- WARNING:", state, "input CSV is empty"))
        } else {
          codes <- unique(df$site_no)

          # get dates for site
          begin <- min(df$begin_date)
          end <- max(df$end_date)

          if(svc == "qw") {
            qw_codes <- paste0("USGS-", codes)
            # get grab sample data
            info <- readWQPqw(
              siteNumbers = qw_codes,
              parameterCd = varid,
              startDate = begin,
              endDate = end
            )
          } else {
            # get daily mean data
            info <- readNWISdata(
              sites = codes,
              parameterCd = varid,
              service = svc,
              startDate = begin,
              endDate = end
            )
          }

          # save to wrtiepath
          write.csv(info, wp)
        }
        print(paste0("---- ", state, ": DONE"))
      },
      error = function(e) {
        print(paste("---- ERROR:", state))
      },
      finally = {
        # if df empty
        if(nrow(info) < 1) {
          print(paste("------ results empty:", state, "    ", varid))
        }
      }
    )
  }
}

stateInfoRetrievalLoop <- function(readpath, writepath) {
  print("USGS site info retrieval")

  for (state in state.abb) {
    print(paste("-- attempting info pull", state))

    tryCatch(
      expr = {
        rp <- paste0(readpath, state, ".csv")
        wp <- paste0(writepath, state, "_info.csv")

        # read in CSV
        df <- fread(rp,
                    colClasses=c("character")
                    )

        if(nrow(df) == 0) {
          print(paste("---- WARNING:", state, "input CSV is empty"))
        } else {
          codes <- unique(df$site_no)

          site_info <- readNWISsite(
            siteNumbers = codes
          )

          # save to wrtiepath
          write.csv(site_info, wp)
        }
        print(paste0("---- ", state, ": DONE"))
      },
      error = function(e) {
        print(paste("---- ERROR:", state))
      },
      finally = {
        # if df empty
        if(nrow(site_info) < 1) {
          print(paste("------ results empty:", state, "    ", varid))
        }
      }
    )
  }
}

stateCompiler <- function(listfiles) {
  for (file in listfiles) {
    tryCatch(
      expr = {
          state_data <- fread(file)

          if(!exists("all_df")) {
            all_df <- state_data
            print("__ CREATING DATAFRAME __")
            print(paste("DONE:", file))
          } else {
            all_df <- rbind(all_df, state_data, fill = TRUE)
            print(paste("DONE:", file))
          }
        },
      error = function(e) {
        print(paste("---- ERROR:", file))
        }
    )
  }
  return(all_df)
}
