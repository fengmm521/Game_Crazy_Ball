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
// CANIMHEADER : header d'un ensemble d'animations
//
//----------------------------------------------------------------------------------
#import "CAnimHeader.h"
#import "CAnim.h"
#import "CFile.h"

// Table d'approximation des animations
// ------------------------------------
static short tableApprox[][4]=
{
	{ANIMID_APPEAR,ANIMID_WALK,ANIMID_RUN,0},	// 0  ANIMID_STOP
	{ANIMID_RUN,ANIMID_STOP,0,0},               // 1  ANIMID_WALK
	{ANIMID_WALK,ANIMID_STOP,0,0},              // 2  ANIMID_RUN
	{ANIMID_STOP,ANIMID_WALK,ANIMID_RUN,0},		// 3  ANIMID_APPEAR
	{ANIMID_STOP,0,0,0},                        // 4  ANIMID_DISAPPEAR
	{ANIMID_STOP,ANIMID_WALK,ANIMID_RUN,0},		// 5  ANIMID_BOUNCE
	{ANIMID_STOP,ANIMID_WALK, ANIMID_RUN,0},	// 6  ANIMID_SHOOT
	{ANIMID_WALK, ANIMID_RUN, ANIMID_STOP,0},	// 7  ANIMID_JUMP
	{ANIMID_STOP, ANIMID_WALK, ANIMID_RUN,0},	// 8  ANIMID_FALL
	{ANIMID_WALK, ANIMID_RUN, ANIMID_STOP,0},	// 9  ANIMID_CLIMB
	{ANIMID_STOP,ANIMID_WALK,ANIMID_RUN,0},		// 10 ANIMID_CROUCH
	{ANIMID_STOP,ANIMID_WALK,ANIMID_RUN,0},		// 11 ANIMID_UNCROUCH
	{0, 0, 0, 0},
	{0, 0, 0, 0},
	{0, 0, 0, 0},
	{0, 0, 0, 0},
};

@implementation CAnimHeader

-(void)dealloc
{
	int n;
	for (n=0; n<ahAnimMax; n++)
	{
		if (ahAnimExists[n]!=0)
		{
			[ahAnims[n] release];
		}
	}
	free(ahAnims);
	free(ahAnimExists);
	
	[super dealloc];
}
-(void)load:(CFile*)file 
{
	NSUInteger debut=[file getFilePointer];
	
	[file skipBytes:2];          // ahSize
	ahAnimMax=[file readAShort];
	
	short* offsets=(short*)malloc(ahAnimMax*sizeof(short));
	int n;
	for (n=0; n<ahAnimMax; n++)
	{
		offsets[n]=[file readAShort];
	}
	
	ahAnims=(CAnim**)malloc(ahAnimMax*sizeof(CAnim*));
	ahAnimExists=(unsigned char*)malloc(ahAnimMax);
	for (n=0; n<ahAnimMax; n++)
	{
		ahAnims[n]=nil;
		ahAnimExists[n]=0;
		if (offsets[n]!=0)
		{
			ahAnims[n]=[[CAnim alloc] init];
			[file seek:debut+offsets[n]];
			[ahAnims[n] load:file];
			ahAnimExists[n]=1;
		}
	}
	free(offsets);
	
	// Approximation des animations
	int cptAnim;
	for (cptAnim=0; cptAnim<ahAnimMax; cptAnim++)
	{
		if (ahAnimExists[cptAnim]==0)
		{
			// Animation non definie: recherche dans la table d'approximation
			// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			BOOL bFlag=NO;
			if (cptAnim<12)                                     // Si une des nouvelles animations, on approxime pas!
			{
				for (n=0; n<4; n++)
				{
					unsigned char a=ahAnimExists[tableApprox[cptAnim][n]];
					if (a!=0)
					{
						ahAnims[cptAnim]=ahAnims[tableApprox[cptAnim][n]];
						bFlag=YES;
						break;
					}
				}
			}
			if (bFlag==NO)
			{
				// Pas d'animation disponible: met la premiere trouvee!
				for (n=0; n<ahAnimMax; n++)
				{
					if (ahAnimExists[n]!=0)
					{
						ahAnims[cptAnim]=ahAnims[n];
						break;
					}
				}
			}
		}
		else
		{
			[ahAnims[cptAnim] approximate:cptAnim];
		}
	}     
}
-(void)enumElements:(id)enumImages
{
	int n;
	for (n=0; n<ahAnimMax; n++)
	{
		if (ahAnimExists[n]!=0)
		{		
			[ahAnims[n] enumElements:enumImages];
		}
	}
}


@end
