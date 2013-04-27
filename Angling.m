//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 

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

  [super drop];

}

@end




