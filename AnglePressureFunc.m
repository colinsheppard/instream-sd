//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "AnglePressureFunc.h"

@implementation AnglePressureFunc

+    createBegin: aZone
     setInputMethod: (SEL) anInputMethod
{

   AnglePressureFunc* anglePressureFunc = [super createBegin: aZone];


   [anglePressureFunc setInputMethod: anInputMethod];
   [anglePressureFunc createInputMethodMessageProbeFor: anInputMethod];

   return anglePressureFunc;

}


- createEnd
{

   return [super createEnd];

}


- updateWith: anObj
{
   //is updated with the monthly fishing pressure 


   if(inputMethod == (SEL) nil)
   {
      [InternalError raiseEvent: "ERROR: AnglePressureFunc >>>> updateWith >>>> anObj >>>> inputMethod = %p\n", inputMethod];
   }
  
   if(![anObj respondsTo: inputMethod])
   {
      [InternalError raiseEvent: "ERROR: AnglePressureFunc >>>> updateWith >>>> anObj does not respond to inputMethod\n"];
   }

   if(messageProbe == nil)
   {
      [InternalError raiseEvent: "ERROR: AnglePressureFunc >>>> updateWith: >>>> messageProbe is nil\n"];
   } 


   funcValue = (double) [messageProbe longDynamicCallOn: anObj];

   return self;

}

- (void) drop
{
   [super drop];
}


@end

