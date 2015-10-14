/* Copyright (c) 1996-2014 Clickteam
*
* This source code is part of the iOS exporter for Clickteam Multimedia Fusion 2
* and Clickteam Fusion 2.5.
* 
* Permission is hereby granted to any person obtaining a legal copy 
* of Clickteam Multimedia Fusion 2 or Clickteam Fusion 2.5 to use or modify this source 
* code for debugging, optimizing, or customizing applications created with 
* Clickteam Multimedia Fusion 2 and/or Clickteam Fusion 2.5. 
* Any other use of this source code is prohibited.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
* IN THE SOFTWARE.
*/
//----------------------------------------------------------------------------------
//
// CARRAYLIST : classe extensible de stockage
//
//----------------------------------------------------------------------------------
#import "CArrayList.h"

#define SORT_NAME sorter
#define SORT_TYPE size_t
#define SORT_CMP(x,y) (int)([((CListItem*)(x))->string caseInsensitiveCompare:(((CListItem*)(y))->string)])
#include "sort.h"

@implementation CArrayList

-(id)init
{
	numberOfEntries=0;
	pArray=nil;
	length=0;
	return self;
}
-(void)dealloc
{
	if (pArray!=nil)
	{
		free(pArray);
	}
	[super dealloc];
}
		
-(void)getArray:(NSUInteger)max
{
	if (pArray==nil)
	{            
		pArray=(void**)malloc((max+GROWTH_STEP)*sizeof(void*));
		length=max+GROWTH_STEP;
	}
	else if (max>=length)
	{
		pArray=(void**)realloc(pArray, (max+GROWTH_STEP)*sizeof(void*));
		length=max+GROWTH_STEP;
	}
}
-(void)ensureCapacity:(NSUInteger)max
{
	[self getArray:max];
}
-(NSUInteger)add:(void*)o
{
	[self getArray: numberOfEntries];
	pArray[numberOfEntries]=o;
    return numberOfEntries++;
}
-(NSUInteger)addInt:(int)o
{
	return [self add:(void*)(signed long)o];
}
-(void)addIndex:(NSUInteger)index object:(void*)o
{
	[self getArray: numberOfEntries];
	for (NSUInteger n=numberOfEntries; n>index; n--)
	{
		pArray[n]=pArray[n-1];
	}
	pArray[index]=o;
	numberOfEntries++;
}
-(void)addIndex:(NSUInteger)index integer:(int)o
{
	[self addIndex:index object:(void*)(signed long)o];
}
-(void*)get:(NSUInteger)index
{
	if (index<numberOfEntries)
	{
		return pArray[index];
	}
	return nil;
}
-(int)getInt:(NSUInteger)index
{
	if (index<numberOfEntries)
	{
		return (int)(signed long)pArray[index];
	}
	return 0;
}
-(void)set:(NSUInteger)index object:(void*)o
{
	if (index<numberOfEntries)
	{
		pArray[index]=o;
	}
}
-(void)set:(NSUInteger)index integer:(int)o
{
	if (index<numberOfEntries)
	{
		pArray[index]=(void*)(signed long)o;
	}
}

-(void)setAtGrow:(NSUInteger)index object:(void*)o
{
	if(index >= numberOfEntries)
	{
		[self ensureCapacity:index+1];
		for(NSUInteger i=numberOfEntries; i<=index; ++i)
			[self add:0];
	}
	[self set:index object:o];
}

-(void)setAtGrow:(NSUInteger)index integer:(int)o
{
	[self setAtGrow:index object:(void*)(signed long)o];
}

-(void)removeIndex:(NSUInteger)index
{
	if (index<numberOfEntries && numberOfEntries>0)
	{
		for (NSUInteger n=index; n<numberOfEntries-1; n++)
		{
			pArray[n]=pArray[n+1];
		}
		numberOfEntries--;
		pArray[numberOfEntries]=nil;
	}
}
-(void)removeClearIndex:(NSUInteger)index
{
	if (index<numberOfEntries && numberOfEntries>0)
	{
		[((id)pArray[index]) release];
		[self removeIndex:index];
	}
}
-(void)removeIndexRelease:(NSUInteger)i
{
	id o=(id)[self get:i];
	if (o!=nil)
	{
		[o release];
	}
	[self removeIndex:i];
}
-(void)removeIndexFree:(NSUInteger)i
{
	void* o=[self get:i];
	if (o!=nil)
		free(o);
	[self removeIndex:i];
}
-(NSInteger)indexOf:(void*)o
{
	int n;
	for (n=0; n<numberOfEntries; n++)
	{
		if (pArray[n]==o)
		{
			return n;
		}
	}
	return -1;
}
-(NSInteger)indexOfInt:(int)o
{
	return [self indexOf:(void*)(signed long)o];
}
-(void)removeObject:(void*)o
{
	NSInteger n=[self indexOf:o];
	if (n>=0)
	{
		[self removeIndex:n];
	}
}
-(void)removeInt:(NSInteger)o
{
	[self removeObject:(void*)(signed long)o];
}
-(void)removeObjectRelease:(void*)o
{
	NSInteger n=[self indexOf:o];
	if (n>=0)
	{
		[self removeIndexRelease:n];
	}
}
-(int)size
{
	return (int)numberOfEntries;
}
-(void)clear
{
	numberOfEntries=0;
}
-(void)clearRelease
{
	int n;
	for (n=0; n<numberOfEntries; n++)
	{
		id obj = (id)pArray[n];
		if (obj!=nil)
		{
			[obj release];
			pArray[n] = nil;
		}
	}
	numberOfEntries=0;
}
-(void)freeRelease
{
	int n;
	for (n=0; n<numberOfEntries; n++)
	{
		if (pArray[n]!=nil)
		{
			free(pArray[n]);
		}
	}
	numberOfEntries=0;
}


-(NSInteger)findString:(NSString*)string startingAt:(NSUInteger)startIndex
{
	NSUInteger strLen = [string length];
	for(NSUInteger i=startIndex; i<numberOfEntries; ++i)
	{
		CListItem* item = (CListItem*)[self get:i];
		NSString* cmp = item->string;
		NSUInteger cmpLen = [cmp length];

		if(cmpLen < strLen)
			continue;
		
		NSRange range = NSMakeRange(0, MIN(cmpLen,strLen));
		if([cmp compare:string options:NSCaseInsensitiveSearch range:range]==NSOrderedSame)
			return i;
	}
   return -1;
}

-(NSInteger)findStringExact:(NSString*)string startingAt:(NSUInteger)startIndex
{
	for(NSUInteger i=startIndex; i<numberOfEntries; ++i)
	{
		CListItem* item = (CListItem*)[self get:i];
		if([item->string caseInsensitiveCompare:string] == NSOrderedSame)
			return i;
	}
	return -1;
}

-(void)sortCListItems
{
	sorter_tim_sort((SORT_TYPE*)pArray, numberOfEntries);
}

-(NSMutableArray*)getNSArray
{
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:numberOfEntries];
	for(int i=0; i<numberOfEntries; ++i)
	{
		[arr addObject:(id)[self get:i]];
	}
	return arr;
}

@end






@implementation CListItem

-(id)initWithString:(NSString*)s andData:(int)d
{
	if(self = [super init])
	{
		string = [[NSString alloc] initWithString:s];
		data = d;
	}
	return self;
}

-(void)dealloc
{
	[string release];	//Was wrong order before causing rare crash.
	[super dealloc];
}

@end


