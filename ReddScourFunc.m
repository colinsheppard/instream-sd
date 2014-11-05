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

   scourFunc->habShearParamA = (double) LARGEINT;
   scourFunc->habShearParamB = (double) LARGEINT;

   return scourFunc;

}

- createEnd
{

   return [super createEnd];

}


- updateWith: anObj
{
   //double inputValue = -1;
  
   int speciesNdx;

   double scourParam=0.0;
   double shearStress=0.0;
   double scourSurvival=0.0;
 
   double mortReddScourDepth=0;

   double yesterdaysMaxFlow;
   double todaysMaxFlow;
   double tomorrowsMaxFlow;

   id aRedd = anObj;
   id cell = nil;
   FishParams* fishParams;

   if(inputMethod == (SEL) nil)
   {
      fprintf(stderr, "ERROR: ReddSuperimpFunc >>>> updateWith >>>> anObj >>>> inputMethod = %p\n", inputMethod);
      fflush(0);
      exit(1);
   }
  
   if(![anObj respondsTo: inputMethod])
   {
      fprintf(stderr, "ERROR: ReddSuperimpFunc >>>> updateWith >>>> anObj does not respond to inputMethod\n");
      fflush(0);
      exit(1);
   }


   funcValue = 1.0;


   cell = [aRedd getCell];

   if(cell == nil)
   {
       fprintf(stderr, "ReddScourFunc >>>> updateWith >>>> cell id nil\n");
       fflush(0);
       exit(1);
   }

   if(uniformDoubleDist == nil)
   {
      id aRandGen = [cell getRandGen];

      if(aRandGen == nil)
      {
         fprintf(stderr, "ERROR: ReddScourFunc >>>> updateWith >>>> the random generator is nil\n");
         fflush(0);
         exit(1);
      }
     
      //
      //Create the uniform distribution
      //
      uniformDoubleDist = [UniformDoubleDist create: [self getZone]
                                 setGenerator: aRandGen
                                 setDoubleMin: 0.0
                                       setMax: 1.0];
   }

 
   //
   // Get the following parameters once.
   // Assumption: They don't change within a reach during a model run
   //
   if(habShearParamA >= (double) LARGEINT)
   {
       habShearParamA = [cell getHabShearParamA];
   }
   if(habShearParamB >= (double) LARGEINT)
   {
       habShearParamB = [cell getHabShearParamB];
   }
  
   fishParams = [aRedd getFishParams];
   speciesNdx = [aRedd getSpeciesNdx];

   yesterdaysMaxFlow = [cell getPrevDailyMaxFlow];
   todaysMaxFlow = [cell getDailyMaxFlow];
   tomorrowsMaxFlow = [cell getNextDailyMaxFlow];

   if( (yesterdaysMaxFlow < todaysMaxFlow) && (todaysMaxFlow > tomorrowsMaxFlow) ) 
   {
       mortReddScourDepth = fishParams->mortReddScourDepth;

       shearStress = habShearParamA*pow(todaysMaxFlow, habShearParamB);

       scourParam = 3.33*exp(-1.52*shearStress/0.045);

       if(isnan(scourParam) || isinf(scourParam))
       {
            fprintf(stderr, "ERROR: ReddScourFunc >>>> scourParam >>>> updateWith >>>> scourParam is nan or inf\n");
            fprintf(stderr, "ERROR: ReddScourFunc >>>> scourParam >>>> updateWith >>>> shearStress = %f\n", shearStress);
            fprintf(stderr, "ERROR: ReddScourFunc >>>> scourParam >>>> updateWith >>>> todaysMaxFlow = %f\n", todaysMaxFlow);
            fprintf(stderr, "ERROR: ReddScourFunc >>>> scourParam >>>> updateWith >>>> habShearParamA = %f\n", habShearParamA);
            fprintf(stderr, "ERROR: ReddScourFunc >>>> scourParam >>>> updateWith >>>> habShearParamB = %f\n", habShearParamB);
            fflush(0);
            exit(1);
       }

       if((scourParam * mortReddScourDepth) > 100.0)
       {
           funcValue = 1.0;
       }
       else
       {
           scourSurvival = 1.0 - exp(-scourParam * mortReddScourDepth);

           if(isnan(scourSurvival) || isinf(scourSurvival))
           {
                fprintf(stderr, "ERROR: ReddScourFunc >>>> scourParam >>>> updateWith >>>> scourSurvival is nan or inf\n");
                fflush(0);
                exit(1);
           }
            
           if([uniformDoubleDist getDoubleSample] > scourSurvival)
           {
              funcValue = 0.0;
           }
       }

   } // if (flow peaked)

   if((funcValue < 0.0) || (funcValue > 1.0))
   {
      fprintf(stderr,"ERROR: ReddScourFunc >>>> funcValue is not between 0 an 1\n");
      fflush(0);
      exit(1);
   }

   return self;
}

- (void) drop
{
    [super drop];
}


@end
