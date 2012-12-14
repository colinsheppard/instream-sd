//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import <objectbase/SwarmObject.h>
#import "Cell.h"
#import "Logistic.h"
#import "HabitatSpace.h"

#import "DEBUGFLAGS.h"

@interface SurvivalFunc : SwarmObject {

  id myCell;
  int numSpecies;

}
- setCell: aCell;
- createEnd;
//
// update added 3/8/2000
// for the cuthroat scour surv func SKJ
//
- update;
- (float) getSFFor: aFish;
- (int) getNumberOfSpecies;
- (void) drop;
@end
