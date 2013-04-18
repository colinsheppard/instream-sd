//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "ReddSuperimpFunc.h"
#import "FishParams.h"
#import "FishCell.h"
#import "UTMRedd.h"
#import "globals.h"

@implementation ReddSuperimpFunc

+    createBegin: aZone
  setInputMethod: (SEL) anInputMethod
{

   ReddSuperimpFunc* superimpFunc = [super createBegin: aZone];

   superimpFunc->uniformDist = nil;
 

   [superimpFunc setInputMethod: anInputMethod];
   [superimpFunc createInputMethodMessageProbeFor: anInputMethod];

   return superimpFunc;

}


- createEnd
{

   return [super createEnd];

}


- updateWith: anObj
{
   id <List> reddList = nil;
   id <ListIndex> reddListNdx = nil;

   FishParams* otherReddFishParams;

   double superimpSF = 1.0;
   id nextRedd;
   double reddSuperimpRisk = -1.0;
   double cellArea;
   double cellGravelFrac;
   double reddSize;

   id aRedd = anObj;
   id cell = nil;

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

   if(messageProbe == nil)
   {
        fprintf(stderr, "ERROR: ReddSuperimpFunc >>>> updateWith: >>>> messageProbe is nil\n");
        fflush(0);
        exit(1);
   } 

   cell = [aRedd getCell];

   if(uniformDist == nil)
   {
    id aRandGen = [cell getRandGen];

    //
    // Ensure that aRandGen conformsTo the correct protocol
    //

        if(aRandGen == nil)
        {
           fprintf(stderr, "ERROR: ReddSuperimpFunc >>>> the random generator is nil\n");
           fflush(0);
           exit(1);
        }
     

     //
     //Create Uniform Dist
     //
     uniformDist = [UniformDoubleDist create: [self getZone]
                                setGenerator: aRandGen
                                setDoubleMin: 0.0
                                      setMax: 1.0];
 
   }

   //
   // We don't need to use the message probe
   // in this function
   //
   //funcValue = [messageProbe doubleDynamicCallOn: anObj];

   if((reddList = [cell getReddsIContain]) != nil) 
   {
      reddListNdx = [reddList listBegin: scratchZone];

      while(([reddListNdx getLoc] != End) && ((nextRedd = [reddListNdx next]) != nil)) 
      {

            if(nextRedd == aRedd) break;

           //
           // Note: We are neglecting the possibility
           //       that redds last a full year, so we don't
           //       check that createYear = cuurentYear
           //
            if([nextRedd getCreateTimeT] == [aRedd getCurrentTimeT])
            {
                  otherReddFishParams = [nextRedd getFishParams];

                  reddSize = otherReddFishParams->reddSize;
                 
                  cellArea = [cell getPolyCellArea];
  
                  cellGravelFrac = [[aRedd getCell] getCellFracSpawn];
 
                  if(cellGravelFrac == 0.0) 
                  {
                      reddSuperimpRisk = 0.0; //We can't have superimposition
                                              //if there isn't any gravel
                  }
                  else 
                  { 
                      //
                      //reddSuperimpRisk can be greater than 1 and that's ok
                      //
                      reddSuperimpRisk = reddSize/(cellArea*cellGravelFrac);
                  }

                  uniformRanNum = [uniformDist getDoubleSample];

                  if(uniformRanNum < reddSuperimpRisk) 
                  {
                      superimpSF *= [uniformDist getDoubleSample];
                  }
            }

     } //while

     [reddListNdx drop];

    }

    funcValue = superimpSF;
   
   
   if((funcValue < 0.0) || (funcValue > 1.0))
   {
       fprintf(stderr, "ERROR: ReddSuperimpFunc >>>> funcValue is not between 0 an 1\n");
       fflush(0);
       exit(1);
   }


   return self;
}


- (void) drop
{
   //fprintf(stdout, "ReddSuperimpFunc >>>> drop >>>> BEGIN\n");
   //fflush(0);

   if(uniformDist)
   {
      [uniformDist drop];
   }
   [super drop];

   //fprintf(stdout, "ReddSuperimpFunc >>>> drop >>>> END\n");
   //fflush(0);
}


@end

