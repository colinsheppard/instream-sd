//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 

#import "UTMInterpolatorFactory.h"

@implementation UTMInterpolatorFactory

+ create: aZone 
{
   return [super create: aZone];
}



//////////////////////////////////////////
//
// setListOfUTMInputData
//
//////////////////////////////////////////
- setListOfUTMInputData: (id <List>) aList
{
    listOfUTMInputData = aList;
    return self;
}




//////////////////////////////////
//
// setUTMCell
//
//////////////////////////////////
- setUTMCell: (UTMCell *) aUTMCell
{
    utmCell = aUTMCell;
    return self;
}



///////////////////////////////////
//
// createUTMVelocityInterpolator
//
///////////////////////////////////
- createUTMVelocityInterpolator
{
  id <InterpolationTable> velocityInterpolator = nil;

  velocityInterpolator = [utmCell getVelocityInterpolator];

  if(velocityInterpolator != nil)
  {
      fprintf(stderr, "ERROR: UTMInterpolatorFactory >>>> velocityInterpolator already exists for utmCell number %d\n", [utmCell getUTMCellNumber]);
      fflush(0);
      exit(1);
  }

  velocityInterpolator = [InterpolationTable create: [utmCell getUTMCellZone]]; 

  //
  // Add first point 0,0 to ensure velocities do not become negative
  // at low flows.
  //
  [velocityInterpolator addX: 0.0 Y: 0.0];

  [utmCell setVelocityInterpolator: velocityInterpolator];

 
  return self;
}
    


///////////////////////////////////////
//
// createUTMDepthInterpolator
//
//////////////////////////////////////
- createUTMDepthInterpolator
{
  id <InterpolationTable> depthInterpolator = nil;

  depthInterpolator = [utmCell getDepthInterpolator];
  if(depthInterpolator != nil)
  {
      fprintf(stderr, "ERROR: UTMInterpolatorFactory >>>> depthInterpolator already exists for utmCell number %d\n", [utmCell getUTMCellNumber]);
      fflush(0);
      exit(1);
  }

  depthInterpolator = [InterpolationTable create: [utmCell getUTMCellZone]]; 

  [utmCell setDepthInterpolator: depthInterpolator];
 
  return self;
}


///////////////////////////////////////
//
// updateUTMVelocityInterpolator
//
///////////////////////////////////////
- updateUTMVelocityInterpolator
{
   int numberOfNodes = 0;
   int** cornerNodeArray = NULL;
   id <InterpolationTable> velocityInterpolator = nil;
   int i;

   id <ListIndex> ndx = [listOfUTMInputData listBegin: scratchZone];
   UTMInputData* utmInputData = nil;

   //fprintf(stdout, "UTMInterpolatorFactory >>>> updateUTMVelocityInterpolator >>>> BEGIN\n");
   //fflush(0);

   if(utmCell == nil)
   {
      fprintf(stdout, "ERROR: UTMInterpolatorFactory >>>> updateUTMVelocityInterpolator >>>> utmCell is nil\n");
      fflush(0);
      exit(1);
   }
      
   numberOfNodes = [utmCell getNumberOfNodes];
   cornerNodeArray = [utmCell getCornerNodeArray];
   velocityInterpolator = [utmCell getVelocityInterpolator];

   while(([ndx getLoc] != End) && ((utmInputData = [ndx next]) != nil))
   {
       double utmFlow = [utmInputData getUTMFlow];
       double** velocityArray = [utmInputData getVelocityArray]; 
       double averageVelocity = 0.0;

       for(i = 0; i <  numberOfNodes; i++)
       {
            averageVelocity += *velocityArray[*cornerNodeArray[i]]; 
       }

       averageVelocity = averageVelocity/numberOfNodes;

       [velocityInterpolator addX: utmFlow Y: averageVelocity];
   }

   [ndx drop];

   //fprintf(stdout, "UTMInterpolatorFactory >>>> updateUTMVelocityInterpolator >>>> END\n");
   //fflush(0);

   //exit(0);

   return self;
}



/////////////////////////////////////////
//
// updateUTMDepthInterpolator
//
/////////////////////////////////////////
- updateUTMDepthInterpolator
{
   int numberOfNodes = 0;
   int** cornerNodeArray = NULL;
   id <InterpolationTable> depthInterpolator = nil;
   int i;

   id <ListIndex> ndx = [listOfUTMInputData listBegin: scratchZone];
   UTMInputData* utmInputData = nil;

   //fprintf(stdout, "UTMInterpolatorFactory >>>> updateUTMDepthInterpolator >>>> BEGIN\n");
   //fflush(0);

   if(utmCell == nil)
   {
      fprintf(stdout, "ERROR: UTMInterpolatorFactory >>>> updateUTMDepthInterpolator >>>> utmCell is nil\n");
      fflush(0);
      exit(1);
   }
      
   numberOfNodes = [utmCell getNumberOfNodes];
   cornerNodeArray = [utmCell getCornerNodeArray];
   depthInterpolator = [utmCell getDepthInterpolator];

   while(([ndx getLoc] != End) && ((utmInputData = [ndx next]) != nil))
   {
       double utmFlow = [utmInputData getUTMFlow];
       double** depthArray = [utmInputData getDepthArray]; 
       double averageDepth = 0.0;

       for(i = 0; i <  numberOfNodes; i++)
       {
            averageDepth += *depthArray[*cornerNodeArray[i]]; 
       }

       averageDepth = averageDepth/numberOfNodes;

       [depthInterpolator addX: utmFlow Y: averageDepth];
   }

   [ndx drop];

   //fprintf(stdout, "UTMInterpolatorFactory >>>> updateUTMDepthInterpolator >>>> END\n");
   //fflush(0);

   return self;
}


- (void) drop
{
    [super drop];
}

@end
