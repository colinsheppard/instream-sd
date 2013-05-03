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


#import "ReddScour.h"


@implementation ReddScour

+ createBegin: aZone
{

  ReddScour* aCustomProb = [super createBegin: aZone];

  aCustomProb->scourFunc = nil;

  return aCustomProb;

}

- createEnd
{
  return [super createEnd];
}


- createReddScourFuncWithMap: (id <Map>) aMap
                withInputMethod: (SEL) anInputMethod
{

  scourFunc = [ReddScourFunc createBegin: probZone
                          setInputMethod: anInputMethod];
  if(scourFunc == nil)
  {
     fprintf(stderr, "ERROR: ReddScour >>>> createReddScourFuncWithMap:withInputMethod: >>>> scourFunc is nil\n");
     fflush(0);
     exit(1);
  }

  return scourFunc;

}



- (double) getSurvivalProb
{

    id aFunc=nil;

    aFunc = [funcList getFirst];

    //fprintf(stdout, "ReddScour >>>> getSurvivalProb >>>> BEGIN\n");
    //fflush(0); 

    if(aFunc == nil)
    {
       fprintf(stderr, "ERROR: ReddScour >>>> getSurvivalProb >>>> aFunc is nil\n");
       fflush(0);
       exit(1);
    }

    //fprintf(stdout, "ReddScour >>>> getSurvivalProb >>>> END\n");
    //fflush(0); 

    //return [scourFunc getFuncValue];
    return [aFunc getFuncValue];
}


- (void) drop
{
    fprintf(stdout, "ReddScour >>>> drop >>>> BEGIN\n");
    fflush(0);

    [super drop];

    fprintf(stdout, "ReddScour >>>> drop >>>> END\n");
    fflush(0);
}


@end



