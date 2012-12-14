//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 




#include <math.h>
#import  "UTMTrout.h"
#import "UTMRedd.h"

@protocol Model
- (time_t)getModelTime;
- createANewFishFrom: aRedd;
- addToEmptyReddList: aRedd;

- (UTMTrout *) createNewFishWithFishParams: (FishParams *) aFishParams  
                         withTroutClass: (Class) aTroutClass
                                    Age: (int) age
                                 Length: (float) fishLength;

- addAFish: (UTMTrout *) aTrout;

- (int) getScenario;
- (int) getReplicate;
- (FILE *) getReddSummaryFilePtr;
- (FILE *) getReddReportFilePtr;

@end



@implementation UTMRedd

///////////////////////////////////////
//
// createBegin
//
//////////////////////////////////////
+ createBegin: aZone
{
    UTMRedd* redd = [super createBegin: aZone];
    redd->fishParams = nil;
    redd->printSummaryFlag = NO;
    redd->printMortalityFlag = NO;
    redd->printList = nil; 
    redd->survPrintList = nil; 
    return redd;
}


//////////////////////////////////////////////
//
// - createEnd
//
/////////////////////////////////////////////
- createEnd 
{
  [super createEnd];

  reddZone = [Zone create: [self getZone]];

  numEggsToEmerge = 0;
  emergeDays = 0;

  fracDeveloped = 0.0;

  numberOfEggsLostToDewatering = 0;
  numberOfEggsLostToScouring = 0;
  numberOfEggsLostToLowTemp = 0;
  numberOfEggsLostToHiTemp = 0;
  numberOfEggsLostToSuperImp = 0;


  
  reddNormalDist = [NormalDist create: reddZone 
                         setGenerator: randGen
                              setMean: fishParams->reddNewLengthMean
                            setStdDev: fishParams->reddNewLengthStdDev];


  return self;
}


/////////////////////////////////////////
//
// createPrintList
// invoked from the model swarm
//
////////////////////////////////////////
- createPrintList
{
   if(printSummaryFlag == YES)
   {
        printList     = [List create: reddZone];
   }
   return self;
}



////////////////////////////////////
//
// createSurvPrintList
// invoked from the model swarm
//
///////////////////////////////////
- createSurvPrintList
{
    if(printMortalityFlag ==  YES)
    {
        survPrintList = [List create: reddZone];
    }

    return self;
}

//////////////////////////////////////////////
//
// setTimeManager
//
////////////////////////////////////////////
- setTimeManager: (id <TimeManager>) aTimeManager
{
    timeManager = aTimeManager;
    return self;
}


- setModel: aModel
{
   model = (id <Model>) aModel;
   return self;
}



- setFishParams: (FishParams *) aFishParams
{
   fishParams = aFishParams;
   return self;
}


- (FishParams *) getFishParams
{
    return fishParams;
}

- setWorld: (FishCell *) aCell 
{
  fishCell = aCell;
  utmCellNumber = [fishCell getUTMCellNumber];
  return self;
}

  
- (FishCell *) getWorld 
{
  return fishCell;
}

- setCreateTimeT: (time_t) aCreateTime 
{
    createTime = aCreateTime;
    return self;
}

- (time_t) getCreateTimeT 
{
    return createTime;
}

- (time_t) getCurrentTimeT 
{
    return [model getModelTime];
}


- setReddColor: (Color) aColor 
{
    myColor = aColor;
    return self;
}

- (Color) getReddColor 
{
    return myColor;
}


/////////////////////////////////////////////////////////////
//
// drawSelfOn
//
/////////////////////////////////////////////////////////////
- drawSelfOn: (id <Raster>) aRaster 
         atX: (int) anX 
           Y: (int) aY 
{
  [aRaster ellipseX0: anX - 5 
                  Y0: aY - 3 
                  X1: anX + 5 
                  Y1: aY + 3 
               Width: 2 
               Color: myColor];  

  return self;
}


///////////////////////////////////
//
// setSpecies
//
//////////////////////////////////
- setSpecies: (id <Symbol>) aSymbol 
{
    species = aSymbol;

    if(fishParams == nil)
    {
        fprintf(stderr, "ERROR: UTMRedd >>>> setSpecies >>>> fishParams must be set prior to this set method\n");
        fflush(0);
        exit(1);
    }

    strncpy(speciesName, [fishParams getSpeciesName], 35);
    return self;
}



- (id <Symbol>) getSpecies 
{
    return species;
}



- setSpeciesNdx: (int) aSpeciesNdx 
{
  speciesNdx = aSpeciesNdx;
  return self;
}

- (int) getSpeciesNdx 
{
  return [fishParams getFishSpeciesIndex];;
}

- setSpawnerLength: (double) aDouble 
{
    spawnerLength = aDouble;
    return self;
}

- (double) getSpawnerLength 
{
    return spawnerLength;
}

- setNumberOfEggs: (int) anInt 
{
    numberOfEggs = anInt;
    initialNumberOfEggs = numberOfEggs;
    return self;
}

- setPercentDeveloped: (double) aDouble 
{
  fracDeveloped = aDouble;
  return self;
}


// Redd Daily Routine Methods: survive, develop, emerge
 

  // Redd mortality risk computation

//////////////////////////////////////////////////////////////
//
// survive
//
//////////////////////////////////////////////////////////////
- survive 
{
   double eggsLostToDewatering = 0.0;
   double eggsLostToScouring = 0.0;
   double eggsLostToLowTemp = 0.0;
   double eggsLostToHiTemp = 0.0;
   double eggsLostToSuperImp = 0.0;

   double dewater = -LARGEINT;
   //double scour = -LARGEINT;
   double loTemp = -LARGEINT;
   double hiTemp = -LARGEINT;
   double superImp = -LARGEINT;

   //fprintf(stdout, "UTMRedd >>>> survive >>>> BEGIN\n");
   //fflush(0);

   //
   // Begin code for the survival manager 
   //
   {
        id <List> listOfSurvProbs;
        id <ListIndex> lstNdx;
        id <SurvProb> aProb;

        [fishCell updateReddHabitatSurvProb];
        [fishCell updateReddSurvivalProbFor: self];

        listOfSurvProbs = [fishCell getReddListOfSurvProbsFor: self];
        lstNdx = [listOfSurvProbs listBegin: scratchZone];

        while(([lstNdx getLoc] != End) && ((aProb = [lstNdx next]) != nil))
        {

            //
            // These should be in this order -- see FishCell.m
            //
            if(dewater == -LARGEINT) dewater = [aProb getSurvivalProb];
            //else if (scour == -LARGEINT) scour = [aProb getSurvivalProb];
            else if (loTemp == -LARGEINT) loTemp = [aProb getSurvivalProb];
            else if (hiTemp == -LARGEINT) hiTemp = [aProb getSurvivalProb];
            else if (superImp == -LARGEINT) superImp = [aProb getSurvivalProb];
        }

        [lstNdx drop];  

        if(    (dewater == -LARGEINT) 
            //|| (scour == -LARGEINT) 
            || (loTemp == -LARGEINT)
            || (hiTemp == -LARGEINT)
            || (superImp == -LARGEINT))
         {
               fprintf(stderr, "ERROR: Redd >>>> survive probability values not properly set\n");
               fflush(0);
               //exit(1);
         }

   }

   eggsLostToDewatering = (numberOfEggs * (1.0 - dewater)) + 0.5;
   numberOfEggs -= (int) eggsLostToDewatering;
                           
   //eggsLostToScouring = (numberOfEggs * (1.0 - scour)) + 0.5;
   //numberOfEggs -= (int) eggsLostToScouring;
   eggsLostToScouring = 0.0;

   eggsLostToLowTemp = (numberOfEggs * (1.0 - loTemp)) + 0.5;
   numberOfEggs -= (int) eggsLostToLowTemp;

   eggsLostToHiTemp = (numberOfEggs * (1.0 - hiTemp)) + 0.5;
   numberOfEggs -= (int) eggsLostToHiTemp;

   eggsLostToSuperImp = (numberOfEggs * (1.0 - superImp)) + 0.5;
   numberOfEggs -= (int) eggsLostToSuperImp;

   //
   // End code for the survival manager
   //

   numberOfEggsLostToDewatering += (int)eggsLostToDewatering;
   numberOfEggsLostToScouring += (int)eggsLostToScouring;
   numberOfEggsLostToLowTemp += (int)eggsLostToLowTemp;
   numberOfEggsLostToHiTemp += (int)eggsLostToHiTemp;
   numberOfEggsLostToSuperImp += (int)eggsLostToSuperImp;

  if(printSummaryFlag == YES)
  {
      [self createPrintString: (int) eggsLostToDewatering
                             : (int) eggsLostToScouring
                             : (int) eggsLostToLowTemp
                             : (int) eggsLostToHiTemp
                             : (int) eggsLostToSuperImp
                             : [(id <Model>)[[fishCell getSpace] getModel] getModelTime] ];
  
   }
   if(printMortalityFlag == YES)
   {
      [self createSurvPrintString];
   }
 
   if(numberOfEggs <= 0 )
   {
      [self removeWhenEmpty];
   }

   //fprintf(stdout, "UTMRedd >>>> survive >>>> END\n");
   //fflush(0);

   return self;
}




//////////////////////////////////////////////////////////////
//
// develop
//
//////////////////////////////////////////////////////////////
- develop 
{
    //fprintf(stdout, "UTMRedd >>>> develop >>>> BEGIN\n");
    //fflush(0);

    if((numberOfEggs > 0) && (fracDeveloped < 1.0) )
    {
       double rDPA, rDPB, rDPC;
       double temperature=-1;  //what is a good value here?
       double  reddDailyDevelop;

       rDPA = fishParams->reddDevelParamA; 
       rDPB = fishParams->reddDevelParamB; 
       rDPC = fishParams->reddDevelParamC; 

       if(fishCell != nil) 
       {
          temperature = [fishCell getUTMCellTemperature];
       }
       else 
       {
            fprintf(stderr, "WARNING: Redd >>>> develop >>>> Redd %p has no fishCell\n", self);
            fflush(0);
       }

       reddDailyDevelop = rDPA + (rDPB * temperature) + ( rDPC * pow(temperature,2) );
       fracDeveloped += reddDailyDevelop;
     
    }

    //fprintf(stdout, "UTMRedd >>>> develop >>>> END\n");
    //fflush(0);

    return self;
}



//////////////////////////////////////////////
//
// emerge
//
/////////////////////////////////////////////
- emerge 
{
  int numFishToEmerge;

  //fprintf(stdout, "UTMRedd >>>>  emerge >>>> BEGIN\n");
  //fflush(0);

  if((fracDeveloped >= 1.0) && (numberOfEggs > 0)) 
  {

      emergeDays++;

      // We assume that the percent of eggs emerging on each day 
      // (starting when percentDeveloped reaches 100%) is 10% the first day,
      // 20% the second day, etc. until all eggs have emerged.

      numFishToEmerge = (int) (emergeDays * 0.10 * numberOfEggs); 

      //
      // create new fish 
      //
      if(numFishToEmerge >= numberOfEggs) 
      {
          numFishToEmerge = numberOfEggs;
      }
      if(numFishToEmerge > 0) 
      {
         int   count;

         for (count = 1; count <= numFishToEmerge; count++) 
         {
	   // For each egg emerging from the redd, the model creates a
	   // new fish object.  The fish inherits its species and
	   // location from the redd.  

           [self turnMyselfIntoAFish];
	   numberOfEggs--;
         }
       }

       //
       // determine if Redd empty - if so, remove redd
       //
       if(numberOfEggs <= 0) 
       {
           [self removeWhenEmpty];
       }
  }

  //fprintf(stdout, "UTMRedd >>>>  emerge >>>> END\n");
  //fflush(0);

  return self;
}

//////////////////////////////////////////////////////////////
//
// removeWhenEmpty
//
/////////////////////////////////////////////////////////////
- removeWhenEmpty 
{ 
   //fprintf(stdout, "UTMRedd >>>> removeWhenEmpty >>>> BEGIN\n");
   //fflush(0);

   [self createReddSummaryStr];
   [self printReddSummary];  

   [model addToEmptyReddList: self];

   [fishCell removeRedd: self]; 

   fishCell = nil;

   //fprintf(stdout, "UTMRedd >>>> removeWhenEmpty >>>> END\n");
   //fflush(0);

   return self;
}


/////////////////////////////////////////////////////////////////
//
// turnMySelfIntoAFish
//
////////////////////////////////////////////////////////////////
- turnMyselfIntoAFish
{
    id newFish = nil;
    double length = LARGEINT;
    double depthLengthRatio = 0.0;

    //fprintf(stdout, "UTMRedd >>>> turnMyselfIntoAFish >>>> BEGIN\n");
    //fflush(0);

    while((length = [reddNormalDist getDoubleSample]) < (0.5*fishParams->reddNewLengthMean))
    {
        ;
    }

    newFish = [model createNewFishWithFishParams: fishParams  
                           //withTroutClass: [objc_get_class([[fishParams getFishSpecies] getName]) class] 
                           withTroutClass: [objc_get_class([fishParams getSpeciesName]) class] 
                                      Age: 0
                                   Length: length];

   //
   // Initialize fish's depth/length ratio so stranding mort works
   //
   depthLengthRatio = [fishCell getUTMCellDepth] /length;
   [newFish setDepthLengthRatio: depthLengthRatio];
   [newFish setNewFishActivityToFEED];
  
   [newFish setFishColor: myColor];

   [fishCell addFish: newFish]; 
   [newFish setWorld: fishCell];

   [model addAFish: newFish];

   //fprintf(stdout, "UTMRedd >>>> turnMyselfIntoAFish >>>> END\n");
   //fflush(0);

   return self;
}


///////////////////////////////////////
//
//
//
//////////////////////////////////////
- setPrintSummaryFlagToYes
{
   printSummaryFlag = YES;
   return self;
}





///////////////////////////////////////
//
//
//
//////////////////////////////////////
- setPrintMortalityFlagToYes
{
    printMortalityFlag = YES;
    return self;
}


//////////////////////////////////////////////////////////
//
//printReport
//
/////////////////////////////////////////////////////
- printReport: (FILE *) printRptPtr 
{
  
  if(printSummaryFlag == YES)
  {
      id <ListIndex> printNdx;
      char* nextString;

      fprintf(printRptPtr,"\n\n%s %p\n","BEGIN REPORT for Redd", self);

      fprintf(printRptPtr,"Redd: %p Species: %s  CellNo: %d\n", self,
                                                                [species getName],
                                                                utmCellNumber);

      fprintf(printRptPtr,"Redd: %p INITIAL NUMBER OF EGGS: %d\n", self, initialNumberOfEggs);

      fprintf(printRptPtr,"\n%-12s%-12s%-12s%-10s%-10s%-10s%-10s\n", "Redd",
                                                                     "Date",
                                                                     "Dewatering", 
                                                                     "Scouring",
                                                                     "LowTemp",
                                                                     "HiTemp",
                                                                     "SuperImposition");
    
      printNdx = [printList listBegin: [self getZone]];

      while(([printNdx getLoc] != End) && ((nextString = (char *) [printNdx next]) != (char *) nil))
      {
         fprintf(printRptPtr,"%s",(char *) nextString);
         [[self getZone] free: nextString];
      }


      fprintf(printRptPtr,"%-12p%-12s%-12d%-10d%-10d%-10d%-10d\n", self, 
                                                                  "TOTALS:",
                                                                  numberOfEggsLostToDewatering,
                                                                  numberOfEggsLostToScouring,
                                                                  numberOfEggsLostToLowTemp,
                                                                  numberOfEggsLostToHiTemp,
                                                                  numberOfEggsLostToSuperImp);
    
      fprintf(printRptPtr,"\n\n%s %p\n","END REPORT for Redd", self);
      fflush(printRptPtr);

      [printNdx drop];
      [printList drop];
  }

  return self;
}



////////////////////////////////////////////////////////////////
//
//createPrintString
//
////////////////////////////////////////////////////////////////
- createPrintString: (int) eggsLostToDewatering
                   : (int) eggsLostToScouring
                   : (int) eggsLostToLowTemp
                   : (int) eggsLostToHiTemp
                   : (int) eggsLostToSuperImp
                   : (time_t) aModelTime_t {

  if(printSummaryFlag == YES)
  {
     char* printString;
     const char* formatString = "%-12p%-12s%-12d%-10d%-10d%-10d%-10d\n";

     printString  = [reddZone  allocBlock: 300*sizeof(char)];

 
     sprintf((char *)printString,formatString, self,
                                            [timeManager getDateWithTimeT: aModelTime_t],
                                            eggsLostToDewatering,
                                            eggsLostToScouring,
                                            eggsLostToLowTemp,
                                            eggsLostToHiTemp,
                                            eggsLostToSuperImp);


      [printList addLast: (void *) printString];

  }

  return self;
}




//This is broken wrt the changes in 
//the survival manager


//////////////////////////////////////////////////////////
//
// printReddSurvReport
//
/////////////////////////////////////////////////////
- printReddSurvReport: (FILE *) printRptPtr 
{
   if(printMortalityFlag == YES)
   {
       id <ListIndex> printNdx;
       char* nextString;
       const char *formatString;

       //fprintf(stdout, "UTMRedd >>>> printReddSurvReport >>>> BEGIN\n");
       //fprintf(stdout, "UTMRedd >>>> printReddSurvReport >>>> printRptPtr = %p\n", printRptPtr);
       //fflush(0);

       fprintf(printRptPtr,"\n\n%s %p\n","BEGIN SURVIVAL REPORT for Redd", self);

       fprintf(printRptPtr,"Redd: %p Species: %s  CellNo: %d\n",self,
                                                   [species getName],
                                                      utmCellNumber);
       fprintf(printRptPtr,"Redd: %p INITIAL NUMBER OF EGGS: %d\n", self, initialNumberOfEggs);

       formatString = "\n%-12s%-12s%-12s%-12s%-12s%-12s%-12s%-12s%-12s%-12s\n";

       fprintf(printRptPtr,formatString, "Redd",
                                         "Species",
                                         "Temperature",
                                         "Flow",
                                         "Depth",
                                         "Dewatering", 
                                         "Scouring",
                                         "LowTemp",
                                         "HiTemp",
                                         "SuperImposition");


       printNdx = [survPrintList listBegin: [self getZone]];

       while(([printNdx getLoc] != End) && ((nextString = (char *) [printNdx next]) != (char *) nil))
       {
         fprintf(printRptPtr,"%s",(char *) nextString);
         fflush(printRptPtr);
         //[[self getZone] free: (void *) nextString];
       }

       [printNdx setLoc: Start];
       while(([printNdx getLoc] != End) && ((nextString = (char *) [printNdx next]) != (char *) nil))
       {
         [reddZone freeBlock: (void *) nextString blockSize: 300*sizeof(char)];
       }

       fprintf(printRptPtr,"\n\n%s %p\n","END SURVIVAL REPORT for Redd", self);

       [printNdx drop];
       [survPrintList drop];

       //fprintf(stdout, "UTMRedd >>>> printReddSurvReport >>>> END\n");
       //fflush(0);
     
  }
  return self;
}






////////////////////////////////////////////////////////////////
//
//createSurvPrintString
//
////////////////////////////////////////////////////////////////
- createSurvPrintString 
{
   if(printMortalityFlag == YES)
   {
       char* printString;
       const char* formatString;
       double dewater = -LARGEINT;
       double scour = -LARGEINT;
       double loTemp = -LARGEINT;
       double hiTemp = -LARGEINT;
       double superImp = -LARGEINT;

       //fprintf(stdout, "UTMRedd >>>> createSurvPrintString >>>> BEGIN\n");
       //fflush(0);

       //
       // Begin code for the survival manager 
       //
       {
             id <List> listOfSurvProbs;
             id <ListIndex> lstNdx;
             id <SurvProb> aProb;

             [fishCell updateReddSurvivalProbFor: self];
             [fishCell updateReddHabitatSurvProb];
     
             listOfSurvProbs = [fishCell getReddListOfSurvProbsFor: self];
             lstNdx = [listOfSurvProbs listBegin: scratchZone];
     
             while(([lstNdx getLoc] != End) && ((aProb = [lstNdx next]) != nil))
             {

                 //
                 // These should be in this order -- see FishCell.m
                 //
                 if(dewater == -LARGEINT) dewater = [aProb getSurvivalProb];
                 //else if (scour == -LARGEINT) scour = [aProb getSurvivalProb];
                 else if (loTemp == -LARGEINT) loTemp = [aProb getSurvivalProb];
                 else if (hiTemp == -LARGEINT) hiTemp = [aProb getSurvivalProb];
                 else if (superImp == -LARGEINT) superImp = [aProb getSurvivalProb];
             }

             [lstNdx drop];  

             if(    (dewater == -LARGEINT) 
                 //|| (scour == -LARGEINT) 
                 || (loTemp == -LARGEINT)
                 || (hiTemp == -LARGEINT)
                 || (superImp == -LARGEINT))
              {
                    fprintf(stderr, "ERROR: Redd >>>> survive probability values not properly set\n");
                    fflush(0);
                    //exit(1);
              }

        }


       //
       // Not using scour 
       // 
       scour = 0.0;

       printString  = (char *) [reddZone allocBlock: 300*sizeof(char)];

       formatString = "%-12p%-12s%-12f%-12f%-12f%-12f%-12f%-12f%-12f%-12f\n";
     
       sprintf((char *)printString,formatString, self  , [species getName],
                                                       [fishCell getUTMCellTemperature],
                                                       [fishCell getDailyMeanFlow],
                                                       [fishCell getUTMCellDepth],
                                                       dewater,
                                                       scour,
                                                       loTemp,
                                                       hiTemp,
                                                       superImp);
       [survPrintList addLast: (void *) printString];
     
       //fprintf(stdout, "UTMRedd >>>> createSurvPrintString >>>> END\n");
       //fflush(0);
   }

  return self;
}



////////////////////////////////////////////////////////
//
// createReddSummaryStr
//
///////////////////////////////////////////////////////
- createReddSummaryStr 
{
  char* formatString = "%-12d%-12d%-12p%-12s%-12d%-12s%-21d%-12s%-12d%-12d%-12d%-12d%-12d%-12d\n";

  char reddCreateDate[12];
  char emptyDate[12];

  int fryEmerged = initialNumberOfEggs - (   numberOfEggsLostToDewatering
                                           + numberOfEggsLostToScouring
                                           + numberOfEggsLostToLowTemp
                                           + numberOfEggsLostToHiTemp
                                           + numberOfEggsLostToSuperImp);

  //fprintf(stdout, "UTMRedd >>>> createReddSummaryStr >>>> BEGIN\n");
  //fflush(0);

  if(summaryString == NULL)
  {
      summaryString = (char *) [reddZone  allocBlock: 300*sizeof(char)];
  }

  strncpy(reddCreateDate, [timeManager getDateWithTimeT: createTime], 11);  
  strncpy(emptyDate, [timeManager getDateWithTimeT: [model getModelTime]], 11);
  
  sprintf(summaryString, formatString, [model getScenario],  
                                       [model getReplicate],
                                       self,
                                       [species getName],
                                       utmCellNumber,
                                       reddCreateDate,
                                       initialNumberOfEggs,
                                       emptyDate,
                                       numberOfEggsLostToDewatering,
                                       numberOfEggsLostToScouring,
                                       numberOfEggsLostToLowTemp,
                                       numberOfEggsLostToHiTemp,
                                       numberOfEggsLostToSuperImp,
                                       fryEmerged);

  //fprintf(stdout, "UTMRedd >>>> createReddSummaryStr >>>> END\n");
  //fflush(0);

  return self;

}

////////////////////////////////////////////////////////////
//
// printReddSummary
//
////////////////////////////////////////////////////////////
- printReddSummary 
{
  FILE* fptr = [model getReddSummaryFilePtr];

  //fprintf(stdout, "UTMRedd >>>> printReddSummary >>>> BEGIN\n");
  //fflush(0);

  if(fptr == NULL) 
  {
      fprintf(stderr, "ERROR: UTMRedd >>>> printReddSummary >>>> The FILE pointer is NULL\n");
      fflush(0);
      exit(1);
  }

  fprintf(fptr,"%s",summaryString);
  fflush(0);

  if(summaryString != NULL)
  {
      [reddZone freeBlock: summaryString
                blockSize: 300*sizeof(char)];
  }
  

  //fprintf(stdout, "UTMRedd >>>> printReddSummary >>>> END\n");
  //fflush(0);

  return self;
}


///////////////////////////////
//
// getADouble
//
//////////////////////////////
- (double) getADouble
{
   return 1.0;
}


////////////////////////////
//
// drop
//
////////////////////////////
- (void) drop
{
     [reddNormalDist drop];
     [reddZone drop];
     [super drop];
}

@end

