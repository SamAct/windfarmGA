#' @title Adjust the amount of turbines per windfarm
#' @name trimton
#' @description  Adjust the mutated individuals to the required amount of
#' turbines.
#'
#' @export
#' @importFrom dplyr select group_by summarise_each %>%
#' @importFrom utils globalVariables
#'
#' @param mut A binary matrix with the mutated individuals (matrix)
#' @param nturb A numeric value indicating the amount of required turbines
#' (numeric)
#' @param allparks A data.frame consisting of all individuals of the
#' current generation (data.frame)
#' @param nGrids A numeric value indicating the total amount of grid cells
#' (numeric)
#' @param trimForce A boolean value which determines which adjustment
#' method should be used. TRUE uses a probabilistic approach and
#' FALSE uses a random approach (logical)
#'
#' @return Returns a binary matrix with the correct amount of turbines
#' per individual (matrix)
#' @examples \donttest{
#' ## Create a random rectangular shapefile
#' library(sp)
#' Polygon1 <- Polygon(rbind(c(0, 0), c(0, 2000), c(2000, 2000), c(2000, 0)))
#' Polygon1 <- Polygons(list(Polygon1),1);
#' Polygon1 <- SpatialPolygons(list(Polygon1))
#' Projection <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
#' +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
#' proj4string(Polygon1) <- CRS(Projection)
#' plot(Polygon1,axes=TRUE)
#'
#' ## Create a uniform and unidirectional wind data.frame and plots the
#' ## resulting wind rose
#' ## Uniform wind speed and single wind direction
#' data.in <- as.data.frame(cbind(ws=12,wd=0))
#'
#' ## Calculate a Grid and an indexed data.frame with coordinates and grid cell Ids.
#' Grid1 <- GridFilter(shape = Polygon1,resol = 200,prop = 1);
#' Grid <- Grid1[[1]]
#' AmountGrids <- nrow(Grid)
#'
#' startsel <- StartGA(Grid,10,20);
#' wind <- as.data.frame(cbind(ws=12,wd=0))
#' fit <- fitness(selection = startsel,referenceHeight = 100, RotorHeight=100,
#'               SurfaceRoughness=0.3,Polygon = Polygon1, resol1 = 200,rot=20, dirspeed = wind,
#'               srtm_crop="",topograp=FALSE,cclRaster="")
#' allparks <- do.call("rbind",fit);
#'
#' ## SELECTION
#' ## print the amount of Individuals selected.
#' ## Check if the amount of Turbines is as requested.
#' selec6best <- selection1(fit, Grid,2, T, 6, "VAR");
#' selec6best <- selection1(fit, Grid,2, T, 6, "FIX");
#' selec6best <- selection1(fit, Grid,4, F, 6, "FIX");
#'
#' ## CROSSOVER
#' ## u determines the amount of crossover points,
#' ## crossPart determines the method used (Equal/Random),
#' ## uplimit is the maximum allowed permutations
#' crossOut <- crossover1(selec6best, 2, uplimit = 300, crossPart="RAN");
#' crossOut <- crossover1(selec6best, 7, uplimit = 500, crossPart="RAN");
#' crossOut <- crossover1(selec6best, 3, uplimit = 300, crossPart="EQU");
#'
#' ## MUTATION
#' ## Variable Mutation Rate is activated if more than 2 individuals represent
#' ## the current best solution.
#' mut <- mutation(a = crossOut, p = 0.3);
#' mut==crossOut
#'
#' ## TRIMTON
#' ## After Crossover and Mutation, the amount of turbines in a windpark change and have to be
#' ## corrected to the required amount of turbines.
#' mut1 <- trimton(mut = mut, nturb = 10, allparks = allparks, nGrids = AmountGrids,
#'                 trimForce=FALSE)
#' colSums(mut1)
#'
#'}
#' @author Sebastian Gatscha
trimton           <- function(mut, nturb, allparks, nGrids, trimForce){

  nGrids1 <- 1:nGrids

  lepa <- length(mut[1,])
  mut1 <- list();
  for (i in 1:lepa) {
    mut1[[i]] <- mut[,i]
    e <- mut[,i]==1
    ## How many turbines are in the current park?
    ele <- length(e[e==T]);
    ## How much turbines are there too many?
    zviel <- ele - nturb;
    ## Which grid cell IDs have a turbine
    welche <- which(e==TRUE);

    trimForce <- toupper(trimForce)
    if (1==1){

      # Calculate probability, that Turbine is selected to be eliminated.
      indivprop <- dplyr::select(allparks, Rect_ID, Parkfitness, AbschGesamt);
      # Group mean wake effect and fitness value of a grid cell.
      indivprop <- indivprop %>% dplyr::group_by(Rect_ID) %>% dplyr::summarise_each(dplyr::funs(mean));

      k <- 0.5

      propwelche <- data.frame(cbind(RectID=welche,Prop=rep(mean(indivprop$AbschGesamt),length(welche))));
      propexi <- indivprop[indivprop$Rect_ID %in% welche,];
      propexi <- as.data.frame(propexi)
      npt <- (1+((max(propexi$AbschGesam)-propexi$AbschGesam)/(1+max(propexi$AbschGesam))))
      npt0 <- (1+((max(propexi$Parkfitness)-propexi$Parkfitness)/(1+max(propexi$Parkfitness))))
      NewProb <- 1/(npt/(npt0^k))

      propwelche[welche %in%  indivprop$Rect_ID,]$Prop <- NewProb;

      propwelcheN <-  data.frame(cbind(RectID=nGrids1,Prop=rep(min(indivprop$AbschGesamt),length(nGrids1))));
      propexiN <- indivprop[indivprop$Rect_ID %in% nGrids1,];
      propexiN <- as.data.frame(propexiN)
      npt1 <- (1+((max(propexiN$AbschGesam)-propexiN$AbschGesam)/(1+max(propexiN$AbschGesam))))
      npt2 <- (1+((max(propexiN$Parkfitness)-propexiN$Parkfitness)/(1+max(propexiN$Parkfitness))))^k
      NewProb1 <- (npt1/npt2)
      propwelcheN[propwelcheN$RectID %in%  indivprop$Rect_ID,]$Prop <- NewProb1;
      if (!all(propwelcheN$RectID %in%  indivprop$Rect_ID==TRUE)){
        qu <- min(NewProb1)
        propwelcheN[!propwelcheN$RectID %in%  indivprop$Rect_ID,]$Prop <- qu
      }
      propwelcheN <- propwelcheN[!propwelcheN$RectID %in% welche,];
      ## P1 - Deleting Turbines
      prob1 <- propwelche$Prop;
      ## P2 - Adding Turbines
      prob2 <- propwelcheN$Prop;
    }

    if (zviel != 0) {
      if (zviel > 0) {
        if (trimForce == TRUE){
          # Delete turbines with Probability
          smpra <- sort(sample(welche, zviel,replace=F,prob = prob1));
          prob1[which(welche==smpra[1])]
        } else {
          # Delete them randomly
          smpra <- sort(sample(welche, zviel,replace=F));
        }
        # Delete the 1 entry and make no turbine.
        mut1[[i]][smpra] <- 0
      } else {
        if (trimForce == TRUE){
          # Add turbines with Probability
          smpra <- sort(sample(propwelcheN$RectID, (-zviel),replace=F, prob = prob2));
        } else {
          # Add turbines randomly
          smpra <- sort(sample(propwelcheN$RectID, (-zviel),replace=F));
        }
        # Assign 1 to binary code. So Turbine is created here.
        mut1[[i]][smpra] <- 1;
      }
    }
  }
  mut1 <- do.call("cbind", mut1)
  return(mut1)
}
