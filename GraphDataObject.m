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



#import "GraphDataObject.h"

@implementation GraphDataObject
+ createBegin: aZone {
  GraphDataObject* obj;

  obj = [super createBegin: aZone];

  obj->cumSum = 0;

  return obj;

}

- createEnd {
  
  return [super createEnd];

}

- setDataSource: anObject {

  dataSource = anObject;

  return self;

}

/////////////////////////////////////////
//
// getData
//
// in the event the data source is an 
// integer pointer
//
////////////////////////////////////////
- (int) getData {

  count = *((int *) dataSource);


  //fprintf(stderr, "GRAPH DATA OBJECT >>>> getData dataSource = %p \n", dataSource);
  //fprintf(stderr, "GRAPH DATA OBJECT >>>> getData count = %d \n", count);
  //fflush(0);

  return count;

}


////////////////////////////////////////////////
//
// getCumSum
//
////////////////////////////////////////////////
- (unsigned) getCumSum {

  cumSum += [dataSource getCount];

  fprintf(stderr, "GRAPH DATA OBJECT cumSum = %d \n", cumSum);
  fflush(0);
  

  return cumSum;

}

- (unsigned) getCount {

  if(1) {
  fprintf(stderr, "GRAPH DATA OBJECT >>>> getCount dataSource = %p \n", dataSource);
  fprintf(stderr, "GRAPH DATA OBJECT >>>> getCount count = %d \n", [dataSource getCount]);
  fflush(0);
  }

   return [dataSource getCount];

}

- (void) drop
{
    [super drop];
}
@end
