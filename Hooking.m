//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "Hooking.h"
#import "Trout.h"
#import "FishParams.h"
#import <math.h>


@implementation Hooking

+ createBegin: aZone
{

  Hooking* aCustomProb = [super createBegin: aZone];

  return aCustomProb;

}

- createEnd
{

  return [super createEnd];

}


- (double) getSurvivalProb
{

    Trout* aTrout;
    unsigned int timesHooked = 0;
    int speciesNdx;
    double survivalProb = 1.0;
    FishParams* fishParams = (FishParams *) nil;

    aTrout = [survMgr getCurrentAnimal];

    fishParams = [aTrout getFishParams];

    speciesNdx = [aTrout getSpeciesNdx];

    timesHooked = [aTrout getTimesHooked];

    if(timesHooked > 0)
    {
        if(timesHooked == 1)
        {  
            survivalProb = fishParams->mortFishAngleHookSurvRate;
        }
        else
        {
            survivalProb = pow(fishParams->mortFishAngleHookSurvRate, timesHooked);
        }
    }


    
    /*
    fprintf(stderr, "HOOKINGSP >>>> timesHooked = %d\n", timesHooked);
    fflush(0);
    */


    if((survivalProb < 0.0) || (survivalProb > 1.0))
    {
        fprintf(stderr, "ERROR: AnglingSP >>>> survivalPob is NOT between 0 or 1\n");
        fflush(0);
        exit(1);
    }

    return survivalProb;

}


- (void) drop
{
   [super drop];
}


@end



