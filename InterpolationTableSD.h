/*
EcoSwarm library for individual-based modeling, last revised February 2012.
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; Colin Sheppard, critter@stanfordalumni.org; and
Steve Jackson, Jackson Scientific Computing, McKinleyville, California.
Development sponsored by US Bureau of Reclamation under the 
Central Valley Project Improvement Act, EPRI, USEPA, USFWS,
USDA Forest Service, and others.
Copyright (C) 2004-2012 Lang, Railsback & Associates.

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
// NOTE: THIS IS A NON-STANDARD VERSION OF INTERPOLATION TABLE
// WITH A SPEED-UP THAT CHECKS WHETHER INPUT IS THE SAME AS PREVIOUS
// TIME getValueFor: was called.


#import <objectbase/SwarmObject.h>
#import <collections.h>
//#import "ZoneAllocMapper.h"
#import <math.h>
#include <stdlib.h>
#define LARGEINT 2147483647


@interface InterpolationTableSD : SwarmObject
{

  id <Zone> interpolationZone;

  unsigned funcArrayMax;

  BOOL useLogs;

  id <Array> xValues;
  id <Array> yValues;

  double maxX;
  
  double previousX;
  double previousResult;

}

+ create: aZone;

- addX: (double) anX
     Y: (double) aY;

- reset;

- setLogarithmicInterpolationOn;

- (double) getValueFor: (double) anX;

- (double) interpolateFor: (double) anX;

- (int) getTableIndexFor: (double) anX;

- (double) getInterpFractionFor: (double) anX;

- (double) getValueWithTableIndex: (int) anIndex 
               withInterpFraction: (double) aFraction;


- printSelf;
- (void) drop;




@end

