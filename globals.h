//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import <defobj.h>
#import "FishParams.h"

int speciesNDX;

// use this to initialize integers

#define LARGEINT 2147483647
#define XCOORDINATE 0
#define YCOORDINATE 1
#define ZCOORDINATE 2
#define DIMENSION 2
#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#define CELL_COLOR_START 0
#define CELL_COLOR_MAX 60
#define UTMBOUNDARYCOLOR 61
#define TAG_CELL_COLOR 62
#define UTMINTERIORCOLOR 63
#define BARRIER_COLOR 71

#define DAYTIMERASTER 72
#define NIGHTTIMERASTER 73


#define TAG_FISH_COLOR 70
#define FISHCOLORSTART 63

#define FISH_LENGTH_COEF 3


#ifndef PI
#define PI 3.141592654
#endif


// define the segregation symbols for species and list
extern id <Symbol> Redd;
extern id <Symbol> Male, Female;
extern id <Symbol> Population, Dead, Cached, Killed;
extern FishParams ** dataZone;




id randGen; // use the same generator for all random draws in the model

//
// Define the line length for
// comment header lines in input files
// 
#define HCOMMENTLENGTH 200

#define LOWER_LOGISTIC_DEPENDENT 0.1
#define UPPER_LOGISTIC_DEPENDENT 0.9



