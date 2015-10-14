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
// CFONTBANK: stockage des fontes
//
//----------------------------------------------------------------------------------
#import "CFontBank.h"
#import "CRunApp.h"
#import "CFont.h"
#import "CServices.h"
#import "CFile.h"
#import "CFontInfo.h"

@implementation CFontBank

-(id)initWithApp:(CRunApp*)app
{
	runApp=app;
	return self;
}
-(void)dealloc
{
	if (fonts!=nil)
	{
		free(fonts);
	}
	if (handleToIndex!=nil)
	{
		free(handleToIndex);
	}
	if (offsetsToFonts!=nil)
	{
		free(offsetsToFonts);
	}
	if (useCount!=nil)
	{
		free(useCount);
	}
	[super dealloc];
}
-(void)preLoad
{
	// Nombre d'elements
	int number = [runApp->file readAInt];	
	
	// Explore les handles
	int n;
	maxHandlesReel = 0;
	NSUInteger debut = [runApp->file getFilePointer];
	CFont* temp = [[CFont alloc] init];
	for (n = 0; n < number; n++)
	{
		[temp loadHandle:runApp->file];
		maxHandlesReel = MAX(maxHandlesReel, temp->handle + 1);
	}
	[runApp->file seek:debut];
	if(maxHandlesReel > 0)
		offsetsToFonts = (int*)malloc(maxHandlesReel*sizeof(int));
	else
		offsetsToFonts = NULL;
	for (n = 0; n < number; n++)
	{
		debut = [runApp->file getFilePointer];
		[temp loadHandle:runApp->file];
		offsetsToFonts[temp->handle] = (int)debut;
	}
	[temp release];
	if(maxHandlesReel > 0)
		useCount = (short*)malloc(maxHandlesReel*sizeof(short));
	else
		useCount = NULL;
	[self resetToLoad];
	handleToIndex = nil;
	maxHandlesTotal = maxHandlesReel;
	nFonts = 0;
	fonts = nil;
}
-(void)load
{
	int n;
	nFonts = 0;
	for (n = 0; n < maxHandlesReel; n++)
	{
		if (useCount[n] != 0)
		{
			nFonts++;
		}
	}

	CFont** newFonts = NULL;
	if(nFonts > 0)
		newFonts=(CFont**)calloc(nFonts, sizeof(CFont*));

	int count = 0;
	int h;
	for (h = 0; h < maxHandlesReel; h++)
	{
		if (useCount[h] != 0)
		{
			if (fonts != nil && handleToIndex[h] != -1 && fonts[handleToIndex[h]] != nil)
			{
				newFonts[count] = fonts[handleToIndex[h]];
				newFonts[count]->useCount = useCount[h];
			}
			else
			{
				newFonts[count] = [[CFont alloc] init];
				[runApp->file seek:offsetsToFonts[h]];
				[newFonts[count] load:runApp->file];
				newFonts[count]->useCount = useCount[h];
			}
			count++;
		}
		else
		{
			if (fonts!=nil && handleToIndex[h]>=0 && fonts[handleToIndex[h]]!=nil)
			{
				[fonts[handleToIndex[h]] release];
			}
		}			
	}
	if (fonts!=nil)
	{
		free(fonts);
	}		
	fonts = newFonts;
	
	// Cree la table d'indirection
	if(handleToIndex != nil)
		free(handleToIndex);
	
	handleToIndex = (short*)malloc(maxHandlesReel*sizeof(short));
	for (n = 0; n < maxHandlesReel; n++)
	{
		handleToIndex[n] = -1;
	}
	for (n = 0; n < nFonts; n++)
	{
		handleToIndex[fonts[n]->handle] = (short) n;
	}
	maxHandlesTotal = maxHandlesReel;
	
	// Plus rien a charger
	[self resetToLoad];
}
-(CFont*)getFontFromHandle:(short)handle
{
	// Protection jeux niques
	if (handle == -1)
	{
		return nullFont;	
	}
	// Retourne la fonte
	if (handle >= 0 && handle < maxHandlesTotal)
	{
		if (handleToIndex[handle] != -1)
		{
			return fonts[handleToIndex[handle]];
		}
	}
	return nil;
}
-(CFont*)getFontFromIndex:(short)index
{
	if (index >= 0 && index < nFonts)
	{
		return fonts[index];
	}
	return nil;
}
-(CFontInfo*)getFontInfoFromHandle:(short)handle
{
	CFont* font = [self getFontFromHandle:handle];
	return [font getFontInfo];
}
-(void)resetToLoad
{
	int n;
	for (n = 0; n < maxHandlesReel; n++)
	{
		useCount[n] = 0;
	}
}
-(void)setToLoad:(short)handle
{
	// Protection jeux niques
	if (handle == -1)
	{
		if (nullFont == nil)
		{
			nullFont = [[CFont alloc] init];
			[nullFont createDefaultFont];
		}
		return;
	}
	useCount[handle]++;
}
-(short)enumerate:(short)num
{
	[self setToLoad:num];
	return -1;
}
-(short)addFont:(CFontInfo*)info
{
	int h;
	
	// Cherche une fonte identique
	int n;
	for (n = 0; n < nFonts; n++)
	{
		if (fonts[n] == nil)
		{
			continue;
		}
		if (fonts[n]->lfHeight != info->lfHeight)
		{
			continue;
		}
		if (fonts[n]->lfWeight != info->lfWeight)
		{
			continue;
		}
		if (fonts[n]->lfItalic != info->lfItalic)
		{
			continue;
		}
		if (fonts[n]->lfUnderline != info->lfUnderline)
		{
			continue;
		}
		if (fonts[n]->lfStrikeOut != info->lfStrikeOut)
		{
			continue;
		}
		if ([fonts[n]->lfFaceName caseInsensitiveCompare:info->lfFaceName]!=0)
		{
			continue;
		}
		break;
	}
	if (n < nFonts)
	{
		return fonts[n]->handle;
	}
	
	// Cherche un handle libre
	short hFound = -1;
	for (h = maxHandlesReel; h < maxHandlesTotal; h++)
	{
		if (handleToIndex[h] == -1)
		{
			hFound = (short) h;
			break;
		}
	}
	
	// Rajouter un handle
	short* newHToI;
	if (hFound == -1)
	{
		newHToI = (short*)malloc((maxHandlesTotal + 10)*sizeof(short));
		for (h = 0; h < maxHandlesTotal; h++)
		{
			newHToI[h] = handleToIndex[h];
		}
		for (; h < maxHandlesTotal + 10; h++)
		{
			newHToI[h] = -1;
		}
		hFound = (short) maxHandlesTotal;
		maxHandlesTotal += 10;
		if (handleToIndex!=nil)
		{
			free(handleToIndex);
		}
		handleToIndex = newHToI;
	}
	
	// Cherche une fonte libre
	int f;
	int fFound = -1;
	for (f = 0; f < nFonts; f++)
	{
		if (fonts[f] == nil)
		{
			fFound = f;
			break;
		}
	}
	
	// Rajouter une image?
	if (fFound == -1)
	{
		CFont** newFonts = (CFont**)calloc((nFonts + 10), sizeof(CFont*));
		for (f = 0; f < nFonts; f++)
		{
			newFonts[f] = fonts[f];
		}
		for (; f < nFonts + 10; f++)
		{
			newFonts[f] = nil;
		}
		fFound = nFonts;
		nFonts += 10;
		if (fonts!=nil)
		{
			free(fonts);
		}
		fonts = newFonts;
	}
	
	// Ajoute la nouvelle image
	handleToIndex[hFound] = (short) fFound;
	fonts[fFound] = [[CFont alloc] init];
	fonts[fFound]->handle = hFound;
	fonts[fFound]->lfHeight = info->lfHeight;
	fonts[fFound]->lfWeight = info->lfWeight;
	fonts[fFound]->lfItalic = info->lfItalic;
	fonts[fFound]->lfUnderline = info->lfUnderline;
	fonts[fFound]->lfStrikeOut = info->lfStrikeOut;
	fonts[fFound]->lfFaceName = [[NSString alloc] initWithString:info->lfFaceName];
	
	return hFound;
}
@end
