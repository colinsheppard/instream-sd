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




#import "HabitatSpace.h"
#import "Trout.h"
#import "TroutModelSwarm.h"
#import "UTMRedd.h"
#import "BreakoutReporter.h"
#import "FishCell.h"
#import "globals.h"

@implementation FishCell

+ create: aZone 
{
  FishCell* fishCell = [super create: aZone];

  fishCell->cellFracSpawn = 0.0;
  fishCell->cellFracShelter = 0.0;
  fishCell->cellDistToHide = 0.0;

  fishCell->cellDataSet = NO;

  fishCell->velocityInterpolator = nil;
  fishCell->depthInterpolator = nil;

  return fishCell;
}

///////////////////////////////////////////
//
// setShadeColorMax
//
///////////////////////////////////////////
- setShadeColorMax: (double) aShadeColorMax
{
       shadeColorMax = aShadeColorMax;
       return self;
}


//////////////////////////////////////////
//
// toggleColorRep
//
//////////////////////////////////////////
- toggleColorRep: (double) aShadeColorMax
{
   // fprintf(stdout, "FishCell >>>> toggleColorRep >>>> BEGIN\n");
   // fflush(0);

   if(strncmp(rasterColorVariable, "depth",5) == 0)
   {
       strncpy(rasterColorVariable, "velocity", 9);
   }
   else if(strncmp(rasterColorVariable, "velocity",8) == 0)
   {
       strncpy(rasterColorVariable, "depth", 6);
   }
   else
   {
       fprintf(stderr, "ERROR: FishCell >>>> toggleColorRep >>>> incorrect rasterColorVariable\n");
       fflush(0);
       exit(1);
   }

   shadeColorMax = aShadeColorMax;

   // fprintf(stdout, "FishCell >>>> toggleColorRep >>>> END\n");
   // fflush(0);

   return self;
}


//////////////////////////////////////////////////
//
// tagPolyCell
//
//////////////////////////////////////////////////
- tagPolyCell
{
     [super tagPolyCell];
     [model updateTkEventsFor: space];
     return self;
}

///////////////////////////////////////////////////
//
// unTagPolyCell
//
//////////////////////////////////////////////////
- unTagPolyCell
{
     [super unTagPolyCell];
     [model updateTkEventsFor: space];
     return self;
}

////////////////////////////////////////
//
// tagAdjacentCells
//
///////////////////////////////////////
- tagAdjacentCells
{
    [super tagAdjacentCells];
    [model updateTkEventsFor: space];
    return self;
}

////////////////////////////////////////
//
// unTagAdjacentCells
//
///////////////////////////////////////
- unTagAdjacentCells
{
    [super unTagAdjacentCells];
    [model updateTkEventsFor: space];
    return self;
}


///////////////////////////////////////////////
//
// tagNeighborsWithin:
// (formerly: tagCellsWithin)
//
///////////////////////////////////////////////
- tagNeighborsWithin: (double) aRange
{
   id <List> tempList;
   id <ListIndex> cellNdx;
   id nextCell=nil;

   tempList = [List create: scratchZone];

    [self getNeighborsWithin: aRange
                      withList: tempList];

    cellNdx = [tempList listBegin: scratchZone];

    while(([cellNdx getLoc] != End) && ((nextCell = [cellNdx next]) != nil)) 
    {
         [nextCell tagPolyCell];
    } 

    [model updateTkEventsFor:reach];

    [cellNdx drop];
    [tempList drop];

    return self;
}


///////////////////////////////////////////////
//
// countNeighborsWithin:
//
///////////////////////////////////////////////
- (int) countNeighborsWithin: (double) aRange
{
   id <List> tempList;
   int theCount;

   tempList = [List create: scratchZone];

    [self getNeighborsWithin: aRange
                      withList: tempList];

   theCount = [tempList getCount];


   [tempList drop];

   return theCount;
}


/////////////////////////////////////////////////////////////////////
//
// drawSelfOn
//
/////////////////////////////////////////////////////////////////////
- drawSelfOn: (id <Raster>) aRaster 
{
  double colorVariable = 0.0;
  double colorRatio;
  int i;
  id aRedd;
  int pixToUse;
  double numToDraw;
  double counter;
  double dryDepthThreshold = 0.1;

  //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> BEGIN\n");
  //fflush(0);

  //
  // don't call super, do all of the work here 
  //

  // If cell is dry shade it accordingly, otherwise shade according to colormap
  if(polyCellDepth < dryDepthThreshold){
	  interiorColor = DRY_CELL_COLOR;
  }else{
    if(rasterColorVariable == NULL){
        fprintf(stderr, "ERROR: FishCell >>>> drawSelfOn >>>> rasterColorVariable has not been set\n");
        fflush(0);
        exit(1);
    }
    if(strcmp("depth",rasterColorVariable) == 0){
 	colorVariable = polyCellDepth; 
    }else if(strcmp("velocity",rasterColorVariable) == 0){
 	colorVariable = polyCellVelocity; 
    }else{
 	 fprintf(stderr, "ERROR: FishCell >>>> draswSelfOn >>>> Unknown rasterColorVariable value = %s\n",rasterColorVariable);
 	 fflush(0);
 	 exit(1);
    }
    if(fabs(shadeColorMax) <= 0.000000001){
        fprintf(stderr, "ERROR: FishCell >>>> drawSelfOn >>>> shadeColorMax is 0.0\n");
        fflush(0);
        exit(1);
    }
    colorRatio = colorVariable/shadeColorMax; 
 
 //  New shading code 1/14/2011 SFR
 
    if (colorRatio >= 1.0)
     {
       colorRatio = 0.99;  // so interiorColor truncates to CELL_COLOR_MAX - 1
     }
 
    interiorColor = (int) ( ((double) CELL_COLOR_MAX) * colorRatio);

  }
   if(tagCell)
   {
      interiorColor = TAG_CELL_COLOR;
   }
   if(1)
   {

     //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> maxIndex = %d\n", maxIndex);
     //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> interiorColor = %d\n", interiorColor);
     //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> polyCellDepth = %f\n", polyCellDepth);
     //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> polyCellVelocity = %f\n", polyCellVelocity);
     //fflush(0);
      

      for(i = 0;i < pixelCount; i++)
      {
          [aRaster drawPointX: polyCellPixels[i]->pixelX Y: polyCellPixels[i]->pixelY Color: interiorColor];
      }

      numberOfNodes = [polyPointList getCount];
      for(i = 1; i < numberOfNodes; i++) 
      { 
          [aRaster lineX0: [[polyPointList atOffset: i - 1] getDisplayX]
                       Y0: [[polyPointList atOffset: i - 1] getDisplayY]
                       X1: [[polyPointList atOffset: i % numberOfNodes] getDisplayX]
                       Y1: [[polyPointList atOffset: i % numberOfNodes] getDisplayY]
                    Width: 1
                    Color: POLYBOUNDARYCOLOR];

      }
   }
  
   numToDraw = (double) [fishIContain getCount];
   if(numToDraw > 0.0)
   {
       counter = 0.0;
       id <ListIndex> ndx;
       ndx = [fishIContain listBegin: scratchZone];
       Trout* fish = nil;

       while(([ndx getLoc] != End) && ((fish = [ndx next]) != nil))
       {    
          counter = counter + 1.0;
          pixToUse = (int) (pixelCount * (counter / (numToDraw + 1.0)));
           [fish drawSelfOn: aRaster 
                        atX: polyCellPixels[pixToUse]->pixelX 
                          Y: polyCellPixels[pixToUse]->pixelY];
       }
  
       [ndx drop];
   }


 
   if([reddsIContain getCount] > 0);
   {
        id <ListIndex> ndx = [reddsIContain listBegin: scratchZone];
 
        while(([ndx getLoc] != End) && ((aRedd = [ndx next]) != nil)) 
        {
             [aRedd drawSelfOn: aRaster];
             }
        [ndx drop];
  }
 

  //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> END\n");
  //fflush(0);

  return self;
}






///////////////////////////////////////////////
//
// buildObjects
//
//////////////////////////////////////////////
- buildObjects 
{
  if(myRandGen == nil)
  {
     fprintf(stderr, "ERROR: FishCell >>>> buildObjects >>>> myRandGen is nil\n");
     fflush(0);
     exit(1);
  } 

  //
  // misc initializations
  //
  fishIContain  = [List create: cellZone];
  reddsIContain = [List create: cellZone];
  listOfAdjacentCells = [List create: cellZone];

  if(fishParamsMap == nil)
  {
     fprintf(stderr, "ERROR: Cell >>>> buildObjects >>>> fishParamsMap is nil\n");
     fflush(0);
     exit(1);
  }

  [self initializeSurvProb];

  foodReportFirstTime=YES;
  depthVelRptFirstTime=YES;
 
  return self;
}


////////////////////////////////////////////////
//
// setVelocityInterpolator
//
////////////////////////////////////////////////
-  setVelocityInterpolator: (id <InterpolationTableSD>) aVelocityInterpolator
{
    velocityInterpolator = aVelocityInterpolator;
    return self;
}


////////////////////////////////////////////////////
//
// getVelocityInterpolator
//
////////////////////////////////////////////////////
-  (id <InterpolationTableSD>) getVelocityInterpolator
{
   return velocityInterpolator;
}


////////////////////////////////////////////////
//
// setDepthInterpolator
//
////////////////////////////////////////////////
-  setDepthInterpolator: (id <InterpolationTableSD>) aDepthInterpolator
{
    depthInterpolator = aDepthInterpolator;
    return self;
}
/////////////////////////////////////////////////////
//
// getDepthInterpolator
//
/////////////////////////////////////////////////////
-  (id <InterpolationTableSD>) getDepthInterpolator
{
    return depthInterpolator;
}


/////////////////////////////////////////////
//
// checkVelocityInterpolator
//
////////////////////////////////////////////
- checkVelocityInterpolator
{
  if(velocityInterpolator == nil)
  {
      fprintf(stdout, "FishCell >>>> checkVelocityInterpolator >>>> velocityInterpolator is nil in polyCell = %d in reach = %s, this is likely due to missing data in the reach's hydraulic input file.\n", polyCellNumber, [reach getReachName]);
      fflush(0);
      exit(1);
  }
  return self;
}

/////////////////////////////////////////////
//
// checkDepthInterpolator
//
////////////////////////////////////////////
- checkDepthInterpolator
{
  if(depthInterpolator == nil)
  {
      fprintf(stdout, "FishCell >>>> checkDepthInterpolator >>>> depthInterpolator is nil in polyCell = %d in reach = %s\n", polyCellNumber, [reach getReachName]);
      fflush(0);
      exit(1);
  }
  return self;
}



///////////////////////////////
//
// updatePolyCellDepth  -- 
// This is no longer used; instead: updateWithDepthTableIndex:
//
///////////////////////////////
- updatePolyCellDepthWith: (double) aFlow
{
   polyCellDepth = [depthInterpolator getValueFor: aFlow];

   return self;
}


////////////////////////////////////////////////////////
//
// getPolyCellDepth
//
///////////////////////////////////////////////////////
- (double) getPolyCellDepth
{
   if(polyCellDepth < 0.0)
   {
         fprintf(stderr, "ERROR: FishCell >>>> %d  reach = %s flow = %f depth = %f date = %s >>>> getPolyCellDepth >>>> polyCellDepth is negative\n", 
                                polyCellNumber, 
                                [reach getReachName], 
                                [reach getRiverFlow], 
                                polyCellDepth,
                                [timeManager getDateWithTimeT: [reach getModelTime]]) ;
         fflush(0);
         //exit(1);
   }

   return polyCellDepth;
}


//////////////////////////////
//
// updatePolyCellVelocity  --
// This is no longer used; instead: updateWithDepthTableIndex:
//
//////////////////////////////
- updatePolyCellVelocityWith: (double) aFlow
{
   polyCellVelocity = [velocityInterpolator getValueFor: aFlow];

   if(polyCellVelocity < 0.0)
   {
         fprintf(stderr, "ERROR: FishCell >>>> reach = %s >>>> cell number = %d aFlow = %f polyCellVelocity = %f >>>> updatePolyCellVelocityWith >>>> polyCellVelocity is negative\n", 
	[reach getReachName], polyCellNumber, aFlow, polyCellVelocity);
         fflush(0);
         [velocityInterpolator printSelf];
         exit(1);
   }

   return self;
}


//////////////////////////////
//
// updateWithDepthTableIndex:
//
//////////////////////////////
- updateWithDepthTableIndex: (int) depthInterpolationIndex
        depthInterpFraction: (double) depthInterpFraction
              velTableIndex: (int) velInterpolationIndex
          velInterpFraction: (double) velInterpFraction
  {
 
    polyCellVelocity = 
      [velocityInterpolator getValueWithTableIndex: velInterpolationIndex 
                                withInterpFraction: velInterpFraction];

    polyCellDepth = 
      [depthInterpolator getValueWithTableIndex: depthInterpolationIndex
                             withInterpFraction: depthInterpFraction];

   if (polyCellDepth < 0.0)
    {
      polyCellDepth = 0.0;   // This can happen at flows less than lowest in hydraulic input
    }

   return self;
}





////////////////////////////////////
//
// getPolyCellVelocity
//
////////////////////////////////////
- (double) getPolyCellVelocity
{
   if(polyCellVelocity < 0.0)
   {
         fprintf(stderr, "ERROR: FishCell >>>> %d  reach = %s flow = %f velocity = %f date = %s >>>> getPolyCellVelocity >>>> polyCellVelocity is negative\n", 
                                polyCellNumber, 
                                [reach getReachName], 
                                [reach getRiverFlow], 
                                polyCellVelocity,
                                [timeManager getDateWithTimeT: [reach getModelTime]]) ;
         fflush(0);
         exit(1);
   }
    return polyCellVelocity;
}


////////////////////////////////////
//
// setRandGen
//
//////////////////////////////////
- setRandGen: aRandGen
{
    myRandGen = aRandGen;
    return self;
}

//////////////////////////////////////
//
// getRandGen
//
//////////////////////////////////////
- getRandGen
{
    return myRandGen;
}

/////////////////////////////////////////////////////////////////////
//
// setSpace
//
////////////////////////////////////////////////////////////////////
- setSpace: aSpace 
{
   space = aSpace;
   return self;
}




////////////////////////////////////////////////////////////////////
//
// getSpace
//
///////////////////////////////////////////////////////////////////
- getSpace 
{
  return space;
}



/////////////////////////////////
//
// setReach
//
////////////////////////////////
- setReach: aReach
{
   reach = aReach;
   return self;
}


//////////////////////////////////
//
// getReach
//
/////////////////////////////////
- getReach
{
   return reach;
}



///////////////////////////////////////
//
// setReachEnd
//
///////////////////////////////////////
- setReachEnd: (char) aReachEnd
{
     reachEnd = aReachEnd;
     return self;
}


//////////////////////////////////////
//
// getReachEnd
//
//////////////////////////////////////
- (char) getReachEnd
{
     return reachEnd;
}


//////////////////////////////////////////
//
// calcCellDistToUS
//
//////////////////////////////////////////
- calcCellDistToUS
{
    id <List> upstreamCells = [reach getUpstreamCells];

    if([upstreamCells contains: self]) 
    {
             cellDistToUS = 0.0;
    }
    else
    {
        id <ListIndex> ndx = [upstreamCells listBegin: scratchZone];
        FishCell* oFishCell = nil;
    
        double oPolyCenterX = 0.0;
        double oPolyCenterY = 0.0;

        double distToUS     = (double) 1.0E99;

        cellDistToUS = (double) 1.0E99;

        while(([ndx getLoc] != End) && ((oFishCell = [ndx next]) != nil))
        {
                 oPolyCenterX = [oFishCell getPolyCenterX];
                 oPolyCenterY = [oFishCell getPolyCenterY];

                 distToUS = sqrt(pow((polyCenterX - oPolyCenterX), 2) + pow((polyCenterY - oPolyCenterY), 2));

                 cellDistToUS = (cellDistToUS < distToUS) ? cellDistToUS : distToUS; 
        }

        [ndx drop];
        ndx = nil;
    }

    //fprintf(stdout, "FishCell >>>> calcCellDistToUS >>>> cellNumber = %d >>>>> cellDistToUS = %f\n", polyCellNumber, cellDistToUS);
    //fflush(0);

    return self;
}


//////////////////////////////////////////////
//
// calcCellDistToDS
//
///////////////////////////////////////////////
- calcCellDistToDS
{
    id <List> downstreamCells = [reach getDownstreamCells];

    if([downstreamCells contains: self]) 
    {
             cellDistToDS = 0.0;
    }
    else
    {
        id <ListIndex> ndx = [downstreamCells listBegin: scratchZone];
        FishCell* oFishCell = nil;
    
        double oPolyCenterX = 0.0;
        double oPolyCenterY = 0.0;

        double distToDS     = (double) 1.0E99;

        cellDistToDS = (double) 1.0E99;

        while(([ndx getLoc] != End) && ((oFishCell = [ndx next]) != nil))
        {
                 oPolyCenterX = [oFishCell getPolyCenterX];
                 oPolyCenterY = [oFishCell getPolyCenterY];

                 distToDS = sqrt(pow((polyCenterX - oPolyCenterX), 2) + pow((polyCenterY - oPolyCenterY), 2));

                 cellDistToDS = (cellDistToDS < distToDS) ? cellDistToDS : distToDS; 
        }

        [ndx drop];
        ndx = nil;
    }

    //fprintf(stdout, "FishCell >>>> calcCellDistToDS >>>> cellNumber = %d >>>>> cellDistToDS = %f\n", polyCellNumber, cellDistToDS);
    //fflush(0);

    return self;
}

//////////////////////////////////////////////
//
// calcCellDistToCells
//
///////////////////////////////////////////////
//- calcCellDistToCells{
    //fprintf(stdout, "FishCell >>>> calcCellDistToCells >>>> cellNumber = %d >>>>> cellDistToDS = %f\n", polyCellNumber);
    //fflush(0);

//}


/////////////////////////////////
//
// getCellDistToUS
//
/////////////////////////////////
- (double) getCellDistToUS
{
     return cellDistToUS;
}


/////////////////////////////////
//
// getCellDistToDS
//
/////////////////////////////////
- (double) getCellDistToDS
{
     return cellDistToDS;
}


/////////////////////////////////////////////////////
//
// setTimeManager
//
/////////////////////////////////////////////////////
- setTimeManager: (id <TimeManager>) aTimeManager
{
     timeManager = aTimeManager;
     return self;
}

/////////////////////////////////////////////
//
// setModel
//
/////////////////////////////////////////////
- setModel: (id <TroutModelSwarm>) aModel
{
    model = (id <TroutModelSwarm>) aModel;
    return self;
}


//////////////////////////////////////
//
// setFishParamsMap
//
/////////////////////////////////////
- setFishParamsMap: (id <Map>) aMap
{
    fishParamsMap = aMap;
    return self;
}



///////////////////////////////////////////
//
// setNumberOfSpecies
//
///////////////////////////////////////////

- setNumberOfSpecies: (int) aNumberOfSpecies
{
    numberOfSpecies = aNumberOfSpecies;
    return self;
}



//////////////////////////////////////////////
//
// setHabShearParamA:habShearParamB
//
////////////////////////////////////////////
- setHabShearParamA: (double) aHabShearParamA
     habShearParamB: (double) aHabShearParamB
{
    habShearParamA = aHabShearParamA;
    habShearParamB = aHabShearParamB;
    return self;
}


////////////////////////////////////////
//
// getHabShearParamA
//
////////////////////////////////////////
- (double) getHabShearParamA
{
   return habShearParamA;
}


////////////////////////////////////////
//
// getHabShearParamB
//
////////////////////////////////////////
- (double) getHabShearParamB
{
   return habShearParamB;
}

///////////////////////////////////////////////
//
// getHabShelterSpeedFrac
//
///////////////////////////////////////////////
- (double) getHabShelterSpeedFrac
{
   return [space getHabShelterSpeedFrac];
}

////////////////////////////////
//
// getDistanceTo
//
///////////////////////////////
- (double) getDistanceTo: aCell
{
   double distance  = 0.0;
   double distanceX = 0.0;
   double distanceY = 0.0;
  
   if(aCell != self)
   {
       distanceX =  [self getPolyCenterX] - [aCell getPolyCenterX];
       distanceY =  [self getPolyCenterY] - [aCell getPolyCenterY];
       distance = distanceX*distanceX + distanceY*distanceY;
       distance = sqrt(distance);
   }
   else
   {
      distance = 0.0;
   }
  
   /*
   fprintf(stdout, "FishCell >>>> getDistanceTo >>>> utmCenterX = %f [aCell getUTMCenterX] = %f\n", utmCenterX, [aCell getUTMCenterX]);
   fprintf(stdout, "FishCell >>>> getDistanceTo >>>> utmCenterY = %f [aCell getUTMCenterY] = %f\n", utmCenterY, [aCell getUTMCenterY]);
   fprintf(stdout, "FishCell >>>> getDistanceTo >>>> distanceX = %f\n", distanceX);
   fprintf(stdout, "FishCell >>>> getDistanceTo >>>> distanceY = %f\n", distanceY);
   fprintf(stdout, "FishCell >>>> getDistanceTo >>>> distance = %f\n", distance);
   fflush(0);
   */
   	
   return distance;
}



////////////////////////////////////////////////////////
//
// setDistanceToHide
//
///////////////////////////////////////////////////////
- setDistanceToHide: (double) aDistance 
{
  cellDistToHide = aDistance;
  return self;
}


//////////////////////////////////////////////////////
//
// getDistanceToHide
//
/////////////////////////////////////////////////////
- (double) getDistanceToHide 
{
   return cellDistToHide;
}

////////////////////////////////////////////////////////////
//
// calcDailyMeanDepthAndVelocityFor 
//
////////////////////////////////////////////////////////////
- calcDailyMeanDepthAndVelocityFor: (double) aMeanFlow
{
    meanDepth    = [depthInterpolator getValueFor: aMeanFlow];
   
    if(meanDepth < 0.0)
    {
       meanDepth = 0.0;
    }

    meanVelocity = [velocityInterpolator getValueFor: aMeanFlow];
   

    //fprintf(stdout, "FishCell >>>> calcDailyMean .... meanDepth = %f\n", meanDepth);
    //fprintf(stdout, "FishCell >>>> calcDailyMean .... meanVelocity = %f\n", meanVelocity);
    //fflush(0);
 
    return self;
}

/////////////////////////////////////
//
// isDryAtDailyMeanFlow
//
/////////////////////////////////////
- (BOOL) isDryAtDailyMeanFlow
{
   BOOL isDry = NO;

   if(meanDepth <= 0.0)
   {
      isDry = YES;
   }

   return isDry;
}


///////////////////////////////////////
//
// getAnglingPressure
//
///////////////////////////////////////
- (double) getAnglingPressure
{
    return [space getAnglingPressure];
}

/////////////////////////////////
//
// tagDestCells
//
////////////////////////////////
- tagDestCells
{
    tagCell = YES;
    return self;
}


///////////////////////////////////////////////
//
// getNeighborsWithin
//
//////////////////////////////////////////////
- getNeighborsWithin: (double) aRange 
            withList: (id <List>) aCellList
{
  //fprintf(stdout, "FishCell >>>> getNeighborsWithin >>>> BEGIN\n");
  //fflush(0);

  [space getNeighborsWithin: aRange 
                         of: self
                   withList: aCellList];

  //fprintf(stdout, "FishCell >>>> getNeighborsWithin >>>> END\n");
  //fflush(0);

  return self;
}

///////////////////////////////////////////////
//
// getNeighborsInReachWithin
//
//////////////////////////////////////////////
- getNeighborsInReachWithin: (double) aRange 
            withList: (id <List>) aCellList
{
  //fprintf(stdout, "FishCell >>>> getNeighborsInReachWithin >>>> BEGIN\n");
  //fflush(0);

  [space getNeighborsInReachWithin: aRange 
                         of: self
                   withList: aCellList];

  //fprintf(stdout, "FishCell >>>> getNeighborsInReachWithin >>>> END\n");
  //fflush(0);

  return self;
}

////////////////////////////////
//
// getNumberOfFish
//
///////////////////////////////
- (int) getNumberOfFish 
{
   return [fishIContain getCount];
}




//////////////////////////////////////////////////////////////////
//
// getNumberOfRedds
//
/////////////////////////////////////////////////////////////////
- (int) getNumberOfRedds 
{
  return [reddsIContain getCount];
}




//////////////////////////////////////////////////////////////////
//
// getFishIContain
//
/////////////////////////////////////////////////////////////////
- (id <List>) getFishIContain 
{
   return fishIContain;
}




//////////////////////////////////////////////////////////////////
//
// getReddsIContain
//
/////////////////////////////////////////////////////////////////
- (id <List>) getReddsIContain 
{
   return reddsIContain;
}


/*
///////////////////////////////////////////////////////////////////
//
// calcDepthAndVelocityWithIndex
//
///////////////////////////////////////////////////////////////////
- calcDepthAndVelocityWithIndex: (int) anInterpolationIndex
             withInterpFraction: (double) anInterpFraction
{
   aVelocity = [velocityInterpolator getValueWithTableIndex: anInterpolationIndex 
                                         withInterpFraction: anInterpFraction];

   aWsl = [wslInterpolator getValueWithTableIndex: anInterpolationIndex
                                   withInterpFraction: anInterpFraction];

   if(aDepth < 0.0)
    {
      aDepth = 0.0;
    }

   if(aVelocity < 0.0) 
   {
     aVelocity = 0.0;
   }

   velocity = aVelocity;
   depth = aDepth;

   return self;
}

*/

///////////////////////////////////////////
//
// getYesterdaysRiverFlow
//
/////////////////////////////////////////
- (double) getYesterdaysRiverFlow 
{
  return [space getYesterdaysRiverFlow];
}


///////////////////////////////////////////
//
// getRiverFlow
//
/////////////////////////////////////////
- (double) getRiverFlow 
{
  return [space getRiverFlow];
}


////////////////////////////////////////////////////////////////////
//
// getTomrrowsRiverFlow
//
////////////////////////////////////////////////////////////////////
- (double) getTomorrowsRiverFlow 
{
  return [space getTomorrowsRiverFlow];
}

////////////////////////////////////////////////////////////////////
//
// getFlowChange
//
////////////////////////////////////////////////////////////////////
- (double) getFlowChange 
{
    return [space getFlowChange];
}




//////////////////////////////////////////////////////////////////
//
// setCellFracShelter
//
//////////////////////////////////////////////////////////////////
- (void) setCellFracShelter: (double) aDouble 
{
   if(aDouble > 1.0){
         fprintf(stderr, "ERROR: FishCell >>>> setCellFracShelter >>>> attempted to set cellFracShelter to a value of %f but cellFracShelter must be <= 1.0\n", aDouble);
         fflush(0);
         exit(1);
   }
    cellFracShelter = aDouble;
}


/////////////////////////////////////////////////////////////////
//
// calcCellShelterArea
//
////////////////////////////////////////////////////////////////
- (void) calcCellShelterArea 
{
    cellShelterArea = polyCellArea*cellFracShelter;
}

/////////////////////////////////////
//
// resetShelterAreaAvailable
//
////////////////////////////////////////
- (void) resetShelterAreaAvailable 
{
   shelterAreaAvailable = cellShelterArea;
 
   if(shelterAreaAvailable > 0.0)
   {
       isShelterAvailable = YES;
   }
   else
   {
       isShelterAvailable = NO;
   }
}


////////////////////////////////////
//
// getShelterAreaAvailable 
//
////////////////////////////////////
- (double) getShelterAreaAvailable 
{
     return shelterAreaAvailable;
}

//////////////////////////////////
//
// getIsShelterAvailable
//
//////////////////////////////////
- (BOOL) getIsShelterAvailable
{
      return isShelterAvailable;
}

/////////////////////////////////////////////////
//
// setFracHidingCover
//
////////////////////////////////////////////////

- setFracHidingCover: (double) aDouble 
{
   if(aDouble > 1.0){
         fprintf(stderr, "ERROR: FishCell >>>> setFracHidingCover >>>> attempted to set fracHidingCover to a value of %f but fracHidingCover must be <= 1.0\n", aDouble);
         fflush(0);
         exit(1);
   }
   fracHidingCover = aDouble;
   return self;
}




////////////////////////////////////
//
// resetHidingCover
//
////////////////////////////////////
- (void) resetHidingCover
{
   availableHidingCover = [self getPolyCellArea] * fracHidingCover;
   //return self;

}


//////////////////////////////////////
//
// getIsHidingCoverAvailable
//
//////////////////////////////////////
- (BOOL) getIsHidingCoverAvailable
{
    BOOL isHidingCoverAvailable = NO;

    if(availableHidingCover > 0.0) 
    {
        isHidingCoverAvailable = YES;
    }
  
    return isHidingCoverAvailable;
}


/////////////////////////////////////////
//
// getHidingCoverAvailable
//
////////////////////////////////////////
- (double) getHidingCoverAvailable
{
    return availableHidingCover;  
}   

//////////////////////////////////////////////////////////////////
//
// setCellFracSpawn
//
//////////////////////////////////////////////////////////////////
- setCellFracSpawn: (double) aDouble 
{
   if(aDouble > 1.0){
         fprintf(stderr, "ERROR: FishCell >>>> setCellFracSpawn >>>> attempted to set cellFracSpawn to a value of %f but cellFracSpawn must be <= 1.0\n", aDouble);
         fflush(0);
         exit(1);
   }
   cellFracSpawn = aDouble;
   return self;
}


////////////////////////////////////////////////////////////////////
//
// getCellFracSpawn
//
////////////////////////////////////////////////////////////////////
- (double) getCellFracSpawn 
{
   return cellFracSpawn;
}


/////////////////////////////////////////////////////
//
// getCellFracShelter
//
/////////////////////////////////////////////////////
- (double) getCellFracShelter
{
    return cellFracShelter;
}

//////////////////////////////////////////////////////
//
// spawnHere
//
/////////////////////////////////////////////////////
- spawnHere: aFish 
{
   [self addFish: aFish];
   return self;
}

/////////////////////////////////////////////////////////////
//
// eatHere
//
/////////////////////////////////////////////////////////////
- eatHere: aFish 
{
  //
  // sheltered?
  //
  if(shelterAreaAvailable > 0.0) 
  {
    if([aFish getAmIInAShelter] == YES ) 
    {
        shelterAreaAvailable -= [aFish getFishShelterArea];
    }
    if(shelterAreaAvailable < 0.0) 
    {
         shelterAreaAvailable = 0.0;
         isShelterAvailable = NO;
    }
  }

  hourlyAvailDriftFood -= [aFish getHourlyDriftConRate];
  hourlyAvailSearchFood -= [aFish getHourlySearchConRate];

  [self addFish: aFish];

    //fprintf(stdout, "FishCell >>>> eatHere >>>> writeFoodAvailReport: %s \n",([[space getModel] getWriteFoodAvailabilityReport])?"YES":"NO");
    //fflush(0);

  if([[space getModel] getWriteFoodAvailabilityReport]){
    [self foodAvailAndConInCell: aFish];
  }

  return self;
}


/////////////////////////////////////////////////////////////////////
//
// addFish
//
//
/////////////////////////////////////////////////////////////////////
- addFish: aFish 
{
  id fishOldCell=nil;

  fishOldCell = [aFish getCell];
  //fprintf(stdout, "FishCell >>>> addFish >>>> fishOldCell: %s \n",(fishOldCell!=nil)?"found":"not found");
  //fflush(0);

  if(fishOldCell != nil) [fishOldCell removeFish: aFish];
   
  [fishIContain addLast: aFish];
  [aFish setCell: self];

  [aFish setHabitatSpace: reach];

  numberOfFish = [fishIContain getCount];

  return self;
}


/////////////////////////////////////////////////////////////
//
// moveHere
//
/////////////////////////////////////////////////////////////
- moveHere: aFish 
{
  //
  //in Hiding cover
  //
  if(availableHidingCover > 0.0)
  {
        if([aFish getAmIInHidingCover] == YES)
        {
           availableHidingCover -= [aFish getFishHidingCoverArea];
        }
        if(availableHidingCover < 0.0)
        {
           availableHidingCover = 0.0;
        }
  }      


  //
  // sheltered?
  //
  if(shelterAreaAvailable > 0.0 ) 
  {
      if([aFish getAmIInAShelter] == YES ) 
      {
             shelterAreaAvailable -= [aFish getFishShelterArea];
      }
      if(shelterAreaAvailable < 0.0) 
      {
         shelterAreaAvailable = 0.0;
      }
  }

  hourlyAvailDriftFood -= [aFish getHourlyDriftConRate];
  hourlyAvailSearchFood -= [aFish getHourlySearchConRate];

  
  [self addFish: aFish];

#ifdef REPORT_ON
  [self foodAvailAndConInCell: aFish];
#endif

  return self;
}



/////////////////////////////////////////////////////////////////////////
//
// removeFish
//
/////////////////////////////////////////////////////////////////////////
- removeFish: aFish 
{
  [fishIContain remove: aFish];
  [aFish setCell: nil];
  numberOfFish = [fishIContain getCount];
  return self;
}




///////////////////////////////////////////////////////////////
//
// addRedd
//
//
// addRedd has a different functionality from addFish.  Since
// redds don't move around like fish, they spend their entire
// life in once cell.  So, an "addRedd" only occurs after the
// creation of a new redd. 
//
// NOTE: The new Redd MUST BE added to the BEGINNING of the
//       reddIContain List in order to make the SUPER IMPOSITION
//       function work.
//
//
///////////////////////////////////////////////////////////////
- addRedd: aRedd 
{
  id <UniformIntegerDist> reddPixelDist = [UniformIntegerDist create: scratchZone
                                                        setGenerator: myRandGen
                                                       setIntegerMin: 0
                                                              setMax: (pixelCount - 1) ];

  int aPixelNum = [reddPixelDist getIntegerSample];

  [reddsIContain addFirst: aRedd];

  [aRedd setRasterX: polyCellPixels[aPixelNum]->pixelX];
  [aRedd setRasterY: polyCellPixels[aPixelNum]->pixelY];

  [reddPixelDist drop];

  //fprintf(stdout, "FishCell >>>> addRedd >>>> END\n");
  //fflush(0);

  return self;
}




/////////////////////////////////////////////////////////////
//
// removeRedd
//
/////////////////////////////////////////////////////////////
- removeRedd: aRedd 
{
  [reddsIContain remove: aRedd];
  return self;
}



//////////////////////////////////////////////////////////
//
// getHabPreyEnergyDensity
//
/////////////////////////////////////////////////////////
- (double) getHabPreyEnergyDensity 
{
  return [space getHabPreyEnergyDensity];
}



//////////////////////////////////////////////////
//
// getTemperature
//
//////////////////////////////////////////////////
- (double) getTemperature 
{
  return [space getTemperature];
}


//////////////////////////////////////////////////
//
// getTurbidity
//
//////////////////////////////////////////////////
- (double) getTurbidity 
{
  return [space getTurbidity];
}


/////////////////////////////////////////////
//
// calcDriftHourlyTotal
//
////////////////////////////////////////////
-  calcDriftHourlyTotal 
{
   driftHourlyCellTotal = (  3600 
                          * polyCellArea
                          * polyCellDepth
                          * polyCellVelocity
                          * [space getHabDriftConc])
                          /[space getHabDriftRegenDist];
   return self;
}


////////////////////////////////////////////
//
// calcSearchHourlyTotal
//
//////////////////////////////////////////////
- calcSearchHourlyTotal 
{
  searchHourlyCellTotal = polyCellArea * [space getHabSearchProd];
  return self;
}


//////////////////////////////////////////
//
// getHourlyAvailDriftFood
//
////////////////////////////////////////
- (double) getHourlyAvailDriftFood 
{
   return hourlyAvailDriftFood;
}

//////////////////////////////////////////
//
// getHourlyAvailSearchFood
//
////////////////////////////////////////
- (double) getHourlyAvailSearchFood 
{
   return hourlyAvailSearchFood;
}

//////////////////////////////////
//
// updateDSCellHourlyTotal
//
//////////////////////////////////
- (void) updateDSCellHourlyTotal 
{
  [self calcDriftHourlyTotal];
  [self calcSearchHourlyTotal];
}


/////////////////////////////////////
//
//resetAvailHourlyTotal
//
//////////////////////////////////////
- (void) resetAvailHourlyTotal 
{
   hourlyAvailDriftFood = driftHourlyCellTotal;
   hourlyAvailSearchFood = searchHourlyCellTotal;
}
////////////////////////////////////////////////
//
// getDayLength
//
////////////////////////////////////////////////
- (double) getDayLength 
{
   return [space getDayLength];
}

//////////////////////////////////////////
//
// isDepthGreaterThan0
//
/////////////////////////////////////////
- (BOOL) isDepthGreaterThan0
{
    if(polyCellDepth <= 0.0)
    {
        return NO;
    }

    return YES;
}

///////////////////////////////////////
//
// getPiscivorousFishDensity
//
///////////////////////////////////////
- (double) getPiscivorousFishDensity
{
   return [space calcPiscivorousFishDensity];
} 


////////////////////////////////////////////////
//
// initializeSurvProb
//
////////////////////////////////////////////////
- initializeSurvProb 
{
  id <Index> mapNdx;
  FishParams* fishParams = nil;

  //fprintf(stdout, "FishCell >>>> initializeSurvProb >>>> BEGIN\n");
  //fflush(0);

  if(numberOfSpecies <= 0)
  {
     fprintf(stderr, "ERROR: FishCell >>>> initializeSurvProb >>>> numberOfSpecies is 0\n");
     fflush(0);
     exit(1);
  }

  survMgrMap = [Map create: cellZone];
  survMgrReddMap = [Map create: cellZone];

  mapNdx = [fishParamsMap mapBegin: scratchZone];

  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {
     id <SurvMGR> survMgr;
     id <Symbol> species = [fishParams getFishSpecies];
 
     survMgr = [SurvMGR     createBegin: cellZone
                     withHabitatObject: self];

     [survMgrMap at: species  insert: survMgr];
	 
	 // The order in which mortality sources are added here is
	 // the order in which they will be executed; specified in
	 // model description.

      // High Temperature
     [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "HighTemperature"] 
                        withType: "SingleFunctionProb"
                  withAgentKnows: YES
                 withIsStarvProb: NO];

      [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "HighTemperature"] 
                           withInputObjectType: 0
                             withInputSelector: M(getTemperature)
                                   withXValue1: fishParams->mortFishHiTT9
                                   withYValue1: 0.9
                                   withXValue2: fishParams->mortFishHiTT1
                                   withYValue2: 0.1];

    // High velocity
       [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "Velocity"] 
                        withType: "LimitingFunctionProb"
                  withAgentKnows: YES
                 withIsStarvProb: NO];

      [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "Velocity"] 
                           withInputObjectType: 1 
                             withInputSelector: M(getSwimSpdVelocityRatio)
                                   withXValue1: fishParams->mortFishVelocityV9
                                   withYValue1: 0.9
                                   withXValue2: fishParams->mortFishVelocityV1
                                   withYValue2: 0.1];

     [survMgr addBoolSwitchFuncToProbWithSymbol:  [model getFishMortalitySymbolWithName: "Velocity"]
                       withInputObjectType: 1
                            withInputSelector: M(getAmIInHidingCover)
                               withYesValue: fishParams->mortFishVelocityCoverFactor 
                                withNoValue: 0.0];

     
     // Stranding and low depth
     [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "Stranding"] 
                        withType: "SingleFunctionProb"
                  withAgentKnows: YES
                 withIsStarvProb: NO];

      [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "Stranding"] 
                           withInputObjectType: 1
                             withInputSelector: M(getDepthLengthRatio)
                                   withXValue1: fishParams->mortFishStrandD1
                                   withYValue1: 0.1
                                   withXValue2: fishParams->mortFishStrandD9
                                   withYValue2: 0.9];

     // Aquatic Predation
     [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
             withType: "LimitingFunctionProb"
       withAgentKnows: YES
      withIsStarvProb: NO];

     [survMgr addBoolSwitchFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
          withInputObjectType: 0
               withInputSelector: M(getCurrentPhase)
               //withInputSelector: M(getPhaseOfPrevStep)
                  withYesValue: fishParams->mortFishAqPredDayMin
                   withNoValue: fishParams->mortFishAqPredNightMin];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: 0
                            withInputSelector: M(getPiscivorousFishDensity)
                                  withXValue1: fishParams->mortFishAqPredP9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishAqPredP1
                                  withYValue2: 0.1];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: 0
                            withInputSelector: M(getPolyCellDepth)
                                  withXValue1: fishParams->mortFishAqPredD9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishAqPredD1
                                  withYValue2: 0.1];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: 1
                            withInputSelector: M(getFishLength)
                                  withXValue1: fishParams->mortFishAqPredL1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishAqPredL9
                                  withYValue2: 0.9];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: 0
                            withInputSelector: M(getTemperature)
                                  withXValue1: fishParams->mortFishAqPredT9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishAqPredT1
                                  withYValue2: 0.1];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: 0
                            withInputSelector: M(getTurbidity)
                                  withXValue1: fishParams->mortFishAqPredU1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishAqPredU9
                                  withYValue2: 0.9];

     [survMgr addBoolSwitchFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
          withInputObjectType: 1 
               withInputSelector: M(getAmIInHidingCover)
                  withYesValue: fishParams->mortFishAqPredCoverFactor
                   withNoValue: 0.0];

     // TerrestialPredation Predation
     [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
             withType: "LimitingFunctionProb"
       withAgentKnows: YES
      withIsStarvProb: NO];

     [survMgr addBoolSwitchFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
          withInputObjectType: 0 
               withInputSelector: M(getCurrentPhase)
               //withInputSelector: M(getPhaseOfPrevStep)
                  withYesValue: fishParams->mortFishTerrPredDayMin
                   withNoValue: fishParams->mortFishTerrPredNightMin];
     
     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: 0
                            withInputSelector: M(getPolyCellDepth)
                                  withXValue1: fishParams->mortFishTerrPredD1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishTerrPredD9
                                  withYValue2: 0.9];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: 0
                            withInputSelector: M(getTurbidity)
                                  withXValue1: fishParams->mortFishTerrPredT1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishTerrPredT9
                                  withYValue2: 0.9];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: 1
                            withInputSelector: M(getFishLength)
                                  withXValue1: fishParams->mortFishTerrPredL9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishTerrPredL1
                                  withYValue2: 0.1];

	 [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: 0
                            withInputSelector: M(getPolyCellVelocity)
                                  withXValue1: fishParams->mortFishTerrPredV1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishTerrPredV9
                                  withYValue2: 0.9];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: 0
                            withInputSelector: M(getDistanceToHide)
                                  withXValue1: fishParams->mortFishTerrPredH9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishTerrPredH1
                                  withYValue2: 0.1];

     [survMgr addBoolSwitchFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
          withInputObjectType: 1 
               withInputSelector: M(getAmIInHidingCover)
                  withYesValue: fishParams->mortFishTerrPredCoverFactor
                   withNoValue: 0.0];

     // Poor Condition
     [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "PoorCondition"]
                       withType: "SingleFunctionProb"
                 withAgentKnows: YES
                withIsStarvProb: YES];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "PoorCondition"] 
                          withInputObjectType: 1
                            withInputSelector: M(getFishCondition)
                                  withXValue1: fishParams->mortFishConditionK1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishConditionK9
                                  withYValue2: 0.9];

     // Angling 
      [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "Angling"] 
                        withType: "CustomProb"
                  withAgentKnows: NO
                 withIsStarvProb: NO];
      
     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "Angling"] 
            withInputObjectType: 1
                 withInputSelector: M(getFishLength)
                     withXValue1: fishParams->mortFishAngleL1
                     withYValue1: LOWER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishAngleL9
                     withYValue2: UPPER_LOGISTIC_DEPENDENT];

     // Hooking
      [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "Hooking"] 
                       withType: "CustomProb"
                 withAgentKnows: NO
                withIsStarvProb: NO];
 
     [survMgr setLogisticFuncLimiterTo: 20.0];

     survMgr = [survMgr createEnd];
								  
     [survMgr setLogisticFuncLimiterTo: 20.0];
     //[survMgr setTestOutputOnWithFileName: "SurvMGRTest.out"];
     survMgr = [survMgr createEnd];
     //fprintf(stdout, "FishCell >>>> initializeSurvProb >>>> after createEnd\n");
     //fflush(0);

  }
 
  [mapNdx setLoc: Start];

  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {

     id <SurvMGR> survMgr;
     id <Symbol> species = [fishParams getFishSpecies];
 
     survMgr = [SurvMGR     createBegin: cellZone
                     withHabitatObject: self];

     [survMgrReddMap at: species insert: survMgr];

    //
    // Dewatering
    //
    [survMgr addPROBWithSymbol: [model getReddMortalitySymbolWithName: "ReddDewater"]
                      withType: "SingleFunctionProb"
                withAgentKnows: YES
               withIsStarvProb: NO];

    [survMgr addBoolSwitchFuncToProbWithSymbol: [model getReddMortalitySymbolWithName: "ReddDewater"]
                           withInputObjectType: 0
                             withInputSelector: M(isDryAtDailyMeanFlow)
                                  withYesValue: fishParams->mortReddDewaterSurv
		                           withNoValue: 1.0];

     //
     // Scouring
     // 
     [survMgr addPROBWithSymbol: [model getReddMortalitySymbolWithName: "ReddScour"] 
                       withType: "CustomProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];
     
     [survMgr addCustomFuncToProbWithSymbol: [model getReddMortalitySymbolWithName: "ReddScour"] 
                              withClassName: "ReddScourFunc"
                        withInputObjectType: 1
                          withInputSelector: M(getCell)];

     //
     // Low Temperature
     //
     [survMgr addPROBWithSymbol: [model getReddMortalitySymbolWithName: "LowTemperature"]
                       withType: "SingleFunctionProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];


     [survMgr addLogisticFuncToProbWithSymbol: [model getReddMortalitySymbolWithName: "LowTemperature"] 
                          withInputObjectType: 0
                            withInputSelector: M(getTemperature)
                                  withXValue1: fishParams->mortReddLoTT1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortReddLoTT9
                                  withYValue2: 0.9];

     //
     // High Temperature
     //
     [survMgr addPROBWithSymbol: [model getReddMortalitySymbolWithName: "HighTemperature"]
                       withType: "SingleFunctionProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];


     [survMgr addLogisticFuncToProbWithSymbol: [model getReddMortalitySymbolWithName: "HighTemperature"] 
                          withInputObjectType: 0
                            withInputSelector: M(getTemperature)
                                  withXValue1: fishParams->mortReddHiTT9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortReddHiTT1
                                  withYValue2: 0.1];

     //
     // Superimposition
     //
      [survMgr addPROBWithSymbol: [model getReddMortalitySymbolWithName: "ReddSuperimp"] 
                       withType: "CustomProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];
   
      [survMgr addCustomFuncToProbWithSymbol: [model getReddMortalitySymbolWithName: "ReddSuperimp"] 
                               withClassName: "ReddSuperimpFunc"
                         withInputObjectType: 1
                           withInputSelector: M(getCell)];

     [survMgr setLogisticFuncLimiterTo: 20.0];
     //[survMgr setTestOutputOnWithFileName: "SurvMGRTest.out"]; This isn't working with scour
     survMgr = [survMgr createEnd];
  }
 
  //fprintf(stdout, "Cell >>>> initializeSurvProb >>>> END\n");
  //fflush(0);

  return self;
}

////////////////////////////
//
// getPhaseOfPrevStep
//
////////////////////////////
- (int) getPhaseOfPrevStep
{
   return [space getPhaseOfPrevStep];
}

//////////////////////////////
//
// getDayNightPhaseSwitch
//
//////////////////////////////
- (BOOL) getDayNightPhaseSwitch
{
    return [space getDayNightPhaseSwitch];
}

/////////////////////////////////////////
//
// getCurrentPhase
//
////////////////////////////////////////
- (int) getCurrentPhase
{
    return [space getCurrentPhase];
}

///////////////////////////////
//
// getNumberOfDaylightHours
//
///////////////////////////////
- (double) getNumberOfDaylightHours
{
    return [space getNumberOfDaylightHours];
}

///////////////////////////////
//
// getNumberOfNightHours
//
///////////////////////////////
- (double) getNumberOfNightHours
{
    return [space getNumberOfNightHours];
}

////////////////////////////////////////////////////////////////////
//
// getChangeInDailyFlow
//
////////////////////////////////////////////////////////////////////
- (double) getChangeInDailyFlow 
{
  return [space getChangeInDailyFlow];
}

//////////////////////////////////////
//
// getDailyMeanFlow
//
/////////////////////////////////////
- (double) getDailyMeanFlow
{
     return [space getDailyMeanFlow];
}

////////////////////////////////////
//
// getPrevDailyMeanFlow
//
////////////////////////////////////
- (double) getPrevDailyMeanFlow
{
    return [space getPrevDailyMeanFlow];
}

/////////////////////////////////////
//
// getPrevDailyMaxFlow
//
/////////////////////////////////////
- (double) getPrevDailyMaxFlow
{
    return [space getPrevDailyMaxFlow];
}
//////////////////////////////////////
//
// getDailyMaxFlow
//
//////////////////////////////////////
- (double) getDailyMaxFlow
{
   return [space getDailyMaxFlow];
}
//////////////////////////////////////
//
// getNextDailyMaxFlow
//
///////////////////////////////////////
- (double) getNextDailyMaxFlow
{
   return [space getNextDailyMaxFlow];
}



/////////////////////////////////////////////////////
//
// updateHabitatSurvivalProb
//
/////////////////////////////////////////////////////
- updateHabitatSurvivalProb 
{
  //fprintf(stdout, "FishCell >>>> updateHabitatSurvivalProb >>>> BEGIN\n");
  //fflush(0);

  [survMgrMap forEach: M(updateForHabitat)];
  
  // Redd survival managers are now updated in [redd survive]
  [survMgrReddMap forEach: M(updateForHabitat)];

  //fprintf(stdout, "FishCell >>>> updateHabitatSurvivalProb >>>> END\n");
  //fflush(0);
  return self;
}


//////////////////////////////////
//
// updateHabSurvProbForAqPred
//
/////////////////////////////////
- updateHabSurvProbForAqPred
{
  //fprintf(stdout, "FishCell >>>> updateHabSurvProbForAqPred >>>> BEGIN\n");
  //fflush(0);

  [survMgrMap forEach: M(updateForHabitat)];

  //fprintf(stdout, "FishCell >>>> updateHabSurvProbForAqPred >>>> END\n");
  //fflush(0);

  return self;
}


/////////////////////////////////////
//
// updateFishSurvivalProbFor
//
/////////////////////////////////////
- updateFishSurvivalProbFor: aFish
{
  //fprintf(stdout, "FishCell >>>> updateFishSurvivalProbFor >>>> BEGIN\n");
  //fflush(0);

   [[survMgrMap at: [aFish getSpecies]] 
          updateForAnimal: aFish]; 

  //fprintf(stdout, "FishCell >>>> updateFishSurvivalProbFor >>>> END\n");
  //fflush(0);

   return self;
}


- updateReddSurvivalProbFor: aRedd
{
  //fprintf(stdout, "FishCell >>>> updateReddSurvivalProbFor >>>> BEGIN\n");
  //fflush(0);

   [[survMgrReddMap at: [aRedd getSpecies]] 
               updateForAnimal: aRedd]; 

   [[survMgrReddMap at: [aRedd getSpecies]] 
               updateForHabitat]; 

			   //fprintf(stdout, "FishCell >>>> updateReddSurvivalProbFor >>>> BEGIN\n");
  //fflush(0);

   return self;
}


//////////////////////////////////////////
//
//(id <List>) getListOfSurvProbsFor: aFish
//
//////////////////////////////////////////
- (id <List>) getListOfSurvProbsFor: aFish
{
   return [[survMgrMap at: [aFish getSpecies]] getListOfSurvProbsFor: aFish]; 
}

//////////////////////////////////////////
//
//(id <List>) getReddListOfSurvProbsFor: aRedd
//
//////////////////////////////////////////
- (id <List>) getReddListOfSurvProbsFor: aRedd
{
   return [[survMgrReddMap at: [aRedd getSpecies]] getListOfSurvProbsFor: aRedd]; 
}



- (double) getTotalKnownNonStarvSurvivalProbFor: aFish
{
  return  [[survMgrMap at: [aFish getSpecies]] getTotalKnownNonStarvSurvivalProbFor: aFish];
}



- (double) getStarvSurvivalFor: aFish
{
   return [[survMgrMap at: [aFish getSpecies]] 
           getStarvSurvivalFor: aFish]; 
}


- foodAvailAndConInCell: aFish 
{
  FILE * foodReportPtr=NULL;
  const char * foodReportFile = "Food_Availability_Out.csv";
  char strDataFormat[100];
  char date[12];
  double hourlySearchConRate;
  double hourlyDriftConRate;
  char * fileMetaData;

  if([space getFoodReportFirstTime] == YES){
     if((foodReportPtr = fopen(foodReportFile,"w")) == NULL){
          fprintf(stderr, "ERROR: Cannot open %s for writing",foodReportFile);
          fflush(0);
          exit(1);
     }
     fileMetaData = [BreakoutReporter reportFileMetaData: scratchZone];
     fprintf(foodReportPtr,"\n%s\n\n",fileMetaData);
     [scratchZone free: fileMetaData];

     fprintf(foodReportPtr,"%s,%s,%s,%s,%s,%s,%s,%s,%s\n","Date",
                                                       "ReachName",
                                                       "PolyCellNumber",
                                                       "SearchFoodProd",
                                                       "DriftFoodProd",
                                                       "SearchAvail",
                                                       "Driftavail",
                                                       "SearchConsumed",
                                                       "DriftConsumed");
     fflush(foodReportPtr);

  }

  if([space getFoodReportFirstTime] == NO)
  {
      if((foodReportPtr = fopen(foodReportFile,"a")) == NULL)
      {
          fprintf(stderr, "ERROR: Cannot open %s for writing\n", foodReportFile);
          fflush(0);
          exit(1);
      }

      hourlySearchConRate = [aFish getHourlySearchConRate];
      hourlyDriftConRate = [aFish getHourlyDriftConRate];

      strncpy(date, [timeManager getDateWithTimeT: [space getModelTime]],12);
      strcpy(strDataFormat,"%s,%s,%d,%E,%E,%E,%E,%E,%E\n");
      // Use the following if you want the floating point data to be pretty
      //strcpy(strDataFormat,"%s,%s,%d,");
      //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: searchHourlyCellTotal]);
      //strcat(strDataFormat,",");
      //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: driftHourlyCellTotal]);
      //strcat(strDataFormat,",");
      //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: hourlyAvailSearchFood]);
      //strcat(strDataFormat,",");
      //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: hourlyAvailDriftFood]);
      //strcat(strDataFormat,",");
      //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: hourlySearchConRate]);
      //strcat(strDataFormat,",");
      //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: hourlyDriftConRate]);
      //strcat(strDataFormat,"\n");

      //fprintf(stdout, "FishCell >>>> foodAvailAndConInCell >>> format of line = %s \n", strDataFormat);
      //fflush(0);
      //exit(1);

      fprintf(foodReportPtr,strDataFormat, date,
					  [[self getSpace] getReachName],
                                           polyCellNumber,
                                           searchHourlyCellTotal,
                                           driftHourlyCellTotal,
                                           hourlyAvailSearchFood,
                                           hourlyAvailDriftFood,
                                           hourlySearchConRate,
                                           hourlyDriftConRate);

     fflush(foodReportPtr);
  }

  if(foodReportPtr != NULL) 
  {
      fclose(foodReportPtr);
  }

  [space setFoodReportFirstTime: NO];

  return self;
}



/////////////////////////////////////////
//
// depthVelReport
//
/////////////////////////////////////////
- depthVelReport: (FILE *) depthVelPtr {
    char date[12];
    char strDataFormat[100];
    double theFlow;

    if([space getDepthVelRptFirstTime] == YES){
         fprintf(depthVelPtr,"%s,%s,%s,%s,%s,%s\n", "Date",
                                                    "Flow",
                                                    "PolyCellNumber",
                                                    "PolyCellArea",
                                                    "PolyCellDepth",
                                                    "PolyCellVelocity");
         fflush(depthVelPtr);
    }
    if(polyCellDepth != 0){
      theFlow = [space getRiverFlow];
      strncpy(date, [timeManager getDateWithTimeT: [space getModelTime]],12);
      strcpy(strDataFormat,"%s,%E,%d,%E,%E,%E\n");
      //pretty print
      //strcpy(strDataFormat,"%s,");
      //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: theFlow]);
      //strcat(strDataFormat,",%d,");
      //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: polyCellArea]);
      //strcat(strDataFormat,",");
      //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: polyCellDepth]);
      //strcat(strDataFormat,",");
      //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: polyCellVelocity]);
      //strcat(strDataFormat,"\n");

      fprintf(depthVelPtr,strDataFormat, date,
                                         theFlow,
                                         polyCellNumber,
                                         polyCellArea,
                                         polyCellDepth,
                                         polyCellVelocity);
      fflush(depthVelPtr);
    }
    [space setDepthVelRptFirstTime: NO];
    return self;
}


- (double) getHabDriftConc
{
    return [space getHabDriftConc];
}



- (double) getHabSearchProd
{
    return [space getHabSearchProd];
}


///////////////////////////////////
//
// setCellDataSet
//
//////////////////////////////////
- setCellDataSet: (BOOL) aBool
{
   cellDataSet = aBool;
   return self;
}

//////////////////////////////////
//
// checkCellDataSet
//
/////////////////////////////////
- checkCellDataSet
{
    if(cellDataSet == NO)
    {
        fprintf(stderr, "FishCell >>>> checkCellDataSet >>>>  fracShelter, distToHide, fracSpawn has not been set\n");
        fprintf(stderr, "FishCell >>>> checkCellDataSet >>>>  cellNumber = %d in reach = %s\n", polyCellNumber, [reach getReachName]);
        fflush(0);
        exit(1);
    }

    return self;
}

///////////////////////////////////////////////////////////////////////////////
//
// compareToUS
// Needed by QSort in HabitatSpace method: calcPolyDistFromRE
//
///////////////////////////////////////////////////////////////////////////////
- (int) compareToUS: (FishCell *) cell {
  double otherCellDistToUS = [cell getCellDistToUS];

  if(cellDistToUS > otherCellDistToUS){
    return 1;
  }else if (cellDistToUS == otherCellDistToUS){
    return 0;
  }else{
    return -1;
  }
}

///////////////////////////////////////////////////////////////////////////////
//
// compareToDS
// Needed by QSort in HabitatSpace method: calcPolyDistFromRE
//
///////////////////////////////////////////////////////////////////////////////
- (int) compareToDS: (FishCell *) cell {
  double otherCellDistToDS = [cell getCellDistToDS];

  if(cellDistToDS > otherCellDistToDS){
    return 1;
  }else if (cellDistToDS == otherCellDistToDS){
    return 0;
  }else{
    return -1;
  }
}

/////////////////////////////////////////
//
// drop
//
////////////////////////////////////////
- (void) drop
{

   //fprintf(stdout, "FishCell >>>> drop >>>> BEGIN\n");
   //fflush(0);
   

   [fishIContain  removeAll];
   [fishIContain  drop];
   fishIContain = nil;
   [reddsIContain removeAll];
   [reddsIContain drop];
   reddsIContain = nil;

   [listOfAdjacentCells removeAll];
   [listOfAdjacentCells drop];
   listOfAdjacentCells = nil;

   [survMgrMap deleteAll];
   [survMgrMap drop];
   survMgrMap = nil;

   [survMgrReddMap deleteAll];
   [survMgrReddMap drop];
   survMgrReddMap = nil;

   [velocityInterpolator drop];
   [depthInterpolator drop];

   [super drop];
   self = nil;

   //fprintf(stdout, "FishCell >>>> drop >>>> END\n");
   //fflush(0);
}

@end


