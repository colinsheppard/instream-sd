//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import "Func.h"

@interface LogisticFunc: Func
{

    double logisticLimiter;

    double pA;
    double pB;

    double prevInputVal;
    double prevFuncVal;
 
 

}

+      createBegin: aZone 
   withInputMethod: (SEL) anInputMethod
        usingIndep: (double) xValue1
               dep: (double) yValue1
             indep: (double) xValue2
               dep: (double) yValue2;

- createEnd;

- updateWith: anObj;

- setLogisticFuncLimiterTo: (double) aLimiter;

- initializeWithIndep: (double) x1 dep: (double) y1
	       indep: (double) x2 dep: (double) y2;
-(double) evaluateFor: (double) x; 
- (double) getpA;
- (double) getpB;

- (void) drop;


@end

