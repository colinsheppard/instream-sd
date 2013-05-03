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
// TroutFunc is placed on the list of animal
// update functions in the survival manager.
// All it does is set and return the current
// animal. It seems safer to do it this way
// because when updating/getting the survival probs,
// the survival manager can test to ensure
// that the current animal is indeed the animal
// that we want to operate on and NOT an animal
// from a previous calculation. 
//


#import "TroutFunc.h"

@implementation TroutFunc

+    createBegin: aZone
  setInputMethod: (SEL) anInputMethod
{

   TroutFunc* troutFunc = [super createBegin: aZone];

   troutFunc->aTrout = nil;

   //
   // Added 8/25/01 for use with SurvMGR output routines
   //  
   [troutFunc setInputMethod: anInputMethod];
   [troutFunc createInputMethodMessageProbeFor: anInputMethod];

   return troutFunc;

}


- createEnd
{

   return [super createEnd];

}


- updateWith: anObj
{

    aTrout = anObj;

    funcValue = 1.0;

    return self;

}




- getTrout
{
    if(aTrout == nil) 
    {
        fprintf(stderr, "ERROR: TroutFunc >>>> aTrout is %p\n", aTrout);
        fflush(0);
        exit(1);
    }

   return aTrout;
}

- (void) drop
{
    [super drop];
}


@end
