//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import "TimeSeriesInputManager.h"


@implementation TimeSeriesInputManager

 +    createBegin: (id <Zone>) aZone
     withDataType: (char *) aTypeString
    withInputFile: (char *) aFileName
  withTimeManager: (id <TimeManager>) aTimeManager
    withStartTime: (time_t) aStartTime
      withEndTime: (time_t) anEndTime
    withCheckData: (BOOL) aFlag;
{
   
     TimeSeriesInputManager* timeSeriesInputManager;
 
     timeSeriesInputManager = [super createBegin: aZone];

     timeSeriesInputManager->timeSeriesInputZone = [Zone create: aZone]; 

     timeSeriesInputManager->timeManager = nil; 

     if(strncmp(aTypeString, "DAILY", strlen("DAILY")) == 0)
     {
           timeSeriesInputManager->inputDataType = DAILY;
     }
     else if(strncmp(aTypeString, "HOURLY", strlen("HOURLY")) == 0)
     {
           timeSeriesInputManager->inputDataType = HOURLY;
     }
     else if(strncmp(aTypeString, "OTHER", strlen("OTHER")) == 0)
     {
           timeSeriesInputManager->inputDataType = OTHER;
     }
     else
     {
          fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> createBegin >>>> incorrect data type >>>> data type >>>> aTypeString = %s\n", aTypeString);
          fflush(0);
          exit(1);
     }


     timeSeriesInputManager->inputFileName = (char *) [timeSeriesInputManager->timeSeriesInputZone allocBlock: strlen(aFileName) + 1];

     strcpy(timeSeriesInputManager->inputFileName, aFileName);

     timeSeriesInputManager->timeManager = aTimeManager;

     if(timeSeriesInputManager == nil)
     {
        fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> createBegin >>>> timeManager = is nil\n");
        fflush(0);
        exit(1);
     }


     timeSeriesInputManager->startTime = aStartTime;
     timeSeriesInputManager->endTime = anEndTime;

     timeSeriesInputManager->log10OfValuesOn = NO;

     timeSeriesInputManager->checkData = aFlag;

     return timeSeriesInputManager;

}


- createEnd
{

  if(checkData == TRUE)
  {
       [self checkData];
  }

  [self readInputRecords];

  return [super createEnd];

}




//SETTING

////////////////////////////////////
//
// setLog10OfValues
//
////////////////////////////////////
- setLog10OfValues
{

  int i;
  double aValue;

  if(log10OfValuesOn == NO) 
  {

      for(i = 0; i < numRecords; i++)
      {
          
          aValue = inputRecord[i][1];
    
          if(aValue <= 0.0)
          {
              fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> setLog10OfValues >>>> input data is less than or equal to zero >>>> input data = %f inputFileName = %s \n", aValue, inputFileName);
              fflush(0);
              exit(1);
          }
    
          inputRecord[i][1] = log10(aValue);
      }


      log10OfValuesOn = YES;
  }

  return self;
}


//
//USING
//

////////////////////////////////////////////
//
// getValueForTime
// 
///////////////////////////////////////////
- (double) getValueForTime: (time_t) aTime
{

   int i;
   BOOL ERROR = YES;
   double returnVal = -LARGEINT;

   if((startTime <= aTime) && (aTime <= endTime))
   {
       ERROR = NO;
   }

   if(!ERROR)
   {
       ERROR = YES;

       for(i=0; i<numRecords; i++) 
       {

           if( (time_t) inputRecord[i][0] == aTime) 
           {
               returnVal = inputRecord[i][1];
               ERROR = NO;
               break;
           }

       }
   }

   //
   //Trap Errors Here
   //
   if(ERROR)
   {
       //for(i=0; i<numRecords; i++){
	  //fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> getValueForTime >>>> time %ld \n",inputRecord[i][0]);
       //}
       fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> getValueForTime >>>> starttime %ld endTime %ld \n",startTime,endTime);
       fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> getValueForTime >>>> No data with time %ld  Date %s\n with Hour %d\n with Minute %d\n with Second %d inputFileName = %s\n",
                                                                                  aTime,
                                                                                  [timeManager getDateWithTimeT: aTime],
                                                                                  [timeManager getHourWithTimeT: aTime],
                                                                                  [timeManager getMinuteWithTimeT: aTime],
                                                                                  [timeManager getSecondWithTimeT: aTime],
                                                                                  inputFileName);
       fflush(0);
       exit(1);

   }

  return returnVal; 

}




/////////////////////////////////////////////////////////////
//
// getMeanValueWithStartTime:
//               withEndTime:
//
//////////////////////////////////////////////////////////////
- (double) getMeanValueWithStartTime: (time_t) aStartTime
                         withEndTime: (time_t) anEndTime
{
   double meanValue = 0;

   int i;
   BOOL ERROR = FALSE;

   int startNdx = 0;
   int endNdx = 0;
   int recordCount = 0;

   if(aStartTime >= anEndTime)
   {
       fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMeanValueWithStartTime:withEndTime\n end time is before start time \n");
       fflush(0);
       ERROR = TRUE;
   }



   if(!ERROR)
   {
       if((aStartTime < startTime) && (anEndTime < startTime))
       {
           fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMeanValueWithStartTime:withEndTime\n start time and end time passed to manager is before model start time\n");
           fflush(0);
           ERROR = TRUE;
       }
       else if((aStartTime > endTime) && (anEndTime > endTime))
       {
           fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMeanValueWithStartTime:withEndTime\n start time and end time passed to manager is after model end time\n");
           fflush(0);
           ERROR = TRUE;
       }

   }
    
  
   if(!ERROR)
   {

       ERROR = TRUE;

       for(i = 0; i < numRecords; i++)
       {
           if((time_t) inputRecord[i][0] >= aStartTime) 
           {
               startNdx = i;
               ERROR = FALSE;
               break;
           }
       }
   }
   

   if(!ERROR)
   {

        ERROR = TRUE;

        for(i = startNdx; i < numRecords; i++)
        {

           endNdx = i;

           if((time_t) inputRecord[i][0] >= anEndTime)
           {
               ERROR = FALSE;
               break;
           }
               
        }

   }

   if(!ERROR)
   {
       i = startNdx;

       while( (startNdx <= i) && (i <= endNdx))
       {
           meanValue += inputRecord[i][1];

           //fprintf(stdout, "TimeSeriesInputManager >>>> getMeanValueWith: >>>> startNdx %d >>>> endNdx %d\n", startNdx, endNdx);
           //fprintf(stdout, "TimeSeriesInputManager >>>> getMeanValueWith: >>>> inputRecord[%d][1] = %f\n", i, inputRecord[i][1]);
           //fprintf(stdout, "TimeSeriesInputManager >>>> getMeanValueWith: >>>> meanValue = %f\n", meanValue);
           //fflush(0);

           //ERROR = FALSE;
           i++;
           ++recordCount;
         

       }
   }


   if(ERROR)
   {
        fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> getMeanValueWithStartTime:withEndTime: >>>> \n no data between start date %s with hour %d minute %d second %d \n",
                         [timeManager getDateWithTimeT: aStartTime],
                         [timeManager getHourWithTimeT: aStartTime],
                         [timeManager getMinuteWithTimeT: aStartTime],
                         [timeManager getSecondWithTimeT: aStartTime]);
        fprintf(stderr, "and end date %s with hour %d minute %d second %d\n", 
                         [timeManager getDateWithTimeT: anEndTime],
                         [timeManager getHourWithTimeT: anEndTime],
                         [timeManager getMinuteWithTimeT: anEndTime],
                         [timeManager getSecondWithTimeT: anEndTime]);
        fflush(0); 
        exit(1);
   }
   
   //fprintf(stdout, "TimeSeriesInputManager >>>> getMeanValueWith: >>>> recordCount = %d\n", recordCount);

   return (meanValue/(double) recordCount);
}





////////////////////////////////////////////////////////////
//
// getMaxValueWithStartTime:
    //          withEndTime:
//
////////////////////////////////////////////////////////////
- (double) getMaxValueWithStartTime: (time_t) aStartTime
                        withEndTime: (time_t) anEndTime
{
   double maxValue = -LARGEINT;

   int i;
   BOOL ERROR = FALSE;

   int startNdx = 0;
   int endNdx = 0;

   if(aStartTime >= anEndTime)
   {
       fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMaxValueWithStartTime:withEndTime\n end time is before start time\n");
       fflush(0);
       ERROR = TRUE;
   }


   if(!ERROR)
   {
       if((aStartTime < startTime) && (anEndTime < startTime))
       {
           fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMaxValueWithStartTime:withEndTime\n start time and end time passed to manager is before model start time\n");
           fflush(0);
           ERROR = TRUE;
       }
       else if((aStartTime > endTime) && (anEndTime > endTime))
       {
           fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMaxValueWithStartTime:withEndTime\n start time and end time passed to manager is after model end time\n");
           fflush(0);
           ERROR = TRUE;
       }

   }

   if(!ERROR)
   {
       ERROR = TRUE;

       for(i = 0; i < numRecords; i++)
       {
           if((time_t) inputRecord[i][0] >= aStartTime) 
           {
               startNdx = i;
               ERROR = FALSE;
               break;
           }
       }
   }

   if(!ERROR)
   {
        for(i = startNdx; i < numRecords; i++)
        {

           endNdx = i;

           if((time_t) inputRecord[i][0] >= anEndTime)
           {
               break;
           }
               
        }

   }

   if(!ERROR)
   {
       i = startNdx;

       ERROR = TRUE;

       while((startNdx <= i) && (i <= endNdx))
       {
           maxValue = (maxValue > inputRecord[i][1]) ?  maxValue : inputRecord[i][1];

           //fprintf(stdout, "TimeSeriesInputManager >>>> getMaxValueWith: >>>> startNdx %d >>>> endNdx %d\n", startNdx, endNdx);
           //fprintf(stdout, "TimeSeriesInputManager >>>> getMaxValueWith: >>>> inputRecord[%d][1] = %f\n", i, inputRecord[i][1]);
           //fprintf(stdout, "TimeSeriesInputManager >>>> getMaxValueWith: >>>> maxValue = %f\n", maxValue);
           //fflush(0);

           ERROR = FALSE;
           i++;
       }
   }


   if(ERROR)
   {
        fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> getMaxValueWithStartTime:withEndTime: >>>> \n no data found between start date %s with hour %d minute %d second %d \n", 
                         [timeManager getDateWithTimeT: aStartTime],
                         [timeManager getHourWithTimeT: aStartTime],
                         [timeManager getMinuteWithTimeT: aStartTime],
                         [timeManager getSecondWithTimeT: aStartTime]);

        fprintf(stderr, "and end date %s with hour %d minute %d second %d\n", 
                         [timeManager getDateWithTimeT: anEndTime],
                         [timeManager getHourWithTimeT: anEndTime],
                         [timeManager getMinuteWithTimeT: anEndTime],
                         [timeManager getSecondWithTimeT: anEndTime]);
        fflush(0); 
        exit(1);
   }
   
   return maxValue;

}




////////////////////////////////////////////////////////////
//
// getMinValueWithStartTime:
    //          withEndTime:
//
///////////////////////////////////////////////////////////
- (double) getMinValueWithStartTime: (time_t) aStartTime
                        withEndTime: (time_t) anEndTime
{
   double minValue = LARGEINT;

   int i;
   BOOL ERROR = FALSE;

   int startNdx = 0;
   int endNdx = 0;

   if(aStartTime >= anEndTime)
   {
       fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMinValueWithStartTime:withEndTime\n end time is before start time\n");
       fflush(0);
       ERROR = TRUE;
   }


   if(!ERROR)
   {
       if((aStartTime < startTime) && (anEndTime < startTime))
       {
           fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMinValueWithStartTime:withEndTime\n start time end time passed to manager is before model start time\n");
           fflush(0);
           ERROR = TRUE;
       }
       else if((aStartTime > endTime) && (anEndTime > endTime))
       {
           fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMinValueWithStartTime:withEndTime\n start time end time passed to manager is after model end time\n");
           fflush(0);
           ERROR = TRUE;
       }

   }

    
   if(!ERROR)
   {
       ERROR = TRUE;

       for(i = 0; i < numRecords; i++)
       {
           if((time_t) inputRecord[i][0] >= aStartTime) 
           {
               startNdx = i;
               ERROR = FALSE;
               break;
           }
       }
   }

   if(!ERROR)
   {
        for(i = startNdx; i < numRecords; i++)
        {
           endNdx = i;

           if((time_t) inputRecord[i][0] >= anEndTime)
           {
               break;
           }
        }
   }

   if(!ERROR)
   {
       i = startNdx;

       while((startNdx <= i) && (i <= endNdx))
       {
           minValue = (minValue < inputRecord[i][1]) ?  minValue : inputRecord[i][1];

           //fprintf(stdout, "TimeSeriesInputManager >>>> getMinValueWith: >>>> startNdx %d >>>> endNdx %d\n", startNdx, endNdx);
           //fprintf(stdout, "TimeSeriesInputManager >>>> getMinValueWith: >>>> inputRecord[%d][1] = %f\n", i, inputRecord[i][1]);
           //fprintf(stdout, "TimeSeriesInputManager >>>> getMinValueWith: >>>> minValue = %f\n", minValue);
           //fflush(0);

           ERROR = FALSE;
           i++;
       }
   }


   if(ERROR)
   {
        fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> getMinValueWithStartTime:withEndTime: >>>> \n no data found between start date %s with hour %d minute %d second %d \n", 
                         [timeManager getDateWithTimeT: aStartTime],
                         [timeManager getHourWithTimeT: aStartTime],
                         [timeManager getMinuteWithTimeT: aStartTime],
                         [timeManager getSecondWithTimeT: aStartTime]);

        fprintf(stderr, "and end date %s with hour %d minute %d second %d\n", 
                         [timeManager getDateWithTimeT: anEndTime],
                         [timeManager getHourWithTimeT: anEndTime],
                         [timeManager getMinuteWithTimeT: anEndTime],
                         [timeManager getSecondWithTimeT: anEndTime]);
        fflush(0); 
        exit(1);
   }
   
   return minValue;

}


////////////////////////////////////////////////////////////////////
//
// getMeanAntiLogValueWithStartTime: (time_t) aStartTime
//                      withEndTime: (time_t) anEndTime
//
/////////////////////////////////////////////////////////////////////
- (double) getMeanAntiLogValueWithStartTime: (time_t) aStartTime
                                withEndTime: (time_t) anEndTime
{
   double meanValue = 0;

   int i;
   BOOL ERROR = FALSE;

   int startNdx = 0;
   int endNdx = 0;
   int recordCount = 0;


   if(!log10OfValuesOn)
   {
        fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMeanAntiLogValueWith:withEndTime >>>>\n attempting to get antilog values of non-logged data\n");
        fflush(0);
        exit(1);
   }  


   if(aStartTime >= anEndTime)
   {
       fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMeanAntiLogValueWithStartTime:withEndTime\n end time is before start time\n");
       fflush(0);
       ERROR = TRUE;
   }



   if(!ERROR)
   {
       if((aStartTime < startTime) && (anEndTime < startTime))
       {
           fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMeanAntiLogValueWithStartTime:withEndTime\n start time end time passed to manager is before model start time\n");
           fflush(0);
           ERROR = TRUE;
       }
       else if((aStartTime > endTime) && (anEndTime > endTime))
       {
           fprintf(stderr, "ERROR >>>> TimeSeriesInputManager >>>> getMeanAntiLogValueWithStartTime:withEndTime\n start time end time passed to manager is after model end time\n");
           fflush(0);
           ERROR = TRUE;
       }
   }

    
   if(!ERROR)
   {
       for(i = 0; i < numRecords; i++)
       {
           if((time_t) inputRecord[i][0] >= aStartTime) 
           {
               startNdx = i;
               ERROR = FALSE;
               break;
           }
       }
   }
   

   if(!ERROR)
   {
        for(i = startNdx; i < numRecords; i++)
        {

           endNdx = i;

           if((time_t) inputRecord[i][0] >= anEndTime)
           {
               ERROR = FALSE;
               break;
           }
               
        }

   }

   if(!ERROR)
   {
       i = startNdx;

       while( (startNdx <= i) && (i <= endNdx))
       {
           meanValue += pow(10, inputRecord[i][1]);

           //fprintf(stdout, "TimeSeriesInputManager >>>> getAntiLogMeanValueWith: >>>> startNdx %d >>>> endNdx %d\n", startNdx, endNdx);
           //fprintf(stdout, "TimeSeriesInputManager >>>> getAntiLogMeanValueWith: >>>> inputRecord[%d][1] = %f\n", i, inputRecord[i][1]);
           //fprintf(stdout, "TimeSeriesInputManager >>>> getAntiLogMeanValueWith: >>>> meanValue = %f\n", meanValue);
           //fflush(0);

           ERROR = FALSE;
           i++;
           ++recordCount;
         

       }
   }

   
   //fprintf(stdout, "TimeSeriesInputManager >>>> getMeanValueWith: >>>> recordCount = %d\n", recordCount);

   return (meanValue/(double) recordCount);

}



//////////////////////////////////////////
//
// printDataToFileNamed
//
///////////////////////////////////////////
- printDataToFileNamed: (char *) aFileName
{

    FILE* filePtr=NULL;
    int ndx=0;
    time_t aCurrentTime =0;
 
    char date[12];
    int hour;
    int minute;
    int second;

    double data;    

    if(filePtr==NULL)
    {
      if((filePtr = fopen(aFileName, "w")) == NULL)
      {
           [InternalError raiseEvent: "ERROR opening file %s for writing\n", aFileName];
      }

    }


    aCurrentTime = [timeManager getCurrentTimeT]; 


    for(ndx=0; ndx < numRecords; ndx++)
    {
         strncpy(date, [timeManager getDateWithTimeT: (time_t) inputRecord[ndx][0]],11);
         hour = [timeManager getHourWithTimeT: (time_t) inputRecord[ndx][0]];
         minute = [timeManager getMinuteWithTimeT: (time_t) inputRecord[ndx][0]];
         second = [timeManager getSecondWithTimeT: (time_t) inputRecord[ndx][0]];
         data = inputRecord[ndx][1];

         if(log10OfValuesOn == YES)
         {
             data = pow(10, data);
         } 
          

         if(inputDataType == DAILY)
         {
             fprintf(filePtr, "%ld %s %f\n", (long) inputRecord[ndx][0], date, data);
             fflush(filePtr);
         }
         else if (inputDataType == HOURLY)
         {
             fprintf(filePtr, "%ld %s %d %f\n", (long) inputRecord[ndx][0], date, hour, data);
             fflush(filePtr);
         }
         else if(inputDataType == OTHER)
         {
             fprintf(filePtr, "%ld %s %d %d %d %f\n", (long) inputRecord[ndx][0], date, hour, minute, second, data);
             fflush(filePtr);
         }
         else
         {
             fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> printDataToFileNamed >>>> unknown data type\n");
             fflush(0);
             exit(1);
         } 


       
    } 


  return self;
}




/////////////////////////////////////////////////////
//
// readInputRecords
//
/////////////////////////////////////////////////////
- readInputRecords
{

  FILE* inputFP=NULL;
  char tempString[200];
  char header1[200];

  int inputNdx = 0;

  time_t anInputTime;
  time_t prevInputTime = 0;


  char date[12];
  int hour = 0;
  int minute = 0;
  int second = 0;

  double inputData;

  int lineNumber = 3;

  numRecords = 0;

  if((inputFP = fopen(inputFileName, "r")) != NULL)
  {

      fgets(header1,HCOMMENTLENGTH,inputFP);
      fgets(header1,HCOMMENTLENGTH,inputFP);
      fgets(header1,HCOMMENTLENGTH,inputFP);

      while(fgets(tempString, 200, inputFP) != NULL)
      {

          if(inputDataType == DAILY)
          {
              sscanf(tempString,"%s%lf", date, &inputData);
              anInputTime = (double) [timeManager getTimeTWithDate: date];
          }
          else if(inputDataType == HOURLY)
          {
              sscanf(tempString,"%s%d%lf", date, &hour, &inputData);
              anInputTime = (double) [timeManager getTimeTWithDate: date
                                                          withHour: hour
                                                        withMinute: minute
                                                        withSecond: second];
          }
          else  //OTHER
          {
              sscanf(tempString,"%s%d%d%d%lf", date, &hour, &minute, &second, &inputData);  
              anInputTime = (double) [timeManager getTimeTWithDate: date
                                                          withHour: hour
                                                        withMinute: minute
                                                        withSecond: second];
          }
    
	  if(anInputTime > 970356400 && anInputTime < 970359900){
	    fprintf(stdout,"start %d end %d input %d data %f \n", startTime, endTime, anInputTime, inputData);
	    fflush(0);
	  }

          if((startTime <= anInputTime) && (anInputTime <= endTime))
          {
              numRecords++;
          }
          
      }

      fclose(inputFP);

      if(numRecords > 0)
      {
  
          if((inputFP = fopen(inputFileName, "r")) == NULL)
          {
              fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> readInputRecords >>>> error opening %s\n", inputFileName);
              fflush(0);
              exit(1);
          }

          fgets(header1,HCOMMENTLENGTH,inputFP);
          fgets(header1,HCOMMENTLENGTH,inputFP);
          fgets(header1,HCOMMENTLENGTH,inputFP);

          inputRecord = (double **)[ZoneAllocMapper allocBlockIn: timeSeriesInputZone
                                                      ofSize: numRecords*sizeof(double *)];
    

              while(fgets(tempString, 200, inputFP) != NULL)
              {
                  lineNumber++;

                  if(inputDataType == DAILY)
                  {
                      sscanf(tempString,"%s%lf", date, &inputData);
                      anInputTime = (double) [timeManager getTimeTWithDate: date];
                  }
                  else if(inputDataType == HOURLY)
                  {
                      sscanf(tempString,"%s%d%lf", date, &hour, &inputData);
                      anInputTime = (double) [timeManager getTimeTWithDate: date
                                                                  withHour: hour
                                                                withMinute: minute
                                                                withSecond: second];
                  }
                  else //OTHER
                  {
                      sscanf(tempString,"%s%d%d%d%lf", date, &hour, &minute, &second, &inputData);
                      anInputTime = (double) [timeManager getTimeTWithDate: date
                                                                  withHour: hour
                                                                withMinute: minute
                                                                withSecond: second];
                  }
        
        
                  if(inputNdx == 0)
                  {
                       prevInputTime = anInputTime;
                  }
                  else if(prevInputTime < anInputTime)
                  {
                      prevInputTime = anInputTime;
                  }
                  else
                  {
                      fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> readInputRecords >>>> Data file %s not increasing in time; Check lineNumber %d\n", inputFileName, lineNumber);
                      fflush(0);
                      exit(1);
                  }

                 if((startTime <= anInputTime) && (anInputTime <= endTime))
                 {
        
                     inputRecord[inputNdx] = (double *)[ZoneAllocMapper allocBlockIn: timeSeriesInputZone  
                                                                   ofSize: 2*sizeof(double)];
          
                     inputRecord[inputNdx][0] = anInputTime;
                   
                     inputRecord[inputNdx][1] = inputData;
    
                     inputNdx++;
                                 
                 }
                 else if(anInputTime > endTime)
                 {
                      break;
                 }
        
    
              }
    
              //cleanup
              fclose (inputFP);



              if(numRecords != inputNdx) 
              {
                   fprintf(stderr, "ERROR: TimeSeriesInputManager >>>>> readInputRecords >>>> check data file %s near line %d\n", inputFileName, lineNumber);
                   fflush(0);
                   exit(1);
              }

    
              fprintf(stdout, "TimeSeriesInputManager >>>>> readInputRecords >>>> number data records created = %d\n", inputNdx);
              fflush(0);
    
          }
          else //numRecords == 0
          {
              fprintf(stderr, "ERROR: TimeSeriesInputManager >>>>> readInputRecords >>>> No data found between starting and ending dates for file %s\n", inputFileName);
              fprintf(stderr, "ERROR: TimeSeriesInputManager >>>>> readInputRecords >>>> No data records created\n");
              fprintf(stderr, "ERROR: TimeSeriesInputManager >>>>> readInputRecords >>>> Check the startTime and endTime.\n");
              fflush(0);
              exit(1);
          }
    
  }
  else
  {
      fprintf(stderr,  "ERROR: TimeSeriesInputManager >>>>> readInputRecords >>>> Unable to open time series input file  %s\n", inputFileName);
      fflush(0);
      exit(1);
  }
     

  return self;
    
}

/////////////////////////////////////////////////////
//
// checkData
//
// Makes sure that the data is in the correct format
// and has correct character types
//
//////////////////////////////////////////////////////
- checkData
{

  FILE* inputFP=NULL;
  char header1[200];

  char inputString[200];
  char outString[200];

  int prevHour = 0;

  int hour = 0;
  int minute = 0;
  int second = 0;

  BOOL ERROR = FALSE;
  BOOL WASERROR = FALSE;

  char dateStr[25];
  char hourStr[25];
  char minuteStr[25];
  char secondStr[25];
  char dataStr[50];

  BOOL DATEERROR = FALSE;

  unsigned lineNumber = 3;


  checkData = TRUE;

  if((inputFP = fopen(inputFileName, "r")) != NULL)
  {


      fgets(header1,HCOMMENTLENGTH,inputFP);
      fgets(header1,HCOMMENTLENGTH,inputFP);
      fgets(header1,HCOMMENTLENGTH,inputFP);


      while(fgets(inputString, 200, inputFP) != NULL)
      {
          ++lineNumber;


          if(inputDataType == DAILY)
          {

                  int i;
                  int j = 0;
                  int whichField = 0;
                  BOOL FIRSTSPACE = TRUE;

                  for(i = 0; i < strlen(inputString); i++)
                  {
                        
                       if(isspace(inputString[i])) 
                       { 
                          if(FIRSTSPACE)
                          {
                              whichField++;
                              j = 0;
                              FIRSTSPACE = FALSE;
                              continue;
                          }
                          else
                          {
                              continue;
                          }
                       }

                       if(whichField == 0)
                       {
                           dateStr[j++] = inputString[i];
                           dateStr[j] = '\0';
                           FIRSTSPACE = TRUE;
                       }
                       else if(whichField == 1)
                       {
                           dataStr[j++] = inputString[i];
                           dataStr[j] = '\0';
                           FIRSTSPACE = TRUE;
                       }
                       

                  }

              sprintf(outString, "TimeSeriesInputManager >>>>  line %d >>>> %s %s\n", lineNumber, dateStr, dataStr);

              DATEERROR = FALSE;

              if(dateStr == NULL)
              {
                  DATEERROR = TRUE;
              }
              else if(![timeManager checkDateFormat: dateStr])
              {
                  DATEERROR = TRUE;
              }

              if(DATEERROR)
              {
                  fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the **DATE** format on line %d of input file %s\n", lineNumber, inputFileName);
                  fflush(0);    
              }

              ERROR = DATEERROR || ERROR;


          }
          else if(inputDataType == HOURLY)
          {

                  int i;
                  int j = 0;
                  int whichField = 0;
                  BOOL FIRSTSPACE = TRUE;
                
                  for(i = 0; i < strlen(inputString); i++)
                  {
                        
                       if(isspace(inputString[i])) 
                       { 
                          if(FIRSTSPACE)
                          {
                              whichField++;
                              j = 0;
                              FIRSTSPACE = FALSE;
                              continue;
                          }
                          else
                          {
                              continue;
                          }
                       }

                       if(whichField == 0)
                       {
                               dateStr[j++] = inputString[i];
                               dateStr[j] = '\0';
                               FIRSTSPACE = TRUE;
                       }
                       else if(whichField == 1)
                       {

                               hourStr[j++] = inputString[i];
                               hourStr[j] = '\0';
                               FIRSTSPACE = TRUE;
                       }
                       else if(whichField == 2)
                       {

                               dataStr[j++] = inputString[i];
                               dataStr[j] = '\0';
                               FIRSTSPACE = TRUE;
                       }

                 }


              sprintf(outString, "TimeSeriesInputManager >>>>  line %d >>>> %s %s %s\n", lineNumber, dateStr, hourStr, dataStr);

              DATEERROR = FALSE;

              if(dateStr == NULL)
              {
                  DATEERROR = TRUE;
              }
              else if(![timeManager checkDateFormat: dateStr])
              {
                  DATEERROR = TRUE;
              }

              if(DATEERROR)
              {
                  fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the **DATE** format on line %d of input file %s\n", lineNumber, inputFileName);
                  fflush(0);    
              }

              ERROR = DATEERROR || ERROR;



              //
              // Now check the hours in the input data...
              //
 
              if(hourStr == NULL)
              {
                  fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the **HOUR** format on line %d of input file %s\n", lineNumber, inputFileName);
                  fflush(0);
                  ERROR = TRUE;
              }
              else
              { 
                  BOOL HOURERROR = FALSE;       

                  hour = atoi(hourStr);
                 
                  //
                  // lineNumber 4 is the first actual line of data, so 
                  // just set prevHour to hour to get things started...
                  //
                  if(lineNumber == 4)
                  {
                            ; //ok
                  }
                  else if(hour < 0 || hour > 24)
                  {
                      HOURERROR = TRUE;
                  }
                  else if(prevHour == hour)
                  {
                      HOURERROR = TRUE;
                  }
                  else if((hour == 1) && (prevHour == 24))
                  {
                           ; //ok
                  }
                  else if((hour == 0) && (prevHour == 23))
                  {
                           ; //ok
                  }
                  else if(hour > prevHour + 1)
                  {
                      HOURERROR = TRUE;
    
                  }              
                  else if(prevHour > hour)
                  {
                      HOURERROR = TRUE;
                  }
                  

                  if(HOURERROR)
                  {               
                      fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the **HOUR** sequence near line %d of input file %s\n", lineNumber, inputFileName);
                      fflush(0);    
                  }

                  ERROR = HOURERROR || ERROR;

                  prevHour = hour;
                  
              }
              
                     }
          else //input data type == OTHER
          {
                  int i;
                  int j = 0;
                  int whichField = 0;
                  BOOL FIRSTSPACE = TRUE;

                  //
                  // Read and parse input string...
                  //
                  for(i = 0; i < strlen(inputString); i++)
                  {
                        
                       if(isspace(inputString[i])) 
                       { 
                          if(FIRSTSPACE)
                          {
                              whichField++;
                              j = 0;
                              FIRSTSPACE = FALSE;
                              continue;
                          }
                          else
                          {
                              continue;
                          }
                       }

                       if(whichField == 0)
                       {
                               dateStr[j++] = inputString[i];
                               dateStr[j] = '\0';
                               FIRSTSPACE = TRUE;
                       }
                       else if(whichField == 1)
                       {

                               hourStr[j++] = inputString[i];
                               hourStr[j] = '\0';
                               FIRSTSPACE = TRUE;
                       }
                       else if(whichField == 2)
                       {

                               minuteStr[j++] = inputString[i];
                               minuteStr[j] = '\0';
                               FIRSTSPACE = TRUE;
                       }
                       else if(whichField == 3)
                       {

                               secondStr[j++] = inputString[i];
                               secondStr[j] = '\0';
                               FIRSTSPACE = TRUE;
                       }
                       else if(whichField == 4)
                       {

                               dataStr[j++] = inputString[i];
                               dataStr[j] = '\0';
                               FIRSTSPACE = TRUE;
                       }

                 }


              sprintf(outString, "TimeSeriesInputManager >>>> line %d >>>> %s %s %s %s %s\n", lineNumber, dateStr, hourStr, minuteStr, secondStr, dataStr);
              fflush(0);


              //
              // Check the date
              //

              DATEERROR = FALSE;

              if(dateStr == NULL)
              {
                  DATEERROR = TRUE;
              }
              else if(![timeManager checkDateFormat: dateStr])
              {
                  DATEERROR = TRUE;
              }

              if(DATEERROR)
              {
                  fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the **DATE** format on line %d of input file %s\n", lineNumber, inputFileName);
                  fflush(0);    
              }

              ERROR = DATEERROR || ERROR;


              //
              // Check the hour
              //

              //
              // Now check the time in the input data...
              //
 
              if((hourStr == NULL) || (minuteStr == NULL) || (secondStr == NULL))
              {
                  fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the **TIME** format on line %d of input file %s\n", lineNumber, inputFileName);
                  fflush(0);
                  ERROR = TRUE;
              }
              else
              { 

                  BOOL HOURERROR = FALSE;
                  BOOL MINUTEERROR = FALSE;
                  BOOL SECONDERROR = FALSE;

                  hour = atoi(hourStr);
                  minute = atoi(minuteStr);
                  second = atoi(secondStr);
                 
                  //
                  // lineNumber 4 is the first actual line of data, so 
                  // just set prevHour to hour to get things started...
                  //
                  if(lineNumber == 4)
                  {
                         ; //ok
                  }
                  else if(hour < 0 || hour > 24)
                  {
                      HOURERROR = TRUE;
                  }
                  
                  if(HOURERROR)
                  {               
                      fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the **TIME** sequence near line %d of input file %s\n", lineNumber, inputFileName);
                      fflush(0);    
                  }

                  ERROR = HOURERROR || ERROR;

                  prevHour = hour;
                  

              
                  //
                  // Check the minute and second
                  //


                  if(minute < 0 || minute > 59)
                  {
                      MINUTEERROR = TRUE;
                  }
                  if(second < 0 || second > 59)
                  {
                      SECONDERROR = TRUE;
                  }
               
                  if(MINUTEERROR)
                  {
                      fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the **MINUTE** format on line %d of input file %s\n", lineNumber, inputFileName);
                      fflush(0);    
    
                  }
       
                  if(SECONDERROR)
                  {
                      fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the **SECOND** format on line %d of input file %s\n", lineNumber, inputFileName);
                      fflush(0);    
                  }
              
                  ERROR = MINUTEERROR || ERROR;
                  ERROR = SECONDERROR || ERROR;
              }

         }

        

          //
          // After the date and time have been checked,
          // check the data...
          //
          if(dataStr == NULL)
          {
              fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the data format on line %d of input file %s\n", lineNumber, inputFileName);
              fflush(0);
              ERROR = TRUE;
          }
          else
         {
            int length = (int) strlen(dataStr);
            int i;

            int numberOfDots = 0;
            int numberOfEs = 0;

            BOOL DATAERROR = FALSE;

            for(i=0; i < length; i++)
            {

                if(!((isdigit(dataStr[i])) || (dataStr[i] == '.') || (dataStr[i] == '-')) && (i == 0))
                {
                     if(dataStr[i] == '.') ++numberOfDots;
                     DATAERROR = TRUE;
                     break;
                }
                else if(isdigit(dataStr[i]) || dataStr[i] == '.' || isspace(dataStr[i]) || (toupper(dataStr[i]) == toupper('e')))
                {
                     if(dataStr[i] == '.') ++numberOfDots;
                     if(toupper(dataStr[i]) == toupper('e')) ++numberOfEs;
             
                     if((numberOfDots > 1) || (numberOfEs > 1))
                     {
                         DATAERROR = TRUE;
                         break;
                     }
                     else if(isspace(dataStr[i-1]) && isdigit(dataStr[i]))
                     {
                         DATAERROR = TRUE;
                         break;
                     }
                     else if(isspace(dataStr[i-1]) && (toupper(dataStr[i]) == toupper('e')))
                     {
                         DATAERROR = TRUE;
                         break;
                     }

                }
                else
                {
                     DATAERROR = TRUE;
                     break;
                }
                
            } //for

            if(DATAERROR)
            {
                fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> data input error\ncheck the **DATA** format on line %d of input file %s\n", lineNumber, inputFileName);
                fflush(0);    
                DATAERROR = TRUE;
            }

            ERROR = DATAERROR || ERROR;


         } //else

         if(ERROR)
         {
             fprintf(stdout, "%s", outString);
             fflush(0);
             WASERROR = ERROR;
             ERROR = FALSE;
         }
         

    } //while

    //cleanup
    fclose (inputFP);

  }
  else
  {
      fprintf(stderr, "Unable to open time series input file %s\n", inputFileName);
      fflush(0);
      exit(1);
  }
 
  if(WASERROR) 
  {
      fprintf(stderr, "ERROR: TimeSeriesInputManager >>>> checkData >>>> error in file %s\n", inputFileName);
      fflush(0);
      exit(1);
  }
  

  //fprintf(stdout, "TimeSeriesInputManager >>>> checkData EXIT \n");
  //fflush(0);


   return self;
}




/////////////////////////////////
//
// drop
//
///////////////////////////////
- (void) drop
{
   if(timeSeriesInputZone != nil)
   {
       [timeSeriesInputZone drop];
       timeSeriesInputZone  = nil;
   }

   [super drop];

}


@end

