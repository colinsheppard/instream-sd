/*
EcoSwarm library for individual-based modeling, last revised February 2012.
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; Colin Sheppard, critter@stanfordalumni.org; and
Steve Jackson, Jackson Scientific Computing, McKinleyville, California.
Development sponsored by US Bureau of Reclamation under the 
Central Valley Project Improvement Act, EPRI, USEPA, USFWS,
USDA Forest Service, and others.
Copyright (C) 2004-2012 Lang, Railsback & Associates.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see file LICENSE); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.
*/


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

