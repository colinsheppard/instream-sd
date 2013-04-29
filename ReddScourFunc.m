//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


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

       mortReddShearParamA = fishParams->mortReddShearParamA;
       mortReddShearParamB = fishParams->mortReddShearParamB;
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
