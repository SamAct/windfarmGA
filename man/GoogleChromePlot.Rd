% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/GoogleChromePlot.R
\name{GoogleChromePlot}
\alias{GoogleChromePlot}
\title{Plot the Best Results in Google Chrome}
\usage{
GoogleChromePlot(result, Polygon1, best = 1, plotEn = 1, Projection)
}
\arguments{
\item{result}{The output matrix of \code{\link{windfarmGA}} or
\code{\link{genAlgo}}, which has stored all relevant information.
(matrix)}

\item{Polygon1}{The considered area as shapefile (SpatialPolygons)}

\item{best}{A numeric value indicating the best individual
to be plotted. 1 will indicate the solution with highest value. (numeric)}

\item{plotEn}{A numeric value that indicates if the best energy or
efficiency output should be plotted. (plotEn==1) will plot the best
energy solution and (plotEn==2) will plot the best efficiency solution.
(numeric)}

\item{Projection}{A desired Projection can be used instead
of the default Lambert Azimuthal Equal Area Projection. (character)}
}
\description{
Plot the best energy or efficiency solutions in Google Chrome
with a satellite background image of Google maps. Input Polygon is
not plotted
}
\examples{
\donttest{
## Add some data examples from the package
load(file = system.file("extdata/resultrect.rda", package = "windfarmGA"))
load(file = system.file("extdata/polygon.rda", package = "windfarmGA"))

## Plot the results of a wind farm optimization
result <- resultrect
Polygon1 <- polygon
GoogleChromePlot(result, Polygon1, 1, 1)
}
}
\author{
Sebastian Gatscha
}
