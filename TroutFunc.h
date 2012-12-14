//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "Func.h"
#import "UTMTrout.h"
#import "globals.h"


//
// TroutFunc is placed on the list of animal
// update functions in the survival manager.
// All it does is set and return the current
// animal. It seems safer to do it this way
// because when updating/getting the survival probs,
// the survival manager can test to ensure
// that the current animal is indeed the animal
// that we want to operate on and NOT an animal
// from a previous calculation. 
//

@interface TroutFunc : Func
{

   id aTrout;

}

+    createBegin: aZone
  setInputMethod: (SEL) anInputMethod;

- createEnd;


//
// This is where the current animal is set
//
- updateWith: anObj;

- getTrout;

- (void) drop;
@end
