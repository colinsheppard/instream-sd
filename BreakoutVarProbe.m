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




#import <objc/objc-api.h>
#include <stdlib.h>

#import "BreakoutVarProbe.h"


@implementation BreakoutVarProbe

- setIsVarProbe: (BOOL) aBool
{
    isVarProbe = aBool;
    return self;
}


- setDataObject: (id) aDataObject
{
   dataObject = aDataObject;
   return self;
}


- setColumnLabel: (char *) aColumnLabel
{
    if(strlen(aColumnLabel) < 50)
    {
        strncpy(columnLabel, aColumnLabel, strlen(aColumnLabel));
    }
    else
    {
        [InternalError raiseEvent: "ERROR: BreakoutVarProbe >>>> setColumnLabel >>>> columnLabel too long\n"];
    }

    return self;
 
}

- setDataColumnWidth: (int) aColumnWidth
{
    columnWidth = aColumnWidth;
    return self;
}

- setUseCSV: (BOOL) aUseCSV
{
     useCSV = aUseCSV;
     return self;
}

- setDataType: (char *) aDataType
{
     strcpy(dataType, aDataType);

     if(!useCSV)
     {
         if(strcmp(dataType, "id") == 0)
         {
              sprintf(formatString, "%s%d%s", "%-", columnWidth, "p");
         }
         else if(strcmp(dataType, "double") == 0)
         {
              sprintf(formatString, "%s%d%s", "%-", columnWidth, "f");
         }
         else if(strcmp(dataType, "int") == 0)
         {
              sprintf(formatString, "%s%d%s", "%-", columnWidth, "ld");
         }
         else if(strcmp(dataType, "string") == 0)
         {
              sprintf(formatString, "%s%d%s", "%-", columnWidth, "s");
         }
         else
         {
             fprintf(stderr, "ERROR: BreakoutDataColumn >>>> setDataType >>>> data type not found\n");
             fflush(0);
             exit(1);
         }
     }
     else
     {
         if(strcmp(dataType, "id") == 0)
         {
              sprintf(formatString, "%s%s%s", "%", "p", ",");
         }
         else if(strcmp(dataType, "double") == 0)
         {
              sprintf(formatString, "%s%s%s", "%", "f", ",");
         }
         else if(strcmp(dataType, "int") == 0)
         {
              sprintf(formatString, "%s%s%s", "%", "ld", ",");
         }
         else if(strcmp(dataType, "string") == 0)
         {
              sprintf(formatString, "%s%s%s", "%", "s", ",");
         }
         else
         {
             fprintf(stderr, "ERROR: BreakoutDataColumn >>>> setDataType >>>> data type not found\n");
             fflush(0);
             exit(1);
         }

     }
     return self;
}

- (BOOL) getIsVarProbe
{
   return isVarProbe;
}


- (id) getDataObject
{
    return dataObject;
}


- (SEL) getDataSelector
{
   return dataSelector;
}


- (char *) getDataType
{
    return dataType;
}

- (char *) getColumnLabel
{
   return columnLabel;
}

- (char *) getFormatString
{
    return formatString;
}



- (const char *)probeAsString 
{

    return [super probeAsString: dataObject Buffer: buffer]; 
}




- setProbedVariable: (const char *) aVariable
{

   IvarList_t anIvarList = probedClass->ivars;
   int i = 0;
   
   while (i < anIvarList->ivar_count
          && strcmp (anIvarList->ivar_list[i].ivar_name, aVariable) != 0)
    i++;
  
   if (i == anIvarList->ivar_count)
   {
       fprintf(stderr, "ERROR: BreakoutVarProbe >>>> setProbedVariable >>>> variable %s was not found in Class %s \n", aVariable, [probedClass getName]);
       fflush(0);
       exit(1);
   }

   [super setProbedVariable: aVariable];

   return self;
}

@end
