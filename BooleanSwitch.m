//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "BooleanSwitch.h"

@implementation BooleanSwitch


+          create: aZone
  withInputMethod: (SEL) anInputMethod
     withYesValue: (double) aYesValue
      withNoValue: (double) aNoValue;
{

   BooleanSwitch* booleanSwitch = [super create: aZone];

   booleanSwitch->messageProbe = nil;

   [booleanSwitch setInputMethod: anInputMethod];
   [booleanSwitch createInputMethodMessageProbeFor: anInputMethod];


   booleanSwitch->yesValue = aYesValue;
   booleanSwitch->noValue = aNoValue;

   return booleanSwitch;

}




- updateWith: anObj
{


   BOOL inputVal=NO;

    
   if(inputMethod == (SEL) nil)
   {
      [InternalError raiseEvent: "ERROR: BooleanSwitch >>>> updateWith >>>> anObj >>>> inputMethod = %p\n", inputMethod];
   }
      

   if(![anObj respondsTo: inputMethod])
   {
      [InternalError raiseEvent: "ERROR: BooleanSwitch >>>> updateWith >>>> anObj does not respond to inputMethod\n"];
   }

   if(messageProbe == nil)
   {
       [InternalError raiseEvent: "ERROR: BooleanSwitch >>>> updateWith: >>>> messageProbe is nil\n"];
 
   } 

   inputVal = (BOOL) [messageProbe longDynamicCallOn: anObj];


   //fprintf(stdout, "BooleanSwitch >>>> anUpdateObj inputVal = %u \n", inputVal);
   //fflush(0);

   funcValue = (inputVal == YES)? yesValue : noValue;

   //fprintf(stdout, "BooleanSwitch >>>> anUpdateObj funcValue = %f \n", funcValue);
   //fflush(0);

   return self;

}

- (void) drop
{
   [super drop];
}


@end

