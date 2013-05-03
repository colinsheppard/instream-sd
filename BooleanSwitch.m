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

