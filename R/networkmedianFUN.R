#' Deriving the network median.
#' The network median is found for each iteration (normally based on timeseries). Values are removed, one at a time, across the iteration, with the removal specified by the group option. The final product is a column that for the network value that can be used as a proxy in other analyses.
#'
#' @param obs The data to derive the network median from.
#' @param group An identifying variable.
#' @param id This is an option if some column is required to remain in the final output (e.g. site). Default is `NA`.
#' @param by.row This option is if the iterations need to happen over the group (default, `TRUE`).
#' @param statistic This is the statistic to use to summarise the data. Default is `median`.
#' @export
#' @examples
#' networkmedianFUN()

networkmedianFUN <- function(x, group, obs, by.row = T, id = NA, statistic = median){

	list.of.packages <- c("stats","lubridate","data.table","tidyverse");
  new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])];
  if(length(new.packages)) install.packages(new.packages);
  lapply(list.of.packages, library, character.only = T);

  # define variables
  x <- as.data.table(x);
  x$obs <- x[, ..obs];
	x$group <- x[, ..group];
  if(!is.na(id)) x$id <- x[, ..id];

  # filter data to that of interest
  z = x[, list(group, obs)];
  if(!is.na(id)) z.id <- x[, list(group, id, obs)];

  net.day.FUN <- function(z){
    if(length(z$obs) > 1){
      network.proxy <- unlist(sapply(seq(1, nrow(z)), function(i){
        test = z[-i,];
        network.proxy <- statistic(test$obs, na.rm = T);
        return(network.proxy);
      }))
      } else {
        network.proxy <- NA;
        network.proxy <- as.numeric(network.proxy);
      }
    z <- cbind(z, network.proxy);
    z <- unique(z);
    };

  net.FUN <- function(z){
    group.list <- as.vector(unique(z$group));
    output = data.frame(group = as.character(),
                        network.proxy = as.numeric());
    for(i in group.list){
			if(length(z$obs) > 1){
				selected.group = i;
				group.stat <- data.frame(group = selected.group,
																 network.proxy = statistic(z$obs[z$group != selected.group], na.rm = T))
				output = bind_rows(output, group.stat);
			}
		}
		x <- full_join(x, output);
    x <- unique(x);
	}

  if(by.row == T){
    Z.data <- z[, net.day.FUN(.SD), by = group];
  }

  if(by.row == F){
    Z.data <- net.FUN(z)
  }

	if(!is.na(id)) Z.data <- join(Z.data, z.id);
	return(Z.data);
};