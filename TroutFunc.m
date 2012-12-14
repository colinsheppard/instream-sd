//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


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


#import "TroutFunc.h"

@implementation TroutFunc

+    createBegin: aZone
  setInputMethod: (SEL) anInputMethod
{

   TroutFunc* troutFunc = [super createBegin: aZone];

   troutFunc->aTrout = nil;

   //
   // Added 8/25/01 for use with SurvMGR output routines
   //  
   [troutFunc setInputMethod: anInputMethod];
   [troutFunc createInputMethodMessageProbeFor: anInputMethod];

   return troutFunc;

}


- createEnd
{

   return [super createEnd];

}


- updateWith: anObj
{

    aTrout = anObj;

    funcValue = 1.0;

    return self;

}




- getTrout
{
    if(aTrout == nil) 
    {
        fprintf(stderr, "ERROR: TroutFunc >>>> aTrout is %p\n", aTrout);
        fflush(0);
        exit(1);
    }

   return aTrout;
}

- (void) drop
{
    [super drop];
}


@end
