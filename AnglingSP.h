//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 





#import <random.h>
#import "SurvProb.h"
//#import "PoissonDistProtocol.h"
#import "AnglePressureFunc.h"
#import "ReachLengthFunc.h"
#import "TroutFunc.h"
#import "globals.h"



@interface AnglingSP : SurvProb
{

  TroutFunc* troutFunc;
  id <PoissonDist> poissonDist;
  id <UniformDoubleDist> uniformDist;

}

+ createBegin: aZone;
- createEnd;


-  createAnglePressureFuncWithMap: (id <Map>) aMap
            withInputMethod: (SEL) anInputMethod;

-  createReachLengthFuncWithMap: (id <Map>) aMap
            withInputMethod: (SEL) anInputMethod;

-  createTroutFuncWithMap: (id <Map>) aMap
            withInputMethod: (SEL) anInputMethod;


- (double) getSurvivalProb;


- (void) drop;

@end



