//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 




#import "StationObject.h"

@implementation Station 

+ createBegin: aZone {
  Station * newStation;
  id <Array> tempArray;
  id tempZone;

  newStation = [super createBegin: aZone]; 

  tempArray = [Array createBegin: aZone];
  [tempArray setCount: 0];
  [tempArray setDefaultMember: nil];
  tempArray = [tempArray createEnd];
 
  newStation->flowArray = tempArray; 
  

  tempArray = [Array createBegin: aZone];
  [tempArray setCount: 0];
  [tempArray setDefaultMember: nil];
  tempArray = [tempArray createEnd];
 
  newStation->velocityArray = tempArray; 
  

  tempArray = [Array createBegin: aZone];
  [tempArray setCount: 0];
  [tempArray setDefaultMember: nil];
  tempArray = [tempArray createEnd];
 
  newStation->depthArray = tempArray; 
  
  tempZone = [Zone create: aZone];

  newStation->stationZone = tempZone;

  newStation->maxFlowOffset = 0;
  newStation->maxDepthOffset = 0;
  newStation->maxVelocityOffset = 0;


  return newStation;

}


- createEnd {
 
  return [super createEnd];

}

- setCellNo: (int) aCellNo {

  cellNo = aCellNo;

  return self;

}


- setTransect: (int) aTransect {

   transect = aTransect;

   return self;

}


- setStation: (double) aStation {

   station = aStation;

   return self;

}

- setElev: (double) anElev {

  elev = anElev;

  return self;

}





- (int) getCellNo {

  return cellNo;

}





- (int) getTransect {

  return transect;

}

- (double) getStation {

   return station;

}


///////////////////////////////////////////////////////
//
// getVelocityAtOffset
//
//////////////////////////////////////////////////////
- (double) getVelocityAtOffset: (int) anOffset {
  double velocity;

  if( (anOffset > maxVelocityOffset) || (anOffset < 0) ) {

   [InternalError raiseEvent:"ERROR: In *station* offset is out of bounds\n"];

  } 

  velocity = *( (double *) [velocityArray atOffset: anOffset]);  
 
  return velocity;

}


///////////////////////////////////////////////////////
//
// getDepthAtOffset
//
//////////////////////////////////////////////////////
- (double) getDepthAtOffset: (int) anOffset {
  double depth;

  if( (anOffset > maxDepthOffset) || (anOffset < 0) ) {

   [InternalError raiseEvent:"ERROR: In *station* offset is out of bounds\n"];

  } 

  depth = *( (double *) [depthArray atOffset: anOffset]);  
 
  return depth;

}



/////////////////////////////////////////////////////////
//
// addAFlow
//
/////////////////////////////////////////////////////////
- addAFlow: (double) aFlow atTransect: (int) aTransect
                          andStation: (double) aStation {

  double *log10Flow;

  if( (aTransect != transect) || (abs(aStation - station) > 0.0001) ) {

    [InternalError raiseEvent:"ERROR: transect and/or station incorrect in Station\n"];

  }

   log10Flow = (double *) [stationZone alloc: sizeof(double)];




    if(aFlow > 0) {
  
       *log10Flow = log10(aFlow);

    }
    else if(aFlow == 0.0) {
    
       *log10Flow = -4.0;

       [WarningMessage raiseEvent: "Warning: In StationObject FLOW is 0 and the log flow is being set to -4\n"];

    }
    else {

       [InternalError raiseEvent: "ERROR: FLOW is negative (Hydraulic input file) aborting\n"];
   
    }
 
   offset = [flowArray getCount];

   //fprintf(stdout,"STATIONOBJECT>>>> Transect = %d Cellno = %d Station = %f offset = %d aFlow = %f \n", transect, cellNo, station, offset, aFlow);
   //fflush(0);

   [flowArray setCount: offset + 1];
   [flowArray atOffset: offset put: (void *) log10Flow];
  
   maxFlowOffset++;

   return self;

}




//////////////////////////////////////////////////////////
//
// addADepth
//
/////////////////////////////////////////////////////////
- addADepth: (double) aDepth atTransect: (int) aTransect
                          andStation: (double) aStation {

  double *log10Depth;

  if( (aTransect != transect) || (abs(aStation - station) > 0.0001) ) {

    [InternalError raiseEvent:"ERROR: transect and/or station incorrect in Station\n"];

  }

   log10Depth = (double *) [stationZone alloc: sizeof(double)];
  

   if(aDepth <= 0) {

      *log10Depth = -1.0;

   }
   else {

       *log10Depth = log10(100*aDepth);

   }

   offset = [depthArray getCount];

   //fprintf(stdout,"STATIONOBJECT>>>> Transect = %d Cellno = %d Station = %f offset = %d aDepth = %f \n", transect, cellNo, station, offset, aDepth);
   //fflush(0);

   [depthArray setCount: offset + 1];
   [depthArray atOffset: offset put: (void *) log10Depth];
  
   maxDepthOffset++;

   return self;

}




/////////////////////////////////////////////////////////////////
//
// addAVelocity
//
/////////////////////////////////////////////////////////////////
- addAVelocity: (double) aVelocity atTransect: (int) aTransect 
                                   andStation: (double) aStation {

  double *log10Velocity;

  // 
  // set the average velocity for all the stations within a transect
  //

  if( (aTransect != transect) || (abs(aStation - station) > 0.0001) ) {

    [InternalError raiseEvent:"ERROR: transect and/or station incorrect in Station\n"];

  }

   log10Velocity = (double *) [stationZone alloc: sizeof(double)];
  
   
   if(aVelocity <= 0) {

       *log10Velocity = -1.0;

   }
   else {

      *log10Velocity = log10(100*aVelocity);

   }

   offset = [velocityArray getCount];

   //fprintf(stdout,"STATIONOBJECT>>>> Transect = %d Cellno = %d Station = %f offset = %d aVelocity = %f \n", transect, cellNo, station, offset, aVelocity);
   //fflush(0);

   [velocityArray setCount: offset + 1];
   [velocityArray atOffset: offset put: (void *) log10Velocity];
  
   maxVelocityOffset++;

   return self;

}



- checkMaxOffsets {

   if(   (maxFlowOffset != maxDepthOffset) 
      || (maxFlowOffset != maxVelocityOffset) 
      || (maxDepthOffset != maxVelocityOffset) ) {

      [InternalError raiseEvent: "ERROR: max Offsets are different in station object\n"];

   }

  return self;


}


- checkArraySizes {






  return self;

}


- printFlowArray {
  int i;

 fprintf(stdout,"\n");

  for(i = 0; i < maxFlowOffset; i++) {

     fprintf(stdout,"STATIONOBJECT>>>>> flowArray[%d] = %f \n", i, *((double *) [flowArray atOffset: i]));
     fflush(0);
  
  }


  return self;

}

- printVelocityArray {
  int i;

 fprintf(stdout,"\n");

  for(i = 0; i < maxVelocityOffset; i++) {

     fprintf(stdout,"STATIONOBJECT>>>>> transect = %d station = %f velocityArray[%d] = %f \n",transect, station, i, pow(10, *((double *) [velocityArray atOffset: i])));
     fflush(0);
  
  }


  return self;

}


- printDepthArray {
  int i;

 fprintf(stdout,"\n");

  for(i = 0; i < maxDepthOffset; i++) {

     fprintf(stdout,"STATIONOBJECT>>>>> transect = %d station = %f depthArray[%d] = %f \n",transect, station, i, pow(10, *((double *) [depthArray atOffset: i])));
     fflush(0);
  
  }


  return self;

}



- printSelf {
int i;

  fprintf(stdout,"\n");
  fprintf(stdout,"TRANSECT = %d \n", transect);
  fprintf(stdout,"STATION  ELEV \n");
  fprintf(stdout,"%f       %f      ", station, elev);
  
  for(i = 0; i < maxDepthOffset; i++) {

  fprintf(stdout," %f ", *((double *) [velocityArray atOffset: i]) );     

  }
  fprintf(stdout,"\n");
  fflush(0);

return self;

}

@end
