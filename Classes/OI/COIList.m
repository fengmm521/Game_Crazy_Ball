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
// COILIST : liste des OI de l'application
//
//----------------------------------------------------------------------------------
#import "COIList.h"
#import "CRunApp.h"
#import "CChunk.h"
#import "COI.h"
#import "IEnum.h"

@implementation COIList

-(void)dealloc
{
	int index;
	for (index=0; index<oiMaxIndex; index++)
	{
		if (ois[index]!=nil)
		{
			[ois[index] release];
	    }
	}
	free(ois);
	free(oiLoaded);
	free(oiToLoad);
	
	[super dealloc];
}
-(void)preLoad:(CFile*)file
{
	// Alloue la table de OI
	oiMaxIndex=(short)[file readAInt];
	ois=(COI**)calloc(oiMaxIndex, sizeof(COI*));
	
	// Explore les chunks
	int index;
	oiMaxHandle=0;
	CChunk* chk=[[CChunk alloc] init];
	for (index=0; index<oiMaxIndex; index++)
	{
		NSUInteger posEnd;
		chk->chID=0;
		while (chk->chID!=CHUNK_LAST)
		{
			[chk readHeader:file];
			if (chk->chSize==0)
				continue;
			posEnd=[file getFilePointer]+chk->chSize;
			switch(chk->chID)
			{
					// CHUNK_OBJINFOHEADER
				case 0x4444:
					ois[index]=[[COI alloc] init];
					[ois[index] loadHeader:file];
					if (ois[index]->oiHandle>=oiMaxHandle)
						oiMaxHandle=(short)(ois[index]->oiHandle+1);
					break;
					// CHUNK_OBJINFONAME
				case 0x4445:
				{
					COI* oi = ois[index];
					if(oi != nil)
						oi->oiName=[file readAString];
					break;
				}
					// CHUNK_OBJECTSCOMMON
				case 0x4446:
				{
					COI* oi = ois[index];
					if(oi != nil)
						oi->oiFileOffset=[file getFilePointer];
					break;
				}
			}
			// Positionne a la fin du chunk
			[file seek:posEnd];
		}
	}
	[chk release];
	
	// Table OI To Handle
	if(oiMaxHandle > 0)
		oiHandleToIndex=(short*)malloc(oiMaxHandle*sizeof(short));
	else
		oiHandleToIndex = NULL;
	for (index=0; index<oiMaxIndex; index++)
	{
		oiHandleToIndex[ois[index]->oiHandle] = (short)index;
	}
	
	// Tables de chargement
	if(oiMaxHandle > 0)
	{
		oiToLoad=(char*)malloc(oiMaxHandle*sizeof(char));
		oiLoaded=(char*)malloc(oiMaxHandle*sizeof(char));
	}
	else
	{
		oiToLoad = nil;
		oiLoaded = nil;
	}
	int n;
	for (n=0; n<oiMaxHandle; n++)
	{
		oiToLoad[n]=0;
		oiLoaded[n]=0;
	}
}
-(COI*)getOIFromHandle:(short)handle
{
	return ois[oiHandleToIndex[handle]];
}
-(COI*)getOIFromIndex:(short)index
{
	return ois[index];
}
-(void)resetOICurrent
{
	int n;
	for (n=0; n<oiMaxIndex; n++)
	{
	    ois[n]->oiFlags&=~OILF_CURFRAME;
	}
}
-(void)setOICurrent:(int)handle
{
	ois[oiHandleToIndex[handle]]->oiFlags|=OILF_CURFRAME;
}
-(COI*)getFirstOI
{
	int n;
	for (n=0; n<oiMaxIndex; n++)
	{
	    if ((ois[n]->oiFlags&OILF_CURFRAME)!=0)
	    {
			currentOI=n;
			return ois[n];
	    }
	}
	return nil;
}
-(COI*)getNextOI
{
	if (currentOI<oiMaxIndex)
	{
	    int n;
	    for (n=currentOI+1; n<oiMaxIndex; n++)
	    {
			if ((ois[n]->oiFlags&OILF_CURFRAME)!=0)
			{
				currentOI=n;
				return ois[n];
			}
	    }
	}
	return nil;
}
-(void)resetToLoad
{
	int n;
	for (n=0; n<oiMaxHandle; n++)
	{
	    oiToLoad[n]=0;
	}
}
-(void)setToLoad:(int)n
{
	oiToLoad[n]=1;
}
-(void)load:(CFile*)file 
{
	int h;
	for (h=0; h<oiMaxHandle; h++)
	{
	    if (oiToLoad[h]!=0)
	    {
			if (oiLoaded[h]==0 || (oiLoaded[h]!=0 && (ois[oiHandleToIndex[h]]->oiLoadFlags&OILF_TORELOAD)!=0) )
			{
				[ois[oiHandleToIndex[h]] load:file];
				oiLoaded[h]=1;
			}
	    }
	    else
	    {
			if (oiLoaded[h]!=0)
			{
				[ois[oiHandleToIndex[h]] unLoad];
				oiLoaded[h]=0;
			}
	    }
	}
	[self resetToLoad];
}
-(void)enumElements:(id)enumImages withFont:(id)enumFonts
{
	int h;
	for (h=0; h<oiMaxHandle; h++)
	{
	    if (oiLoaded[h]!=0)
	    {
			[ois[oiHandleToIndex[h]] enumElements:enumImages withFont:enumFonts];
	    }
	}
}


@end
