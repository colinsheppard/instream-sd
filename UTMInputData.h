//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import <objectbase/SwarmObject.h>
#import <stdlib.h>
#import "globals.h"

@interface UTMInputData : SwarmObject
{
   id <Zone> inputDataZone;

   double utmFlow;
   char utmVelocityDataFile[50];
   char utmDepthDataFile[50];
   
   int numberOfVelNodes;
   double** velocityArray;  // centimeters
   int numberOfDepthNodes;
   double** depthArray;     // centimeters

}
+ create: aZone;

- setUTMFlow: (double) aFlow;
- setUTMVelocityDataFile: (char *) aVelocityDataFile;
- setUTMDepthDataFile: (char *) aDepthDataFile;

- createVelocityArray;
- createDepthArray;

- (double) getUTMFlow;
- (char *) getUTMVelocityDataFile;
- (char *) getUTMDepthDataFile;

- (double **) getVelocityArray;
- (double **) getDepthArray;

- (int) compareFlows: otherInputData;

- (void) drop;

@end

