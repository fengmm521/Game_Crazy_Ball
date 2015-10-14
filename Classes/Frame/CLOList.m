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
// CLOLIST : liste de levelobjects
//
//----------------------------------------------------------------------------------
#import "CLOList.h"
#import "CRunApp.h"
#import "CLO.h"
#import "CFile.h"
#import "COI.h"
#import "COIList.h"

@implementation CLOList

-(id)initWithApp:(CRunApp*)a
{
	app=a;
	return self;
}
-(void)dealloc
{
	for (int n = 0; n < nIndex; n++)
		[list[n] release];
	
	free(list);
	free(handleToIndex);
	[super dealloc];
}
-(void)load
{
	nIndex = [app->file readAInt];
	list = (CLO**)malloc(nIndex*sizeof(CLO*));
	int n;
	short maxHandles = 0;

	for (n = 0; n < nIndex; n++)
	{
		list[n] = (CLO*)[[CLO alloc] init];

		[list[n] load:app->file];
		if (list[n]->loHandle + 1 > maxHandles)
		{
			maxHandles = (short) (list[n]->loHandle + 1);
		}
		COI* pOI = [app->OIList getOIFromHandle:list[n]->loOiHandle];
		list[n]->loType = pOI->oiType;
	}

	lHandleToIndex=maxHandles;
	if(maxHandles > 0)
		handleToIndex = (short*)malloc(maxHandles*sizeof(short));
	else
		handleToIndex = NULL;
	for (n = 0; n < nIndex; n++)
	{
		handleToIndex[list[n]->loHandle] = (short)n;
	}
}

-(CLO*)getLOFromIndex:(short)index
{
	return list[index];
}

-(CLO*)getLOFromHandle:(short)handle
{
	if (handle<lHandleToIndex)
	{
		return list[handleToIndex[handle]];
	}
	return nil;
}
	
-(CLO*)next_LevObj
{
	CLO* plo;
	
	if (loFranIndex < nIndex)
	{
		do
		{
			plo = list[loFranIndex++];
			if (plo->loType >= OBJ_SPR)
			{
				return plo;
			}
		} while (loFranIndex < nIndex);
	}
	return nil;
}

-(CLO*)first_LevObj
{
	loFranIndex = 0;
	return [self next_LevObj];
}	

@end
