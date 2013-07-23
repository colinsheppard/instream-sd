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

#import "Angling.h"
#import "Trout.h"
#import "FishCell.h"
#import "TroutModelSwarm.h"

@implementation Angling

+ createBegin: aZone
{
  #ifdef TEST_OUTPUT_ON
     static FILE* outPtr = NULL;
  #endif
  
  Angling* aCustomProb = [super createBegin: aZone];


  aCustomProb->poissonDist = [PoissonDist create: aCustomProb->probZone
                                    setGenerator: randGen];

  aCustomProb->uniformDist = [UniformDoubleDist create: aCustomProb->probZone
                                          setGenerator: randGen
                                          setDoubleMin: 0
                                                setMax: 1.0];

  #ifdef TEST_OUTPUT_ON
   if(outPtr == NULL)
   {
     if((outPtr = fopen("AnglingSurvTest.rpt", "w")) == NULL)
     {
         fprintf(stderr, "ERROR: Angling >>>> getSurvivalProb >>>> unable to open AnglingSurvTest.Rpt\n");
         fflush(0);
         exit(1);
     }

   }
   aCustomProb->anglingFP = outPtr;
  #endif 

  return aCustomProb;
}



- createEnd
{
  return [super createEnd];
}



//////////////////////////////////////////////////
//
// getSurvivalProb
//
// This method has two points from where it can return
//
/////////////////////////////////////////////////
- (double) getSurvivalProb
{
    double captureRate;
    double anglePressure;

    Trout* aTrout;
    FishParams* fishParams = (FishParams *) nil;
    FishCell* habitatObj;
    unsigned int timesHooked = 0;
  //  int speciesNdx;
    double fishLength;
    
    int i;
    double survivalProb = 1.0;
    double timeInterval;

    aTrout = [survMgr getCurrentAnimal];

    if([aTrout getAmIInHidingCover])
    {
		//fprintf(stdout, "ANGLINGSP >>>> fish is in hiding cover\n");
        [aTrout setTimesHooked: 0];
        return 1.0;
    }

    fishParams = [aTrout getFishParams];
    habitatObj = [survMgr getHabitatObject];

    anglePressure = [habitatObj getAnglingPressure];

    if(anglePressure <= 0.0)
    {
		//fprintf(stdout, "ANGLINGSP >>>> angle pressure is zero\n");
        [aTrout setTimesHooked: 0];
        return 1.0;
    }


  //  speciesNdx = [aTrout getSpeciesNdx];

    captureRate =   fishParams->mortFishAngleSuccess
                  * anglePressure
                  * [[habitatObj getSpace] getReachLength] * 1.0E-5
                  * [[funcList getFirst] getFuncValue];

    timeInterval = 
        (double) [[[habitatObj getSpace] getModel] getNumHoursSinceLastStep]/24;

	//fprintf(stdout, "ANGLINGSP >>>> capture rate: %f\n", captureRate);

    timesHooked = [poissonDist  getUnsignedSampleWithOccurRate: (double) captureRate
                                                  withInterval: (double) timeInterval];

    fishLength = [aTrout getFishLength];

    if(timesHooked > 0)
    {
        for(i=0; i < timesHooked; i++)
        {
            if( (fishLength < (fishParams->mortFishAngleSlotLower))
                || (fishLength > (fishParams->mortFishAngleSlotUpper)))
            {
               if([uniformDist getDoubleSample] < fishParams->mortFishAngleFracKeptLegal)
               {
                  survivalProb = 0.0;
               } 
            }
            else
            {
               if([uniformDist getDoubleSample] < fishParams->mortFishAngleFracKeptIllegal)
               {
                  survivalProb = 0.0;
               } 
            }
        }
    }

    [aTrout setTimesHooked: timesHooked];
    
    #ifdef TEST_OUTPUT_ON
    {
        static BOOL firstTime = YES;
   
        if(firstTime == YES)
        {
            fprintf(anglingFP,"%-20s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s\n", "AnglingSurvProb", "FishCell", "Trout", "CurrentPhase", "FishLength", "AnglePressure", "TimeInterval", "CaptureRate", "TimesHooked", "SurvProb");
            fflush(anglingFP);
            firstTime = NO;
        }
        else
        {
            fprintf(anglingFP,"%-20p%-15d%-15p%-15E%-15E%-15E%-15E%-15E%-15E%-15E\n", 
                                         self, 
                                         [habitatObj getPolyCellNumber], 
                                         aTrout, 
                                         (double) [aTrout getCurrentPhase],
                                         fishLength, 
                                         anglePressure, 
                                         timeInterval, 
                                         captureRate, 
                                         (double) timesHooked, 
                                         survivalProb);

            fflush(anglingFP);
        }
       
        /*
        fprintf(stderr, "ANGLINGSP >>>> self = %p\n", self);
        fprintf(stderr, "ANGLINGSP >>>> anglePressure = %f\n", anglePressure);
        fprintf(stderr, "ANGLINGSP >>>> timeInterval = %f\n", timeInterval);
        fprintf(stderr, "ANGLINGSP >>>> captureRate = %f\n", captureRate);
        fprintf(stderr, "ANGLINGSP >>>> timesHooked = %d\n", timesHooked);
        fprintf(stderr, "ANGLINGSP >>>> getSurvivalProb\n");
        fflush(0);
        */
    }
    #endif
   
    if((survivalProb < 0.0) || (survivalProb > 1.0))
    {
        fprintf(stderr, "ERROR: Angling >>>> survivalPob is NOT between 0 or 1\n");
        fflush(0);
        exit(1);
    }

    return survivalProb;

}



- (void) drop
{
  [poissonDist drop];
  [uniformDist drop];
 
  #ifdef TEST_OUTPUT_ON
  {
    static BOOL FIRSTDROP = YES; 
    if(FIRSTDROP == YES)
    {
       fclose(anglingFP);
       anglingFP = NULL;
       FIRSTDROP = NO;
    }
    anglingFP = NULL;
  }
  #endif

  if(randGen){
      [randGen drop]; 
      randGen = nil;
  }

  [super drop];

  //fprintf(stdout, "Angling >>>> drop >>>> END\n");
  //fflush(0);
}

@end




