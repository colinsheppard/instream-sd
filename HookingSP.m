//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "HookingSP.h"
#import "Trout.h"
#import "math.h"


@implementation HookingSP

+ createBegin: aZone
{

  HookingSP* aCustomProb = [super createBegin: aZone];

  aCustomProb->troutFunc = nil;

  return aCustomProb;

}

- createEnd
{

  return [super createEnd];

}


- createTroutFuncWithMap: (id <Map>) aMap
         withInputMethod: (SEL) anInputMethod
{

  troutFunc = [TroutFunc createBegin: probZone
                      setInputMethod: anInputMethod];

  return troutFunc;

}


- (double) getSurvivalProb
{

    id aTrout;
    unsigned int timesHooked = 0;
    int speciesNdx;
    double survivalProb = 1.0;

    aTrout = [troutFunc getTrout];

    speciesNdx = [aTrout getSpeciesNdx];

    timesHooked = [aTrout getTimesHooked];

    if(timesHooked > 0)
    {

        survivalProb = pow(dataZone[speciesNdx]->mortFishAngleHookSurvRate, timesHooked);

    }
    else
    {
        survivalProb = 1.0;
    }


    [aTrout setTimesHooked: 0];
    
    /*
    fprintf(stderr, "HOOKINGSP >>>> timesHooked = %d\n", timesHooked);
    fflush(0);
    */


    if((survivalProb < 0.0) || (survivalProb > 1.0))
    {
        [InternalError raiseEvent: "ERROR: AnglingSP >>>> survivalPob is NOT between 0 or 1\n"];
    }

    return survivalProb;

}



- (void) drop
{
    [super drop];
}

@end



