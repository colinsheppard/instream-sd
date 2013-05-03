/*
inSTREAM Version 6.0, May 2013.
Individual-based stream trout modeling software. 
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; and Colin Sheppard, critter@stanfordalumni.org.
Development sponsored by US Bureau of Reclamation, EPRI, USEPA, USFWS,
USDA Forest Service, and others.
Version 6.0 sponsored by Argonne National Laboratory and Western
Area Power Administration.
Copyright (C) 2004-2013 Lang, Railsback & Associates.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see file LICENSE); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.
*/


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
#define DRY_CELL_COLOR 76
#define TAG_CELL_COLOR 62
#define POLYINTERIORCOLOR 63
#define POLYBOUNDARYCOLOR 61
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



