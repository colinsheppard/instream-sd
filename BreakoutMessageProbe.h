/*
EcoSwarm library for individual-based modeling, last revised February 2012.
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; Colin Sheppard, critter@stanfordalumni.org; and
Steve Jackson, Jackson Scientific Computing, McKinleyville, California.
Development sponsored by US Bureau of Reclamation under the 
Central Valley Project Improvement Act, EPRI, USEPA, USFWS,
USDA Forest Service, and others.
Copyright (C) 2004-2012 Lang, Railsback & Associates.

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



#import <objectbase/SwarmObject.h>
#import <objectbase/MessageProbe.h>
#import <string.h>
#import <stdlib.h>

#ifndef TRUE
   #define TRUE 1
#endif

#ifndef FALSE
   #define FALSE 0
#endif


@interface BreakoutMessageProbe : MessageProbe
{

   BOOL isVarProbe;
   char columnLabel[50];
   id dataObject;
   SEL dataSelector;
   char formatString[10];
   char dataType[20];

   int columnWidth;

   BOOL useCSV;

}

+              create: aZone
    setProbedSelector: (SEL) aSelector
        setDataObject: anObj;


- setIsVarProbe: (BOOL) aBool;
- setColumnLabel: (char *) aColumnLabel;
- setDataColumnWidth: (int) aColumnWidth;
- setDataType: (char *) aDataType;



- (BOOL) getIsVarProbe;
- (char *) getColumnLabel;
- (id) getDataObject;
- (SEL) getDataSelector;
- setUseCSV: (BOOL) aUseCSV;
- (char *) getDataType;
- (char *) getFormatString;

@end
