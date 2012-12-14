//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import "ZoneAllocMapper.h"

@implementation ZoneAllocMapper

+ (void *) allocBlockIn: aZone
                 ofSize: (size_t) aSize 
{ 
  ZoneAllocMapper *obj = [super create: aZone];
  obj->block = [aZone allocBlock: aSize];

  obj->size = aSize;

  setMappedAlloc (obj);

  return obj->block;
}

- (void)mapAllocations: (mapalloc_t)mapalloc 
{
  mapalloc->size = size;
  mapAlloc (mapalloc, block);
}

- (void) drop
{
   fprintf(stdout, "ZoneAllocMapper >>>> drop >>>> BEGIN\n");
   fflush(0);

   [super drop];

   fprintf(stdout, "ZoneAllocMapper >>>> drop >>>> END\n");
   fflush(0);
} 


@end

