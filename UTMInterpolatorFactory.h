//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 

#include <stdlib.h>

#import <objectbase/SwarmObject.h>

#import "globals.h"
#import "UTMInputData.h"
#import "UTMCell.h"
#import "InterpolationTableP.h"

@interface UTMInterpolatorFactory : SwarmObject
{
   id <List> listOfUTMInputData;
   UTMCell* utmCell;
}

+ create: aZone;

- setListOfUTMInputData: (id <List>) aList;
- setUTMCell: (UTMCell *) aUTMCell;

- createUTMVelocityInterpolator;
- createUTMDepthInterpolator;

- updateUTMVelocityInterpolator;
- updateUTMDepthInterpolator;

- (void) drop;

@end

