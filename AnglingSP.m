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

//
// This custom survival prob simulates mortality due to angling harvest.
// it uses 6 functions, which must which must be created (and therefore 
// appear on the POBS's funcList) in this order;
// 
// 1. A constant function for parameter mortFishAngleSuccess
//
// 2. A custom function for angling pressure
//
// 3. A constant function for reach length
//
// 4. A logistic function for the trout length factor
//
// 5. A function for obtaining the current animal (Trout)
//
// 6. A boolean switch function for the day/night factor
//
//


#import "AnglingSP.h"
#import "Trout.h"
#import "Cell.h"
#import "TroutModelSwarm.h"

@implementation AnglingSP

+ createBegin: aZone
{

  AnglingSP* aCustomProb = [super createBegin: aZone];

  aCustomProb->funcList = [List create: aCustomProb->probZone];

  aCustomProb->poissonDist = nil;
  aCustomProb->uniformDist = nil;

  return aCustomProb;

}

- createEnd
{

  return [super createEnd];

}


- createAnglePressureFuncWithMap: (id <Map>) aMap
           withInputMethod: (SEL) anInputMethod
{

  AnglePressureFunc* anglePressureFunc = [AnglePressureFunc createBegin: probZone
                                                         setInputMethod: anInputMethod];


  [funcList addLast: anglePressureFunc];
 
  anglePressureFunc = [anglePressureFunc createEnd];

  return anglePressureFunc;

}


- createReachLengthFuncWithMap: (id <Map>) aMap
             withInputMethod: (SEL) anInputMethod
{

  ReachLengthFunc* reachLengthFunc = [ReachLengthFunc createBegin: probZone
                                         setInputMethod: anInputMethod];

  [funcList addLast: reachLengthFunc];

  reachLengthFunc = [reachLengthFunc createEnd];

  return reachLengthFunc;

}


- createTroutFuncWithMap: (id <Map>) aMap
         withInputMethod: (SEL) anInputMethod
{

  troutFunc = [TroutFunc createBegin: probZone
                      setInputMethod: anInputMethod];

  return troutFunc;

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
    id <ListIndex> listNdx=nil;
    id aFunc=nil;
    double captureRate = 1.0;

    id aTrout = [troutFunc getTrout];
    unsigned int timesHooked = 0;
    int speciesNdx;
    double fishLength;
    int i;
    double survivalProb = 1.0;
    int timeInterval = [[[habitatObj getSpace] getModel] getNumHoursSinceLastStep];

    if(poissonDist == nil) 
    {

     poissonDist = [PoissonDist create: probZone
                          setGenerator: randGen];



    }
    
    if(uniformDist == nil) 
    {
         uniformDist = [UniformDoubleDist create: probZone
                                     setGenerator: randGen
                                    setDoubleMin: 0
                                           setMax: 1.0];
    }


    //
    //
    //
    //fprintf(stdout, "ANGLINGSP >>>> numHoursSinceLastStep = %d\n", 
               //[[[habitatObj getSpace] getModel] getNumHoursSinceLastStep]);
    //fflush(0);
    //
    //
    //



    // 
    // If the dayNightFactor is zero (as it will often be),
    // then there is no angling pressure and therefore the
    // the fish will not get hooked.
    //
    if([[funcList atOffset: 4] getFuncValue] == 0.0)
    {

       [aTrout  setTimesHooked: 0];
       
       return 1.0;

    }



    listNdx = [funcList listBegin: scratchZone];

    [listNdx setLoc: Start];


    //
    // captureRate is equal to angleSuccess * anglePressure * reachlength
    // * dayNightFactor * logistic(fishLength) * 10E-5.
    // The first 5 terms are the first 5 functions in the PROB
    //
    while(([listNdx getLoc] != End) && ((aFunc = [listNdx next]) != nil))
    {
        captureRate *= [aFunc getFuncValue];

        /*
        fprintf(stderr, "ANGLINGSP >>>> getFuncValue\n");
        fprintf(stderr, "ANGLINGSP >>>> captureRate = %f\n", captureRate);
        fprintf(stderr, "ANGLINGSP >>>> getFuncValue\n");
        fflush(0);
        */
    }

    [listNdx drop];

    captureRate *= 0.00001;

    timesHooked = [poissonDist  getUnsignedSampleWithOccurRate: (double) captureRate
                                                  withInterval: (double) timeInterval];


    speciesNdx = [aTrout getSpeciesNdx];
    fishLength = [aTrout getFishLength];

    if(timesHooked > 0)
    {
        for(i=0; i < timesHooked; i++)
        {
            if(    (fishLength < dataZone[speciesNdx]->mortFishAngleSlotLower)
                || (fishLength > dataZone[speciesNdx]->mortFishAngleSlotUpper))
            {

               if([uniformDist getDoubleSample] < dataZone[speciesNdx]->mortFishAngleFracKeptLegal)
               {
                  survivalProb = 0.0;
               } 

            }
            else
            {
               if([uniformDist getDoubleSample] < dataZone[speciesNdx]->mortFishAngleFracKeptIllegal)
               {
                  survivalProb = 0.0;
               } 
            }
            
        }
    }
    else
    {
        survivalProb = 1.0;
    }


    [aTrout setTimesHooked: timesHooked];
    
    /*
    fprintf(stderr, "ANGLINGSP >>>> getFuncValue\n");
    fprintf(stderr, "ANGLINGSP >>>> captureRate = %f\n", captureRate);
    fprintf(stderr, "ANGLINGSP >>>> timesHooked = %d\n", timesHooked);
    fprintf(stderr, "ANGLINGSP >>>> getFuncValue\n");
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
   [poissonDist drop];
   [uniformDist drop];
   [super drop];
}


@end



