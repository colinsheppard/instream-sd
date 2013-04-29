//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 




#include <math.h>
#import  "Trout.h"
#import "UTMRedd.h"

@protocol Model
- (time_t)getModelTime;
- createANewFishFrom: aRedd;
- addToEmptyReddList: aRedd;

- (Trout *) createNewFishWithFishParams: (FishParams *) aFishParams  
                         withTroutClass: (Class) aTroutClass
                                    Age: (int) age
                                 Length: (float) fishLength;

- addAFish: (Trout *) aTrout;

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
  numberOfEggsLostToSuperimp = 0;

  if([model getWriteReddMortReport] == YES){
    printList     = [List create: reddZone];
  }
  if([model getWriteReddSurvReport] == YES){
    survPrintList = [List create: reddZone];
  }

  reddNormalDist = [NormalDist create: reddZone 
                         setGenerator: randGen
                              setMean: fishParams->reddNewLengthMean
                            setStdDev: fishParams->reddNewLengthStdDev];


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


- setReddBinomialDist: (id <BinomialDist>) aBinomialDist
{
   reddBinomialDist = aBinomialDist;
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

- setCell: (FishCell *) aCell 
{
  myCell = aCell;
  cellNumber = [myCell getPolyCellNumber];
  return self;
}

  
- (FishCell *) getCell 
{
  return myCell;
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
{
  if (myRasterX >= 0)  // myRasterX is -1 if there are no pixels in cell
  {
  [aRaster ellipseX0: myRasterX - 4 
                  Y0: myRasterY - 3 
                  X1: myRasterX + 4 
                  Y1: myRasterY + 3 
               Width: 1 
               Color: myColor];  
  }

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

    strncpy(speciesName, [fishParams getInstanceName], 35);
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
  int eggsLostToDewatering=0;
  int eggsLostToScouring=0;
  int eggsLostToLowTemp=0;
  int eggsLostToHiTemp=0;
  int eggsLostToSuperimp=0;

  int totalEggsLost = 0;

   double dewater = -LARGEINT;
   double scour = -LARGEINT;
   double loTemp = -LARGEINT;
   double hiTemp = -LARGEINT;
   double superimp = -LARGEINT;

   //fprintf(stdout, "UTMRedd >>>> survive >>>> BEGIN\n");
   //fflush(0);

   //
   // Begin code for the survival manager 
   //
   {
        id <List> listOfSurvProbs;
        id <ListIndex> lstNdx;
        id <SurvProb> aProb;

	// I think the following is redundant of updateReddSurvivalProbFor --colin
        // [myCell updateReddHabitatSurvProb];
        [myCell updateReddSurvivalProbFor: self];

        listOfSurvProbs = [myCell getReddListOfSurvProbsFor: self];
        lstNdx = [listOfSurvProbs listBegin: scratchZone];

        while(([lstNdx getLoc] != End) && ((aProb = [lstNdx next]) != nil))
        {

            //
            // These should be in this order -- see FishCell.m
            //
            if(dewater == -LARGEINT) dewater = [aProb getSurvivalProb];
            else if (scour == -LARGEINT) scour = [aProb getSurvivalProb];
            else if (loTemp == -LARGEINT) loTemp = [aProb getSurvivalProb];
            else if (hiTemp == -LARGEINT) hiTemp = [aProb getSurvivalProb];
            else if (superimp == -LARGEINT) superimp = [aProb getSurvivalProb];
        }

        [lstNdx drop];  

        if(    (dewater == -LARGEINT) 
            || (scour == -LARGEINT) 
            || (loTemp == -LARGEINT)
            || (hiTemp == -LARGEINT)
            || (superimp == -LARGEINT))
         {
               fprintf(stderr, "ERROR: Redd >>>> survive probability values not properly set\n");
               fflush(0);
               exit(1);
         }

   }
   //
   // End code for the survival manager
   //

	   if(numberOfEggs > 0){
		eggsLostToDewatering = [reddBinomialDist getUnsignedSampleWithNumTrials: (unsigned) numberOfEggs
																withProbability: (1.0 - dewater)];
		numberOfEggs -= eggsLostToDewatering; 
	}
	if(numberOfEggs > 0){
		eggsLostToScouring = [reddBinomialDist getUnsignedSampleWithNumTrials: (unsigned) numberOfEggs
														  withProbability: (1.0 - scour)];
		numberOfEggs -= eggsLostToScouring; 
	}
	if(numberOfEggs > 0){
		eggsLostToLowTemp = [reddBinomialDist getUnsignedSampleWithNumTrials: (unsigned) numberOfEggs
														 withProbability: (1.0 - loTemp)];
		numberOfEggs -= eggsLostToLowTemp; 
	}
	if(numberOfEggs > 0){
		eggsLostToHiTemp = [reddBinomialDist getUnsignedSampleWithNumTrials: (unsigned) numberOfEggs
														withProbability: (1.0 - hiTemp)];
		numberOfEggs -= eggsLostToHiTemp; 
	}
	if(numberOfEggs > 0){
		eggsLostToSuperimp = [reddBinomialDist getUnsignedSampleWithNumTrials: (unsigned) numberOfEggs
														  withProbability: (1.0 - superimp)];
		numberOfEggs -= eggsLostToSuperimp; 
	}
	if(numberOfEggs < 0){
		fprintf(stderr, "ERROR: Redd >>>> survive >>>> numberOfEggs is less than 0\n");
		fflush(0);
		exit(1);
	}

   numberOfEggsLostToDewatering += (int)eggsLostToDewatering;
   numberOfEggsLostToScouring += (int)eggsLostToScouring;
   numberOfEggsLostToLowTemp += (int)eggsLostToLowTemp;
   numberOfEggsLostToHiTemp += (int)eggsLostToHiTemp;
   numberOfEggsLostToSuperimp += (int)eggsLostToSuperimp;

   totalEggsLost =  numberOfEggsLostToDewatering 
				 + numberOfEggsLostToScouring 
				 + numberOfEggsLostToLowTemp 
				 + numberOfEggsLostToHiTemp 
				 + numberOfEggsLostToSuperimp;

  if(totalEggsLost > initialNumberOfEggs){
	   fprintf(stderr, "ERROR: Redd >>>> survive >>>> totalEggsLost is greater than the initialNumberOfEggs\n");
	   fprintf(stderr, "ERROR: Redd >>>> survive >>>> totalEggsLost %d\n", totalEggsLost);
	   fprintf(stderr, "ERROR: Redd >>>> survive >>>> initialNumberOfEggs %d\n", initialNumberOfEggs);
	   fflush(0);
	   exit(1);
   }

  if([model getWriteReddMortReport] == YES){
	[self createPrintString: eggsLostToDewatering
							  : eggsLostToScouring
							  : eggsLostToLowTemp
							  : eggsLostToHiTemp
							  : eggsLostToSuperimp
							  : [model getModelTime] ];
	  }

  if([model getWriteReddSurvReport] == YES){
	[self createSurvPrintStringWithDewaterSF: dewater
								withScourSF: scour
							   withLoTempSF: loTemp
							   withHiTempSF: hiTemp
							 withSuperimpSF: superimp];
	}
 
  if(numberOfEggs < 0){
     fprintf(stderr, "ERROR: Redd >>>> survive >>>> numberOfEggs is less than zero\n");
     fflush(0);
     exit(1);
  }
  if(numberOfEggs == 0 ) 
  {
    if([model getWriteReddMortReport] == YES){
      [self printReport];
    }
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

       if(myCell != nil) 
       {
          temperature = [myCell getTemperature];
       }
       else 
       {
            fprintf(stderr, "WARNING: Redd >>>> develop >>>> Redd %p has no myCell\n", self);
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
		   if([model getWriteReddMortReport] == YES){
			 [self printReport]; // Added 2/28/04 skj
		   }
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

   [myCell removeRedd: self]; 

   myCell = nil;

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
                           withTroutClass: [objc_get_class([fishParams getInstanceName]) class] 
                                      Age: 0
                                   Length: length];

   //
   // Initialize fish's depth/length ratio so stranding mort works
   //
   depthLengthRatio = [myCell getPolyCellDepth] /length;
   [newFish setDepthLengthRatio: depthLengthRatio];
   [newFish setNewFishActivityToFEED];
  
   [newFish setFishColor: myColor];

   [myCell addFish: newFish]; 
   [newFish setWorld: myCell];

   [model addAFish: newFish];

   //fprintf(stdout, "UTMRedd >>>> turnMyselfIntoAFish >>>> END\n");
   //fflush(0);

   return self;
}

- setRasterX: (unsigned) anX
{
    myRasterX = anX;

    //    fprintf(stderr,"Setting rasterX to %d \n",myRasterX);
    //    fflush(0);

    return self;
}

- setRasterY: (unsigned) aY
{
    myRasterY = aY;
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
- printReport 
{
  id <ListIndex> printNdx;
  id nextString;
  FILE* printRptPtr = [model getReddReportFilePtr];

  if(printRptPtr == NULL)
  {
      fprintf(stderr, "ERROR: Redd >>>> printReport >>>> printRptPtr = %p\n", printRptPtr);
      fflush(0);
      exit(1);
  }

  fprintf(printRptPtr,"\n%s %p\n","BEGIN REPORT for Redd", self);
  fprintf(printRptPtr,"Redd: %p Scenario = %d Replicate = %d\n", self, [model getScenario],
                                                                       [model getReplicate]);

  fprintf(printRptPtr,"Redd: %p Species: %s  CellNumber: %d\n", self,
                                                                [species getName],
                                                                cellNumber);

  fprintf(printRptPtr,"Redd: %p INITIAL NUMBER OF EGGS: %d\n", self, initialNumberOfEggs);

  fprintf(printRptPtr,"\n%-12s%-12s%-12s%-10s%-10s%-10s%-10s\n", "Redd",
                                                                 "Date",
                                                                 "Dewatering", 
                                                                 "Scouring",
                                                                 "LowTemp",
                                                                 "HiTemp",
                                                                 "Superimposition");

  printNdx = [printList listBegin: [self getZone]];

  while(([printNdx getLoc] != End) && ((nextString = [printNdx next]) != nil)) 
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
                                                              numberOfEggsLostToSuperimp);

  fprintf(printRptPtr,"\n\n%s %p\n","END REPORT for Redd", self);

  [printNdx drop];
  [printList drop];

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
                   : (int) eggsLostToSuperimp
                   : (time_t) aModelTime_t {

  id printString;
  const char* formatString;

  printString  = [[self getZone] alloc: 300*sizeof(char)];

  formatString = "%-12p%-12s%-12d%-10d%-10d%-10d%-10d\n";
 
  sprintf((char *)printString,formatString, self,
                                            [timeManager getDateWithTimeT: aModelTime_t],
                                            eggsLostToDewatering,
                                            eggsLostToScouring,
                                            eggsLostToLowTemp,
                                            eggsLostToHiTemp,
                                            eggsLostToSuperimp);


  [printList addLast: printString];

  return self;
}


////////////////////////////////////////////////////////////////
//
//createSurvPrintString
//
////////////////////////////////////////////////////////////////
- createSurvPrintStringWithDewaterSF: (double) aDewaterSF
                         withScourSF: (double) aScourSF
                        withLoTempSF: (double) aLoTempSF
                        withHiTempSF: (double) aHiTempSF
                      withSuperimpSF: (double) aSuperimpSF
 {

  id printString;
  char formatString[150];

  printString  = [[self getZone] alloc: 300*sizeof(char)];

  strcpy(formatString,"%p,%s,%E,%E,%E,%E,%E,%E,%E,%E\n");

  sprintf((char *)printString,formatString,self,
					    [species getName],
                                            [myCell getTemperature],
                                            [myCell getRiverFlow],
                                            [myCell getPolyCellDepth],
                                            aDewaterSF,
                                            aScourSF,
                                            aLoTempSF,
                                            aHiTempSF,
                                            aSuperimpSF);
  [survPrintList addLast: printString];
  return self;
}



//////////////////////////////////////////////////////////
//
//printReddSurvReport
//
/////////////////////////////////////////////////////
- printReddSurvReport: (FILE *) printRptPtr {
  id <ListIndex> printNdx;
  id nextString;
  const char *formatString;

  fprintf(printRptPtr,"\n\n%s %p\n","BEGIN SURVIVAL REPORT for Redd", self);

  fprintf(printRptPtr,"Redd: %p Species: %s  CellNumber: %d\n", self,
                                                                [species getName],
                                                                cellNumber);

  fprintf(printRptPtr,"Redd: %p INITIAL NUMBER OF EGGS: %d\n", self, initialNumberOfEggs);
  formatString = "\n%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n";

  fprintf(printRptPtr,formatString, "Redd",
                                    "Species",
                                    "Temperature",
                                    "Flow",
                                    "Depth",
                                    "Dewatering", 
                                    "Scouring",
                                    "LowTemp",
                                    "HiTemp",
                                    "Superimposition");

  printNdx = [survPrintList listBegin: [self getZone]];

  while( ([printNdx getLoc] != End) && ( (nextString = [printNdx next]) != nil) ) {
    fprintf(printRptPtr,"%s",(char *) nextString);
    [[self getZone] free: (void *) nextString];
  }

  fprintf(printRptPtr,"\n\n%s %p\n","END SURVIVAL REPORT for Redd", self);

[printNdx drop];
[survPrintList drop];

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
       double superimp = -LARGEINT;

       //fprintf(stdout, "UTMRedd >>>> createSurvPrintString >>>> BEGIN\n");
       //fflush(0);

       //
       // Begin code for the survival manager 
       //
       {
             id <List> listOfSurvProbs;
             id <ListIndex> lstNdx;
             id <SurvProb> aProb;

             [myCell updateReddSurvivalProbFor: self];
             // again I think the following is redundant --colin
	     //[myCell updateReddHabitatSurvProb];
     
             listOfSurvProbs = [myCell getReddListOfSurvProbsFor: self];
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
                 else if (superimp == -LARGEINT) superimp = [aProb getSurvivalProb];
             }

             [lstNdx drop];  

             if(    (dewater == -LARGEINT) 
                 //|| (scour == -LARGEINT) 
                 || (loTemp == -LARGEINT)
                 || (hiTemp == -LARGEINT)
                 || (superimp == -LARGEINT))
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
                                                       [myCell getTemperature],
                                                       [myCell getDailyMeanFlow],
                                                       [myCell getPolyCellDepth],
                                                       dewater,
                                                       scour,
                                                       loTemp,
                                                       hiTemp,
                                                       superimp);
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
                                           + numberOfEggsLostToSuperimp);

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
                                       cellNumber,
                                       reddCreateDate,
                                       initialNumberOfEggs,
                                       emptyDate,
                                       numberOfEggsLostToDewatering,
                                       numberOfEggsLostToScouring,
                                       numberOfEggsLostToLowTemp,
                                       numberOfEggsLostToHiTemp,
                                       numberOfEggsLostToSuperimp,
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

