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



