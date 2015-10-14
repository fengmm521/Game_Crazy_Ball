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
#import "ObjectSelection.h"

#import "CRunApp.h"
#import "CEvents.h"
#import "CEventProgram.h"
#import "CRun.h"
#import "CObjInfo.h"
#import "CQualToOiList.h"
#import "CObject.h"
#import "COIList.h"

@interface ObjectSelection()
-(BOOL)filterQualifierObjects:(CObject*)rdPtr andOi:(short)Oi andNegate:(BOOL)negate andFilterFunction:(FilterFunction)filter;
-(BOOL)filterNonQualifierObjects:(CObject*)rdPtr andOi:(short)Oi andNegate:(BOOL)negate andFilterFunction:(FilterFunction)filter;
@end

@implementation ObjectSelection


-(id)initWithRunHeader:(CRunApp*)runApp
{
	if((self = [super init]))
	{
		rhPtr = runApp;
		run = rhPtr->run;
		eventProgram = rhPtr->events;
	}
	return self;
}

//Selects *all* objects of the given object-type
-(void)selectAll:(short)OiList
{
	CObjInfo* pObjectInfo = run->rhOiList[OiList];
	pObjectInfo->oilNumOfSelected = pObjectInfo->oilNObjects;
	pObjectInfo->oilListSelected = pObjectInfo->oilObject;
	pObjectInfo->oilEventCount = eventProgram->rh2EventCount;

	int i = pObjectInfo->oilObject;
	while(i >= 0)
	{
		CObject* pObject = run->rhObjectList[i];
		pObject->hoNextSelected = pObject->hoNumNext;
		i = pObject->hoNumNext;
	}
}

//Resets all objects of the given object-type
-(void)selectNone:(short)OiList
{
	CObjInfo* pObjectInfo = run->rhOiList[OiList];
	pObjectInfo->oilNumOfSelected = 0;
	pObjectInfo->oilListSelected = -1;
	pObjectInfo->oilEventCount = eventProgram->rh2EventCount;
}

//Resets the SOL and inserts only one given object
-(void)selectOneObject:(CObject*)object
{
	CObjInfo* pObjectInfo = object->hoOiList;
	pObjectInfo->oilNumOfSelected = 1;
	pObjectInfo->oilEventCount = eventProgram->rh2EventCount;
	pObjectInfo->oilListSelected = object->hoNumber;
	run->rhObjectList[object->hoNumber]->hoNextSelected = -1;
}

//Resets the SOL and inserts the given list of objects
-(void)selectObjects:(short)OiList withObjects:(CObject**)objects andCount:(int)count
{
	if(count <= 0)
		return;
	
	CObjInfo* pObjectInfo = run->rhOiList[OiList];
	pObjectInfo->oilNumOfSelected = count;
	pObjectInfo->oilEventCount = eventProgram->rh2EventCount;
	
	short prevNumber = objects[0]->hoNumber;
	pObjectInfo->oilListSelected = prevNumber;
	
	for(int i=1; i<count; i++)
	{
		short currentNumber = objects[i]->hoNumber;
		run->rhObjectList[prevNumber]->hoNextSelected = currentNumber;
		prevNumber = currentNumber;
	}
	run->rhObjectList[prevNumber]->hoNextSelected = -1;
}


//Run a custom filter on the SOL (via function callback)
-(BOOL)filterObjects:(CObject*)rdPtr andOi:(short)OiList andNegate:(BOOL)negate andFilterFunction:(FilterFunction)filter;
{
	if(OiList & 0x8000)
		return [self filterQualifierObjects:rdPtr andOi:OiList & 0x7FFF andNegate:negate andFilterFunction:filter] ^ negate;
	else
		return [self filterNonQualifierObjects:rdPtr andOi:OiList & 0x7FFF andNegate:negate andFilterFunction:filter] ^ negate;
}


//Filter qualifier objects
-(BOOL)filterQualifierObjects:(CObject*)rdPtr andOi:(short)OiList andNegate:(BOOL)negate andFilterFunction:(FilterFunction)filter
{
	CQualToOiList* CurrentQualToOi = eventProgram->qualToOiList[OiList];

	BOOL hasSelected = NO;
	int i = 0;

	while( i<CurrentQualToOi->nQoi)
	{
		short CurrentOi = CurrentQualToOi->qoiList[i+1];
		hasSelected |= [self filterNonQualifierObjects:rdPtr andOi:CurrentOi andNegate:negate andFilterFunction:filter];
		i+=2;
	}
	return hasSelected;
}

//Filter normal objects
-(BOOL)filterNonQualifierObjects:(id)tag andOi:(short)OiList andNegate:(BOOL)negate andFilterFunction:(FilterFunction)filter
{
	CObjInfo* pObjectInfo = run->rhOiList[OiList];
	if(pObjectInfo == nil)
		return NO;
	
	BOOL hasSelected = NO;
	if(pObjectInfo->oilEventCount != eventProgram->rh2EventCount)
		[self selectAll:OiList];	//The SOL is invalid, must reset.

	//If SOL is empty
	if(pObjectInfo->oilNumOfSelected <= 0)
		return false;

	int firstSelected = -1;
	int count = 0;
	int current = pObjectInfo->oilListSelected;
	CObject* previous = NULL;

	while(current >= 0)
	{
		CObject* pObject = run->rhObjectList[current];
		BOOL useObject = filter(tag, pObject) ^ negate;
		hasSelected |= useObject;

		if(useObject)
		{
			if(firstSelected == -1)
				firstSelected = current;

			if(previous != NULL)
				previous->hoNextSelected = current;
			
			previous = pObject;
			count++;
		}
		current = pObject->hoNextSelected;
	}
	if(previous != NULL)
		previous->hoNextSelected = -1;

	pObjectInfo->oilListSelected = firstSelected;
	pObjectInfo->oilNumOfSelected = count;

	return hasSelected;
}

//Return the number of selected objects for the given object-type
-(int)getNumberOfSelected:(short)OiList
{
	if(OiList & 0x8000)
	{
		OiList &= 0x7FFF;	//Mask out the qualifier part
		int numberSelected = 0;

		CQualToOiList* CurrentQualToOi = eventProgram->qualToOiList[OiList];

		int i=0;
		while(i<CurrentQualToOi->nQoi)
		{
			CObjInfo* CurrentOi = run->rhOiList[CurrentQualToOi->qoiList[i+1]];
			numberSelected += CurrentOi->oilNumOfSelected;
			i+=2;
		}
		return numberSelected;
	}
	else
	{
		CObjInfo* pObjectInfo = run->rhOiList[OiList];
		return pObjectInfo->oilNumOfSelected;
	}
}

-(BOOL)objectIsOfType:(CObject*)obj type:(short)OiList
{
	if(OiList & 0x8000)
	{
		OiList &= 0x7FFF;	//Mask out the qualifier part
		CQualToOiList* CurrentQualToOi = eventProgram->qualToOiList[OiList];

		int i=0;
		while(i<CurrentQualToOi->nQoi)
		{
			CObjInfo* CurrentOi = run->rhOiList[CurrentQualToOi->qoiList[i+1]];
			if(CurrentOi->oilOi == obj->hoOi)
				return YES;
			i+=2;
		}
		return NO;
	}
	return (obj->hoOi == run->rhOiList[OiList]->oilOi);
}


@end