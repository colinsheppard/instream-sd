//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



// dists.include.using.m

// Code common to all distributions
// Random version 0.8
// 


-(id <BasicRandomGenerator>) getGenerator {
   return randomGenerator;
}

-(unsigned) getVirtualGenerator {
   return virtualGenerator;
}

-(BOOL) getOptionsInitialized {
   return optionsInitialized;
}

-(unsigned long long int) getCurrentCount {
   return currentCount;
}

-(unsigned) getStateSize {
   return stateSize;
}

-(const char *) getName {
   return distName;
}

-(unsigned) getMagic {
   return distMagic;
}

// dists.include.using.m

