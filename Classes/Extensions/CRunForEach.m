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

#import "CRunForEach.h"
#import "CExtension.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CCreateObjectInfo.h"
#import "CRunApp.h"
#import "CRun.h"
#import "CValue.h"
#import "CArrayList.h"
#import "ObjectSelection.h"
#import "CEventProgram.h"

@implementation CRunForEach

#define CON_ONFOREACHLOOPSTRING				0
#define CON_FOREACHLOOPISPAUSED				1
#define CON_OBJECTISPARTOFLOOP				2
#define CON_OBJECTISPARTOFGROUP				3
#define CON_ONFOREACHLOOPOBJECT				4
#define CON_LAST							5

#define ACT_STARTFOREACHLOOPFOROBJECT		0
#define ACT_PAUSEFOREACHLOOP				1
#define ACT_RESUMEFOREACHLOOP				2
#define ACT_SETFOREACHLOOPITERATION			3
#define ACT_STARTFOREACHLOOPFORGROUP		4
#define ACT_ADDOBJECTTOGROUP				5
#define ACT_ADDFIXEDTOGROUP					6
#define ACT_REMOVEOBJECTFROMGROUP			7
#define ACT_REMOVEFIXEDFROMGROUP			8

#define EXP_LOOPFV							0
#define EXP_LOOPITERATION					1
#define EXP_LOOPMAXITERATION				2
#define EXP_GROUPSIZE						3

-(int)getNumberOfConditions
{
	return CON_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	forEachLoops = [[NSMutableDictionary alloc] init];
	groups = [[NSMutableDictionary alloc] init];
	currentForEach = nil;
	currentGroup = nil;
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	[forEachLoops release];
	[groups release];
}

BOOL filterPartOfLoop(CObject* rdPtr, CObject* object)
{
	if(object == nil)
		return false;
	
	CRunForEach* foreach = (CRunForEach*)rdPtr;
	ForEachLoop* loop = foreach->partOfLoop;
	int fixed = [object fixedValue];
	return ([loop->fvs indexOfInt:fixed] >= 0);
}

BOOL filterPartOfGroup(CObject* rdPtr, CObject* object)
{
	if(object == nil)
		return false;
	
	CRunForEach* foreach = (CRunForEach*)rdPtr;
	CArrayList* group = foreach->partOfGroup;
	int fixed = [object fixedValue];
	return ([group indexOfInt:fixed] >= 0);
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd
{
    switch(num)
    {
		case CON_ONFOREACHLOOPSTRING:
			return [[cnd getParamExpString:rh withNum:0] isEqualToString:currentForEach->name];
		case CON_FOREACHLOOPISPAUSED:
		{
			ForEachLoop* loop = [forEachLoops objectForKey:[cnd getParamExpString:rh withNum:0]];
			return (loop != nil && loop->paused == YES);
		}
		case CON_OBJECTISPARTOFLOOP:
		{
			LPEVP event = [cnd getParamObject:rh withNum:0];
			LPEVT pe = (PEVT)(((LPBYTE)event)-CND_SIZE);
			BOOL isNegated = (pe->evtFlags2 & EVFLAG2_NOT);
			partOfLoop = [forEachLoops objectForKey:[cnd getParamExpString:rh withNum:1]];
			oiToCheck = event->evp.evpW.evpW0;
			return [rh->objectSelection filterObjects:(id)self andOi:oiToCheck andNegate:isNegated andFilterFunction:&filterPartOfLoop];
		}
		case CON_OBJECTISPARTOFGROUP:
		{
			LPEVP event = [cnd getParamObject:rh withNum:0];
			LPEVT pe = (PEVT)(((LPBYTE)event)-CND_SIZE);
			BOOL isNegated = (pe->evtFlags2 & EVFLAG2_NOT);
			partOfGroup = [groups objectForKey:[cnd getParamExpString:rh withNum:1]];
			oiToCheck = event->evp.evpW.evpW0;
			return [rh->objectSelection filterObjects:(id)self andOi:oiToCheck andNegate:isNegated andFilterFunction:&filterPartOfGroup];
		}
		case CON_ONFOREACHLOOPOBJECT:
			if(currentForEach != nil && [[cnd getParamExpString:rh withNum:0] isEqualToString:currentForEach->name]){
				[rh->objectSelection selectOneObject:currentLooped];
				return YES;
			}
			break;
    }
    return NO;
}

//Adds all selected objects to the list of fixed values 
BOOL getSelected(CObject* rdPtr, CObject* object)
{
	CRunForEach* foreach = (CRunForEach*)rdPtr;
	[foreach->populateLoop addObject:object];
	return YES;	//Don't filter out any objects
}
//Adds all selected objects to the current group
BOOL getSelectedForGroup(CObject* rdPtr, CObject* object)
{
	CRunForEach* foreach = (CRunForEach*)rdPtr;
	CArrayList* array = [foreach->groups objectForKey:foreach->currentGroup];
	int currentFixed = [object fixedValue];
	
	if(array != nil)
	{
		for(int i=0; i<[array size]; ++i)
		{
			int fixedInArray = [array getInt:i];
			if(currentFixed == fixedInArray)
				return YES;
		}
		[array addInt:currentFixed];
	}
	return YES;	//Don't filter out any objects
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_STARTFOREACHLOOPFOROBJECT:
		{
			NSString* loopName = [act getParamExpString:rh withNum:0];
			int oiList = [act getParamObjectType:rh withNum:1];
			
			ForEachLoop* loop = [[ForEachLoop alloc] init];
			populateLoop = loop;
			
			//Populate the current foreachloop with all the fixed values of the currently selected objects
			[rh->objectSelection filterObjects:(CObject*)self andOi:oiList andNegate:NO andFilterFunction:&getSelected];

			loop->name = [[NSString alloc] initWithString:loopName];
			loop->loopMax = [loop->fvs size];
			
			[self executeForEachLoop:loop];
			break;
		}
		case ACT_PAUSEFOREACHLOOP:
		{
			ForEachLoop* loop = [forEachLoops objectForKey:[act getParamExpString:rh withNum:0]];
			if(loop != nil){
				loop->paused = YES;
			}
			break;
		}
		case ACT_RESUMEFOREACHLOOP:
		{
			NSString* loopName = [act getParamExpString:rh withNum:0];
			ForEachLoop* loop = [forEachLoops objectForKey:loopName];
			if(loop != nil){
				loop->paused = NO;
				[pausedLoops removeObjectForKey:loopName];
				[self executeForEachLoop:loop];
			}
			break;
		}
		case ACT_SETFOREACHLOOPITERATION:
		{
			ForEachLoop* loop = [forEachLoops objectForKey:[act getParamExpString:rh withNum:0]];
			if(loop != nil){
				loop->loopIndex = [act getParamExpression:rh withNum:1];
			}
			break;
		}
		case ACT_STARTFOREACHLOOPFORGROUP:
		{
			NSString* loopName = [act getParamExpString:rh withNum:0];
			CArrayList* group = [groups objectForKey:[act getParamExpString:rh withNum:1]];
			if(group != nil)
			{
				ForEachLoop* loop = [[ForEachLoop alloc] init];
				loop->name = [[NSString alloc] initWithString:loopName];
				loop->loopMax = [group size];
				//Copy arraylist
				for(int i=0; i<loop->loopMax; ++i){
					[loop->fvs add:[group get:i]];
				}
				[self executeForEachLoop:loop];
			}
			break;
		}
		case ACT_ADDOBJECTTOGROUP:
		{
			if(ho->hoAdRunHeader->rhEvtProg->rh2ActionLoopCount != 0)
				return;
			
			short oiToAdd = [act getParamObjectType:rh withNum:0];
			currentGroup = [act getParamExpString:rh withNum:1];
			CArrayList* group = [groups objectForKey:currentGroup];

			//Create group if it doesn't exist
			if(group == nil){
				group = [[CArrayList alloc] init];
				[groups setObject:group forKey:currentGroup];
			}
			
			[rh->objectSelection filterObjects:(CObject*)self andOi:oiToAdd andNegate:NO andFilterFunction:&getSelectedForGroup];
			currentGroup = nil;
			break;
		}	
		case ACT_ADDFIXEDTOGROUP:
		{
			int fixed = [act getParamExpression:rh withNum:0];
			NSString* groupName = [act getParamExpString:rh withNum:1];
			CArrayList* group = [groups objectForKey:groupName];
			
			if(fixed == 0)
				break;
			
			//Create group if it doesn't exist
			if(group == nil){
				group = [[CArrayList alloc] init];
				[groups setObject:group forKey:groupName];
			}
			[group addInt:fixed];
			break;
		}	
		case ACT_REMOVEOBJECTFROMGROUP:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			NSString* groupName = [act getParamExpString:rh withNum:1];
			CArrayList* group = [groups objectForKey:groupName];
			
			if(group == nil || object == nil)
				break;
			
			[group removeInt:[object fixedValue]];
			
			//Delete group if empty
			if([group size] == 0){
				[groups removeObjectForKey:groupName];
				[group release];
			}
			break;
		}
		case ACT_REMOVEFIXEDFROMGROUP:
		{
			int fixed = [act getParamExpression:rh withNum:0];
			NSString* groupName = [act getParamExpString:rh withNum:1];
			CArrayList* group = [groups objectForKey:groupName];
			
			if(group == nil || fixed == 0)
				break;
			
			[group removeInt:fixed];
			
			//Delete group if empty
			if([group size] == 0){
				[groups removeObjectForKey:groupName];
				[group release];
			}
			break;
		}
	}
}

-(void)executeForEachLoop:(ForEachLoop*)loop
{
	//Store current loop
	ForEachLoop* prevLoop = currentForEach;
	[forEachLoops setObject:loop forKey:loop->name];
	currentForEach = loop;
	for(;loop->loopIndex < loop->loopMax; ++loop->loopIndex)
	{
		//Was the loop paused?
		if(loop->paused){
			//Move the fastloop to the 'paused' table
			[pausedLoops setObject:loop forKey:loop->name];
			[forEachLoops removeObjectForKey:loop->name];
			break;
		}
		[ho generateEvent:CON_ONFOREACHLOOPSTRING withParam:0];
		
		currentLooped = [ho getObjectFromFixed:[loop->fvs getInt:loop->loopIndex]];
		if(currentLooped != nil)
			[ho generateEvent:CON_ONFOREACHLOOPOBJECT withParam:0];
	}
	//Release the loop?
	if(!loop->paused)
	{
		[forEachLoops removeObjectForKey:loop->name];
		[loop release];
	}
	//Restore the previous loop (in case of nested loops)
	currentForEach = prevLoop;
}

-(CValue*)expression:(int)num
{
	switch(num){
		case EXP_LOOPFV:
		{
			NSString* loopName = [[ho getExpParam] getString];
			ForEachLoop* loop = [forEachLoops objectForKey:loopName];
			if(loop == nil)
				break;
			return [rh getTempValue:[loop->fvs getInt:loop->loopIndex]];
		}
		case EXP_LOOPITERATION:
		{
			NSString* loopName = [[ho getExpParam] getString];
			ForEachLoop* loop = [forEachLoops objectForKey:loopName];
			if(loop == nil)
				break;
			return [rh getTempValue:(int)loop->loopIndex];
		}
		case EXP_LOOPMAXITERATION:
		{
			NSString* loopName = [[ho getExpParam] getString];
			ForEachLoop* loop = [forEachLoops objectForKey:loopName];
			if(loop == nil)
				break;
			return [rh getTempValue:(int)loop->loopMax];
		}
		case EXP_GROUPSIZE:
		{
			NSString* groupName = [[ho getExpParam] getString];
			CArrayList* group = [groups objectForKey:groupName];
			if(group == nil)
				break;
			return [rh getTempValue:[group size]];
		}
	}
	return [rh getTempValue:0];
}
@end

@implementation ForEachLoop
-(id)init
{
	if((self = [super init])){
		name = nil;
		paused = NO;
		loopIndex = 0;
		loopMax = 0;
		fvs = [[CArrayList alloc] init];
	}
	return self;
}
-(void)dealloc
{
	if(name != nil)
		[name release];
	[fvs release];
	[super dealloc];
}
-(void)addObject:(CObject*)object
{
	[fvs addInt:[object fixedValue]];
}
-(void)addFixed:(int)fixed
{
	[fvs addInt:fixed];
}
@end
