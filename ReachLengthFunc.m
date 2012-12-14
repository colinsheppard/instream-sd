//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "ReachLengthFunc.h"

@implementation ReachLengthFunc

+    createBegin: aZone
  setInputMethod: (SEL) anInputMethod
{

   ReachLengthFunc* reachLengthFunc = [super createBegin: aZone];


   [reachLengthFunc setInputMethod: anInputMethod];
   [reachLengthFunc createInputMethodMessageProbeFor: anInputMethod];

   return reachLengthFunc;

}


- createEnd
{

   return [super createEnd];

}


- updateWith: anObj
{ 



   if(inputMethod == (SEL) nil)
   {
      [InternalError raiseEvent: "ERROR: ReachLengthFunc >>>> updateWith >>>> anObj >>>> inputMethod = %p\n", inputMethod];
   }
  
   if(![anObj respondsTo: inputMethod])
   {
      [InternalError raiseEvent: "ERROR: ReachLengthFunc >>>> updateWith >>>> anObj does not respond to inputMethod\n"];
   }

   if(messageProbe == nil)
   {
      [InternalError raiseEvent: "ERROR: ReachLengthFunc >>>> updateWith: >>>> messageProbe is nil\n"];
   } 


   funcValue = [messageProbe doubleDynamicCallOn: anObj];

   return self;

}


- (void) drop
{
    [super drop];
}




@end

