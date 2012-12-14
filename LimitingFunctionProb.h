//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import <objectbase/SwarmObject.h>
#import <string.h>

#import "SurvProb.h"
#import "globals.h"
#import "ZoneAllocMapper.h"
#import "BooleanSwitchFunc.h"
#import "LogisticFunc.h"
#import "ConstantFunc.h"


@interface LimitingFunctionProb : SurvProb
{

double minSurvProb;

//
// this list will contain the logistic,
// constant, and boolean switch functions
//
//id <List> funcList;

id minProbFunc;

}

+ createBegin: aZone;
- createEnd;
- (id <List>) getMultiFunctionList;
- (double) getSurvivalProb;

- (void) drop;

@end
