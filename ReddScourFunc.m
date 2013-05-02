/*
inSTREAM Version 6.0, May 2013.
Individual-based stream trout modeling software. 
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; and Colin Sheppard, critter@stanfordalumni.org.
Development sponsored by US Bureau of Reclamation, EPRI, USEPA, USFWS,
USDA Forest Service, and others.
Version 6.0 sponsored by Argonne National Laboratory and Western
Area Power Administration.
Copyright (C) 2004-2013 Lang, Railsback & Associates.

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


#import "ReddScourFunc.h"
#import "FishCell.h"
#import "UTMRedd.h"
#import "globals.h"

@implementation ReddScourFunc

+    createBegin: aZone
  setInputMethod: (SEL) anInputMethod
{

   ReddScourFunc* scourFunc = [super createBegin: aZone];

   [scourFunc setInputMethod: anInputMethod];
   [scourFunc createInputMethodMessageProbeFor: anInputMethod];


   return scourFunc;

}


- createEnd
{

   return [super createEnd];

}


- updateWith: anObj
{
   //double inputValue = -1;
  
  // int speciesNdx;

   double scourParam=0;
   double shearStress=0;
 
   double mortReddShearParamA=0;
   double mortReddShearParamB=0;
   double mortReddScourDepth=0;

   double yesterdaysMaxFlow;
   double todaysMaxFlow;
   double tomorrowsMaxFlow;

   id aRedd = anObj;
   id cell = nil;

   //fprintf(stdout, "ReddScourFunc >>>> updateWith >>>> BEGIN\n");
   //fflush(0);


   if(inputMethod == (SEL) nil)
   {
      [InternalError raiseEvent: "ERROR: ReddScourFunc >>>> updateWith >>>> anObj >>>> inputMethod = %p\n", inputMethod];
   }
  
   if(![anObj respondsTo: inputMethod])
   {
      [InternalError raiseEvent: "ERROR: ReddScourFunc >>>> updateWith >>>> anObj does not respond to inputMethod\n"];
   }

   /*
   if(messageProbe == nil)
   {
      [InternalError raiseEvent: "ERROR: ReddScourFunc >>>> updateWith: >>>> messageProbe is nil\n"];
   } 
   */

   funcValue = 1.0;

   //inputValue = [messageProbe doubleDynamicCallOn: anObj];

   cell = [aRedd getCell];

   //speciesNdx = [aRedd getSpeciesNdx];
   fishParams = [aRedd getFishParams];


   yesterdaysMaxFlow = [cell getPrevDailyMaxFlow];
   todaysMaxFlow = [cell getDailyMaxFlow];
   tomorrowsMaxFlow = [cell getNextDailyMaxFlow];

   if( (yesterdaysMaxFlow < todaysMaxFlow) && (todaysMaxFlow > tomorrowsMaxFlow) ) 
   {

       mortReddShearParamA = [cell getHabShearParamA];
       mortReddShearParamB = [cell getHabShearParamB];
       mortReddScourDepth = fishParams->mortReddScourDepth;

       shearStress = mortReddShearParamA*pow(todaysMaxFlow, mortReddShearParamB);

       scourParam = 3.33*exp(-1.52*shearStress/0.045);
 
       funcValue = 1.0 - exp(-scourParam * mortReddScourDepth);

   }

   if((funcValue < 0.0) || (funcValue > 1.0))
   {
       fprintf(stderr, "ERROR: ReddScourFunc >>>> funcValue is not between 0 an 1\n");
       fflush(0);
       exit(1);
   }

   //fprintf(stdout, "ReddScourFunc >>>> updateWith >>>> END\n");
   //fflush(0);

   return self;
}

- (void) drop
{
    [super drop];
}


@end
