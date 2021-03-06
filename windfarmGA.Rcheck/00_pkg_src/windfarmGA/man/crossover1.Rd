% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/crossover1.R
\name{crossover1}
\alias{crossover1}
\title{Crossover Method}
\usage{
crossover1(se6, u, uplimit, crossPart)
}
\arguments{
\item{se6}{The selected individuals. The output of \code{\link{selection1}}
(list)}

\item{u}{The crossover point rate. (numeric)}

\item{uplimit}{The upper limit of allowed permutations. The current
algorithm has an upper bound of 300 permutations. (numeric)}

\item{crossPart}{The crossover method. Either "EQU" or "RAN". (character)}
}
\value{
Returns a binary coded matrix of all permutations and all grid
cells, 0 indicates no turbine and 1 indicates a turbine in the grid cell.
(matrix)
}
\description{
The crossover method of the genetic algorithm, which takes
the selected individuals after the \code{\link{selection1}} function and
produces new offsprings through permutation.
}
\examples{
 ## Create two random parents with an index and random binary values
 Parents <- data.frame(cbind(ID=1:20,bin=sample(c(0,1),20,replace=TRUE,
                         prob = c(70,30)),bin.1=sample(c(0,1),20,
                         replace=TRUE,prob = c(30,70))))
 Parents

 ## Create random Fitness values for both individuals
 FitParents <- data.frame(cbind(ID=1,Fitness=1000,Fitness.1=20))
 FitParents

 ## Assign both values to a list
 CrossSampl <- list(Parents,FitParents);
 str(CrossSampl)

 ## Cross their data at equal locations with 2 crossover parts
 crossover1(CrossSampl, u=1.1, uplimit=300, crossPart = "EQU")

 ## with 3 crossover parts and equal locations
 crossover1(CrossSampl, u=2.5, uplimit=300, crossPart = "EQU")

 ## or with random locations and 5 crossover parts
 crossover1(CrossSampl, u=4.9, uplimit=300, crossPart = "RAN")


}
\author{
Sebastian Gatscha
}
