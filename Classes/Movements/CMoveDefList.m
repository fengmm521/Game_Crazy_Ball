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
// CMOVEDEFLIST : liste des mouvements d'un objet'
//
//----------------------------------------------------------------------------------
#import "CMoveDefList.h"
#import "CFile.h"
#import "CMoveDef.h"
#import "CMoveDefStatic.h"
#import "CMoveDefRace.h"
#import "CMoveDefGeneric.h"
#import "CMoveDefBall.h"
#import "CMoveDefPath.h"
#import "CMoveDefPlatform.h"
#import "CMoveDefExtension.h"
#import "CMoveDefMouse.h"

@implementation CMoveDefList

-(void)dealloc
{
	for (int n=0; n<nMovements; n++)
		[moveList[n] release];
	
	free(moveList);
	[super dealloc];
}
-(void)load:(CFile*)file 
{
	NSUInteger debut=[file getFilePointer];
	nMovements=[file readAInt];
	moveList=(CMoveDef**)malloc(nMovements*sizeof(CMoveDef*));
	
	int n;
	for (n=0; n<nMovements; n++)
	{
		[file seek:debut+4+16*n];              // sizeof(MvtHrd)
		
		// Lis les donnÈe
		int moduleNameOffset=[file readAInt];
		int mvtID=[file readAInt];
		int dataOffset=[file readAInt];
		int dataLength=[file readAInt];
        
		// Lis le debut du header movement
		[file seek:debut+dataOffset];
		short control=[file readAShort];
		short type=[file readAShort];
		unsigned char move=[file readAByte];
		unsigned char mo=[file readAByte];
		[file skipBytes:2];
		int dirAtStart=[file readAInt];
		switch (type)
		{
                // MVTYPE_STATIC
			case 0:
				moveList[n]=[[CMoveDefStatic alloc] init];
				break;
                // MVTYPE_MOUSE
			case 1:
				moveList[n]=[[CMoveDefMouse alloc] init];
				break;
                // MVTYPE_RACE
			case 2:
				moveList[n]=[[CMoveDefRace alloc] init];
				break;
                // MVTYPE_GENERIC
			case 3:
				moveList[n]=[[CMoveDefGeneric alloc] init];
				break;
                // MVTYPE_BALL
			case 4:
				moveList[n]=[[CMoveDefBall alloc] init];
				break;
                // MVTYPE_TAPED
			case 5:
				moveList[n]=[[CMoveDefPath alloc] init];
				break;
                // MVTYPE_PLATFORM
			case 9:
				moveList[n]=[[CMoveDefPlatform alloc] init];
				break;
                // MVTYPE_EXT				
			case 14:
				moveList[n]=[[CMoveDefExtension alloc] init];
				break;
		}
		[moveList[n] setData:type withControl:control andMoveAtStart:move andDirAtStart:dirAtStart andOptions:mo];
		[moveList[n] load:file withLength:dataLength-12];
		if (type==14)       // MVTYPE_EXT
		{
			[file seek:debut+moduleNameOffset];
			NSString* name=[file readAString];
			[((CMoveDefExtension*)moveList[n]) setModuleName:[name substringToIndex:[name length]-4] withID:mvtID];
			[name release];
		}
	}
}

@end
