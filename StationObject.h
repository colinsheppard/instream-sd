//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import <ctype.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <math.h>

#import <objectbase/SwarmObject.h>
#import <collections.h>

@interface Station : SwarmObject {

int cellNo;
int transect;
double station;
double elev;


int offset;
int maxFlowOffset;
int maxDepthOffset;
int maxVelocityOffset;

//
// the values in the following 
// are log base 10
//

id <Array> flowArray;       // each element is log10(100*value)
id <Array> velocityArray;   // ditto
id <Array> depthArray;      // ditto 

id <Zone> stationZone;

}

+ createBegin: aZone;
- createEnd;

- setCellNo: (int) aCellNo;
- setTransect: (int) aTransect;
- setStation: (double) aStation;
- setElev: (double) anElev;


- (int) getCellNo;
- (int) getTransect;
- (double) getStation;

- (double) getVelocityAtOffset: (int) anOffset;
- (double) getDepthAtOffset: (int) anOffset;



- addAFlow: (double) aFlow atTransect: (int) aTransect
                           andStation: (double) aStation;
- addADepth: (double) aDepth atTransect: (int) aTransect
                             andStation: (double) aStation;
- addAVelocity: (double) aVelocity atTransect: (int) aTransect
                                   andStation: (double) aStation;

- checkArraySizes;

- printFlowArray;
- printVelocityArray;
- printDepthArray;

- checkMaxOffsets;
- printSelf;
@end


