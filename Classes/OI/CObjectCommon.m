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
// COBJECTCOMMON : Donnees d'un objet normal
//
//----------------------------------------------------------------------------------
#import "CObjectCommon.h"
#import "CFile.h"
#import "CDefValues.h"
#import "CDefStrings.h"
#import "CAnimHeader.h"
#import "CDefCounters.h"
#import "CDefCounter.h"
#import "CDefObject.h"
#import "CMoveDefList.h"
#import "CDefTexts.h"
#import "CDefCCA.h"
#import "COI.h"
#import "CTransitionData.h"

@implementation CObjectCommon

-(id)init
{
	self=[super init];
	
	ocMovements=nil;     /// La liste des mouvements
    ocValues=nil;          /// Les alterable values par defaut
    ocStrings=nil;        /// Les alterable strings
    ocAnimations=nil;     /// Les animations
    ocCounters=nil;   /// Settings lives / scores / counter
    ocObject=nil;          /// L'objet lui meme'
    ocExtension=nil;	/// Les donn�es objets extension
	ocVersion=0;
	ocID=0;
	ocPrivate=0;
	
	return self;
}
-(void)dealloc
{
	if (ocMovements!=nil)
	{
		[ocMovements release];
	}
    if (ocValues!=nil)
	{
		[ocValues release];
	}
    if (ocStrings!=nil) 
	{
		[ocStrings release];
	}
    if (ocAnimations!=nil)
	{
		[ocAnimations release];
	}
    if (ocCounters!=nil)
	{
		[ocCounters release];
	}
    if (ocObject!=nil)
	{
		[ocObject release];
	}
    if (ocExtension!=nil)
	{
		free(ocExtension);
	}
	if (ocFadeIn!=nil)
	{
		[ocFadeIn release];
	}
	if (ocFadeOut!=nil)
	{
		[ocFadeOut release];
	}
	[super dealloc];
}
-(void)load:(CFile*)file withType:(short)type andCOI:(COI*)pOi;
{
	pCOI=pOi;
	
	// Position de debut
	NSUInteger debut=[file getFilePointer];
	
	// Lis le header
	int n;
	[file skipBytes:4];			    // DWORD ocDWSize;	Total size of the structures
	int oExtension=[file readAShort];	    // WORD Extension structure 
	int oMovements=[file readAShort];	    // WORD Offset of the movements
	[file skipBytes:2];			    // WORD For version versions > MOULI 
	int oCounter=[file readAShort];             // WORD Pointer to COUNTER structure
	int oAnimations=[file readAShort];	    // WORD Offset of the animations
	int oData=[file readAShort];		    // WORD Pointer to DATA structure
	ocOEFlags=[file readAInt];		    // New flags
	for (n=0; n<8; n++)
	{
	    ocQualifiers[n]=[file readAShort];	    // OC_MAX_QUALIFIERS Qualifier list
	}
	[file skipBytes:2];
	int oValues=[file readAShort];		    // WORD Values structure
	int oStrings=[file readAShort];             // WORD String structure
	ocFlags2=[file readAShort];		    // WORD New news flags, before was ocEvents
	ocOEPrefs=[file readAShort];		    // WORD Automatically modifiable flags
	ocIdentifier=[file readAInt];		    // DWORD Identifier d'objet
	ocBackColor=[file readAColor];		    // COLORREF Background color
	int oFadeIn=[file readAInt];                // DWORD Offset fade in 
	int oFadeOut=[file readAInt];		    // DWORD Offset fade out 
	//	int ocValueNames=file.readAInt();	    // For the debugger
	//	int ocStringNames=file.readAInt();	    
	
	// Charge les movements
	if (oMovements!=0)
	{
	    [file seek:debut+oMovements];
	    ocMovements=[[CMoveDefList alloc] init];
	    [ocMovements load:file];
	}
	// Charge les values
	if (oValues!=0)
	{
		[file seek:debut+oValues];
		ocValues=[[CDefValues alloc] init];
		[ocValues load:file];
	}
	// Charge les strings
	if (oStrings!=0)
	{
		[file seek:debut+oStrings];
		ocStrings=[[CDefStrings alloc] init];
		[ocStrings load:file];
	}
	// Charge les animations
	if (oAnimations!=0)
	{
		[file seek:debut+oAnimations];
		ocAnimations=[[CAnimHeader alloc] init];
		[ocAnimations load:file];
	}
	// Les donnees counters
	if (oCounter!=0)
	{
		[file seek:debut+oCounter];
		ocObject=[[CDefCounter alloc] init];
		[ocObject load:file];
	}
	// Les donnees extension
	if (oExtension!=0)
	{
		[file seek:debut+oExtension];
	    int size=[file readAInt];
	    [file skipBytes:4];
	    ocVersion=[file readAInt];
	    ocID=[file readAInt];
	    ocPrivate=[file readAInt];
	    size-=20;
		ocExtLength=size;
	    if (size!=0)
	    {
			ocExtension=(unsigned char*)malloc(size);
			[file readACharBuffer:(char*)ocExtension withLength:size];
	    }
	}
	// Le fade in
	if (oFadeIn!=0)
	{
		[file seek:debut+oFadeIn];
		ocFadeIn=[[CTransitionData alloc] init];
		[ocFadeIn load:file];
	}
	// Le fade out
	if (oFadeOut!=0)
	{
		[file seek:debut+oFadeOut];
		ocFadeOut=[[CTransitionData alloc] init];
		[ocFadeOut load:file];
	}

	// Les donnees score/live/counter
	if (oData!=0)
	{
		[file seek:debut+oData];
		switch (type)
		{
			case 3:         // OBJ_TEXT
			case 4:         // OBJ_QUEST 
				ocObject=[[CDefTexts alloc] init];
				[ocObject load:file];
				break;
                
			case 5:         // OBJ_SCORE
			case 6:         // OBJ_LIVES
			case 7:         // OBJ_COUNTER
				ocCounters=[[CDefCounters alloc] init];
				[ocCounters load:file];
				break;
				
			case 9:
				ocObject=[[CDefCCA alloc] init];
				[ocObject load:file];
				break;
		}
	}
}
-(void)enumElements:(id)enumImages withFont:(id)enumFonts
{
	if (ocAnimations!=nil)
	{
		[ocAnimations enumElements:enumImages];
	}
	if (ocObject!=nil)
	{
	    [ocObject enumElements:enumImages withFont:enumFonts];
	}
	if (ocCounters!=nil)
	{
	    [ocCounters enumElements:enumImages withFont:enumFonts];
	}
}

@end
