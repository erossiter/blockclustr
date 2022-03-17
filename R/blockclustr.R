#' Constructs blocked clusters for blocked and clustered random assignment
#'
#' @param data A dataframe with units in rows and variables in columns.
#' @param id_var A string specifying which column of \code{data} is the units' unique identifier
#' @param block_vars A string or vector of strings specifying which columns of \code{data} are the (continuous)
#' blocking covariates.
#' @param n_tr An integer specifying the number of experimental conditions.  This is also the number of
#' clusters per block.
#' @param n_units_per_clust An integer specifying the number of units that should be assigned to each cluster.
#' It will not be used if \code{constraint_list} is specified.
#' @param constraint_var An optional string specifying which column of \code{data} is the variable
#' that cluster composition is constrained by.  Must also specify \code{constraint_list}.
#' @param constraint_list An optional list of vectors specifying all combinations of \code{constraint_var} values
#' that clusters can take. Must also specify \code{constraint_var}.
#' @param algorithm A string specifying the algorithm used to construct blockettes.  See \code{blockTools::block}
#' for more options and information.
#' @param distance A string specifying the distance calculation used when constructing blockettes.  See \code{blockTools::block}
#' for more options and information.
#'
#' @return Returns a list of three elements:
#'
#'
#' \itemize{
#' \item{\code{design}}{ a dataframe containing information about units
#' included in the experimental design}
#' \itemize{
#' \item{\code{id_var}}{ the supplied unique identifier}
#' \item{\code{block_vars}}{ the supplied blocking covariates}
#' \item{\code{constraint_var}}{ the supplied constraint variable, if applicable}
#' \item{\code{block_id}}{ an indicator for which block the unit belongs to}
#' \item{\code{block_id}}{ an indicator for which cluster the unit belongs to}
#' \item{\code{block_id}}{ a treatment indicator, corresponding with the specified number of conditions, \code{n_tr}}
#' }
#' \item{\code{raw_blockettes}}{ is the output of the \code{blockTools::block} function, used to construct blockettes}
#' \item{\code{unused_units}}{ a dataframe containing information about the units in \code{data} not
#' included in the experimental design}
#' }
#'
#'
#' @export
blockclustr <- function(data,
                        id_var,
                        block_vars,
                        n_tr,
                        n_units_per_clust,
                        constraint_var = NULL,
                        constraint_list = NULL,
                        algorithm = "optGreedy",
                        distance = "mahalanobis"){
  # TODO: make all options in blockTools::block
  # that I don't ask for explicitly still be
  # able to be used.  Functions do this, I think,
  # by allowing you to pass a list, or by using "..."

  if(any(!c(id_var, block_vars, constraint_var) %in% colnames(data))){
    stop("Variable name(s) not in data")
  }
  if(any(!complete.cases(data[, c(id_var, block_vars, constraint_var)]))){
    stop("Missing data in blocked cluster algorithm variables:
          'id_var', 'block_vars', and 'constraint_var' (if not NULL)")
  }
  if(any(!apply(data[,block_vars], 2, is.numeric))){
    stop("Non-numeric blocking covariates in 'block_vars'")
  }
  if(any(duplicated(data[,id_var]))){
    stop("Non-unique values in 'id_var'")
  }
  if(is.null(constraint_var) & !is.null(constraint_list) |
     !is.null(constraint_var) & is.null(constraint_list)){
    stop("'constraint_var' and 'constraint_list' need to both be specified
         or both NULL")
  }
  if(!is.null(constraint_var) & any(!unique(unlist(constraint_list)) %in% data[,constraint_var])){
    stop("Values in 'constraint_list' not in 'constraint_var'")
  }
  if(!is.null(constraint_list) & !is.na(n_units_per_clust)){
    warning("Warning: 'n_units_per_clust' will not be used if 'constraint_list' is specified")
  }
  if(!is.null(constraint_list)){
    if(!is.list(constraint_list)){
      stop("'constraint_list' not a list")
    }
  }

  # TODO: deal with is.tibble() warning
  raw_blockettes <- blockTools::block(data = data,
                                      n.tr = n_tr,
                                      id.vars = id_var,
                                      groups = constraint_var,
                                      block.vars = block_vars,
                                      algorithm = algorithm,
                                      distance = distance)

  blockettes <- plyr::ldply(.data = raw_blockettes$blocks,
                            .fun = function(x){

                              # Omit "Max Distance" column
                              x <- x[,-ncol(x)]

                              # Only keep full blockettes
                              x <- x[!apply(x, 1, anyNA), ]

                              # Shuffle order of *individuals* within the blockette
                              x <- plyr::adply(x, 1, sample)

                              # Shuffle order of the *blockettes*
                              x <- x[sample(1:nrow(x)), ]

                              # Clean colnames
                              colnames(x) <- paste0("unit", 1:ncol(x))

                              return(x)
                            })

  # Change order of columns for clarity
  blockettes <- blockettes[, c(2:(n_tr+1), 1)]

  # Remove or change name .id var for clarity
  if(is.null(constraint_var)){
    blockettes[which(colnames(blockettes) == ".id")] <- NULL
  }else{
    colnames(blockettes)[which(colnames(blockettes) == ".id")] <- "constraint_var"
  }

  # Shuffle the order of blockettes
  blockettes <- blockettes[sample(1:nrow(blockettes)), ]

  # Storage
  block_clust_df <- data.frame("id" = numeric(),
                               "block_id" = numeric(),
                               "cluster_id" = numeric())

  # Loop simultaneously creates blocks & clusters
  c_iter <- 1
  b_iter <- 1
  blockettes$used <- F # Indicator for used in design
  for(i in 1:nrow(blockettes)){
    if(blockettes$used[i]) next # Already partnered

    if(is.null(constraint_var)){
      n_units_to_fill <- n_units_per_clust
    }else{
      # Randomly choose one item from constraint_list
      # and pick blockettes randomly, given this constraint
      constraint_to_fill <- unlist(sample(constraint_list, 1))
      n_units_per_clust <- length(constraint_to_fill)
    }

    blockette_idx <- c(i, rep(NA, n_units_per_clust-1))
    for(j in 2:(n_units_per_clust)){

      if(is.null(constraint_var)){
        poss_b <- which(!blockettes$used)
        idx <- pick_blockette(poss_b = poss_b, i = i)
      }else{
        # Updates to what the block currently has
        blockette_constraint <- blockettes$constraint_var[blockette_idx]
        type_needed <- constraint_to_fill
        for(c in blockette_constraint[!is.na(blockette_constraint)]){
          type_needed <- type_needed[-match(c, type_needed)]
        }

        # Randomly pick one blockette given what is still needed
        poss_b <- which(blockettes$constraint_var %in% type_needed & (!blockettes$used))
        idx <- pick_blockette(poss_b = poss_b, i = i)
      }

      # Boot because no cross-partisan partners to chose from
      if(is.na(idx)) break

      # Indicate no longer available
      blockettes$used[i] <- T
      blockettes$used[idx] <- T

      # Update vector for current blockette indices
      blockette_idx[j] <- idx
    }

    # Boot because not enough cross-partisan partners to chose from
    if(any(is.na(blockette_idx))) next

    # Create storage for unit-level dataframe (rather than blockette-level)
    block_df <- data.frame("id" = unlist(blockettes[blockette_idx,1:n_tr]))
    block_df$block_id <- rep(b_iter, n_tr*n_units_per_clust)
    block_df$cluster_id <- rep(c_iter:(c_iter+n_tr-1), each = n_units_per_clust)

    # Add block to storage
    block_clust_df <- rbind(block_clust_df, block_df)

    # Increment counters
    b_iter <- b_iter + 1
    c_iter <- c_iter + n_tr
  }

  # Join blocking information with covariates
  colnames(block_clust_df)[which(colnames(block_clust_df) == "id")] <- id_var
  block_clust_df <- plyr::join(block_clust_df, data, by = id_var, type = "left")

  # Assign treatment
  block_clust_df$Z <- randomizr::block_and_cluster_ra(blocks = block_clust_df$block_id,
                                           clusters = block_clust_df$cluster_id,
                                           conditions = paste0("Z", 1:n_tr),
                                           num_arms = n_tr)

  # Order nicely
  block_clust_df <- block_clust_df[order(block_clust_df$cluster_id), ]

  # Vector of ids of units NOT used in the experiment
  unused_units <- data.frame(data[,id_var][!data[,id_var] %in% block_clust_df[,id_var]])
  colnames(unused_units) <- id_var
  unused_units <- plyr::join(unused_units, data, by = id_var, type = "left")

  return(list(design = block_clust_df,
              raw_blockettes = raw_blockettes,
              unused_units = unused_units))
}


#' @keywords internal
# Helper function for randomly choosing blockettes
pick_blockette <- function(poss_b, i){
  if(i %in% poss_b) poss_b <- poss_b[-which(poss_b == i)]
  if(length(poss_b) == 0){
    b_idx <- NA
  }else if(length(poss_b) == 1){
    b_idx <- poss_b
  }else{
    b_idx <- sample(poss_b, size = 1)
  }
  return(b_idx)
}

