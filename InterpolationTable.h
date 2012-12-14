//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import <objectbase/SwarmObject.h>
#import <collections.h>
#import "ZoneAllocMapper.h"
#import <math.h>

#define LARGEINT 2147483647


@interface InterpolationTable : SwarmObject
{

  id <Zone> interpolationZone;

  unsigned funcArrayMax;

  BOOL useLogs;

  id <Array> xValues;
  id <Array> yValues;

  double maxX;

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

