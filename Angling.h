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
#import "globals.h"

#import "DayPhaseTypes.h"

//#define TEST_OUTPUT_ON

@interface Angling : SurvProb
{

  id <PoissonDist> poissonDist;
  id <UniformDoubleDist> uniformDist;

  #ifdef TEST_OUTPUT_ON
     FILE* anglingFP;
  #endif

}

+ createBegin: aZone;
- createEnd;


- (double) getSurvivalProb;

- (void) drop;
@end



