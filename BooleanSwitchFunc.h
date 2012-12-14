//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import "Func.h"

@interface BooleanSwitchFunc : Func
{


double yesValue;
double noValue;

}

+          create: aZone
  withInputMethod: (SEL) anInputMethod
     withYesValue: (double) aYesValue
      withNoValue: (double) aNoValue;



- updateWith: obj;

- (void) drop;

@end

