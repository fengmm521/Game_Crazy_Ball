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
// CMOVEPATH : Mouvement enregistre
//
//----------------------------------------------------------------------------------
#import "CMovePath.h"
#import "CMove.h"
#import "CObject.h"
#import "CMoveDef.h"
#import "CRAni.h"
#import "CRMvt.h"
#import "CRCom.h"
#import "CRun.h"
#import "CMoveDefPath.h"
#import "CEventProgram.h"
#import "CRunFrame.h"
#import "CAnim.h"
#import "CPathStep.h"

@implementation CMovePath

-(void)initMovement:(CObject*)ho withMoveDef:(CMoveDef*)mvPtr
{
	hoPtr=ho;
	
	CMoveDefPath* mtPtr=(CMoveDefPath*)mvPtr;
	
	MT_XStart=hoPtr->hoX;					//; Position de depart	
	MT_YStart=hoPtr->hoY;
	
	MT_Direction=NO;							//; Vers l'avant
	MT_Pause=0;
	hoPtr->hoMark1=0;
	
	MT_Movement=mtPtr;
	hoPtr->roc->rcMinSpeed=mtPtr->mtMinSpeed;			//; Vitesses mini et maxi
	hoPtr->roc->rcMaxSpeed=mtPtr->mtMaxSpeed;
	MT_Calculs=0;
	MT_GotoNode=nil;
	[self mtGoAvant:0];                                           //; Branche le premier mouvement
	[self moveAtStart:mvPtr];
	hoPtr->roc->rcSpeed=MT_Speed;
	hoPtr->roc->rcChanged=YES;
	if (MT_Movement->mtNumber==0)
	{
	    [self stop];
	}	
}

-(void)kill
{
	[self freeMTNode];
}

-(void)move
{
	hoPtr->hoMark1=0;
	
	// Va faire les animations
	// ~~~~~~~~~~~~~~~~~~~~~~~
	hoPtr->roc->rcAnim=ANIMID_WALK;
	if (hoPtr->roa!=nil)
		[hoPtr->roa animate];
	
	// On est en pause?
	// ~~~~~~~~~~~~~~~
	if (MT_Speed==0)						//; Arrete?
	{
		int pause=MT_Pause;				//; Un compteur?
		if (pause==0)
		{
			hoPtr->roc->rcSpeed=0;
			[hoPtr->hoAdRunHeader newHandle_Collisions:hoPtr];
			return;
		}
		pause-=hoPtr->hoAdRunHeader->rhTimerDelta;
		if (pause>0)
		{
			MT_Pause=pause;
			hoPtr->roc->rcSpeed=0;
			[hoPtr->hoAdRunHeader newHandle_Collisions:hoPtr];			//; Va gerer les collisions tout de meme
			return;
		}
		MT_Pause=0;
		MT_Speed=rmStopSpeed&0x7FFF;
		rmStopSpeed=0;
        hoPtr->roc->rcSpeed=MT_Speed;
	}
	
	// Decoupe le mouvement en plus petits troncons
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	int calculs;
	if ((hoPtr->hoAdRunHeader->rhFrame->leFlags&LEF_TIMEDMVTS)!=0)
	{
		calculs=(int)( 256.0*hoPtr->hoAdRunHeader->rh4MvtTimerCoef );
	}
	else
	{
		calculs=0x100;
	}
	hoPtr->hoAdRunHeader->rhMT_VBLCount=(short)calculs;

	BOOL breakMtNewSpeed;
	while(YES)
	{
		breakMtNewSpeed=NO;
		hoPtr->hoAdRunHeader->rhMT_VBLStep=(short)calculs;
		calculs*=MT_Speed;
		calculs<<=5;                        // PIXEL_SPEED;
		if (calculs<=0x80000)					//; Pente <8
		{
			hoPtr->hoAdRunHeader->rhMT_MoveStep=calculs;
		}
		else
		{
			calculs=0x80000>>5;            //PIXEL_SPEED;
			calculs/=MT_Speed;
			hoPtr->hoAdRunHeader->rhMT_VBLStep=(short)calculs;                //; Nombre de VBL pour un pas
			hoPtr->hoAdRunHeader->rhMT_MoveStep=0x80000;
		}
		while(YES)
		{
			MT_FlagBranch=NO;
			BOOL flag=[self mtMove:hoPtr->hoAdRunHeader->rhMT_MoveStep];
			if (flag==YES && MT_FlagBranch==NO)
			{
				breakMtNewSpeed=YES;
				break;
			}
			if (hoPtr->hoAdRunHeader->rhMT_VBLCount==hoPtr->hoAdRunHeader->rhMT_VBLStep)
			{
				breakMtNewSpeed=YES;
				break;
			}
			if (hoPtr->hoAdRunHeader->rhMT_VBLCount>hoPtr->hoAdRunHeader->rhMT_VBLStep)
			{
				hoPtr->hoAdRunHeader->rhMT_VBLCount-=hoPtr->hoAdRunHeader->rhMT_VBLStep;
				calculs=hoPtr->hoAdRunHeader->rhMT_VBLCount;			//; OUI, on recalcule
				break;
			}
			calculs=hoPtr->hoAdRunHeader->rhMT_VBLCount*MT_Speed;
			calculs<<=5;	    // PIXEL_SPEED
			[self mtMove:calculs];
			breakMtNewSpeed=YES;
			break;
		}
		if (breakMtNewSpeed)
		{
			break;
		}
	}
}

-(BOOL)mtMove:(int)step
{
	// Fait un pas de mouvement
	// ~~~~~~~~~~~~~~~~~~~~~~~~
	step+=MT_Calculs;
	int step2=(step>>16)&0xFFFF;
	if (step2<MT_Longueur)
	{
		MT_Calculs=step;
		int x=(step2*MT_Cosinus)/16384+MT_XOrigin;		// Fois cosinus-> penteX
		int y=(step2*MT_Sinus)/16384+MT_YOrigin;			// Fois sinus-> penteY
		
		hoPtr->hoX=x;
		hoPtr->hoY=y;
		hoPtr->roc->rcChanged=YES;
		[hoPtr->hoAdRunHeader newHandle_Collisions:hoPtr];				//; Appel les collisions
		return hoPtr->rom->rmMoveFlag;					//; Retourne avec les flags
	}
	
	// Trop Long: tronquer le mouvement, et passer au suivant
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	step2-=MT_Longueur;
	step=(step2<<16)|(step&0xFFFF);
	if (MT_Speed!=0)
		step/=MT_Speed;
	step>>=5;                           // PIXEL_SPEED Nombre de VBL en trop
	hoPtr->hoAdRunHeader->rhMT_VBLCount+=(short)(step&0xFFFF);				//; On additionne
	
	hoPtr->hoX=MT_XDest;
	hoPtr->hoY=MT_YDest;
	hoPtr->roc->rcChanged=true;
	[hoPtr->hoAdRunHeader newHandle_Collisions:hoPtr];					//; Appel les collisions
	if (hoPtr->rom->rmMoveFlag) 
		return YES;			//; Sortie forc�e si collision!
	
	// Passe au mouvement suivant / precedent
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	hoPtr->hoMark1=hoPtr->hoAdRunHeader->rhLoopCount;				//; NODE REACHED
	hoPtr->hoMT_NodeName=nil;
	
	// Passe au node suivant
	int number=MT_MoveNumber;
	MT_Calculs=0;						//; En cas de message
	if (MT_Direction==NO)
	{
		// Mouvement suivant
		// -----------------
		number++;
		if (number<MT_Movement->mtNumber)					//; Dernier mouvement?
		{
			hoPtr->hoMT_NodeName=MT_Movement->steps[number]->mdName;
			
			// Goto node : on atteint le noeud?
			// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			if (MT_GotoNode!=nil)
			{
				if (MT_Movement->steps[number]->mdName!=nil)
				{
					if ([MT_GotoNode caseInsensitiveCompare:MT_Movement->steps[number]->mdName]==0)
					{
						MT_MoveNumber=number;                   //; Au cas ou il y a des messages...
						[self mtMessages];
						return [self mtTheEnd];			//; Fin du mouvement
					}
				}
			}
			
			// Mouvement suivant normal
			// ~~~~~~~~~~~~~~~~~~~~~~~~
			[self mtGoAvant:number];
			[self mtMessages];
			return hoPtr->rom->rmMoveFlag;
		}
		// Fin du mouvement vers l'avant
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		hoPtr->hoMark2=hoPtr->hoAdRunHeader->rhLoopCount;	//; END OF PATH
		MT_MoveNumber=number;                               //; Au cas ou il y a des messages...
		if (MT_Direction)           			//; Les messages ont retourne le mouvement: FINI!
		{
			[self mtMessages];
			return hoPtr->rom->rmMoveFlag;
		}
		if (MT_Movement->mtReverse!=0)
		{
			MT_Direction=YES;
			number--;
			hoPtr->hoMT_NodeName=MT_Movement->steps[number]->mdName;
			[self mtGoArriere:number];
			[self mtMessages];
			return hoPtr->rom->rmMoveFlag;
		}
		[self mtReposAtEnd];					//; Repositionne a la fin si necessaire
		if (MT_Movement->mtLoop==0)						//; Loop?
		{
			[self mtTheEnd];					//; Fin du mouvement
			[self mtMessages];
			return hoPtr->rom->rmMoveFlag;
		}
		number=0;
		[self mtGoAvant:number];
		[self mtMessages];
		return hoPtr->rom->rmMoveFlag;
	}
	else
	{
		// Mouvement precedent
		// -------------------
		
		// Goto node : on atteint le noeud?
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if (MT_GotoNode!=nil)
		{
			if (MT_Movement->steps[number]->mdName!=nil)
			{
				if ([MT_GotoNode caseInsensitiveCompare:MT_Movement->steps[number]->mdName]==0)
				{
					[self mtMessages];
					return [self mtTheEnd];			//; Fin du mouvement
				}
			}
		}                
		hoPtr->hoMT_NodeName=MT_Movement->steps[number]->mdName;
		MT_Pause=MT_Movement->steps[number]->mdPause;
		number--;
		if (number>=0)								//; Premier mouvement?
		{
			// Mouvement normal vers l'arriere
			// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			[self mtGoArriere:number];
			[self mtMessages];
			return hoPtr->rom->rmMoveFlag;
		}
		// Arrive au debut du mouvement
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		[self mtReposAtEnd];					//; Repositionne a la fin si necessaire
		if (MT_Direction==NO)
		{
			[self mtMessages];
			return hoPtr->rom->rmMoveFlag;
		}
		if (MT_Movement->mtLoop==0)
		{
			[self mtTheEnd];							//; Fin du mouvement
			[self mtMessages];
			return hoPtr->rom->rmMoveFlag;
		}
		number=0;									//; Redemarre au debut
		MT_Direction=NO;					//; On repart dans le bon sens
		[self mtGoAvant:number];
		[self mtMessages];
		return hoPtr->rom->rmMoveFlag;
	}
}

// Un cran en avant
// ----------------
-(void)mtGoAvant:(int)number
{
	if (number>=MT_Movement->mtNumber)
	{
	    [self stop];
	}
	else
	{
	    MT_Direction=NO;
	    MT_MoveNumber=number;
	    MT_Pause=MT_Movement->steps[number]->mdPause;
	    MT_Cosinus=MT_Movement->steps[number]->mdCosinus;
	    MT_Sinus=MT_Movement->steps[number]->mdSinus;
	    MT_XOrigin=hoPtr->hoX;
	    MT_YOrigin=hoPtr->hoY;
	    MT_XDest=hoPtr->hoX+MT_Movement->steps[number]->mdDx;
	    MT_YDest=hoPtr->hoY+MT_Movement->steps[number]->mdDy;
	    hoPtr->roc->rcDir=MT_Movement->steps[number]->mdDir;
	    [self mtBranche];
	}
}

// Un cran en arriere
// ------------------
-(void)mtGoArriere:(int)number
{
	if (number>=MT_Movement->mtNumber)
	{
	    [self stop];
	}
	else
	{
	    MT_Direction=YES;
	    MT_MoveNumber=number;
	    MT_Cosinus=-MT_Movement->steps[number]->mdCosinus;
	    MT_Sinus=-MT_Movement->steps[number]->mdSinus;
	    MT_XOrigin=hoPtr->hoX;
	    MT_YOrigin=hoPtr->hoY;
	    MT_XDest=hoPtr->hoX-MT_Movement->steps[number]->mdDx;
	    MT_YDest=hoPtr->hoY-MT_Movement->steps[number]->mdDy;
	    int dir=MT_Movement->steps[number]->mdDir;
	    dir+=16;
	    dir&=31;
	    hoPtr->roc->rcDir=dir;
	    [self mtBranche];
	}
}

// Met la fin des calculs
-(void)mtBranche
{
	MT_Longueur=MT_Movement->steps[MT_MoveNumber]->mdLength;
	int speed=MT_Movement->steps[MT_MoveNumber]->mdSpeed;
	
	// Faire une pause?
	int pause=MT_Pause;
	if (pause!=0)
	{
		MT_Pause=pause*20;	
		speed|=0x8000;
		rmStopSpeed=speed;			//; La vitesse de stop
	}
	if (rmStopSpeed!=0)
	{
		speed=0;								// Stop!
	}
	if (speed!=MT_Speed || speed!=0)
	{
		MT_Speed=speed;
		hoPtr->rom->rmMoveFlag=YES;
		MT_FlagBranch=YES;
	}
	hoPtr->roc->rcSpeed=MT_Speed;
}

// Envoie les messages NODE REACHED 
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void)mtMessages
{
	if (hoPtr->hoMark1==hoPtr->hoAdRunHeader->rhLoopCount)
	{
		hoPtr->hoAdRunHeader->rhEvtProg->rhCurParam[0]=0;
		[hoPtr->hoAdRunHeader->rhEvtProg handle_Event:hoPtr withCode:(-20<<16)|(((int)hoPtr->hoType)&0xFFFF) ];	    // CNDL_EXTPATHNODE
		[hoPtr->hoAdRunHeader->rhEvtProg handle_Event:hoPtr withCode:(-35<<16)|(((int)hoPtr->hoType)&0xFFFF) ];	    // CNDL_EXTPATHNODENAME
	}
	if (hoPtr->hoMark2==hoPtr->hoAdRunHeader->rhLoopCount)
	{
		hoPtr->hoAdRunHeader->rhEvtProg->rhCurParam[0]=0;
	    [hoPtr->hoAdRunHeader->rhEvtProg handle_Event:hoPtr withCode:(-21<<16)|(((int)hoPtr->hoType)&0xFFFF) ];   // CNDL_EXTENDPATH
	}
}

// Fin du mouvement
// ~~~~~~~~~~~~~~~~
-(BOOL)mtTheEnd
{
	MT_Speed=0;
	rmStopSpeed=0;
	hoPtr->rom->rmMoveFlag=YES;
	return YES;
}

// Repositionner le sprite a la fin?
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void)mtReposAtEnd
{
	if (MT_Movement->mtRepos!=0)
	{
		hoPtr->hoX=MT_XStart;
		hoPtr->hoY=MT_YStart;
		hoPtr->roc->rcChanged=YES;
	}
}

// Branche � un node selon son nom
// -------------------------------
-(void)mtBranchNode:(NSString*)pName
{
	int number;
	for (number=0; number<MT_Movement->mtNumber; number++)
	{
		if (MT_Movement->steps[number]->mdName!=nil)
		{
			if ([pName caseInsensitiveCompare:MT_Movement->steps[number]->mdName]==0)
			{
				if (MT_Direction==NO)
				{
					// En avant
					[self mtGoAvant:number];
					hoPtr->hoMark1=hoPtr->hoAdRunHeader->rhLoopCount;
					hoPtr->hoMT_NodeName=MT_Movement->steps[number]->mdName;
					hoPtr->hoMark2=0;
					[self mtMessages];
				}
				else
				{
					if (number>0)
					{
						number--;
						[self mtGoArriere:number];
						hoPtr->hoMark1=hoPtr->hoAdRunHeader->rhLoopCount;
						hoPtr->hoMT_NodeName=MT_Movement->steps[number]->mdName;
						hoPtr->hoMark2=0;
						[self mtMessages];
					}
				}
				hoPtr->rom->rmMoveFlag=YES;
				return;
			}
		}
	}
}

// Goto node : se rend a un noeud
// ------------------------------
-(void)freeMTNode
{
	if (MT_GotoNode!=nil)
	{
		[MT_GotoNode release];
	}
	MT_GotoNode=nil;
}

-(void)mtGotoNode:(NSString*)pName
{
	int number;
	
	for (number=0; number<MT_Movement->mtNumber;  number++)
	{
		if (MT_Movement->steps[number]->mdName!=nil)
		{
			if ([pName caseInsensitiveCompare:MT_Movement->steps[number]->mdName]==0)
			{
				if (number==MT_MoveNumber)
				{
					if (MT_Calculs==0)	// Au debut du node
						return;						
				}
				
				[self freeMTNode];
				MT_GotoNode=[[NSString alloc] initWithString:pName];
				
				if (MT_Direction==NO)
				{
					if (number>MT_MoveNumber)
					{
						// En avant
						if (MT_Speed!=0)
							return;
						if ((rmStopSpeed&0x8000)!=0)
							[self start];
						else
							[self mtGoAvant:MT_MoveNumber];
						return;
					}
					else
					{
						// En arriere
						if (MT_Speed!=0)
						{
							[self reverse];
							return;
						}
						if ((rmStopSpeed&0x8000)!=0)
						{
							[self start];
							[self reverse];
						}
						else
						{
							[self mtGoArriere:MT_MoveNumber-1];
						}
						return;
					}
				}
				else
				{
					if (number<=MT_MoveNumber)
					{
						// En arriere
						if (MT_Speed!=0)
							return;
						if ((rmStopSpeed&0x8000)!=0)
							[self start];
						else
						{
							[self mtGoArriere:MT_MoveNumber-1];
						}
						return;
					}
					else
					{
						// En avant
						if (MT_Speed!=0)
						{
							[self reverse];
							return;
						}
						if ((rmStopSpeed&0x8000)!=0)
						{
							[self start];
							[self reverse];
						}
						else
							[self mtGoAvant:MT_MoveNumber];
						return;
					}
				}
			}
		}
	}
}

-(void)stop
{
	if (rmStopSpeed==0)
	{
		rmStopSpeed=MT_Speed|0x8000;
	}
	MT_Speed=0;
	hoPtr->rom->rmMoveFlag=YES;
}

-(void)start
{
	if ((rmStopSpeed & 0x8000)!=0)
	{
		MT_Speed=rmStopSpeed&0x7FFF;
		MT_Pause=0;							//; Stoppe la pause
		rmStopSpeed=0;
		hoPtr->rom->rmMoveFlag=YES;
	}
}

-(void)reverse
{
	if (rmStopSpeed==0)
	{
		hoPtr->rom->rmMoveFlag=YES;
		int number=MT_MoveNumber;
		if (MT_Calculs==0)					//; Au milieu ou au debut?
		{
			// On est au debut d'un noeud: on passe au suivant / precedent
			// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			MT_Direction=!MT_Direction;
			if (MT_Direction)
			{
				if (number==0)
				{
					MT_Direction=!MT_Direction;
					return;
				}
				number--;
				[self mtGoArriere:number];
			}
			else
			{
				[self mtGoAvant:number];
			}
		}
		else
		{
			// On est en plein mouvement: on inverse les calculs
			// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			MT_Direction=!MT_Direction;						//; Avant/arriere
			MT_Cosinus=-MT_Cosinus;	//; Les pentes
			MT_Sinus=-MT_Sinus;
			int x1=MT_XOrigin;					//; Les coordonnees
			int x2=MT_XDest;
			MT_XOrigin=x2;
			MT_XDest=x1;
			x1=MT_YOrigin;
			x2=MT_YDest;
			MT_YOrigin=x2;
			MT_YDest=x1;
			hoPtr->roc->rcDir+=16;							//; La direction
			hoPtr->roc->rcDir&=31;
			int calcul=(MT_Calculs>>16)&0xFFFF;
			calcul=MT_Longueur-calcul;
			MT_Calculs=(calcul<<16)|(MT_Calculs&0xFFFF);
		}
	}       
}

// ------------------------------------------
// Changement de position d'un mouvement PATH
// ------------------------------------------
-(void)setXPosition:(int)x
{
	int x2=hoPtr->hoX;
	hoPtr->hoX=x;
	
	x2-=MT_XOrigin;
	x-=x2;
	x2=MT_XDest-MT_XOrigin+x;
	MT_XDest=x2;
	x2=MT_XOrigin;
	MT_XOrigin=x;
	x2-=x;
	MT_XStart-=x2;
	hoPtr->rom->rmMoveFlag=YES;
	hoPtr->roc->rcChanged=YES;
	hoPtr->roc->rcCheckCollides=YES;					//; Force la detection de collision
}

-(void)setYPosition:(int)y
{
	int y2=hoPtr->hoY;
	hoPtr->hoY=y;
	
	y2-=MT_YOrigin;
	y-=y2;
	y2=MT_YDest-MT_YOrigin+y;
	MT_YDest=y2;
	y2=MT_YOrigin;
	MT_YOrigin=y;
	y2-=y;
	MT_YStart-=y2;
	hoPtr->rom->rmMoveFlag=YES;
	hoPtr->roc->rcChanged=YES;
	hoPtr->roc->rcCheckCollides=YES;					//; Force la detection de collision
}

-(void)setSpeed:(int)speed
{
	if (speed<0) 
		speed=0;
	if (speed>250) 
		speed=250;
	MT_Speed=speed;
	hoPtr->roc->rcSpeed=speed;
	hoPtr->rom->rmMoveFlag=YES;
}

-(void)setMaxSpeed:(int)speed
{
	[self setSpeed:speed];   
}


@end
