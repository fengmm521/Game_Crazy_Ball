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
// CANIM : definition d'une animation
//
//----------------------------------------------------------------------------------
#import "CAnim.h"
#import "CFile.h"
#import "CAnimDir.h"

// Table des animations n'ayant qu'une seule vitesse
// -------------------------------------------------
static char tableAnimTwoSpeeds[]=
{
	0,     			                 // 0  ANIMID_STOP
	1,                                       // 1  ANIMID_WALK
	1,                                       // 2  ANIMID_RUN
	0,                                       // 3  ANIMID_APPEAR
	0,                                       // 4  ANIMID_DISAPPEAR
	1,                                       // 5  ANIMID_BOUNCE
	0,                                       // 6  ANIMID_SHOOT
	1,                                       // 7  ANIMID_JUMP
	1,                                       // 8  ANIMID_FALL
	1,											 // 9  ANIMID_CLIMB
	1,                                       // 10 ANIMID_CROUCH
	1,                                       // 11 ANIMID_UNCROUCH
	1,                                       // 12
	1,                                       // 13
	1,                                       // 14
	1                                        // 15
};

@implementation CAnim

-(void)dealloc
{
	int n;
	for (n=0; n<32; n++)
	{
		if (anDirs[n]!=nil)
		{
			[anDirs[n] release];
		}
	}
	[super dealloc];
}
-(void)load:(CFile*)file 
{
	NSUInteger debut=[file getFilePointer];
	
	short* offsets=(short*)malloc(32*sizeof(short));
	int n;
	for (n=0; n<32; n++)
	{
		offsets[n]=[file readAShort];
	}
	
	for (n=0; n<32; n++)
	{
		anDirs[n]=nil;
		anTrigo[n]=0;
		anAntiTrigo[n]=0;
		if (offsets[n]!=0)
		{
			anDirs[n]=[[CAnimDir alloc] init];
			[file seek:debut+offsets[n]];
			[anDirs[n] load:file];
		}
	}
	free(offsets);
}
-(void)enumElements:(id)enumImages
{
	int n;
	for (n=0; n<32; n++)
	{
		if (anDirs[n]!=nil)
		{
			[anDirs[n] enumElements:enumImages];
		}
	}
}
-(void)approximate:(int)nAnim
{      
	// Animation definie: travaille les directions non definies
	int d, d2, d3;
	int cpt1, cpt2;
	
	// Boucle d'exploration des directions
	for (d=0; d<32; d++)
	{
		if (anDirs[d]==nil)
		{
			// Boucle d'exploration sens trigonometrique
			for (d2=0, cpt1=d+1; d2<32; d2++, cpt1++)
			{
				cpt1=cpt1&0x1F;
				if (anDirs[cpt1]!=nil)
				{
					anTrigo[d]=(unsigned char)cpt1;
					break;
				}
			}
			// Boucle d'exploration sens anti-trigonometrique
			for (d3=0, cpt2=d-1; d3<32; d3++, cpt2--)
			{
				cpt2=cpt2&0x1F;
				if (anDirs[cpt2]!=nil)
				{
					anAntiTrigo[d]=(unsigned char)cpt2;
					break;
				}
			}
			if (cpt1==cpt2 || d2<d3)						//; Les deux pointent sur la meme
			{
				anTrigo[d]|=0x40;								//; Trigo plus proche
			}
			else if (d3<d2)
			{
				anAntiTrigo[d]|=0x40;								//; Anti-trigo plus proche
			}
		}
		else
		{
			// Egalise la vitesse maxi avec la vitesse mini si necessaire
			if (nAnim<16)
			{
				if (tableAnimTwoSpeeds[nAnim]==0)
				{
					anDirs[d]->adMinSpeed=anDirs[d]->adMaxSpeed;
				}
			}
		}
	}
}


@end
