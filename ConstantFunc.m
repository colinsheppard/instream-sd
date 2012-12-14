//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "ConstantFunc.h"

@implementation ConstantFunc


+ create: aZone withValue: (double) aValue
{
    ConstantFunc* constantFunc = [super create: aZone];


    //if((aValue < 0.0) || (aValue > 1.0))
    //{

        //[InternalError raiseEvent: "ERROR: ConstantFunc >>>> attempting to set ConstantFunc with a non-valid probability\n"];

    //}

    constantFunc->funcValue = aValue;

    return constantFunc;

}
   


//////////////////////////////////////
//
// updateWith:
//
/////////////////////////////////////
- updateWith: anObj
{
   //
   // Nothing to update 
   // so just return self
   //

   return self;
}


- (void) drop
{
    [super drop];
}

@end

