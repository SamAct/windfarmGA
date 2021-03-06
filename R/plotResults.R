#' @title Plot the best Results
#' @name plotResult
#' @description  Plot the best resulting solutions of the genetic algorithm.
#' Depending on \code{plotEn}, either the best energy or efficiency solutions
#' can be plotted. \code{best} indicates the amount of best solutions that
#' should be plotted.
#'
#' @export
#'
#' @importFrom raster crs getData crop mask projectRaster raster getData
#' reclassify plot calc extract cellStats terrain resample overlay res
#' extent
#' @importFrom sp spTransform proj4string
#' @importFrom grDevices colorRampPalette topo.colors
#' @importFrom graphics mtext par plot
#' @importFrom utils read.csv
#' @importFrom calibrate textxy
#' @importFrom stats dist
#'
#' @param result An output matrix of the function \code{\link{windfarmGA}} or
#' \code{\link{genAlgo}}, which has stored all relevant information. (matrix)
#' @param Polygon1 The considered area as shapefile. (SpatialPolygons)
#' @param best A numeric value indicating how many of the best individuals
#' should be plotted. (numeric)
#' @param plotEn A numeric value that indicates if the best energy or
#' efficiency output should be plotted. If (plotEn==1) plots the best energy
#' solutions and (plotEn==2) plots the best efficiency solutions. (numeric)
#' @param topographie A logical value, indicating whether terrain effects
#' should be considered and plotted or not. (logical)
#' @param Grid The grid as SpatialPolygons, which is obtained from
#' \code{\link{GridFilter}} and used for plotting.
#' @param Projection A desired Projection can be used instead
#' of the default Lambert Azimuthal Equal Area Projection. (character)
#' @param sourceCCL The source to the Corine Land Cover raster (.tif). Only
#' required, when the terrain effect model is activated. (character)
#' @param sourceCCLRoughness The source to the adapted
#' Corine Land Cover legend as .csv file. Only required when terrain
#' effect model is activated. As default a .csv file within this
#' package (\file{~/extdata}) is taken that was already adapted
#' manually. To use your own
#' @param weibullsrc A list of Weibull parameter rasters, where the first list
#' item must be the shape parameter raster k and the second item must be the
#' scale parameter raster a of the Weibull distribution. If no list is given,
#' then rasters included in the package are used instead, which currently
#' only cover Austria. This variable is only used if weibull==TRUE. (list)
#'
#' @return Returns a data.frame of the best (energy/efficiency) individual
#' during all iterations. (data.frame)
#'
#' @examples \donttest{
#' ## Add some data examples from the package
#' load(file = system.file("extdata/resultrect.rda", package = "windfarmGA"))
#' load(file = system.file("extdata/resulthex.rda", package = "windfarmGA"))
#' load(file = system.file("extdata/polygon.rda", package = "windfarmGA"))
#'
#' ## Plot the results of a hexagonal grid optimization
#' result <- resulthex
#' Polygon1 <- polygon
#' Grid <- HexaTex(Polygon1, size = 87.5, FALSE)
#' plotResult(result, Polygon1, best = 1, plotEn = 1, topographie = FALSE,
#'            Grid = Grid[[2]])
#'
#' ## Plot the results of a rectangular grid optimization
#' result <- resultrect
#' Polygon1 <- polygon
#' Grid <- GridFilter(Polygon1, resol = 175, 1, FALSE)
#' plotResult(result, Polygon1, best = 1, plotEn = 1, topographie = FALSE,
#'            Grid = Grid[[2]])
#'
#' ## Plot the results of with a weibull mean background
#' result <- resultrect
#' Polygon1 <- polygon
#' load(file = system.file("extdata/a_weibull.rda", package = "windfarmGA"))
#' load(file = system.file("extdata/k_weibull.rda", package = "windfarmGA"))
#' weibullsrc <- list(k_param, a_param)
#' plotResult(result, Polygon1, best = 2, plotEn = 2, topographie = FALSE,
#'            Grid = Grid[[2]], weibullsrc = weibullsrc)
#'
#' ## Plot the hexagonal results ith weibull mean background
#' result <- resulthex
#' Grid <- HexaTex(Polygon1, size = 87.5, FALSE)
#' plotResult(result, Polygon1, best = 2, plotEn = 2, topographie = FALSE,
#'            Grid = Grid[[2]], weibullsrc = weibullsrc)
#'}
#' @author Sebastian Gatscha
plotResult <- function(result,Polygon1,best=3,plotEn=1,
                       topographie=FALSE,Grid,Projection,
                       sourceCCLRoughness,sourceCCL,
                       weibullsrc){

  ## Set graphical parameters
  op <- par(ask=FALSE);   on.exit(par(op));   par(mfrow=c(1,1))

  ## Check Projections and reference systems
  if (is.na(sp::proj4string(Polygon1))) {
    stop("Polygon is not projected.", call. = F )
  }
  if (missing(Projection)) {
    ProjLAEA <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
              +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
  } else {
    ProjLAEA <- Projection;
  }
  if (as.character(raster::crs(Polygon1)) != ProjLAEA) {
    Polygon1 <- sp::spTransform(Polygon1, CRSobj = ProjLAEA)
  }


  ## Check Weibull Rasters
  if (missing(weibullsrc)){
    weibullsrc = NULL
    col2res <- "lightblue"
  } else {
    PolyCrop <- sp::spTransform(Polygon1,
                                CRSobj = proj4string(weibullsrc[[1]]))
    if (class(weibullsrc)=="list" & length(weibullsrc)==2) {
      wblcroped <- lapply(weibullsrc, function(x){
        raster::crop(x,raster::extent(PolyCrop))})
      wblcroped <- lapply(wblcroped, function(x){
        raster::mask(x,PolyCrop)})
      Erwartungswert <- wblcroped[[2]] * (gamma(1 + (1/wblcroped[[1]])))
    } else if (class(weibullsrc)=="list" & length(weibullsrc)==1) {
      wblcroped <- raster::crop(weibullsrc[[1]],raster::extent(PolyCrop))
      wblcroped <- raster::mask(weibullsrc[[1]],PolyCrop)
      Erwartungswert <- wblcroped[[1]]
    } else if (class(weibullsrc)=="RasterLayer") {
      wblcroped <- raster::crop(weibullsrc,raster::extent(PolyCrop))
      wblcroped <- raster::mask(weibullsrc,PolyCrop)
      Erwartungswert <- wblcroped
    }
    col2res = "transparent"
    alpha=0.9
    Erwartungswert <- raster::projectRaster(Erwartungswert, crs = CRS(ProjLAEA))
    # plot(Erwartungswert)
  }


  ## Creat a color ramp
  rbPal1 <- grDevices::colorRampPalette(c('green','red'))

  resultSafe <- result
  ## Plot Best Energy
  if (plotEn == 1) {

    a <- sapply(result[,2], "[", "EnergyOverall")
    b <- data.frame(sapply(a, function(x) x[1]))
    order1 <- order(b, decreasing = F)
    result <- result[,2][order1]
    ledup <- length(result)

    rectid <- (lapply(result, function(x) x$Rect_ID));

    rectidt <- !duplicated(rectid)
    result <- result[rectidt]
    ndif <- length(result)

    cat(paste("N different optimal configurations:", ndif, "\nAmount duplicates:", (ledup-ndif)))
    if (ndif < best) {
      cat(paste("\nNot enough unique Optimas. Show first best Half of different configurations."))
      best = trunc(ndif/2)
    }
    result <- result[(length(result)-best+1):(length(result))]

    for (i in (1:length(result))){
      EnergyBest <- data.frame(result[[i]])
      ## Assign the colour depending on the individual wind speed (from windraster and influence)
      br <- length(levels(factor(EnergyBest$AbschGesamt)))
      if (br > 1) {
        Col <- rbPal1(br)[as.numeric(cut(as.numeric(EnergyBest$AbschGesamt),breaks = br))]
      } else {
        Col <- "green"
      }

      EnergyBest$EnergyOverall <- round(EnergyBest$EnergyOverall, 2)
      EnergyBest$EfficAllDir <- round(EnergyBest$EfficAllDir, 2)

      plot(Polygon1, col=col2res, main=paste("Best Energy:", (best+1)-i, "\n","Energy Output",
                                                 EnergyBest$EnergyOverall[[1]],"kW", "\n", "Efficiency:",
                                                 EnergyBest$EfficAllDir[[1]]));
      if (!is.null(weibullsrc)) {
        raster::plot(Erwartungswert, alpha=alpha, legend = T,axes=F,
                     useRaster=TRUE,add=T,
                     legend.lab="Mean Wind Speed")

      }
      plot(Grid,add=T)

      graphics::mtext("Total Wake Effect in %", side = 2)
      graphics::points(EnergyBest$X,EnergyBest$Y,cex=2,pch=20,col=Col)
      graphics::text(EnergyBest$X, EnergyBest$Y, round(EnergyBest$AbschGesamt,0), cex=0.8, pos=1, col="black")

      distpo <- stats::dist(x = cbind(EnergyBest$X,EnergyBest$Y),method = "euclidian")
      graphics::mtext(paste("minimal Distance", round(min(distpo),2)), side = 1,line=0)
      graphics::mtext(paste("mean Distance", round(mean(distpo),2)), side = 1,line=1)
    }


    ResPlotResult <- EnergyBest
  }
  if(topographie==TRUE && plotEn == 1){

    resol <- as.integer(resultSafe[1,]$inputData['Resolution',])

    polygon1 <- Polygon1
    sel1 <- EnergyBest[,1:2]
    windpo <- 1

    if (missing(sourceCCL)){
      stop("\nNo raster given for the surface roughness. \nAssign the path to the Corine Land Cover raster (.tif) to 'sourceCCL'\n",call. = F)
    }

    if (1==1){
      Polygon1 <-  sp::spTransform(Polygon1, CRSobj = raster::crs("+proj=longlat +datum=WGS84 +ellps=WGS84
                                                                  +towgs84=0,0,0"));
      extpol <- round(Polygon1@bbox,0)[,2]
      srtm <- raster::getData('SRTM', lon=extpol[1], lat=extpol[2]);
      srtm_crop <- raster::crop(srtm, Polygon1);
      srtm_crop <- raster::mask(srtm_crop, Polygon1)

      Polygon1 <-  sp::spTransform(Polygon1, CRSobj = raster::crs(ProjLAEA));
      srtm_crop <- raster::projectRaster(srtm_crop, crs = raster::crs(ProjLAEA));


      # Include Corine Land Cover Raster to get an estimation of Surface Roughness
      ccl <- raster::raster(sourceCCL)
      cclPoly <- raster::crop(ccl,Polygon1)
      cclPoly1 <- raster::mask(cclPoly,Polygon1)

      if (missing(sourceCCLRoughness)) {
        path <- paste0(system.file(package = "windfarmGA"), "/extdata/")
        sourceCCLRoughness <- paste0(path, "clc_legend.csv")
      } else {
        print("You are using your own Corine Land Cover legend.")
        readline(prompt = "\nPress <ENTER> if you want to continue")
        sourceCCLRoughness <- sourceCCLRoughness
      }
      rauhigkeitz <- utils::read.csv(sourceCCLRoughness,header = T,sep = ";");

      cclRaster <- raster::reclassify(cclPoly1,
                                      matrix(c(rauhigkeitz$GRID_CODE,rauhigkeitz$Rauhigkeit_z),ncol = 2))


      # Calculates Wind multiplier. Hills will get higher values, valleys will get lower values.
      orogr1 <- raster::calc(srtm_crop, function(x) {x/(raster::cellStats(srtm_crop,mean,na.rm=T))})
      orogrnum <- raster::extract(x = orogr1, y = as.matrix((sel1)), buffer=resol*2, small=T,fun= mean,na.rm=T);
      windpo <- windpo * orogrnum
      ## Get Elevation of Turbine Locations to estimate the air density at the resulting height
      heightWind <- raster::extract(x= srtm_crop, y = as.matrix((sel1)), small=T,fun= max,na.rm=T);
      par(mfrow=c(1,1))
      plot(srtm_crop, main="SRTM Elevation Data");graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round(heightWind,0),cex=0.8);plot(polygon1,add=T)
      plot(orogr1, main="Wind Speed Multipliers");points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round(windpo,3),cex=0.8);plot(polygon1,add=T)

      # Get Air Density and Pressure from Height Values
      HeighttoBaro <- matrix(heightWind); colnames(HeighttoBaro) <- "HeighttoBaro"
      air_dt <- BaroHoehe(matrix(HeighttoBaro),HeighttoBaro)

      par(mfrow=c(1,1))
      plot(srtm_crop, main="Normal Air Density",col=topo.colors(10));points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = rep(1.225,nrow(sel1)),cex=0.8); plot(polygon1,add=T)
      plot(srtm_crop, main="Corrected Air Density",col=topo.colors(10));points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round(air_dt$rh,2),cex=0.8); plot(polygon1,add=T)


      #CorineLandCover Roughness values
      SurfaceRoughness0 <- raster::extract(x= cclRaster, y = as.matrix((sel1)),buffer=resol*2,
                                           small=T,fun= mean,na.rm=T);
      SurfaceRoughness1 <- raster::extract(x=raster::terrain(srtm_crop,"roughness"), y = as.matrix((sel1)),
                                           buffer=resol*2,
                                           small=T,fun= mean,na.rm=T);
      SurfaceRoughness <- SurfaceRoughness0*(1+(SurfaceRoughness1/max(raster::res(srtm_crop))));
      elrouind <- raster::terrain(srtm_crop,"roughness")
      elrouindn <- raster::resample(elrouind,cclRaster,method="ngb")
      modSurf <- raster::overlay(x = cclRaster,y = elrouindn,
                                 fun=function(x,y){return(x*(1+(y/max(raster::res(srtm_crop)))))})

      graphics::par(mfrow=c(1,1)); cexa=0.9
      raster::plot(cclRaster, main="Corine Land Cover Roughness");points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round(SurfaceRoughness0,2),cex=cexa); plot(polygon1,add=T)
      raster::plot(x=raster::terrain(srtm_crop,"roughness",neighbors = 4), main="Elevation Roughness Indicator");
      graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round((SurfaceRoughness1),2),cex=cexa);
      raster::plot(polygon1,add=T)
      raster::plot(modSurf, main="Modified Surface Roughness");
      graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round((SurfaceRoughness),2),cex=cexa);
      raster::plot(polygon1,add=T)



      RotorHeight <- as.integer(resultSafe[1,'inputData']$inputData['Rotor Height',][[1]])
      k_raster <- raster::calc(modSurf, function(x) {x <- 0.5/(log(RotorHeight/x))})
      # New Wake Decay Constant calculated with new surface roughness values, according to CLC
      k <- 0.5/(log(RotorHeight/SurfaceRoughness))
      graphics::par(mfrow=c(1,1)); cexa=0.9
      raster::plot(k_raster, main="Adapted Wake Decay Constant - K");
      graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round((k),3),cex=cexa);
      raster::plot(polygon1,add=T)
    }
  }

  ## Plot Best Efficiency
  if (plotEn == 2){
    a <- sapply(result[,3], "[", "EfficAllDir")
    b <- data.frame(sapply(a, function(x) x[1]))
    order2 <- order(b, decreasing = F)
    result <- result[,3][order2]
    ledup <- length(result)
    rectid <- lapply(result, function(x) x$Rect_ID)
    rectidt <- !duplicated(rectid)
    result <- result[rectidt]
    ndif <- length(result)

    cat(paste("N different optimal configurations:", ndif, "\nAmount duplicates:", (ledup-ndif)))
    if (ndif < best) {
      cat(paste("\nNot enough unique Optimas. Show first best Half of different configurations."))
      best = trunc(ndif/2)
    }
    result <- result[(length(result)-best+1):(length(result))]

    for (i in (1:length(result))){
      #EfficiencyBest <- do.call("cbind", result[[i]])
      EfficiencyBest <- data.frame(result[[i]])
      ## Assign the colour depending on the individual wind speed (from windraster and influence)
      br <- length(levels(factor(EfficiencyBest$AbschGesamt)))
      if (br > 1) {
        Col1 <- rbPal1(br)[as.numeric(cut(EfficiencyBest$AbschGesamt,breaks = br))]
      } else {
        Col1 <- "green"
      }

      EfficiencyBest$EnergyOverall <- round(EfficiencyBest$EnergyOverall, 2)
      EfficiencyBest$EfficAllDir <- round(EfficiencyBest$EfficAllDir, 2)


      raster::plot(Polygon1, col=col2res,main=paste("Best Efficiency:", (best+1)-i, "\n","Energy Output",
                                                         EfficiencyBest$EnergyOverall[[1]],"kW", "\n", "Efficiency:",
                                                         EfficiencyBest$EfficAllDir[[1]]));
      if (!is.null(weibullsrc)) {
        raster::plot(Erwartungswert, alpha=alpha, legend = T,axes=F,
                     useRaster=TRUE,add=T,
                     legend.lab="Mean Wind Speed")

      }
      plot(Grid,add=T)





      graphics::mtext("Total Wake Effect in %", side = 2)
      graphics::points(EfficiencyBest$X,EfficiencyBest$Y,col=Col1,cex=2,pch=20)
      graphics::text(EfficiencyBest$X, EfficiencyBest$Y, round(EfficiencyBest$AbschGesamt,0), cex=0.8, pos=1)


      distpo <- stats::dist(x = cbind(EfficiencyBest$X,EfficiencyBest$Y),method = "euclidian")
      graphics::mtext(paste("minimal Distance", round(min(distpo),2)), side = 1,line=0)
      graphics::mtext(paste("mean Distance", round(mean(distpo),2)), side = 1,line=1)


    }

    ResPlotResult <- EfficiencyBest
  }
  if(topographie==TRUE && plotEn == 2){

    resol <- as.integer(resultSafe[1,]$inputData['Resolution',])
    polygon1 <- Polygon1
    sel1 <- EfficiencyBest[,1:2]
    windpo <- 1

    if (missing(sourceCCL)){
      stop("\nNo raster given for the surface roughness. \nAssign the path to the Corine Land Cover raster (.tif) to 'sourceCCL'\n",call. = F)
    }

    if (1==1){
      Polygon1 <-  sp::spTransform(Polygon1, CRSobj = raster::crs("+proj=longlat +datum=WGS84 +ellps=WGS84
                                                                  +towgs84=0,0,0"));
      extpol <- round(Polygon1@bbox,0)[,2]
      srtm <- raster::getData('SRTM', lon=extpol[1], lat=extpol[2]);
      srtm_crop <- raster::crop(srtm, Polygon1);
      srtm_crop <- raster::mask(srtm_crop, Polygon1)

      Polygon1 <-  sp::spTransform(Polygon1, CRSobj = raster::crs(ProjLAEA));
      srtm_crop <- raster::projectRaster(srtm_crop, crs = raster::crs(ProjLAEA));


      # Include Corine Land Cover Raster to get an estimation of Surface Roughness
      ccl <- raster::raster(sourceCCL)
      cclPoly <- raster::crop(ccl,Polygon1)
      cclPoly1 <- raster::mask(cclPoly,Polygon1)
      if (missing(sourceCCLRoughness)) {
        path <- paste0(system.file(package = "windfarmGA"), "/extdata/")
        sourceCCLRoughness <- paste0(path, "clc_legend.csv")
      } else {
        print("You are using your own Corine Land Cover legend.")
        readline(prompt = "\nPress <ENTER> if you want to continue")
        sourceCCLRoughness <- sourceCCLRoughness
      }
      rauhigkeitz <- utils::read.csv(sourceCCLRoughness,header = T,sep = ";");
      cclRaster <- raster::reclassify(cclPoly1,
                                      matrix(c(rauhigkeitz$GRID_CODE,rauhigkeitz$Rauhigkeit_z),ncol = 2))


      # Calculates Wind multiplier. Hills will get higher values, valleys will get lower values.
      orogr1 <- raster::calc(srtm_crop, function(x) {x/(raster::cellStats(srtm_crop,mean,na.rm=T))})
      orogrnum <- raster::extract(x= orogr1, y = as.matrix((sel1)), buffer=resol*2, small=T,fun= mean,na.rm=T);
      windpo <- windpo * orogrnum
      ## Get Elevation of Turbine Locations to estimate the air density at the resulting height
      heightWind <- raster::extract(x= srtm_crop, y = as.matrix((sel1)), small=T,fun= max,na.rm=T);
      graphics::par(mfrow=c(1,1))
      raster::plot(srtm_crop, main="SRTM Elevation Data");graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round(heightWind,0),cex=0.8);raster::plot(polygon1,add=T)
      raster::plot(orogr1, main="Wind Speed Multipliers");graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round(windpo,3),cex=0.8);raster::plot(polygon1,add=T)

      # Get Air Density and Pressure from Height Values
      HeighttoBaro <- matrix(heightWind); colnames(HeighttoBaro) <- "HeighttoBaro"
      air_dt <- BaroHoehe(matrix(HeighttoBaro),HeighttoBaro)
      graphics::par(mfrow=c(1,1))
      raster::plot(srtm_crop, main="Normal Air Density",col=topo.colors(10));
      graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = rep(1.225,nrow(sel1)),cex=0.8);
      raster::plot(polygon1,add=T)
      raster::plot(srtm_crop, main="Corrected Air Density",col=topo.colors(10));
      graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round(air_dt$rh,2),cex=0.8);
      raster::plot(polygon1,add=T)


      #CorineLandCover Roughness values
      SurfaceRoughness0 <- raster::extract(x= cclRaster, y = as.matrix((sel1)),buffer=resol*2,
                                           small=T,fun= mean,na.rm=T);
      SurfaceRoughness1 <- raster::extract(x=raster::terrain(srtm_crop,"roughness"),
                                           y = as.matrix((sel1)),buffer=resol*2, small=T,fun= mean,na.rm=T);
      SurfaceRoughness <-SurfaceRoughness0*(1+(SurfaceRoughness1/max(raster::res(srtm_crop))));
      elrouind <- raster::terrain(srtm_crop,"roughness")
      elrouindn <- raster::resample(elrouind,cclRaster,method="ngb")
      modSurf <- raster::overlay(x = cclRaster,y = elrouindn, fun=function(x,y)
                                {return(x*(1+(y/max(raster::res(srtm_crop)))))})

      graphics::par(mfrow=c(1,1)); cexa <- 0.9
      raster::plot(cclRaster, main="Corine Land Cover Roughness");graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round(SurfaceRoughness0,2),cex=cexa);plot(polygon1,add=T)
      raster::plot(x=raster::terrain(srtm_crop,"roughness",neighbors = 4), main="Elevation Roughness Indicator");
      graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round((SurfaceRoughness1),2),cex=cexa);plot(polygon1,add=T)
      raster::plot(modSurf, main="Modified Surface Roughness");graphics::points(sel1$X,sel1$Y,pch=20);
      calibrate::textxy(sel1$X,sel1$Y,labs = round((SurfaceRoughness),2),cex=cexa);plot(polygon1,add=T)


      RotorHeight <- as.integer(resultSafe[1,'inputData']$inputData['Rotor Height',][[1]])
      k_raster <- raster::calc(modSurf, function(x) {x <- 0.5/(log(RotorHeight/x))})
      # New Wake Decay Constant calculated with new surface roughness values, according to CLC
      k <- 0.5/(log(RotorHeight/SurfaceRoughness))
      graphics::par(mfrow=c(1,1)); cexa <- 0.9
      raster::plot(k_raster, main="Adapted Wake Decay Constant - K");
      graphics::points(sel1$X,sel1$Y,pch=20); calibrate::textxy(sel1$X,sel1$Y,labs = round((k),3),cex=cexa);
      raster::plot(polygon1,add=T)
    }
  }

  return(ResPlotResult)
}
