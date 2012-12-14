//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "BooleanSwitchFunc.h"

@implementation BooleanSwitchFunc


+          create: aZone
  withInputMethod: (SEL) anInputMethod
     withYesValue: (double) aYesValue
      withNoValue: (double) aNoValue;
{

   BooleanSwitchFunc* booleanSwitchFunc = [super create: aZone];

   booleanSwitchFunc->messageProbe = nil;

   [booleanSwitchFunc setInputMethod: anInputMethod];
   [booleanSwitchFunc createInputMethodMessageProbeFor: anInputMethod];


   booleanSwitchFunc->yesValue = aYesValue;
   booleanSwitchFunc->noValue = aNoValue;

   return booleanSwitchFunc;

}




- updateWith: anObj
{


   BOOL inputVal=NO;

    
   if(inputMethod == (SEL) nil)
   {
      [InternalError raiseEvent: "ERROR: BooleanSwitchFunc >>>> updateWith >>>> anObj >>>> inputMethod = %p\n", inputMethod];
   }

   if(anObj == nil) 
   {
      [InternalError raiseEvent: "ERROR: BooleanSwitchFunc >>>> updateWith >>>> anObj is nil\n"];
   }
      

   if(![anObj respondsTo: inputMethod])
   {
      [InternalError raiseEvent: "ERROR: BooleanSwitchFunc >>>> updateWith >>>> anObj does not respond to inputMethod\n"];
   }

   if(messageProbe == nil)
   {
       [InternalError raiseEvent: "ERROR: BooleanSwitchFunc >>>> updateWith: >>>> messageProbe is nil\n"];
 
   } 

   inputVal = (BOOL) [messageProbe longDynamicCallOn: anObj];


   //fprintf(stdout, "BooleanSwitchFunc >>>> anUpdateObj inputVal = %u \n", inputVal);
   //fflush(0);

   funcValue = (inputVal == YES)? yesValue : noValue;

   //fprintf(stdout, "BooleanSwitchFunc >>>> anUpdateObj funcValue = %f \n", funcValue);
   //fflush(0);

   return self;

}

- (void) drop
{
    [super drop];
}


@end

