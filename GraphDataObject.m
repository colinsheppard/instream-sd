//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



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
