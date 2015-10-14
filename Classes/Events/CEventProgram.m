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
// CEVENTPROGRAM : Programme des evenements
//
//----------------------------------------------------------------------------------
#import "CEventProgram.h"
#import "CRun.h"
#import "CQualToOiList.h"
#import "CLoadQualifiers.h"
#import "CServices.h"
#import "CRunApp.h"
#import "CRunFrame.h"
#import "CFile.h"
#import "CArrayList.h"
#import "CColMask.h"
#import "COIList.h"
#import "CObjInfo.h"
#import "CLO.h"
#import "CLOList.h"
#import "CObjectCommon.h"
#import "CObject.h"
#import "CRCom.h"
#import "CRMvt.h"
#import "CSprite.h"
#import "IEnum.h"
#import "CArrayList.h"
#import "CSpriteGen.h"
#import "CExtLoader.h"
#import "CSoundBank.h"

extern CALLCOND1_ROUTINE callTable_Condition1[];
extern CALLCOND2_ROUTINE callTable_Condition2[];
extern CALLACTION_ROUTINE callTable_Action[];

@implementation CEventProgram

-(id)initWithApp:(CRunApp*)a
{
	app=a;
	maxObjects=500;
    allocatedStrings=nil;
	return self;
}
-(void)dealloc
{
	[self freeAssembledData];
	if (pEvents!=nil)
	{
		free(pEvents);
        [self freeAllocatedStrings];
	}
	[super dealloc];
}
-(void)setCRun:(CRun*)rh
{
	rhPtr=rh;
}

// Chargement des evenements
-(void)load
{
	char code[4];
	int n = 0;
	int curPos = 0;

	if (pEvents!=nil)
	{
		free(pEvents);
        [self freeAllocatedStrings];
	}
	while (true)
	{
		[app->file readACharBuffer:code withLength:4];
		
		// EVTFILECHUNK_HEAD
		if (code[0] == 'E' && code[1] == 'R' && code[2] == '>' && code[3] == '>')
		{
			maxObjects = [app->file readAShort];
			if (maxObjects < 300)
			{
				maxObjects = 300;
			}
			maxOi = [app->file readAShort];
			nPlayers = [app->file readAShort];
			for (n = 0; n < 7 + OBJ_LAST; n++)
			{
				nConditions[n] = [app->file readAShort];
			}
			nQualifiers = [app->file readAShort];
			if (nQualifiers > 0)
			{
				qualifiers = (CLoadQualifiers**)malloc(nQualifiers*sizeof(CLoadQualifiers*));
				for (n = 0; n < nQualifiers; n++)
				{
					qualifiers[n] = [[CLoadQualifiers alloc] init];
					qualifiers[n]->qOi = [app->file readAShort];
					qualifiers[n]->qType = [app->file readAShort];
				}
			}
		}
		// EVTFILECHUNK_EVTHEAD
		else if (code[0] == 'E' && code[1] == 'R' && code[2] == 'e' && code[3] == 's')
		{
			int size=[app->file readAInt]+4;		// Size
			pEvents = (LPEVG)malloc(size);
			curPos=0;
		}
		// EVTFILECHUNK_EVENTS
		else if (code[0] == 'E' && code[1] == 'R' && code[2] == 'e' && code[3] == 'v')
		{
			int size=[app->file readAInt];		// Size
			[app->file readACharBuffer:(char*)pEvents+curPos withLength:size];
			curPos+=size;
		}
		// EVTFILECHUNK_END
		else if (code[0] == '<' && code[1] == '<' && code[2] == 'E' && code[3] == 'R')
		{
			memset((char*)pEvents+curPos, 0, 2);
			memset((char*)pEvents+curPos+2, 0xFFFFFFFF, 2);
			break;
		}
	}
}

// PREPARATION DU PROGRAMME POUR LE RUN

// Inactive tout un groupe et ses sous-groupes
-(LPEVG)inactiveGroup:(LPEVG)evgPtr
{
	BOOL bQuit;
	LPEVT evtPtr;
	LPGRP grpPtr;
	
	evgPtr->evgFlags &= EVGFLAGS_DEFAULTMASK;
	evgPtr->evgFlags |= EVGFLAGS_INACTIVE;
	
	for (evgPtr=EVGNEXT(evgPtr), bQuit=NO; ;)
	{
		evgPtr->evgFlags &= EVGFLAGS_DEFAULTMASK;
		evgPtr->evgFlags |= EVGFLAGS_INACTIVE;
		
		evtPtr = EVGFIRSTEVT(evgPtr);
		switch (evtPtr->evtCode.evtLCode.evtCode)
		{
			case ((-10 << 16) | 65535):		// CNDL_GROUP:
				grpPtr = (LPGRP)&EVTPARAMS(evtPtr)->evp.evpW.evpW0;
				grpPtr->grpFlags |= GRPFLAGS_PARENTINACTIVE;
				evgPtr = [self inactiveGroup:evgPtr];
				continue;
			case ((-11 << 16) | 65535):		// CNDL_ENDGROUP:
				bQuit = YES;
				evgPtr=EVGNEXT(evgPtr);
				break;
		}
		if (bQuit)
		{
			break;
		}
		evgPtr=EVGNEXT(evgPtr);
	}
	return evgPtr;
}

-(void)prepareProgram
{
	LPEVG evgPtr;
	LPEVT evtPtr;
	LPGRP grpPtr;
	LPEVP evpPtr;
	int evt, evp;
	 
	// Nettoyage des flags groupe
	for (evgPtr = pEvents; evgPtr->evgSize!=0;)
	{
		evgPtr->evgFlags &= EVGFLAGS_DEFAULTMASK;
		
		evtPtr = EVGFIRSTEVT(evgPtr);
		if (evtPtr->evtCode.evtLCode.evtCode == ((-10 << 16) | 65535))	// CNDL_GROUP)
		{
			grpPtr = (LPGRP)&EVTPARAMS(evtPtr)->evp.evpW.evpW0;
			grpPtr->grpFlags &= ~(GRPFLAGS_PARENTINACTIVE | GRPFLAGS_GROUPINACTIVE);
			
			if ((grpPtr->grpFlags & GRPFLAGS_INACTIVE) != 0)
			{
				grpPtr->grpFlags |= GRPFLAGS_GROUPINACTIVE;
			}
		}
		evgPtr=EVGNEXT(evgPtr);
	}
	
	// Activation / desactivation des groupes
	for (evgPtr=pEvents; evgPtr->evgSize!=0;)
	{
		evgPtr->evgFlags &= EVGFLAGS_DEFAULTMASK;
		
		evtPtr = EVGFIRSTEVT(evgPtr);
		if (evtPtr->evtCode.evtLCode.evtCode == ((-10 << 16) | 65535))	// CNDL_GROUP
		{
			grpPtr = (LPGRP)&EVTPARAMS(evtPtr)->evp.evpW.evpW0;
			grpPtr->grpFlags &= ~GRPFLAGS_PARENTINACTIVE;
			
			// Groupe entier inactif?
			if ((grpPtr->grpFlags & GRPFLAGS_GROUPINACTIVE) != 0)
			{
				evgPtr = [self inactiveGroup:evgPtr];
				continue;
			}
		}
		evgPtr=EVGNEXT(evgPtr);
	}
	
	// Mise a zero des flags evenements
	for (evgPtr = pEvents; evgPtr->evgSize!=0; evgPtr=EVGNEXT(evgPtr))
	{
		evtPtr = EVGFIRSTEVT(evgPtr);
		switch (evtPtr->evtCode.evtLCode.evtCode)
		{
			case ((-10 << 16) | 65535):	    // CNDL_GROUP
			case ((-11 << 16) | 65535):	    // CNDL_ENDGROUP
				break;
				
			default:
				evgPtr->evgInhibit = 0;
				evgPtr->evgInhibitCpt = 0;
				for (evt=0; evt<evgPtr->evgNCond+evgPtr->evgNAct; evt++, evtPtr=EVTNEXT(evtPtr))
				{
					// RAZ des flags conditions / actions
					// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					if (evtPtr->evtCode.evtLCode.evtCode < 0)
					{
						evtPtr->evtFlags &= EVFLAGS_DEFAULTMASK;
					}
					else
					{
						evtPtr->evtFlags &= ~(ACTFLAGS_REPEAT | EVFLAGS_NOTDONEINSTART);
					}
							
					// RAZ des parametres speciaux
					// ~~~~~~~~~~~~~~~~~~~~~~~~~~~
					if (evtPtr->evtNParams != 0)
					{
						for (evp=0, evpPtr=EVTPARAMS(evtPtr); evp<evtPtr->evtNParams; evp++, evpPtr=EVPNEXT(evpPtr))
						{
							switch (evpPtr->evpCode)
							{
								case 13:	    // PARAM_EVERY
									evpPtr->evp.evpL.evpL1=evpPtr->evp.evpL.evpL0;
									break;
							}
						}
					}
				}
				break;
		}
	}
}


// ASSEMBLE LE PROGRAMME : BRANCHE LES POINTEURS DANS CHAQUE OBJET , OPTIMISE ET TOUT
-(short)assemblePrograms
{
	LPEVG			evgPtr;
	LPEVT			evtPtr;
	LPEVP			evpPtr;
	LPEXP			expPtr;
	LPPOS			posPtr;
	
	WORD			o, oo;
	short			oi, oi1, oi2;
	short			type, type1, type2;
	short			nOi, i, j, n, num, d, evgF, evgM, q, d1, d2;
	int				code;
	WORD			fWrap;
	WORD			evtAlways, evtAlwaysPos;
	DWORD			cpt, aTimers, ss;
	short*			wPtr;
	short*			wPtr2;
	DWORD*			ulPtr;
	DWORD*			uilPtr;
	
	CObjInfo*		oilPtr;
	LPCDP			cdpPtr;
	
	DWORD* aListPointers=NULL;
	LPDWORD listPos=NULL;
	LPWORD wBufNear=NULL;
	int oil;
	
	do
	{
		rh2ActionCount=0;  				// Force le compte des actions a 0
		
        // Nettoie la curFrame.m_oiList : enleve les blancs, compte les objets
        int oiMax = 0;
        for (nOi = 0  , n=0; n < rhPtr->rhMaxOI; n++)
        {
            if (rhPtr->rhOiList[n]->oilOi != -1)
            {
                rhPtr->rhOiList[n]->oilActionCount = -1;
                rhPtr->rhOiList[n]->oilLimitFlags = 0;
                rhPtr->rhOiList[n]->oilLimitList = -1;
                nOi++;
                if (rhPtr->rhOiList[n]->oilOi + 1 > oiMax)
                {
                    oiMax = rhPtr->rhOiList[n]->oilOi + 1;
                }
            }
        }
		oiMax=MAX(oiMax, nOi);
		
        // Fabrique la liste des oi pour chaque qualifier
        qualToOiList = nil;
        if (nQualifiers > 0)
        {
            short* count = (short*)malloc(nQualifiers*sizeof(short));
            for (q = 0; q < nQualifiers; q++)
            {
                oi = (short) ((qualifiers[q]->qOi) & 0x7FFF);
                count[q] = 0;
                for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
                {
                    if (rhPtr->rhOiList[oil]->oilType == qualifiers[q]->qType)
                    {
                        for (n = 0; n < 8 && rhPtr->rhOiList[oil]->oilQualifiers[n] != -1; n++)      // MAX_QUALIFIERS
                        {
                            if (oi == rhPtr->rhOiList[oil]->oilQualifiers[n])
                            {
                                count[q]++;
                            }
                        }
                    }
                }
            }
			
            qualToOiList = (CQualToOiList**)malloc(nQualifiers*sizeof(CQualToOiList*));
            for (q = 0; q < nQualifiers; q++)
            {
                qualToOiList[q] = [[CQualToOiList alloc] init];
				
                if (count[q] != 0)
                {
                    qualToOiList[q]->qoiList = (short*)malloc( (count[q]*2+2)*sizeof(short) );
					qualToOiList[q]->nQoi=count[q]*2;
                }
				
                i = 0;
                oi = (short) ((qualifiers[q]->qOi) & 0x7FFF);
                for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
                {
                    if (rhPtr->rhOiList[oil]->oilType == qualifiers[q]->qType)
                    {
                        for (n = 0; n < 8 && rhPtr->rhOiList[oil]->oilQualifiers[n] != -1; n++)
                        {
                            if (oi == rhPtr->rhOiList[oil]->oilQualifiers[n])
                            {
                                qualToOiList[q]->qoiList[i * 2] = rhPtr->rhOiList[oil]->oilOi;
                                qualToOiList[q]->qoiList[i * 2 + 1] = (short) oil;
                                i++;
                            }
                        }
                    }
                }
                if (i!=0)
                {
                    qualToOiList[q]->qoiList[i * 2] = -1;
                    qualToOiList[q]->qoiList[i * 2 + 1] = -1;                    
                }
                qualToOiList[q]->qoiActionCount = -1;
            }
			free(count);
        }
		
		// Poke les offsets des oi dans le programme, prepare les parametres / cree les tables de limitations
		// Marque les evenements a traiter dans la boucle
		// --------------------------------------------------------------------------------------------------
		
		// 100 actions STOP par objet...
		LPSHORT colList;
		colBuffer=(short*)calloc((oiMax+1)*100*4, 1);
		
		// Boucle d'exploration du programme
        BOOL bAllocateStrings;
        if (allocatedStrings!=nil)
            bAllocateStrings=NO;
        else
        {
            allocatedStrings=[[CArrayList alloc] init];
            bAllocateStrings=YES;
        }
        
        CCArrayList posStartLoop;
		colList=colBuffer;
		for (evgPtr=pEvents; evgPtr->evgSize!=0; evgPtr=EVGNEXT(evgPtr))
		{   
			// Initialisation des parametres / pointeurs sur oilists/qoioilist
			// -------------------------------------------------------------
			for (evtPtr=EVGFIRSTEVT(evgPtr), i=EVGNEVENTS(evgPtr); i>0; evtPtr=EVTNEXT(evtPtr), i--)
			{
				// Pas de flag BAD
				evtPtr->evtFlags&=~EVFLAGS_BADOBJECT;
				
				// Si evenement pour un objet reel, met l'adresse de l'curFrame.m_oiList
				// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
				if ( EVTTYPE(evtPtr->evtCode.evtLCode.evtCode)>=0 ) 
				{
					evtPtr->evtOiList=[self get_OiListOffset:evtPtr->evtOi withType:EVTTYPE(evtPtr->evtCode.evtLCode.evtCode)];
				}
				
				// Exploration des parametres
				// ~~~~~~~~~~~~~~~~~~~~~~~~~~
				if ( (j=evtPtr->evtNParams)>0 )
				{
					for (evpPtr=EVTPARAMS(evtPtr); j>0; j--, evpPtr=EVPNEXT(evpPtr))
					{
						switch(evpPtr->evpCode)
						{
								// Met un parametre buffer 4 a zero
							case PARAM_BUFFER4:
								evpPtr->evp.evpL.evpL0=0;
								break;
								
								// Trouve le levobj de creation
							case PARAM_SYSCREATE:
								if ( (evtPtr->evtOi&OIFLAG_QUALIFIER)==0 )
								{
									CLO* loPtr;
									cdpPtr=(LPCDP)&evpPtr->evp.evpW.evpW0;
									for (loPtr=[rhPtr->rhFrame->LOList first_LevObj]; loPtr!=0; loPtr=[rhPtr->rhFrame->LOList next_LevObj])
									{
										if (evtPtr->evtOi==(short)loPtr->loOiHandle)
										{
											cdpPtr->cdpHFII=loPtr->loHandle;
											break;
										}
									}
								}
								else
								{
									cdpPtr=(LPCDP)&evpPtr->evp.evpW.evpW0;
									cdpPtr->cdpHFII=-1;
								}
								// Met l'adresse du levObj pour create object
							case PARAM_CREATE:
							case PARAM_SHOOT:
								cdpPtr=(LPCDP)&evpPtr->evp.evpW.evpW0;
								// Si parent==objet, poke l'adresse dans curFrame.m_oiList
							case PARAM_POSITION:
								posPtr=(LPPOS)&evpPtr->evp.evpW.evpW0;
								oi=posPtr->posOINUMParent;
								if (oi!=-1)
								{
									posPtr->posOiList=[self get_OiListOffset:oi withType:posPtr->posTypeParent];
								}
								break;
								
								// Poke l'adresse de l'objet dans l'curFrame.m_oiList
							case PARAM_OBJECT:
								evpPtr->evp.evpW.evpW0=[self get_OiListOffset:evpPtr->evp.evpW.evpW1 withType:evpPtr->evp.evpW.evpW2];
								break;
								
								// Expression : poke l'adresse de l'curFrame.m_oiList dans les parametres objets
							case PARAM_SPEED:
							case PARAM_SAMLOOP:
							case PARAM_MUSLOOP:
							case PARAM_EXPSTRING:
							case PARAM_CMPSTRING:
							case PARAM_EXPRESSION:
							case PARAM_COMPARAISON:
							case PARAM_VARGLOBAL_EXP:
							case PARAM_STRINGGLOBAL_EXP:
							case PARAM_ALTVALUE_EXP:
							case PARAM_ALTSTRING_EXP:
							case PARAM_FLAG_EXP:
								expPtr=(LPEXP)&evpPtr->evp.evpW.evpW1;
								while (expPtr->expCode.expLCode.expCode!=0)
								{
									// Un objet avec OI?
									if (EVTTYPE(expPtr->expCode.expLCode.expCode)>0)
									{
										expPtr->expu.expo.expOiList=[self get_OiListOffset:expPtr->expu.expo.expOi withType:EVTTYPE(expPtr->expCode.expLCode.expCode)];
									}
                                    if (bAllocateStrings && expPtr->expCode.expLCode.expCode==((3<<16)|65535))
                                    {
                                        NSString* string;
                                        if (rhPtr->rhApp->bUnicode==NO)
                                        {
                                            size_t l=strlen((char*)&expPtr->expu.expw.expWParam0);
                                            string=[[NSString alloc] initWithBytes:&expPtr->expu.expw.expWParam0 length:l encoding:NSWindowsCP1252StringEncoding];
                                        }
                                        else 
                                        {
                                            int l=0;
                                            unichar* ptr;
                                            for (ptr=(unichar*)&expPtr->expu.expw.expWParam0; *ptr!=0; ptr++)
                                                l++;                                               
                                            string = [[NSString alloc] initWithCharacters:(unichar*)&expPtr->expu.expw.expWParam0 length:l];
                                        }
                                        [string retain];
                                        expPtr->expu.expw.expWParam0=(short)[allocatedStrings add:string];
                                    }
									expPtr=EXPNEXT(expPtr);
								};
								break;
						}
					}
				}
                if ( evtPtr->evtCode.evtLCode.evtCode == ACTL_STARTLOOP )
                {
                    evpPtr = EVTPARAMS(evtPtr);
                    evpPtr->evp.evpW.evpW0 = 0;
                    LPEXP pToken = (LPEXP)&evpPtr->evp.evpW.evpW1;
                    if ( pToken->expCode.expSCode.expType == -1 && pToken->expCode.expSCode.expNum == 3 && ((LPEXP)((LPBYTE)pToken+pToken->expSize))->expCode.expLCode.expCode == 0 )
                    {
                        CPosStartLoop* pStartLoop = new CPosStartLoop(evpPtr, (NSString*)[allocatedStrings get:pToken->expu.expw.expWParam0]);
                        posStartLoop.Add(pStartLoop);
                        [rhPtr addFastLoop:pStartLoop->m_name withIndexPtr:NULL];
                    }
                }
                else if ( evtPtr->evtCode.evtLCode.evtCode == ACTL_STOPLOOP || evtPtr->evtCode.evtLCode.evtCode == ACTL_SETLOOPINDEX )
                {
                    evpPtr = EVTPARAMS(evtPtr);
                    LPEXP pToken = (LPEXP)&evpPtr->evp.evpW.evpW1;
                    if ( pToken->expCode.expSCode.expType == -1 && pToken->expCode.expSCode.expNum == 3 && ((LPEXP)((LPBYTE)pToken+pToken->expSize))->expCode.expLCode.expCode == 0 )
                    {
                        NSString* pName = (NSString*)[allocatedStrings get:pToken->expu.expw.expWParam0];
                        int idx = -1;
                        if ( [rhPtr addFastLoop:pName withIndexPtr:&idx] != nil )
                        {
                            // Removed in build 284.3, causes issue in GetLoopIndex expression when you restart the frame
                            // Note: addFastLoop must still be called
                            //pToken->expCode.expSCode.expNum = 0; // INT
                            //pToken->expu.expl.expLParam = idx;
                        }
                    }
                }
			}
			
			// Flags par defaut / Listes de limitation
			// ---------------------------------------
			evgF=0;
			evgM=EVGFLAGS_ONCE|EVGFLAGS_LIMITED|EVGFLAGS_STOPINGROUP;
			for (evtPtr=EVGFIRSTEVT(evgPtr), i=EVGNEVENTS(evgPtr); i>0; evtPtr=EVTNEXT(evtPtr), i--)
			{
				type=EVTTYPE(evtPtr->evtCode.evtLCode.evtCode);
				code=evtPtr->evtCode.evtLCode.evtCode;
				n=0;
				if (type>=OBJ_SPR)
				{
					switch (GetEventCode(code))
					{
						case ACTL_EXTSTOP:
						case ACTL_EXTBOUNCE:
							
							evgF|=EVGFLAGS_STOPINGROUP;
							
							// Recherche dans le groupe, la cause du STOP-> limitList
							// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
							oi=evtPtr->evtOi;
							if (oi&OIFLAG_QUALIFIER)
							{
								for (o=[self qual_GetFirstOiList2:evtPtr->evtOiList]; o!=0xFFFF; o=[self qual_GetNextOiList2])
								{
									colList=[self make_ColList1:evgPtr withList:colList andOi:rhPtr->rhOiList[o]->oilOi];
								}
							}
							else
							{
								colList=[self make_ColList1:evgPtr withList:colList andOi:oi];
							}
							break;
						case ACTL_EXTSHUFFLE:
							evgF|=EVGFLAGS_SHUFFLE;
							break;
                        case CNDL_EXTCOLLISION:
                            evpPtr=EVTPARAMS(evtPtr);
                            [self addColList:evtPtr->evtOiList withOiNum:evtPtr->evtOi andOiList2:evpPtr->evp.evpW.evpW0 andOiNum2:evpPtr->evp.evpW.evpW1];
                            [self addColList:evpPtr->evp.evpW.evpW0 withOiNum:evpPtr->evp.evpW.evpW1 andOiList2:evtPtr->evtOiList andOiNum2:evtPtr->evtOi];
                            {
                                // L'objet 1 est-il un sprite?
                                type1=EVTTYPE(evtPtr->evtCode.evtLCode.evtCode);
                                if ([self isTypeRealSprite:type1])
                                    d2=OILIMITFLAGS_QUICKCOL|OILIMITFLAGS_ONCOLLIDE;
                                else
                                    d2=OILIMITFLAGS_QUICKCOL|OILIMITFLAGS_QUICKEXT|OILIMITFLAGS_ONCOLLIDE;
                            }
                            {
                                // L'objet 2 est-il un sprite?
                                evpPtr=EVTPARAMS(evtPtr);
                                type2=evpPtr->evp.evpW.evpW2;
                                if ([self isTypeRealSprite:type2])
                                    d1=OILIMITFLAGS_QUICKCOL|OILIMITFLAGS_ONCOLLIDE;
                                else
                                    d1=OILIMITFLAGS_QUICKCOL|OILIMITFLAGS_QUICKEXT|OILIMITFLAGS_ONCOLLIDE;
                            }
                            n=3;
                            break;
						case CNDL_EXTISCOLLIDING:
						{
							// L'objet 1 est-il un sprite?
							type1=EVTTYPE(evtPtr->evtCode.evtLCode.evtCode);
							if ([self isTypeRealSprite:type1])
							{
								d2=OILIMITFLAGS_QUICKCOL;
							}
							else
							{
								d2=OILIMITFLAGS_QUICKCOL|OILIMITFLAGS_QUICKEXT;
							}
						}
						{
							// L'objet 2 est-il un sprite?
							evpPtr=EVTPARAMS(evtPtr);
							type2=evpPtr->evp.evpW.evpW2;
							if ([self isTypeRealSprite:type2])
							{
								d1=OILIMITFLAGS_QUICKCOL;
							}
							else
							{
								d1=OILIMITFLAGS_QUICKCOL|OILIMITFLAGS_QUICKEXT;
							}
						}
							n=3;
							break;
						case CNDL_EXTINPLAYFIELD:
						case CNDL_EXTOUTPLAYFIELD:
							d1=OILIMITFLAGS_QUICKBORDER;
							n=1;
							break;
						case CNDL_EXTCOLBACK:
							d1=OILIMITFLAGS_QUICKBACK;
							n=1;
							break;
					}
				} 
				else
				{
					switch (code)
					{
						case CNDL_ONCE:
							evgM&=~EVGFLAGS_ONCE;
							break;
						case CNDL_NOTALWAYS:
							evgM|=EVGFLAGS_NOMORE;
							break;
						case CNDL_REPEAT:
							evgM|=EVGFLAGS_NOMORE;
							break;
						case CNDL_NOMORE:
							evgM|=EVGFLAGS_NOTALWAYS+EVGFLAGS_REPEAT;
							break;
						case CNDL_MONOBJECT:
							d2=OILIMITFLAGS_QUICKCOL;
							evpPtr=EVTPARAMS(evtPtr);
							n=2;
							break;
						case CNDL_MCLICKONOBJECT:
							d2=OILIMITFLAGS_QUICKCOL;
							evpPtr=EVPNEXT(EVTPARAMS(evtPtr));
							n=2;
							break;
					}
				}
				// Poke les flags collision
				if (n&1)
				{
					for (o=[self qual_GetFirstOiList:evtPtr->evtOiList]; o!=0xFFFF; o=[self qual_GetNextOiList])
					{
						rhPtr->rhOiList[o]->oilLimitFlags |= d1;
					}
				}
				if (n&2)
				{
					for (o=[self qual_GetFirstOiList:evpPtr->evp.evpW.evpW0]; o!=0xFFFF; o=[self qual_GetNextOiList])
					{
						rhPtr->rhOiList[o]->oilLimitFlags |= d2;
					}
				}
			}
			// Inhibe les anciens flags
			evgPtr->evgFlags&=~evgM;
			evgPtr->evgFlags|=evgF;
		}
		*colList=-1;
	
		// Reserve le buffer des pointeurs sur listes d'events
		// ---------------------------------------------------
		aListPointers=(DWORD*)calloc((NUMBEROF_SYSTEMTYPES+oiMax+1)*4, 1);
			
		// Rempli cette table avec les offsets en fonction des types
		for (type=-NUMBEROF_SYSTEMTYPES, uilPtr=aListPointers, ss=0; type<0; type++, uilPtr++)
		{
			*uilPtr=ss;                                                     
			ss+=nConditions[NUMBEROF_SYSTEMTYPES+type];
		}
		// Continue avec les OI, la taille juste pour le type de l'oi
        for (oil = 0; oil < rhPtr->rhMaxOI; oil++, uilPtr++)
        {
			*uilPtr=ss;
            if (rhPtr->rhOiList[oil]->oilType < KPX_BASE)
            {
                ss += nConditions[NUMBEROF_SYSTEMTYPES + rhPtr->rhOiList[oil]->oilType] + EVENTS_EXTBASE + 1;
            }
            else
            {
				ss += [rhPtr->rhApp->extLoader getNumberOfConditions:rhPtr->rhOiList[oil]->oilType] + EVENTS_EXTBASE + 1;
            }
			n++;
		}
	
		// Reserve le buffer des pointeurs
		DWORD sListPointers;
		sListPointers=ss*4;
		listPointers=(DWORD*)calloc(sListPointers, 1);
		evtAlways=0;
		
		// Explore le programme et repere les evenements
		LPWORD wPtrNear;
		wBufNear=(LPWORD)calloc(maxObjects*2+2, 1);
		for ( evgPtr=pEvents; evgPtr->evgSize!=0; evgPtr=EVGNEXT(evgPtr) )
		{
			evgPtr->evgFlags&=~EVGFLAGS_ORINGROUP;
			BOOL bOrBefore=YES;
			int cndOR=0;
			for (evtPtr=EVGFIRSTEVT(evgPtr), n=0; n<evgPtr->evgNCond; evtPtr=EVTNEXT(evtPtr), n++)
			{
				type=EVTTYPE(evtPtr->evtCode.evtLCode.evtCode);
				code=evtPtr->evtCode.evtLCode.evtCode;
				num=-EVTNUM(code);
				
				if (bOrBefore)
				{
					// Dans la liste des evenements ALWAYS
					if ( (evtPtr->evtFlags&EVFLAGS_ALWAYS)!=0 )
					{
						evtAlways++;
					}
					
					// Dans la liste des evenements generaux si objet systeme
					if (type<0)
					{
						ulPtr=listPointers+*(aListPointers+7+type);		// NUMBEROF_SYSTEMTYPES
						(*(ulPtr+num))++;
					}
					else
						// Un objet normal / qualifier : relie aux objets
					{
						wPtrNear=wBufNear;
						for (o=[self qual_GetFirstOiList:evtPtr->evtOiList]; o!=0xFFFF; o=[self qual_GetNextOiList])
						{
							ulPtr=listPointers+*(aListPointers+NUMBEROF_SYSTEMTYPES+o);		
							(*(ulPtr+num))++;
							*(wPtrNear++)=o;
						}
						*wPtrNear=0xFFFF;
						// Cas special pour les collisions de sprites : branche aux deux sprites (sauf si meme!)
						if (GetEventCode(code)==CNDL_EXTCOLLISION)
						{
							evpPtr=EVTPARAMS(evtPtr);
							for (oo=[self qual_GetFirstOiList:evpPtr->evp.evpW.evpW0]; oo!=0xFFFF; oo=[self qual_GetNextOiList])
							{
								for (wPtrNear=wBufNear; *wPtrNear!=oo && *wPtrNear!=0xFFFF; wPtrNear++) ;
								if (*wPtrNear==0xFFFF)
								{
									ulPtr=listPointers+*(aListPointers+NUMBEROF_SYSTEMTYPES+oo);
									(*(ulPtr+num))++;
								}
							}
						}
					}
				}
				bOrBefore=NO;
				if (evtPtr->evtCode.evtLCode.evtCode==CNDL_OR || evtPtr->evtCode.evtLCode.evtCode==CNDL_ORLOGICAL)
				{
					bOrBefore=YES;
					evgPtr->evgFlags|=EVGFLAGS_ORINGROUP;
					// Un seul type de OR dans un groupe
					if (cndOR==0)
						cndOR=evtPtr->evtCode.evtLCode.evtCode;
					else
						evtPtr->evtCode.evtLCode.evtCode=cndOR;
					// Marque les OR Logical
					if (cndOR==CNDL_ORLOGICAL)
						evgPtr->evgFlags|=EVGFLAGS_ORLOGICAL;
				}
			}
		}
		
		// Calcule les tailles necessaires, poke les pointeurs dans les listes
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		DWORD sEventPointers;
		sEventPointers=evtAlways*8+4;
		for (uilPtr=listPointers, cpt=sListPointers/4; cpt>0; uilPtr++, cpt--)
		{
			if ( *uilPtr!=0 )
			{
				ss=*uilPtr;
				*uilPtr=sEventPointers;
				sEventPointers+=ss*8+4;
			}
		}
		eventPointers=(DWORD*)malloc(sEventPointers);
		memset(eventPointers, (int)0xFFFFFFFF, sEventPointers);
		
		LPDWORD lposPtr=eventPointers;
		listPos=(DWORD*)malloc(sListPointers);
		memmove(listPos, listPointers, sListPointers);

        CPosStartLoop* pPos;

		// 281.4 - fast loops were doubled if there was a frame fade-in transition
		if(rhPtr->rh4PosOnLoop != nil)
		{
			CCArrayList* rh4PosOnLoop = (CCArrayList*)rhPtr->rh4PosOnLoop;
			for (n=0; n < rh4PosOnLoop->Size(); n++)
			{
				CPosOnLoop* pLoop = (CPosOnLoop*)rh4PosOnLoop->Get(n);
				delete pLoop;
			}
			delete rhPtr->rh4PosOnLoop;
			rhPtr->rh4PosOnLoop = nil;
		}

        rhPtr->rh4ComplexOnLoop = NO;



		evtAlwaysPos=0;
		for ( evgPtr=pEvents; evgPtr->evgSize!=0; evgPtr=EVGNEXT(evgPtr) )
		{
			BOOL bOrBefore=YES;
			for (evtPtr=EVGFIRSTEVT(evgPtr), n=0; n<evgPtr->evgNCond; evtPtr=EVTNEXT(evtPtr), n++)
			{
				type=EVTTYPE(evtPtr->evtCode.evtLCode.evtCode);
				code=evtPtr->evtCode.evtLCode.evtCode;
				num=-EVTNUM(code);
				
				if (bOrBefore)
				{
					// Dans la liste des evenements ALWAYS
					if ( (evtPtr->evtFlags&EVFLAGS_ALWAYS)!=0 )
					{
                        
						evtAlways++;
						ulPtr=(LPDWORD)((LPBYTE)eventPointers+evtAlwaysPos);
						*(ulPtr++)=EVGDELTA(evgPtr, pEvents);
						*ulPtr=EVTDELTA(evtPtr, pEvents);
						evtAlwaysPos+=8;
					}
					
					// Dans la liste des evenements generaux si objet systeme
					if (type<0)
					{
						lposPtr=listPos+*(aListPointers+NUMBEROF_SYSTEMTYPES+type)+num;
						ulPtr=(LPDWORD)((LPBYTE)eventPointers+*lposPtr);
						DWORD delta1 = EVGDELTA(evgPtr, pEvents);
						DWORD delta2 = EVTDELTA(evtPtr, pEvents);
						*(ulPtr++) = delta1;
						*ulPtr  = delta2;
						*lposPtr+=8;
                        
                        if (evtPtr->evtCode.evtLCode.evtCode == CNDL_ONLOOP)
						{
							LPEVT evtNext;
							int n;
							BOOL bOR = NO;
							for (evtNext = EVGFIRSTEVT(evgPtr), n = evgPtr->evgNCond; n > 0; evtNext = EVTNEXT(evtNext), n--)
							{
								if (evtNext->evtCode.evtLCode.evtCode == CNDL_OR || evtNext->evtCode.evtLCode.evtCode == CNDL_ORLOGICAL)
									break;
							}
							if (n > 0)
								bOR = YES;
                            
							LPEVP evpPtr = EVTPARAMS(evtPtr);
							LPEXP pToken = (LPEXP)&evpPtr->evp.evpW.evpW1;
                            if ( pToken->expCode.expSCode.expType == -1 && pToken->expCode.expSCode.expNum == 3 && ((LPEXP)((LPBYTE)pToken+pToken->expSize))->expCode.expLCode.expCode == 0 )
							{
								NSString* pName = (NSString*)[allocatedStrings get:pToken->expu.expw.expWParam0];
                                int fastLoopIndex = -1;
                                [rhPtr addFastLoop:pName withIndexPtr:&fastLoopIndex];
								int n;
								for (n = 0; n < posStartLoop.Size(); n++)
								{
									pPos = (CPosStartLoop*)posStartLoop.Get(n);
									if ([pPos->m_name caseInsensitiveCompare:pName] == 0)
									{
										CCArrayList* rh4PosOnLoop = rhPtr->rh4PosOnLoop;
										if ( rh4PosOnLoop == nil)
											rhPtr->rh4PosOnLoop = rh4PosOnLoop = new CCArrayList();
                                        
										int n;
										CPosOnLoop* posOnLoop;
										for (n = 0; n < rh4PosOnLoop->Size(); n++)
										{
											posOnLoop = (CPosOnLoop*)rh4PosOnLoop->Get(n);
											if ([pName caseInsensitiveCompare:posOnLoop->m_name] == 0)
												break;
										}
										if (n == rh4PosOnLoop->Size())
										{
											posOnLoop = new CPosOnLoop(pName, fastLoopIndex);
											rh4PosOnLoop->Add(posOnLoop);
										}
										posOnLoop->AddOnLoop(delta1, bOR);
										posOnLoop->m_bOR|=bOR;
										pPos->m_pEvp->evp.evpW.evpW0 = n + 1;
										break;
									}
								}
							}
							else
							{
								rhPtr->rh4ComplexOnLoop = YES;
							}
						}
					}
					else
						// Un objet normal : relie a l'objet
					{
						wPtrNear=wBufNear;
						for (o=[self qual_GetFirstOiList:evtPtr->evtOiList]; o!=0xFFFF; o=[self qual_GetNextOiList])
						{
							lposPtr=listPos+*(aListPointers+NUMBEROF_SYSTEMTYPES+o)+num;
							ulPtr=(LPDWORD)((LPBYTE)eventPointers+*lposPtr);
							*(ulPtr++)=EVGDELTA(evgPtr, pEvents);
							*ulPtr=EVTDELTA(evtPtr, pEvents);
							*lposPtr+=8;
							*(wPtrNear++)=o;
						}
						*wPtrNear=0xFFFF;
						// Cas special pour les collisions de sprites : branche aux deux sprites (sauf si meme!)
						if (GetEventCode(code)==CNDL_EXTCOLLISION)
						{
							evpPtr=EVTPARAMS(evtPtr);
							for (oo=[self qual_GetFirstOiList:evpPtr->evp.evpW.evpW0]; oo!=0xFFFF; oo=[self qual_GetNextOiList])
							{
								for (wPtrNear=wBufNear; *wPtrNear!=oo && *wPtrNear!=0xFFFF; wPtrNear++) ;
								if (*wPtrNear==0xFFFF)
								{
									lposPtr=listPos+*(aListPointers+NUMBEROF_SYSTEMTYPES+oo)+num;
									ulPtr=(LPDWORD)((LPBYTE)eventPointers+*lposPtr);
									*(ulPtr++)=EVGDELTA(evgPtr, pEvents);
									*ulPtr=EVTDELTA(evtPtr, pEvents);
									*lposPtr+=8;
								}
							}
						}
					}
				}
				bOrBefore=NO;
				if (evtPtr->evtCode.evtLCode.evtCode==CNDL_OR || evtPtr->evtCode.evtLCode.evtCode==CNDL_ORLOGICAL)
				{
					bOrBefore=YES;
				}
			}
		};
		free(wBufNear);
		free(listPos);
        for (n = 0; n < posStartLoop.Size(); n++)
        {
            CPosStartLoop* pLoop = (CPosStartLoop*)posStartLoop.Get(n);
            delete pLoop;
        }
		
		// Adresse des conditions timer
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		uilPtr=listPointers+*(aListPointers+NUMBEROF_SYSTEMTYPES+OBJ_TIMER);
		aTimers=*(uilPtr-EVTNUM(CNDL_TIMER));
		
		// Poke les adresses et les autres flags des pointeurs dans tous OI
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		short* limitList;
		short* limitPos;
		limitBuffer=(short*)malloc((oiMax+1)*2+((char*)colList-(char*)colBuffer)/2);
		limitList=limitBuffer;
        for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
        {
            oilPtr = rhPtr->rhOiList[oil];
			
			// Poke l'offset dans les events
			// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			uilPtr=listPointers+*(aListPointers+NUMBEROF_SYSTEMTYPES+oil);
			oilPtr->oilEvents=(int)((char*)uilPtr-(char*)listPointers);
			
			// Traitement des flags particuliers
			// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			if (oilPtr->oilOEFlags&OEFLAG_MOVEMENTS)
			{
				// Recherche les flags WRAP dans les messages OUT OF PLAYFIELD
				fWrap=0;                           
				ss=*(uilPtr-EVTNUM(CNDL_EXTOUTPLAYFIELD));
				if ( ss!=0 )
				{
					ulPtr=(LPDWORD)((LPBYTE)eventPointers+ss);
					while (*ulPtr!=0xFFFFFFFF)
					{
						evgPtr=EVGOFFSET(pEvents, *ulPtr);
						evtPtr=EVTOFFSET(pEvents, *(ulPtr+1));
						d=EVTPARAMS(evtPtr)->evp.evpW.evpW0;	 	// Prend la direction
						for (evtPtr=[self evg_FindAction:evgPtr withNum:0], n=evgPtr->evgNAct; n>0; n--, evtPtr=EVTNEXT(evtPtr))
						{
							if (evtPtr->evtCode.evtLCode.evtCode==( ACTL_EXTWRAP | (((int)oilPtr->oilType)&0xFFFF) ))
							{
								fWrap|=d;
							}
						}
						ulPtr+=2;
					}
				}
				oilPtr->oilWrap=(BYTE)fWrap;
				
				// Fabrique la table de limitations des mouvements
				// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
				oi1=oilPtr->oilOi;
				for (wPtr=colBuffer, limitPos=limitList; *wPtr!=-1; wPtr+=2)
				{
					if (*wPtr==oi1)
					{
						oi2=*(wPtr+1);
						if (oi2&0x8000)
						{
							oilPtr->oilLimitFlags|=oi2;
							continue;
						}
						for (wPtr2=limitList; wPtr2<limitPos && *wPtr2!=oi2; wPtr2++) 
							;
						if (wPtr2==limitPos) 
							*(limitPos++)=oi2;
					}
				}
				// Marque la fin...
				if (limitPos>limitList)
				{
					oilPtr->oilLimitList=limitList-limitBuffer;
					*limitPos=-1;
					limitList=++limitPos;
				}
			}
		}
		free(colBuffer);
		
		// Met les adresses des tables de pointeur systeme
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		rhEvents[0]=listPointers;		
		for (n=1; n<=NUMBEROF_SYSTEMTYPES; n++)
		{
			rhEvents[n]=(LPDWORD)((LPBYTE)rhEvents[0]+4*(*(aListPointers+NUMBEROF_SYSTEMTYPES-n)));
		}
		free(aListPointers);
				
		// Poke les adresses et les autres flags des pointeurs dans tous les objets definis
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		CObject* hoPtr;
        for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
        {
            oilPtr = rhPtr->rhOiList[oil];
			
            // Explore tous les objets de meme OI dans le programme
            o = oilPtr->oilObject;
            if ((o & 0x8000) == 0)
            {
                do
                {
                    // Met les oi dans les ro
                    hoPtr = rhPtr->rhObjectList[o];
					hoPtr->hoEvents=(LPDWORD)((LPBYTE)rhEvents[0]+oilPtr->oilEvents);					
                    hoPtr->hoOiList = oilPtr;
                    hoPtr->hoLimitFlags = oilPtr->oilLimitFlags;
                    // Flags Wrap pour les objets avec movement
                    if ((hoPtr->hoOEFlags & OEFLAG_MOVEMENTS) != 0)
                    {
                        hoPtr->rom->rmWrapping = oilPtr->oilWrap;
                    }
                    // Si le sprite n'est pas implique dans les collisions -> le passe en neutre
					BOOL bSprites = (hoPtr->hoOEFlags & OEFLAG_SPRITES) != 0;
					BOOL bQuickCol = (hoPtr->hoLimitFlags & OILIMITFLAGS_QUICKCOL) == 0;
                    if (bSprites && bQuickCol)
                    {
                        if (hoPtr->roc->rcSprite != nil)
                        {
                            [hoPtr->roc->rcSprite setSpriteColFlag:0];
                        }
                    }
                    // Sprite en mode inbitate?
                    if ((hoPtr->hoOEFlags & OEFLAG_MANUALSLEEP) == 0)
                    {
                        // On detruit... sauf si...
                        hoPtr->hoOEFlags &= ~OEFLAG_NEVERSLEEP;
						
                        // On teste des collisions avec le decor?
                        if ((hoPtr->hoLimitFlags & OILIMITFLAGS_QUICKBACK) != 0)
                        {
                            // Si masque des collisions general
                            if ((rhPtr->rhFrame->leFlags & LEF_TOTALCOLMASK) != 0)
                            {
                                hoPtr->hoOEFlags |= OEFLAG_NEVERSLEEP;
                            }
                        }
                        // Ou test des collisions normal
                        if ((hoPtr->hoLimitFlags & (OILIMITFLAGS_QUICKCOL | OILIMITFLAGS_QUICKBORDER)) != 0)
                        {
                            hoPtr->hoOEFlags |= OEFLAG_NEVERSLEEP;
                        }
                    }
                    o = hoPtr->hoNumNext;
                } while ((o & 0x8000) == 0);
            }
        }
		
        [self finaliseColList];
        
		// Les messages speciaux
		// ~~~~~~~~~~~~~~~~~~~~~
		if (evtAlways!=0)
		{
			rhEventAlways=eventPointers;
		}
		else
		{
			rhEventAlways=nil;
		}
		// Messages Timer (a bulle!)
		if (aTimers!=0)
			rh4TimerEventsBase=(LPDWORD)((LPBYTE)eventPointers+(DWORD)aTimers);
		else
			rh4TimerEventsBase=0;
		
		bReady=YES;
		
		return 0;
		
	} while (TRUE);	
	return -1;
}
-(void)unBranchPrograms
{
	// Choses generees par AssemblePrograms
	if (qualToOiList!=nil)
	{
		free(qualToOiList);
		qualToOiList=nil;
	}
	if (limitBuffer!=nil)
	{
		free(limitBuffer);
		limitBuffer=nil;
	}
	if (listPointers!=nil)
	{
		free(listPointers);
		listPointers=nil;
	}
	if (eventPointers!=nil)
	{
		free(eventPointers);
		eventPointers=nil;
	}
	if (qualToOiList!=nil)
	{
		int n;
		for (n=0; n<nQualifiers; n++)
		{
			[qualToOiList[n] release];
		}
		free(qualToOiList);
		qualToOiList=nil;
	}
}
-(void)freeAllocatedStrings
{
    if (allocatedStrings!=nil)
    {
        [allocatedStrings clearRelease];
        [allocatedStrings release];
        allocatedStrings=nil;
    }
    
}
-(void)freeAssembledData
{
	bReady=NO;

	[self unBranchPrograms];
    
	if (qualifiers!=nil)
	{
		free(qualifiers);
		qualifiers=nil;
	}
	if (pEvents!=nil)
	{
		free(pEvents);
		pEvents=nil;
	}
	if (rh2PushedEvents!=nil)
	{
		[rh2PushedEvents freeRelease];
		[rh2PushedEvents release];
		rh2PushedEvents=nil;
	}
	
	if (rh2ShuffleBuffer!=nil)
	{
		[rh2ShuffleBuffer release];
		rh2ShuffleBuffer=nil;
	}
}

-(void)addColList:(short)oiList withOiNum:(short)oiNum andOiList2:(short)oiList2 andOiNum2:(short)oiNum2
{
	// Must not do it in fade in mode, otherwise FinaliseColList is called twice...
	if ( rhPtr->rhGameFlags & GAMEFLAGS_FIRSTLOOPFADEIN )
		return;
    
	// First object = qualifier?
    int n;
    short* pOinOil;
	if ( oiNum < 0 )
	{
		if ( qualToOiList != nil )
		{
			CQualToOiList* qoil=qualToOiList[oiList&0x7FFF];			
            for (n=0, pOinOil = qoil->qoiList; n<qoil->nQoi; n+=2, pOinOil+=2)
			{
				[self addColList:*(pOinOil+1) withOiNum:*pOinOil andOiList2:oiList2 andOiNum2:oiNum2];
			}
		}
		return;
	}
    
	// Second object = qualifier?
	if ( oiNum2 < 0 )
	{
		if ( qualToOiList != nil )
		{
			CQualToOiList* qoil=qualToOiList[oiList2&0x7FFF];			
            for (n=0, pOinOil = qoil->qoiList; n<qoil->nQoi; n+=2, pOinOil+=2)
			{
				[self addColList:oiList withOiNum:oiNum andOiList2:*(pOinOil+1) andOiNum2:*pOinOil];
			}
		}
		return;
	}
    
	// Normal objects
	short* colList;
	short currentSize;
	CObjInfo* oilPtr = rhPtr->rhOiList[oiList];
       
	// Allocate buffer for 10 objects
	if (oilPtr->oilColList==nil)
	{
		oilPtr->oilColList = (short*)malloc(sizeof(short)*(2+2*10));
		colList = oilPtr->oilColList;
		*colList = 10;
		*(colList+1) = 0;
	}
	else
	{
		colList = oilPtr->oilColList;
		currentSize = *(colList+1);
        
		// Exit if object already in list
		int n;
		for (n=0; n<currentSize; n++)
		{
			if (oiNum2==*(colList+2+n*2))
			{
				return;
			}
		}
        
		// Reallocate if necessary
		short maxSize = *colList;
		if ( currentSize >= maxSize )
		{
			maxSize += 10;
			colList = (short*)realloc(colList, sizeof(short)*(2+2*maxSize));
			oilPtr->oilColList = colList;
			*colList = maxSize;
		}
	}
    
	currentSize = *(colList+1);
	*(colList+2+currentSize*2) = oiNum2;
	*(colList+2+currentSize*2+1) = oiList2;
	*(colList+1) += 1;
}

-(void)finaliseColList
{    
	CObjInfo* oilPtr;
    int n;
    for (n=0; n<rhPtr->rhMaxOI; n++)
    {
        oilPtr=rhPtr->rhOiList[n];
		if (oilPtr!=nil)
		{
            if (oilPtr->oilColList!=nil)
            {
                short* colList1 = oilPtr->oilColList;
                short numEntries = *(colList1+1);
                oilPtr->oilColList = (short*)malloc(sizeof(short)*(numEntries+1)*2);
                memcpy(oilPtr->oilColList, colList1+2, numEntries * sizeof(short) * 2);
                oilPtr->oilColList[numEntries*2] = -1;
                oilPtr->oilColList[numEntries*2+1] = -1;
                free(colList1);
            }
		}
	}
}

-(LPEVT)evg_FindAction:(LPEVG)evgPtr withNum:(int)n
{
	LPEVT evtPtr;
	int m;
	
	for (evtPtr=EVGFIRSTEVT(evgPtr), m=evgPtr->evgNCond; m>0; m--, evtPtr=EVTNEXT(evtPtr))
		;
	for (m=evgPtr->evgNAct; n>0 && m>0; n--, m--, evtPtr=EVTNEXT(evtPtr))
		;
	return evtPtr;
}

-(short)get_OiListOffset:(short)oi withType:(short)type
{	
	// Un qualifier
	if ((oi & OIFLAG_QUALIFIER) != 0)
	{
		int q;
		for (q = 0; oi != qualifiers[q]->qOi || type != qualifiers[q]->qType; q++);
		return (short) (q | 0x8000);
	}
	// Un objet normal
	else
	{
		int n;
		for (n = 0; n < rhPtr->rhMaxOI && rhPtr->rhOiList[n]->oilOi != oi; n++);
		return (short) n;
	}
}

-(BOOL)isTypeRealSprite:(short)type
{
	int oil;
	for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
	{
		if (rhPtr->rhOiList[oil]->oilOi != -1)
		{
			if (rhPtr->rhOiList[oil]->oilType == type)
			{
				if ((rhPtr->rhOiList[oil]->oilOEFlags & OEFLAG_SPRITES) != 0 && (rhPtr->rhOiList[oil]->oilOEFlags & OEFLAG_QUICKDISPLAY) == 0)
				{
					return YES;
				}
				else
				{
					return NO;
				}
			}
		}
	}
	return YES;
}

-(WORD)qual_GetFirstOiList:(short)o
{
	if ((o & 0x8000) == 0)
	{
		qualOilPtr = -1;
		return (o);
	}
	if (o == -1)
	{
		return -1;
	}
	
	o &= 0x7FFF;
	qualOilPtr = o;
	qualOilPos = 0;
	return [self qual_GetNextOiList];
}

-(WORD)qual_GetNextOiList
{
	short o;
	
	if (qualOilPtr == -1)
	{
		return -1;
	}
	if (qualOilPos >= qualToOiList[qualOilPtr]->nQoi)
	{
		return -1;
	}
	o = qualToOiList[qualOilPtr]->qoiList[qualOilPos + 1];
	qualOilPos += 2;
	return (o);
}

-(WORD)qual_GetFirstOiList2:(short)o
{
	if ((o & 0x8000) == 0)
	{
		qualOilPtr2 = -1;
		return (o);
	}
	if (o == -1)
	{
		return -1;
	}
	
	o &= 0x7FFF;
	qualOilPtr2 = o;
	qualOilPos2 = 0;
	return [self qual_GetNextOiList2];
}

-(WORD)qual_GetNextOiList2
{
	short o;
	
	if (qualOilPtr2 == -1)
	{
		return -1;
	}
	if (qualOilPos2 >= qualToOiList[qualOilPtr2]->nQoi)
	{
		return -1;
	}
	o = qualToOiList[qualOilPtr2]->qoiList[qualOilPos2 + 1];
	qualOilPos2 += 2;
	return (o);
}

// Fabrique la liste des collisions par sprite: ouvre les qualifiers
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(LPSHORT)make_ColList1:(LPEVG)evgPtr withList:(LPSHORT)colList andOi:(short)oi1
{
	short	oi2;
	short	flag, cpt;
	int		code;
	WORD	o;
	LPEVT	evtPtr;
	LPEVP	evpPtr;
	
	for (evtPtr=EVGFIRSTEVT(evgPtr), cpt=evgPtr->evgNCond; cpt>0; evtPtr=EVTNEXT(evtPtr), cpt--)
	{
		if (EVTTYPE(evtPtr->evtCode.evtLCode.evtCode)>=OBJ_SPR)
		{
			flag=(short)(0x8000+OILIMITFLAGS_BACKDROPS);
			code=GetEventCode(evtPtr->evtCode.evtLCode.evtCode);
			switch(code)
			{
				case CNDL_EXTCOLLISION:
					evpPtr=EVTPARAMS(evtPtr);
					for (o=[self qual_GetFirstOiList:evtPtr->evtOiList]; o!=0xFFFF; o=[self qual_GetNextOiList])
					{
						oi2 = rhPtr->rhOiList[o]->oilOi;
						if (oi1==oi2)
						{
							flag=0;
							colList=[self make_ColList2:colList withOi:oi1 andOiList:evpPtr->evp.evpW.evpW0];
						}
					}
					if (flag==0) break;
					for (o=[self qual_GetFirstOiList:evpPtr->evp.evpW.evpW0]; o!=0xFFFF; o=[self qual_GetNextOiList])
					{
						oi2 = rhPtr->rhOiList[o]->oilOi;
						if (oi1==oi2) colList=[self make_ColList2:colList withOi:oi1 andOiList:evtPtr->evtOiList];
					}
					break;
				case CNDL_EXTOUTPLAYFIELD:
					flag=0x8000+EVTPARAMS(evtPtr)->evp.evpW.evpW0;
				case CNDL_EXTCOLBACK:
					for (o=[self qual_GetFirstOiList:evtPtr->evtOiList]; o!=0xFFFF; o=[self qual_GetNextOiList])
					{
						oi2 = rhPtr->rhOiList[o]->oilOi;
						if (oi1==oi2)
						{
							*(colList++)=oi1;
							*(colList++)=flag;
						}
					}
					break;
			}
		}
	}
	return(colList);
}

-(LPSHORT)make_ColList2:(LPSHORT)colList withOi:(OINUM)oi1 andOiList:(WORD)ol
{
	short	oi2;
	WORD	o;
	for (o=[self qual_GetFirstOiList:ol]; o!=0xFFFF; o=[self qual_GetNextOiList])
	{
		oi2 = rhPtr->rhOiList[o]->oilOi;
		
		LPSHORT wPtr;
		for (wPtr=colBuffer; wPtr<colList; wPtr+=2)
		{
			if (*wPtr==oi1 && *(wPtr+1)==oi2)
				break;
		}
		if (wPtr==colList)
		{
			*(colList++)=oi1;
			*(colList++)=oi2;
		}
	}
	return(colList);
}


// POSITIONNE LES FLAGS DE MASQUE DE COLLISION
///////////////////////////////////////////////
-(int)getCollisionFlags
{
	int i, j;
	LPEVG evgPtr;
	LPEVT evtPtr;
	LPEVP evpPtr;
	int flags=0;

	for (evgPtr=pEvents; evgPtr->evgSize!=0; evgPtr=EVGNEXT(evgPtr))
	{   
		for (evtPtr=EVGFIRSTEVT(evgPtr), i=EVGNEVENTS(evgPtr); i>0; evtPtr=EVTNEXT(evtPtr), i--)
		{
			for (evpPtr=EVTPARAMS(evtPtr), j=evtPtr->evtNParams; j>0; j--, evpPtr=EVPNEXT(evpPtr))
			{
				if (evpPtr->evpCode==PARAM_PASTE)
				{
					switch(evpPtr->evp.evpW.evpW0)
					{
						case 1:
							flags|=CM_OBSTACLE;
							break;
						case 2:
							flags|=CM_PLATFORM;
							break;
					}
				}
			}
		}
	}
	return flags;
}

// ENUMERATION DES SONS
-(void)enumSounds:(CSoundBank*)bank
{
	LPEVG evgPtr;
	LPEVT evtPtr;
	LPEVP evpPtr;
	int evt, p;
	
	for (evgPtr=pEvents; evgPtr->evgSize!=0; evgPtr=EVGNEXT(evgPtr))
	{
		for (evtPtr=EVGFIRSTEVT(evgPtr), evt=evgPtr->evgNCond+evgPtr->evgNAct; evt>0; evtPtr=EVTNEXT(evtPtr), evt--)
		{
			for (evpPtr=EVTPARAMS(evtPtr), p=evtPtr->evtNParams; p>0; p--, evpPtr=EVPNEXT(evpPtr))
			{
				switch (evpPtr->evpCode)
				{
					case 6:	    // PARAM_SAMPLE
					case 35:    // PARAM_CNDSAMPLE
						[bank setToLoad:evpPtr->evp.evpW.evpW0];
						[bank setFlags:evpPtr->evp.evpW.evpW0 flags:evpPtr->evp.evpW.evpW1];
						break;
				}
			}
		}
	}
}


// ---------------------------------------------------------------------------
// OBJECT SELECTION FOR EVENTS AND ACTIONS
// ---------------------------------------------------------------------------

-(BOOL)bts:(int*)array withIndex:(int)index
{
	int d = index / 32;
	int mask = 1 << (index & 31);
	BOOL b = (array[d] & mask) != 0;
	array[d] |= mask;
	return b;
}

// -------------------------------------------------------------
// EVENEMENT : RECHERCHE D'UN TYPE DEFINI D'OBJETS, AX=TYPE
// -------------------------------------------------------------
-(CObject*)evt_FirstObjectFromType:(short)nType
{
	rh2EventType = nType;
	if (nType == -1)
	{
		CObject* pHo;
		CObject* pHoStore = nil;
		int oil;
		CObjInfo* poil;
		BOOL bStore = YES;
		for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
		{
			poil = rhPtr->rhOiList[oil];
			if ([self bts:rh4PickFlags withIndex:poil->oilType] == NO)	// Deja vue dans ce groupe d'event (met le flag aussi!) ?
			{
				pHo = [self evt_SelectAllFromType:poil->oilType withFlag:bStore];
				if (pHo != nil)
				{
					pHoStore = pHo;
					bStore = NO;
				}
			}
		}
		if (pHoStore != nil)
		{
			return pHoStore;
		}
	}
	else
	{
		if ([self bts:rh4PickFlags withIndex:nType] == NO)                    // Deja vue dans ce groupe d'event (met le flag aussi!) ?
		{
			return [self evt_SelectAllFromType:nType withFlag:YES];		// NON, on selectionne tout et on retourne le premier
		}
	}

	int oil = 0;
	CObjInfo* oilPtr;
	do
	{
		oilPtr = rhPtr->rhOiList[oil];
		if (oilPtr->oilType == nType)
		{
			if (oilPtr->oilListSelected >= 0)
			{
				CObject* pHo = rhPtr->rhObjectList[oilPtr->oilListSelected];
				rh2EventPrev = nil;
				rh2EventPrevOiList = oilPtr;
				rh2EventPos = pHo;
				rh2EventPosOiList = oil;
				return pHo;
			}
		}
		oil++;									// Un autre OI?
	} while (oil < rhPtr->rhMaxOI);
	return nil;
}

// Retourne le suivant
// ------------------- 
-(CObject*)evt_NextObjectFromType
{
	CObject* pHo = rh2EventPos;
	CObjInfo* oilPtr;
	if (pHo == nil)
	{
		oilPtr = rhPtr->rhOiList[rh2EventPosOiList];
		if (oilPtr->oilListSelected >= 0)
		{
			pHo = rhPtr->rhObjectList[oilPtr->oilListSelected];
			rh2EventPrev = nil;				// Stocke pour la destruction
			rh2EventPrevOiList = oilPtr;
			rh2EventPos = pHo;
			return pHo;
		}
	}
	if (pHo != nil)
	{
		if (pHo->hoNextSelected >= 0)
		{
			rh2EventPrev = pHo;				// Stocke pour la destruction
			rh2EventPrevOiList = nil;
			pHo = rhPtr->rhObjectList[pHo->hoNextSelected];
			rh2EventPos = pHo;
			return pHo;
		}
	}
	
	int oil = rh2EventPosOiList;			// Adresse de l'oilist
	short nType = rhPtr->rhOiList[oil]->oilType;
	oil++;
	while (oil < rhPtr->rhMaxOI)
	{
		if ((rh2EventType != -1 && rhPtr->rhOiList[oil]->oilType == nType) || rh2EventType == -1)
		{
			if (rhPtr->rhOiList[oil]->oilListSelected >= 0)
			{
				pHo = rhPtr->rhObjectList[rhPtr->rhOiList[oil]->oilListSelected];
				rh2EventPrev = nil;
				rh2EventPrevOiList = rhPtr->rhOiList[oil];
				rh2EventPos = pHo;
				rh2EventPosOiList = oil;
				return pHo;
			}
		}
		oil++;									// Un autre OI?
	}
	return nil;
}

// Selectionne TOUS les objets de meme type, retourne le premier dans EAX
// ----------------------------------------------------------------------
-(CObject*)evt_SelectAllFromType:(short)nType withFlag:(BOOL)bStore
{
	int first = -1;
	int evtCount = rh2EventCount;
	
	int oil = 0;
	CObjInfo* oilPtr;
	CObject* pHo;
	do
	{
		oilPtr = rhPtr->rhOiList[oil];
		if (oilPtr->oilType == nType && oilPtr->oilEventCount != evtCount) // Deja selectionne dans cet event?
		{
			oilPtr->oilEventCount = evtCount;					// Fabrique la liste
			if (rh4ConditionsFalse)
			{
				oilPtr->oilListSelected = -1;
				oilPtr->oilNumOfSelected = 0;
			}
			else
			{
				oilPtr->oilNumOfSelected = oilPtr->oilNObjects;
				short num = oilPtr->oilObject;
				if (num >= 0)
				{
					if (first == -1 && bStore == YES)
					{
						first = num;					// Stocke le premier pour aller plus vite
						rh2EventPrev = nil;
						rh2EventPrevOiList = oilPtr;
						rh2EventPosOiList = oil;
					}
					do
					{
						pHo = rhPtr->rhObjectList[num];
						pHo->hoNextSelected = pHo->hoNumNext;
						num = pHo->hoNumNext;
					} while (num >= 0);
					
					num = oilPtr->oilObject;
				}
				oilPtr->oilListSelected = num;
			}
		}
		oil++;										// Un autre OI?
	} while (oil < rhPtr->rhMaxOI);
	
	if (bStore == NO)
	{
		return nil;
	}
	if (first < 0)
	{
		return nil;
	}
	
	pHo = rhPtr->rhObjectList[first];
	rh2EventPos = pHo;
	return pHo;
}

// -------------------------------------------------------------
// EVENEMENT : RECHERCHE DEFINI, EDX=OI
// -------------------------------------------------------------
-(CObject*)evt_FirstObject:(short)sEvtOiList
{
	CObject* pHo;
	
	evtNSelectedObjects = 0;
	rh2EventQualPos = nil;
	rh2EventQualPosNum = -1;
	
	if (sEvtOiList&0x8000)
	{
		// Selectionne TOUS les objets � partir d'un qualifier
		// ---------------------------------------------------
		if (sEvtOiList == (short) -1)	// -1: pas d'objet du tout dans le jeu!
		{
			return nil;
		}
		// Appel de la procedure
		return [self qualProc:sEvtOiList];
	}
	
	CObjInfo* oilPtr = rhPtr->rhOiList[sEvtOiList];
	if (oilPtr->oilEventCount == rh2EventCount)		// Deja selectionne dans cet event?
	{
		// Prend la liste deja exploree dans un event precedent
		// ----------------------------------------------------
		if (oilPtr->oilListSelected < 0)
		{
			return nil;
		}
		pHo = rhPtr->rhObjectList[oilPtr->oilListSelected];
		rh2EventPrev = nil;
		rh2EventPrevOiList = oilPtr;
		rh2EventPos = pHo;
		rh2EventPosOiList = sEvtOiList;
		evtNSelectedObjects = oilPtr->oilNumOfSelected;
		return pHo;
	}
	else
	{
		// Selectionne TOUS les objets de meme type, retourne le premier dans EAX
		// ----------------------------------------------------------------------
		oilPtr->oilEventCount = rh2EventCount;
		
		// Si condition OR et conditions fausse, ne selectionne aucun objet
		if (rh4ConditionsFalse)
		{
			oilPtr->oilListSelected = -1;
			oilPtr->oilNumOfSelected = 0;
			return nil;
		}
		
		// Ajoute les objets
		oilPtr->oilListSelected = oilPtr->oilObject;
		if (oilPtr->oilObject < 0)
		{
			oilPtr->oilNumOfSelected = 0;
			return nil;
		}
		short num = oilPtr->oilObject;
		do
		{
			pHo = rhPtr->rhObjectList[num];
			num = pHo->hoNumNext;
			pHo->hoNextSelected = num;
		} while (num >= 0);
		
		pHo = rhPtr->rhObjectList[oilPtr->oilObject];
		rh2EventPrev = nil;
		rh2EventPrevOiList = oilPtr;
		rh2EventPos = pHo;
		rh2EventPosOiList = sEvtOiList;
		oilPtr->oilNumOfSelected = oilPtr->oilNObjects;
		evtNSelectedObjects = oilPtr->oilNumOfSelected;
		return pHo;
	}
}

-(CObject*)qualProc:(short)sEvtOiList
{
	CObject* pHo;
	CObjInfo* oilPtr;
	int count = 0;
	
	// Selectionne / Compte tous les objets de tous les groupes
	int qoi = 0;
	short qoiList;
	int addCount;
	CQualToOiList* pQoi = qualToOiList[sEvtOiList & 0x7FFF];
	while (qoi < pQoi->nQoi)
	{
		qoiList = pQoi->qoiList[qoi + 1];
		oilPtr = rhPtr->rhOiList[qoiList];
		if (oilPtr->oilEventCount == rh2EventCount)
		{
			// Deja selectionnee dans un evenement precedent
			addCount = 0;
			if (oilPtr->oilListSelected >= 0)
			{
				addCount = oilPtr->oilNumOfSelected;
				if (rh2EventQualPos == nil)
				{
					rh2EventQualPos = pQoi;
					rh2EventQualPosNum = qoi;
				}
			}
		}
		else
		{
			addCount = 0;
			oilPtr->oilEventCount = rh2EventCount;
			
			// Si condition OR et conditions fausse, ne selectionne aucun objet
			if (rh4ConditionsFalse)
			{
				oilPtr->oilListSelected = -1;
				oilPtr->oilNumOfSelected = 0;
			}
			else
			{
				oilPtr->oilListSelected = oilPtr->oilObject;
				if (oilPtr->oilObject < 0)
				{
					oilPtr->oilNumOfSelected = 0;
				}
				else
				{
					if (rh2EventQualPos == nil)
					{
						rh2EventQualPos = pQoi;
						rh2EventQualPosNum = qoi;
					}
					short num = oilPtr->oilObject;
					do
					{
						pHo = rhPtr->rhObjectList[num];
						pHo->hoNextSelected = pHo->hoNumNext;
						num = pHo->hoNumNext;
					} while (num >= 0);
					
					oilPtr->oilNumOfSelected = oilPtr->oilNObjects;
					addCount = oilPtr->oilNObjects;
				}
			}
		}
		count += addCount;
		qoi += 2;
	}
	
	pQoi = rh2EventQualPos;
	if (pQoi != nil)
	{
		oilPtr = rhPtr->rhOiList[pQoi->qoiList[rh2EventQualPosNum + 1]];
		rh2EventPrev = nil;
		rh2EventPrevOiList = oilPtr;
		pHo = rhPtr->rhObjectList[oilPtr->oilListSelected];
		rh2EventPos = pHo;
		rh2EventPosOiList = pQoi->qoiList[rh2EventQualPosNum + 1];
		evtNSelectedObjects = count;
		return pHo;
	}
	return nil;
}

// ------------------------
// RETOURNE L'OBJET SUIVANT
// ------------------------
-(CObject*)evt_NextObject
{
	CObject* pHo = rh2EventPos;
	CObjInfo* oilPtr;
	if (pHo == nil)
	{
		oilPtr = rhPtr->rhOiList[rh2EventPosOiList];
		if (oilPtr->oilListSelected >= 0)
		{
			pHo = rhPtr->rhObjectList[oilPtr->oilListSelected];
			rh2EventPrev = nil;				// Stocke pour la destruction
			rh2EventPrevOiList = oilPtr;
			rh2EventPos = pHo;
			return pHo;
		}
	}
	if (pHo != nil)
	{
		if (pHo->hoNextSelected >= 0)
		{
			rh2EventPrev = pHo;				// Stocke pour la destruction
			rh2EventPrevOiList = nil;
			pHo = rhPtr->rhObjectList[pHo->hoNextSelected];
			rh2EventPos = pHo;
			return pHo;
		}
	}
	if (rh2EventQualPos == nil)			// Une liste de qualifiers?
	{
		return nil;
	}
	
	// Prend la liste de qualifier suivante
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	do
	{
		rh2EventQualPosNum += 2;
		if (rh2EventQualPosNum >= rh2EventQualPos->nQoi)
		{
			return nil;
		}
		oilPtr = rhPtr->rhOiList[rh2EventQualPos->qoiList[rh2EventQualPosNum + 1]];
	} while (oilPtr->oilListSelected < 0);
	
	rh2EventPrev = nil;
	rh2EventPrevOiList = oilPtr;
	pHo = rhPtr->rhObjectList[oilPtr->oilListSelected];
	rh2EventPos = pHo;
	rh2EventPosOiList = rh2EventQualPos->qoiList[rh2EventQualPosNum + 1];
	return pHo;
}

// -------------------------------------------------
// SELECTIONNE TOUS LES OBJETS RELIES A UN QUALIFIER
// -------------------------------------------------
-(void)evt_AddCurrentQualifier:(short)qual
{
	CQualToOiList* pQoi = qualToOiList[qual & 0x7FFF];
	int noil = 0;
	CObjInfo* oilPtr;
	while (noil < pQoi->nQoi)
	{
		oilPtr = rhPtr->rhOiList[pQoi->qoiList[noil + 1]];
		if (oilPtr->oilEventCount != rh2EventCount)
		{
			oilPtr->oilEventCount = rh2EventCount;
			oilPtr->oilNumOfSelected = 0;
			oilPtr->oilListSelected = -1;
		}
		noil += 2;
	}
}

// ----------------------------------------------------------
// ENLEVE L'OBJET COURANT DE LA LISTE DES OBJETS SELECTIONNES
// ----------------------------------------------------------
-(void)evt_DeleteCurrentObject
{
	rh2EventPos->hoOiList->oilNumOfSelected -= 1;					// Un de moins dans l'OiList
	if (rh2EventPrev != nil)
	{
		rh2EventPrev->hoNextSelected = rh2EventPos->hoNextSelected;
		rh2EventPos = rh2EventPrev;                                           // Car le courant est vire!
	}
	else
	{
		//            rhPtr.rhOiList[rh2EventPosOiList].oilListSelected=rh2EventPos.hoNextSelected;
		rh2EventPrevOiList->oilListSelected = rh2EventPos->hoNextSelected;
		rh2EventPos = nil;
	}
}

// -----------------------------------------------
// ADDITIONNE L'OBJET EAX A LA LISTE SI NECESSAIRE
// -----------------------------------------------
-(void)evt_AddCurrentObject:(CObject*)pHo
{
	CObjInfo* oilPtr = pHo->hoOiList;
	if (oilPtr->oilEventCount != rh2EventCount)
	{
		// Aucune selection
		oilPtr->oilEventCount = rh2EventCount;
		oilPtr->oilListSelected = pHo->hoNumber;
		oilPtr->oilNumOfSelected = 1;
		pHo->hoNextSelected = -1;
	}
	else
	{
		// Objet deja selectionne, evite les doublets
		short oils = oilPtr->oilListSelected;
		if (oils < 0)
		{
			oilPtr->oilListSelected = pHo->hoNumber;
			oilPtr->oilNumOfSelected += 1;
			pHo->hoNextSelected = -1;
		}
		else
		{
			CObject* pHo1;
			do
			{
				if (pHo->hoNumber == oils)
				{
					return;
				}
				pHo1 = rhPtr->rhObjectList[oils];
				oils = pHo1->hoNextSelected;
			} while (oils >= 0);
			
			pHo1->hoNextSelected = pHo->hoNumber;
			pHo->hoNextSelected = -1;
			pHo->hoOiList->oilNumOfSelected += 1;
		}
	}
}

// -------------------------------------------
// FORCE L'OBJET EAX SEUL DANS SA PROPRE LISTE
// -------------------------------------------
-(void)deselectThem:(short)oil
{
	CObjInfo* poil = rhPtr->rhOiList[oil];		// Pointe la liste
	poil->oilEventCount = rh2EventCount;
	poil->oilListSelected = -1;
	poil->oilNumOfSelected = 0;
}

-(void)evt_ForceOneObject:(short)oil withObject:(CObject*)pHo
{
	// Deselectionne tous les objets de meme oil
	if (oil >= 0)
	{
		// Un identifier normal
		[self deselectThem:oil];
	}
	else
	{
		// Un qualifier
		if (oil == -1)
		{
			return;
		}
		CQualToOiList* pqoi = qualToOiList[oil & 0x7FFF];
		int qoi;
		for (qoi = 0; qoi < pqoi->nQoi; qoi += 2)
		{
			[self deselectThem:pqoi->qoiList[qoi + 1]];
		}
	}
	
	// Selects the only one
	pHo->hoNextSelected = -1;
	pHo->hoOiList->oilListSelected = pHo->hoNumber;
	pHo->hoOiList->oilNumOfSelected = 1;
	pHo->hoOiList->oilEventCount = rh2EventCount;
}

// -----------------------------------------------
// FORCE TOUT UN TYPE EN PICK, DESELECTIONNE TOUT
// -----------------------------------------------
-(void)evt_DeleteCurrentType:(short)nType
{
	[self bts:rh4PickFlags withIndex:nType];
	
	int oil;
	CObjInfo* oilPtr;
	for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
	{
		oilPtr = rhPtr->rhOiList[oil];
		if (oilPtr->oilType == nType)
		{
			oilPtr->oilEventCount = rh2EventCount;
			oilPtr->oilListSelected = -1;
			oilPtr->oilNumOfSelected = 0;
		}
	}
}

// Deslectionne tous les objets courants
-(void)evt_DeleteCurrent
{
	rh4PickFlags[0] = -1;
	rh4PickFlags[1] = -1;
	rh4PickFlags[2] = -1;
	rh4PickFlags[3] = -1;
	
	int oil;
	CObjInfo* oilPtr;
	for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
	{
		oilPtr = rhPtr->rhOiList[oil];
		oilPtr->oilEventCount = rh2EventCount;
		oilPtr->oilListSelected = -1;
		oilPtr->oilNumOfSelected = 0;
	}
}

// ---------------------------------------------------
// Gestion des OU dans les objets
// ---------------------------------------------------
-(void)evt_MarkSelectedObjects
{
	short num;
	CObject* pHO;
	int oil;
	CObjInfo* oilPtr;
	
	for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
	{
		oilPtr = rhPtr->rhOiList[oil];
		if (oilPtr->oilEventCount == rh2EventCount)
		{
			if (oilPtr->oilEventCountOR != rh4EventCountOR)
			{
				oilPtr->oilEventCountOR = rh4EventCountOR;
				num = oilPtr->oilObject;
				while (num >= 0)
				{
					pHO = rhPtr->rhObjectList[num];
					pHO->hoSelectedInOR = 0;
					num = pHO->hoNumNext;
				}
			}
			num = oilPtr->oilListSelected;
			while (num >= 0)
			{
				pHO = rhPtr->rhObjectList[num];
				pHO->hoSelectedInOR = 1;
				num = pHO->hoNextSelected;
			}
		}
	}
}

// Branche les objets selectionnes dans les OU
-(void)evt_BranchSelectedObjects
{
	short num;
	CObject* pHO;
	CObject* pHOPrev;
	int oil;
	CObjInfo* oilPtr;
	
	for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
	{
		oilPtr = rhPtr->rhOiList[oil];
		if (oilPtr->oilEventCountOR == rh4EventCountOR)
		{
			oilPtr->oilEventCount = rh2EventCount;
			
			num = oilPtr->oilObject;
			pHOPrev = nil;
			while (num >= 0)
			{
				pHO = rhPtr->rhObjectList[num];
				if (pHO->hoSelectedInOR != 0)
				{
					if (pHOPrev != nil)
					{
						pHOPrev->hoNextSelected = num;
					}
					else
					{
						oilPtr->oilListSelected = num;
					}
					pHO->hoNextSelected = -1;
					pHOPrev = pHO;
				}
				num = pHO->hoNumNext;
			}
		}
	}
}

// ---------------------------------------------------
// TROUVE L'OBJET COURANT POUR LES EXPRESSIONS >>> ESI
// ---------------------------------------------------
-(CObject*)get_ExpressionObjects:(short)expoi
{
	if (rh2ActionOn)					// On est dans les actions ?
	{
		// Dans une action
		rh2EnablePick = NO;					// En cas de chooseflag
		return [self get_CurrentObjects:expoi];	// Pointe l'oiList
	}
	
	// Dans un evenement
	// -----------------
	CObjInfo* oilPtr;
	if (expoi >= 0)
	{
		oilPtr = rhPtr->rhOiList[expoi];
		if (oilPtr->oilEventCount == rh2EventCount)		// Selection actuelle?
		{
			if (oilPtr->oilListSelected >= 0)			// Le premier
			{
				return rhPtr->rhObjectList[oilPtr->oilListSelected];
			}
			if (oilPtr->oilObject >= 0)					// Prend le premier objet
			{
				return rhPtr->rhObjectList[oilPtr->oilObject];
			}
			
			// Pas d'objet!
			// ~~~~~~~~~~~~
			return nil;
		}
		else
		{
			if (oilPtr->oilObject >= 0)					// Prend le premier objet
			{
				return rhPtr->rhObjectList[oilPtr->oilObject];
			}
			
			// Pas d'objet!
			// ~~~~~~~~~~~~
			return nil;
		}
	}
	
	// Un qualifier: trouve la premiere liste selectionnee
	// ---------------------------------------------------
	CQualToOiList* pQoi = qualToOiList[expoi & 0x7FFF];
	int qoi = 0;
	if (qoi >= pQoi->nQoi)
	{
		return nil;
	}
	// Recherche un objet selectionne
	do
	{
		oilPtr = rhPtr->rhOiList[pQoi->qoiList[qoi + 1]];
		if (oilPtr->oilEventCount == rh2EventCount)
		{
			if (oilPtr->oilListSelected >= 0)	// Le premier selectionne?
			{
				return rhPtr->rhObjectList[oilPtr->oilListSelected];
			}
		}
		qoi += 2;
	} while (qoi < pQoi->nQoi);
	
	// Pas trouve: prend le premier de la premiere liste disponible
	qoi = 0;
	do
	{
		oilPtr = rhPtr->rhOiList[pQoi->qoiList[qoi + 1]];
		if (oilPtr->oilObject >= 0)							// Le premier selectionne?
		{
			return rhPtr->rhObjectList[oilPtr->oilObject];
		}
		qoi += 2;
	} while (qoi < pQoi->nQoi);
	
	return nil;
}

// ----------------------------------------------------------------------
// TROUVE L'OBJET COURANT POUR UN PARAMETRE PARAM_OBJECT DANS UNE ACTION
// ----------------------------------------------------------------------
-(CObject*)get_ParamActionObjects:(short)qoil withAction:(LPEVT)evtPtr
{
	rh2EnablePick = YES;
	CObject* pObject = [self get_CurrentObjects:qoil];
	if (pObject != nil)
	{
		if (repeatFlag == NO)
		{
			// Pas de suivant
			return pObject;
		}
		else
		{
			// Un suivant
			evtPtr->evtFlags |= ACTFLAGS_REPEAT;		// Refaire cette action
			rh2ActionLoop = YES;			 	// Refaire un tour d'actions
			return pObject;
		}
	}
	evtPtr->evtFlags |= EVFLAGS_NOTDONEINSTART;
	return pObject;
}

// ----------------------------------------------------------------------
// TROUVE L'OBJET COURANT POUR LES ACTIONS, MARQUE LES ACTIONS A REFAIRE
// ----------------------------------------------------------------------
-(CObject*)get_ActionObjects:(LPEVT)evtPtr
{
	evtPtr->evtFlags &= ~EVFLAGS_NOTDONEINSTART;
	rh2EnablePick = YES;
	short qoil = evtPtr->evtOiList;				// Pointe l'oiList
	CObject* pObject = [self get_CurrentObjects:qoil];
	if (pObject != nil)
	{
		if (repeatFlag == NO)
		{
			// Pas de suivant
			return pObject;
		}
		else
		{
			// Un suivant
			evtPtr->evtFlags |= ACTFLAGS_REPEAT;		// Refaire cette action
			rh2ActionLoop = YES;			 	// Refaire un tour d'actions
			return pObject;
		}
	}
	evtPtr->evtFlags |= EVFLAGS_NOTDONEINSTART;
	return pObject;
}

// --------------------------------------------------------------------------
// Retourne un objet pour une action. Entree EDX=OiList. Change tout sauf EDI
// --------------------------------------------------------------------------
-(CObject*)get_CurrentObjects:(short)qoil
{
	if ((qoil&0x8000)==0)
	{
		return [self get_CurrentObject:qoil];
	}
	return [self get_CurrentObjectQualifier:qoil];
}

// -----------------------------------
// GET ACTION OBJECT POUR OBJET NORMAL
// -----------------------------------
-(CObject*)get_CurrentObject:(short)qoil
{
	CObject* pHo;
	CObjInfo* oilPtr = rhPtr->rhOiList[qoil];
	
	if (oilPtr->oilActionCount != rh2ActionCount)	//; Premiere exploration?
	{
		oilPtr->oilActionCount = rh2ActionCount;			//; C'est fait pour cette action
		oilPtr->oilActionLoopCount = rh2ActionLoopCount;
		
		// On recherche le premier dans la liste courante
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if (oilPtr->oilEventCount == rh2EventCount)	//; Liste vraiment courante?
		{
			if (oilPtr->oilListSelected >= 0)					//; La liste des objets selectionnes
			{
				oilPtr->oilCurrentOi = oilPtr->oilListSelected;
				pHo = rhPtr->rhObjectList[oilPtr->oilListSelected];
				oilPtr->oilNext = pHo->hoNextSelected;		//; Numero de l'objet suivant
				if (pHo->hoNextSelected < 0)
				{
					oilPtr->oilNextFlag = NO;				//; Pas de suivant!
					oilPtr->oilCurrentRoutine = 1;                     // gao2ndOneOnly;
					repeatFlag = NO;
					return pHo;
				}
				oilPtr->oilNextFlag = YES;					//; Un suivant!
				oilPtr->oilCurrentRoutine = 2;                         // gao2ndCurrent;
				repeatFlag = YES;
				return pHo;
			}
		}
		
		// Objet non trouve, on prends tous les objets de meme oi
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if (rh2EnablePick)						//; Pick autorise?
		{
			if (oilPtr->oilEventCount == rh2EventCount)	//; Alors juste cet objet?
			{
				oilPtr->oilCurrentRoutine = 0;                     // gao2ndNone;
				oilPtr->oilCurrentOi = -1;						// Pas de suivant
				return nil;
			}
		}
		if (oilPtr->oilObject >= 0)							//; Le numero du premier objet Est-il defini?
		{
			oilPtr->oilCurrentOi = oilPtr->oilObject;			//; Stocke le numero de l'objet courant
			pHo = rhPtr->rhObjectList[oilPtr->oilObject];
			if (pHo == nil)
			{
				oilPtr->oilCurrentRoutine = 0;                     // gao2ndNone;
				oilPtr->oilCurrentOi = -1;						// Pas de suivant
				return nil;
			}
			if (pHo->hoNumNext >= 0)
			{
				// Plusieurs objets
				oilPtr->oilNext = pHo->hoNumNext;				// Numero de l'objet
				oilPtr->oilNextFlag = YES;						// Un suivant!
				oilPtr->oilCurrentRoutine = 3;                 // gao2ndAll;
				repeatFlag = YES;
				return pHo;
			}
			// Un seul objet
			oilPtr->oilNextFlag = NO;							// Pas de suivant!
			oilPtr->oilCurrentRoutine = 1;                     // gao2ndOneOnly;
			repeatFlag = NO;
			return pHo;
		}
		else
		{
			oilPtr->oilCurrentRoutine = 0;                     // gao2ndNone;
			oilPtr->oilCurrentOi = -1;						// Pas de suivant
			return nil;
		}
	}
	
	if (oilPtr->oilActionLoopCount != rh2ActionLoopCount)
	{
		short next;
		oilPtr->oilActionLoopCount = rh2ActionLoopCount;	//; C'est fait pour cette boucle
		switch (oilPtr->oilCurrentRoutine)
		{
                // Pas d'objet
			case 0:                             // gao2ndNone
				repeatFlag = oilPtr->oilNextFlag;
				return nil;
                // Un seul objet
			case 1:                             // gao2ndOneOnly
				pHo = rhPtr->rhObjectList[oilPtr->oilCurrentOi];
				repeatFlag = oilPtr->oilNextFlag;
				return pHo;
                // Objet suivant dans la liste courante
			case 2:                             // gao2ndCurrent
				oilPtr->oilCurrentOi = oilPtr->oilNext;					//; Numero de l'objet suivant
				pHo = rhPtr->rhObjectList[oilPtr->oilNext];
				if (pHo == nil)
				{
					return nil;
				}
				next = pHo->hoNextSelected;
				if (next < 0)
				{
					oilPtr->oilNextFlag = NO;							// Plus de suivant!
					next = oilPtr->oilListSelected;
				}
				oilPtr->oilNext = next;
				repeatFlag = oilPtr->oilNextFlag;
				return pHo;
                // Objet suivant global
			case 3:                             // gao2ndAll
				oilPtr->oilCurrentOi = oilPtr->oilNext;					//; Stocke le numero de l'objet courant
				pHo = rhPtr->rhObjectList[oilPtr->oilNext];
				if (pHo == nil)
				{
					return nil;
				}
				next = pHo->hoNumNext;
				if (next < 0)
				{
					oilPtr->oilNextFlag = NO;							// Pas de suivant!
					next = oilPtr->oilObject;							// Repart au debut
				}
				oilPtr->oilNext = next;
				repeatFlag = oilPtr->oilNextFlag;
				return pHo;
		}
	}
	if (oilPtr->oilCurrentOi < 0)
	{
		return nil;					//; Prend l'objet courant
	}
	pHo = rhPtr->rhObjectList[oilPtr->oilCurrentOi];
	repeatFlag = oilPtr->oilNextFlag;
	return pHo;
}

// GESTION GETACTION OBJECT AVEC QUALIFIER
// --------------------------------------------------------------------------
-(CObject*)get_CurrentObjectQualifier:(short)qoil
{
	CObject* pHo;
	short next, num;
	
	CQualToOiList* pqoi = qualToOiList[qoil & 0x7FFF];
	if (pqoi->qoiActionCount != rh2ActionCount)			//; Premiere exploration?
	{
		// PREMIERE EXPLORATION
		// --------------------
		pqoi->qoiActionCount = rh2ActionCount;			//; C'est fait pour cette action
		pqoi->qoiActionLoopCount = rh2ActionLoopCount;
		
		// On recherche le premier dans les liste courantes
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		num = [self qoi_GetFirstListSelected:pqoi];					//; La premiere liste avec objet selectionne
		if (num >= 0)
		{
			pqoi->qoiCurrentOi = num;
			pHo = rhPtr->rhObjectList[num];
			if (pHo == nil)
			{
				pqoi->qoiCurrentRoutine = 0;           // qoi2ndNone;
				pqoi->qoiCurrentOi = -1;						// Pas de suivant!
				return nil;
			}
			next = pHo->hoNextSelected;
			if (next < 0)
			{
				next = [self qoi_GetNextListSelected:pqoi];
				if (next < 0)
				{
					pqoi->qoiCurrentRoutine = 1;       // qoi2ndOneOnly;
					pqoi->qoiNextFlag = NO;
					repeatFlag = NO;
					return pHo;
				}
			}
			pqoi->qoiNext = next;
			pqoi->qoiCurrentRoutine = 2;               // qoi2ndCurrent;
			pqoi->qoiNextFlag = YES;							// Un suivant!
			repeatFlag = YES;
			return pHo;
		}
		
		// Prendre tous?
		// ~~~~~~~~~~~~~
		if (rh2EnablePick)						// Pick autoris�?
		{
			if (pqoi->qoiSelectedFlag)					//; Une des listes a ete vue pendant les conditions
			{
				pqoi->qoiCurrentRoutine = 0;           // qoi2ndNone;
				pqoi->qoiCurrentOi = -1;						// Pas de suivant!
				return nil;
			}
		}
		num = [self qoi_GetFirstList:pqoi];
		if (num >= 0)
		{
			pqoi->qoiCurrentOi = num;							//; Stocke le numero de l'objet courant
			pHo = rhPtr->rhObjectList[num];
			if (pHo != nil)
			{
				num = pHo->hoNumNext;
				if (num < 0)
				{
					num = [self qoi_GetNextList:pqoi];
					if (num < 0)
					{
						pqoi->qoiCurrentRoutine = 1;               // qoi2ndOneOnly;
						pqoi->qoiNextFlag = NO;
						repeatFlag = NO;
						return pHo;
					}
				}
				pqoi->qoiNext = num;							// Numero de l'objet
				pqoi->qoiCurrentRoutine = 3;                       // qoi2ndAll;
				pqoi->qoiNextFlag = YES;						// Un suivant
				repeatFlag = YES;
				return pHo;
			}
		}
		pqoi->qoiCurrentRoutine = 0;       // qoi2ndNone;
		pqoi->qoiCurrentOi = -1;						// Pas de suivant!
		return nil;
	}
	
	if (pqoi->qoiActionLoopCount != rh2ActionLoopCount)		//; Premiere fois dans la boucle?
	{
		pqoi->qoiActionLoopCount = rh2ActionLoopCount;		//; C'est fait pour cette boucle
		switch (pqoi->qoiCurrentRoutine)
		{
                // Pas d'objet
			case 0:                 // qoi2ndNone
				repeatFlag = pqoi->qoiNextFlag;
				return nil;
                // Un seul objet
			case 1:                 // qoi2ndOneOnly
				pHo = rhPtr->rhObjectList[pqoi->qoiCurrentOi];
				repeatFlag = pqoi->qoiNextFlag;
				return pHo;
                // Objet suivant dans la liste courante
			case 2:                 // qoi2ndCurrent
				pqoi->qoiCurrentOi = pqoi->qoiNext;					// Numero de l'objet suivant
				pHo = rhPtr->rhObjectList[pqoi->qoiNext];
				if (pHo != nil)
				{
					next = pHo->hoNextSelected;
					if (next < 0)
					{
						next = [self qoi_GetNextListSelected:pqoi];
						if (next < 0)
						{
							pqoi->qoiNextFlag = NO;					// Plus de suivant!
							next = [self qoi_GetFirstListSelected:pqoi];                    // Repart au debut
						}
					}
					pqoi->qoiNext = next;
				}
				repeatFlag = pqoi->qoiNextFlag;
				return pHo;
                // Objet suivant global
			case 3:                 // qoi2ndAll
				pqoi->qoiCurrentOi = pqoi->qoiNext;					// Numero de l'objet suivant
				pHo = rhPtr->rhObjectList[pqoi->qoiNext];
				if (pHo != nil)
				{
					next = pHo->hoNumNext;
					if (next < 0)
					{
						next = [self qoi_GetNextList:pqoi];
						if (next < 0)
						{
							pqoi->qoiNextFlag = NO;					// Plus de suivant
							next = [self qoi_GetFirstList:pqoi];			// Repart au debut
						}
					}
					pqoi->qoiNext = next;
				}
				repeatFlag = pqoi->qoiNextFlag;
				return pHo;
		}
	}
	
	if (pqoi->qoiCurrentOi < 0)
	{
		return nil;
	}
	pHo = rhPtr->rhObjectList[pqoi->qoiCurrentOi];
	repeatFlag = pqoi->qoiNextFlag;
	return pHo;
}

// Trouve la prochaine liste avec des objets selectionnes
// ------------------------------------------------------
-(short)qoi_GetNextListSelected:(CQualToOiList*)pqoi
{
	int pos = pqoi->qoiActionPos;
	short qoil;
	CObjInfo* oilPtr;
	while (pos < pqoi->nQoi)
	{
		qoil = pqoi->qoiList[pos + 1];
		oilPtr = rhPtr->rhOiList[qoil];
		if (oilPtr->oilEventCount == rh2EventCount)	//; Liste vue pendant les conditions?
		{
			pqoi->qoiSelectedFlag = YES;						//; Flag: une des liste a ete selectionnee?
			if (oilPtr->oilListSelected >= 0)
			{
				pqoi->qoiActionPos = (short) (pos + 2);
				return oilPtr->oilListSelected;
			}
		}
		pos += 2;
	}
	;										//; La derniere?
	return -1;
}

-(short)qoi_GetFirstListSelected:(CQualToOiList*)pqoi
{
	pqoi->qoiActionPos = 0;
	pqoi->qoiSelectedFlag = NO;
	return [self qoi_GetNextListSelected:pqoi];
}

// Trouve la prochaine liste avec des objets
// -----------------------------------------
-(short)qoi_GetNextList:(CQualToOiList*)pqoi
{
	int pos = pqoi->qoiActionPos;
	short qoil;
	CObjInfo* oilPtr;
	while (pos < pqoi->nQoi)
	{
		qoil = pqoi->qoiList[pos + 1];
		oilPtr = rhPtr->rhOiList[qoil];
		if (oilPtr->oilObject >= 0)
		{
			pqoi->qoiActionPos = (short) (pos + 2);
			return oilPtr->oilObject;
		}
		pos += 2;
	}
	;
	return -1;
}

-(short)qoi_GetFirstList:(CQualToOiList*)pqoi
{
	pqoi->qoiActionPos = 0;
	return [self qoi_GetNextList:pqoi];
}







// ---------------------------------------------------------------------------
// Entree traitement events non relie a un objet, n'arrete pas le moniteur
//			AX= 	Code condition
// ---------------------------------------------------------------------------
-(void)handle_GlobalEvents:(int)cond
{
	int ncond = (int)(-(short)(cond&0xFFFF)); 
	
	LPDWORD pw = rhEvents[ncond];		// Type < 0 - Pointe les listes
	ncond = (int)(short)(cond >> 16);
	pw -= ncond;							// Pointe le pointeur sur la liste
	
	// Un pointeur direct?
	DWORD dw = *pw;
	if ( dw != 0 )
	{
		LPDWORD pdw = (LPDWORD)((LPBYTE)eventPointers + dw);	// Adresse de la liste d'evenements
		[self computeEventList:pdw withObject:(CObject*)1];		// Evalue les evenements
	}
}

// ---------------------------------------------------------------------------
// Entree traitement evenement lie a un objet
//			AX= 	ID Message / Code message
//			ESI=	Structure RO
// ---------------------------------------------------------------------------
-(BOOL)handle_Event:(CObject*)pHo withCode:(int)code
{
	rhCurCode = code; 				// Stocke pour access rapide
	
	// Des evenements definis?
	// ~~~~~~~~~~~~~~~~~~~~~~~
	short temp = (short)-(code>>16);				// Vire le type
	LPDWORD pw = pHo->hoEvents+temp;			// Les evenements lies a l'objet
	
	DWORD dw = *pw;
	if ( dw != 0 )						// Un pointeur direct?
	{
		[self computeEventList:(LPDWORD)((LPBYTE)eventPointers+dw) withObject:pHo];// Evalue les evenements
		return YES;
	}
	return NO;
}

// ---------------------------------------------------------------------------
// 	VERIFIE ET APPELLE LA LISTE DES EVENEMENTS TIMER
// ---------------------------------------------------------------------------
-(void)handle_TimerEvents
{
    BOOL bDelete = NO;
    LPTIMEREVENT pEvent=(LPTIMEREVENT)rhPtr->rh4TimerEvents;
	while (pEvent)
	{
		if (rhPtr->rhTimer>=pEvent->timer)
		{
			if (pEvent->type==TIMEREVENTTYPE_ONESHOT)
			{
				rhPtr->timerEventName=pEvent->name;
                LPDWORD pw = rhEvents[-OBJ_TIMER];
                DWORD dw = pw[-NUM_ONEVENT];
                if ( dw != 0 )
                    [self computeEventList:(LPDWORD)((LPBYTE)eventPointers+dw) withObject:(CObject*)1];
				bDelete=YES;
                pEvent->bDelete = YES;
			}
			else
			{
				if (pEvent->timerPosition==0)
				{
					pEvent->timerPosition=rhPtr->rhTimer;
				}
				while(rhPtr->rhTimer>=pEvent->timerPosition)
				{
					rhPtr->timerEventName=pEvent->name;
					rhCurParam[1]=pEvent->index;
                    LPDWORD pw = rhEvents[-OBJ_TIMER];
                    DWORD dw = pw[-NUM_ONEVENT];
                    if ( dw != 0 )
                        [self computeEventList:(LPDWORD)((LPBYTE)eventPointers+dw) withObject:(CObject*)1];
					pEvent->index++;
					pEvent->loops--;
					if (pEvent->loops==0)
					{
						bDelete=YES;
                        pEvent->bDelete = YES;
						break;
					}
					pEvent->timerPosition+=pEvent->timerNext;
				}
			}
		}
		pEvent=(LPTIMEREVENT)pEvent->next;
	}
    if (bDelete)
    {
        pEvent=(LPTIMEREVENT)rhPtr->rh4TimerEvents;
        LPTIMEREVENT pNext;
        LPTIMEREVENT pPrevious = nil;
        while (pEvent)
        {
            pNext = (LPTIMEREVENT)pEvent->next;
			if (pEvent->bDelete)
			{
				[pEvent->name release];
				if (pPrevious==nil)
					rhPtr->rh4TimerEvents=pNext;
				else
					pPrevious->next=pNext;
				free(pEvent);
			}
			else
			{
				pPrevious=pEvent;
			}
            pEvent = pNext;
        }
    }
}
-(void)compute_TimerEvents
{
	// Avant le fade-in : que les evenements START OF GAME
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if ( (rhPtr->rhGameFlags & GAMEFLAGS_FIRSTLOOPFADEIN) != 0 )
	{
		LPDWORD pw = rhEvents[-OBJ_GAME];
		DWORD dw = pw[-NUM_START];			// Des evenements start of game
		if ( dw != 0 )
		{
			pw[-NUM_START] = 0;						// Une seule fois
			[self computeEventList:(LPDWORD)((LPBYTE)eventPointers + dw) withObject:nil];
			rh4CheckDoneInstart = YES;
		}
		return;
	}
	
	// Les evenements timer
	// ~~~~~~~~~~~~~~~~~~~~
	LPDWORD pw = rhEvents[-OBJ_TIMER];
	DWORD dw = pw[-NUM_TIMER];
	if ( dw != 0 )
	{
		[self computeEventList:(LPDWORD)((LPBYTE)eventPointers+dw) withObject:(CObject*)1];
	}
	
	// Les evenements start of game
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	pw = rhEvents[- OBJ_GAME];
	dw = pw[-NUM_START];					// Des evenements start of game
	if ( dw != 0 )
	{
		pw[-NUM_START] = 0;						// Une seule fois
		if ( rh4CheckDoneInstart )
		{
			// Marque DONEBEFOREFADEIN les actions dÈja effectuees : elle ne seront pas rÈeffectuÈes...
			LPDWORD pdw = (LPDWORD)((LPBYTE)eventPointers+dw);
			LPEVG evgPtr;
			LPEVG evgGroup;
			evgGroup=nil;
			do 
			{
				evgPtr=(LPEVG)((LPBYTE)pEvents+*pdw);
				if (evgPtr!=evgGroup)
				{
					evgGroup=evgPtr;
					LPEVT evtPtr=(LPEVT)((LPBYTE)pEvents+*(pdw+1));
					
					// Pointe les actions
					for (evtPtr=EVTNEXT(evtPtr); evtPtr->evtCode.evtLCode.evtCode<0; evtPtr=EVTNEXT(evtPtr))	
						;
					
					// Stoppe les actions deja effectuees
					int count;
					for (count=evgGroup->evgNAct; count!=0; count--)
					{
						if ( (evtPtr->evtFlags & EVFLAGS_NOTDONEINSTART) == 0 )		// Une action BAD?
							evtPtr->evtFlags |= EVFLAGS_DONEBEFOREFADEIN;
						evtPtr=EVTNEXT(evtPtr);										// Passe au suivant
					}
					
				}
				pdw+=2;
			} while (*pdw != (DWORD)-1);
		}
		[self computeEventList:(LPDWORD)((LPBYTE)eventPointers+dw) withObject:nil];
		if ( rh4CheckDoneInstart )
		{
			// Enleve les flags	
			LPDWORD pdw = (LPDWORD)((LPBYTE)eventPointers + dw);
			LPEVG evgPtr;
			LPEVG evgGroup;
			evgGroup=nil;
			do 
			{
				evgPtr=(LPEVG)((LPBYTE)pEvents+*pdw);
				if (evgPtr!=evgGroup)
				{
					evgGroup=evgPtr;
					LPEVT evtPtr=(LPEVT)((LPBYTE)pEvents+*(pdw+1));
					
					// Pointe les actions
					for (evtPtr=EVTNEXT(evtPtr); evtPtr->evtCode.evtLCode.evtCode<0; evtPtr=EVTNEXT(evtPtr))	
						;
					
					// Enleve le flag
					int count;
					for (count=evgGroup->evgNAct; count!=0; count--)
					{
						evtPtr->evtFlags&=~EVFLAGS_DONEBEFOREFADEIN;
						evtPtr=EVTNEXT(evtPtr);										// Passe au suivant
					}
					
				}
				pdw+=2;
			} while (*pdw != (DWORD)-1);
			rh4CheckDoneInstart=NO;
		}
	}
	
	// Les evenements timer inferieur
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	pw = rhEvents[-OBJ_TIMER];
	dw = pw[-NUM_TIMERINF];
	if ( dw != 0 )
	{
		[self computeEventList:(LPDWORD)((LPBYTE)eventPointers+dw) withObject:nil];
	}
	
	// Les evenements timer superieur
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	dw = pw[-NUM_TIMERSUP];
	if ( dw != 0 )
	{
		[self computeEventList:(LPDWORD)((LPBYTE)eventPointers+dw) withObject:nil];
	}		
}
-(void)restartTimerEvents
{
	LPDWORD pdw=rh4TimerEventsBase;
	LPEVT evtPtr;
	LPEVG evgPtr;
	LPEVP evpPtr;
	if (pdw != nil)
	{
		DWORD dw=*pdw;
		while(dw!=(DWORD)-1)
		{
			evgPtr = (LPEVG)((LPBYTE)pEvents+dw);
			evtPtr = (LPEVT)((LPBYTE)pEvents+*(pdw+1));
			evtPtr->evtFlags |= EVFLAGS_DONE;		    // Marque l'evenement
			evpPtr=(LPEVP)((LPBYTE)evtPtr+CND_SIZE);
			if (evpPtr->evp.evpL.evpL0>rhPtr->rhTimer)	// Compare au timer
			{
				evtPtr->evtFlags &= ~EVFLAGS_DONE;
			}
			pdw+=2;
			dw=*pdw;
		};
	}
}

// ---------------------------------------------------------------------------
// 	EVALUE ET EXECUTE UNE LISTE D'EVENEMENTS
//  EAX: pointe la liste
//	Sortie: NZ si une action a ete validee...
// ---------------------------------------------------------------------------
-(void)computeEventList:(LPDWORD)pdw withObject:(CObject*)pHo
{
	BOOL bTrue;
	LPEVG evgPtr;
	LPEVG evgPtr2;
	LPEVT evtPtr;
	
	// Evaluation des evenements pour ce sprite
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rh3DoStop = 0;						// En cas de STOP dans les actions
	
	DWORD delta=*pdw;						// Delta dans le programme
	rhPtr->rhCurTempValue=rhPtr->rhBaseTempValues;
	do 
	{
		evgPtr=(LPEVG)((LPBYTE)pEvents+delta);	// Pointe le groupe dans le programme
		
		if ( (evgPtr->evgFlags & EVGFLAGS_INACTIVE) == 0 )	// Un groupe inhibe?
		{
			rhEventGroup = evgPtr;					// Adresse du groupe
			rh4PickFlags[0] = 0;		  		// Pas d'objet choisis dans les evenements
			rh4PickFlags[1] = 0;
			rh4PickFlags[2] = 0;
			rh4PickFlags[3] = 0;
			
			// Si pas de OR dans le groupe
			if ((rhEventGroup->evgFlags&EVGFLAGS_ORINGROUP)==0)
			{
				evtPtr=EVGFIRSTEVT(evgPtr);
				rh2EventCount += 1;
				rh4ConditionsFalse=NO;
				
				// Appel de la premiere routine
				if ( pHo != nil )	// Un objet ou pas?
				{
					if ( callTable_Condition1[evtPtr->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](evtPtr, rhPtr, pHo) == NO )			// Pointe la bonne liste de saut
						goto evNextGroup;
					
					goto evNext;
				}
				do {
					if ( callTable_Condition2[evtPtr->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](evtPtr, rhPtr) == NO )			// Pointe la bonne liste de saut
						goto evNextGroup;
				evNext:
					evtPtr=EVTNEXT(evtPtr);		 				// Passe au suivant
				} while( evtPtr->evtCode.evtSCode.evtNum<0 );					// Encore une condition?
				
				// Appel des actions si le resultat est vrai
				// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
				if ( rh3DoStop  )			// Groupe FAUX, mais faire event STOP?
				{
					// Appeler les actions STOP seulement?
					// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					if ( pHo != nil )					// Seulement si un objet defini...
						[self call_Stops:evtPtr withObject:pHo];
				}
				else
				{
					[self call_Actions:evtPtr];
				}
			evNextGroup:;
				pdw+=2;
			}
			else
			{
				rh4EventCountOR++;
				if ((evgPtr->evgFlags&EVGFLAGS_ORLOGICAL)==0)
				{
					if (pHo==nil)
					{
						bTrue=NO;
						do
						{
							rh2EventCount++;
							evtPtr=(LPEVT)((LPBYTE)pEvents+*(pdw+1));
							rh4ConditionsFalse=NO;
							
							do 
							{
								if ( callTable_Condition2[evtPtr->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](evtPtr, rhPtr)==NO )
								{
									rh4ConditionsFalse=YES;
								}
								evtPtr=EVTNEXT(evtPtr);
							} while( evtPtr->evtCode.evtSCode.evtNum<0 && evtPtr->evtCode.evtLCode.evtCode!=CNDL_OR );
							
							[self evt_MarkSelectedObjects];			// Stocke les objets
							if (rh4ConditionsFalse==NO)
							{
								bTrue=YES;
							}
							
							pdw+=2;
							if (*pdw==(DWORD)-1)
								break;
							
							evgPtr=(LPEVG)((LPBYTE)pEvents+*pdw);
							
						}while(evgPtr==rhEventGroup);
						
						if (bTrue)
						{
							rh2EventCount++;
							[self evt_BranchSelectedObjects];		// Branche tous les objets
							while(evtPtr->evtCode.evtSCode.evtNum<0)				// Trouve les actions
								evtPtr=EVTNEXT(evtPtr);
							[self call_Actions:evtPtr];				// Appelle les actions
						}
					}
					else
					{
						bTrue=NO;
						do
						{
							rh2EventCount++;
							evtPtr=(LPEVT)((LPBYTE)pEvents+*(pdw+1));
							rh4ConditionsFalse=NO;
							
							if (callTable_Condition1[evtPtr->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](evtPtr, rhPtr, pHo)==NO)
								rh4ConditionsFalse=1;
							
							evtPtr=EVTNEXT(evtPtr);
							while( evtPtr->evtCode.evtSCode.evtNum<0 && evtPtr->evtCode.evtLCode.evtCode!=CNDL_OR )	 
							{
								if ( callTable_Condition2[evtPtr->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](evtPtr, rhPtr)==NO )
								{
									rh4ConditionsFalse=YES;
								}
								evtPtr=EVTNEXT(evtPtr);
							} 
							
							[self evt_MarkSelectedObjects];						// Stocke les objets
							if (rh4ConditionsFalse==NO)
							{
								bTrue=YES;
							}
							
							pdw+=2;
							if (*pdw==(DWORD)-1)
								break;
							
							evgPtr=(LPEVG)((LPBYTE)pEvents+*pdw);
							
						}while(evgPtr==rhEventGroup);
						
						if (bTrue)
						{
							rh2EventCount++;
							[self evt_BranchSelectedObjects];		// Branche tous les objets
							while(evtPtr->evtCode.evtSCode.evtNum<0)				// Trouve les actions
								evtPtr=EVTNEXT(evtPtr);
							[self call_Actions:evtPtr];				// Appelle les actions
						}
					}
				}
				else
				{
					BOOL bFalse;
					rh4ConditionsFalse=0;
					
					if (pHo==nil)
					{
						bTrue=NO;
						do
						{
							rh2EventCount++;
							evtPtr=(LPEVT)((LPBYTE)pEvents+*(pdw+1));
							bFalse=NO;
							
							do 
							{
								if ( callTable_Condition2[evtPtr->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](evtPtr, rhPtr)==NO )
								{
									bFalse=YES;
									break;
								}
								evtPtr=EVTNEXT(evtPtr);
							} while( evtPtr->evtCode.evtSCode.evtNum<0 && evtPtr->evtCode.evtLCode.evtCode!=CNDL_ORLOGICAL );
							
							if (bFalse==NO)
							{
								[self evt_MarkSelectedObjects];			// Stocke les objets
								bTrue=YES;
							}
							
							pdw+=2;
							if (*pdw==(DWORD)-1)
								break;
							
							evgPtr=(LPEVG)((LPBYTE)pEvents+*pdw);
							
						}while(evgPtr==rhEventGroup);
						
						if (bTrue)
						{
							rh2EventCount++;
							[self evt_BranchSelectedObjects];		// Branche tous les objets
							while(evtPtr->evtCode.evtSCode.evtNum<0)				// Trouve les actions
								evtPtr=EVTNEXT(evtPtr);
							[self call_Actions:evtPtr];				// Appelle les actions
						}
					}
					else
					{
						bTrue=NO;
						do
						{
							rh2EventCount++;
							evtPtr=(LPEVT)((LPBYTE)pEvents+*(pdw+1));
							bFalse=NO;
							
							if (callTable_Condition1[evtPtr->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](evtPtr, rhPtr, pHo))
							{
								evtPtr=EVTNEXT(evtPtr);
								while( evtPtr->evtCode.evtSCode.evtNum<0 && evtPtr->evtCode.evtLCode.evtCode!=CNDL_ORLOGICAL )	 
								{
									if ( callTable_Condition2[evtPtr->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](evtPtr, rhPtr)==NO )
									{
										bFalse=YES;
										break;
									}
									evtPtr=EVTNEXT(evtPtr);
								} 
							}
							else
							{
								bFalse=YES;
							}
							
							if (bFalse==NO)
							{
								[self evt_MarkSelectedObjects];						// Stocke les objets
								bTrue=YES;
							}
							
							pdw+=2;
							if (*pdw==(DWORD)-1)
								break;
							
							evgPtr=(LPEVG)((LPBYTE)pEvents+*pdw);
							
						}while(evgPtr==rhEventGroup);
						
						if (bTrue)
						{
							rh2EventCount++;
							[self evt_BranchSelectedObjects];		// Branche tous les objets
							while(evtPtr->evtCode.evtSCode.evtNum<0)				// Trouve les actions
								evtPtr=EVTNEXT(evtPtr);
							[self call_Actions:evtPtr];				// Appelle les actions
						}
					}
				}				
			}
		}
		else
		{
			// Si inactif, saute tous les groupes de condition
			pdw+=2;
			if (*pdw!=(DWORD)-1) 
			{
				evgPtr2=(LPEVG)((LPBYTE)pEvents+*pdw);
				while(evgPtr2==evgPtr)
				{
					pdw+=2;
					if (*pdw==(DWORD)-1)
						break;
					evgPtr2=(LPEVG)((LPBYTE)pEvents+*pdw);
				}
			}
		}
		delta=*pdw;
	} while ( delta!=(DWORD)-1 );
}
-(void)computeEventFastLoopList:(LPDWORD)pdw
{
	LPEVG evgPtr;
	DWORD delta=*pdw;
	do
	{
		evgPtr=(LPEVG)((LPBYTE)pEvents+delta);	// Pointe le groupe dans le programme
        
		if ( (evgPtr->evgFlags & EVGFLAGS_INACTIVE) == 0 )	// Un groupe inhibe?
		{
			rhEventGroup = evgPtr;					// Adresse du groupe
			rh4PickFlags[0] = 0;		  		// Pas d'objet choisis dans les evenements
			rh4PickFlags[1] = 0;
			rh4PickFlags[2] = 0;
			rh4PickFlags[3] = 0;           
			rh2EventCount++;
            
			LPEVT evtPtr = EVGFIRSTEVT(evgPtr);
			evtPtr = EVTNEXT(evtPtr);		 			// Skips ON LOOP
			while(evtPtr->evtCode.evtSCode.evtNum<0)
			{
				if ( callTable_Condition2[evtPtr->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](evtPtr, rhPtr) == NO )			// Pointe la bonne liste de saut
                    goto evNextGroup;
				evtPtr = EVTNEXT(evtPtr);
			}
			[self call_Actions:evtPtr];
		}
    evNextGroup:
		pdw+=2;
		delta=*pdw;
	} while ( delta!=(DWORD)-1 );
}

// ---------------------------------------------------------------------------
// EXECUTION DES ACTIONS
// ---------------------------------------------------------------------------
-(void)call_Actions:(LPEVT)pActions
{
	LPEVG pEvg = rhEventGroup;		// Pointeur sur le groupe
	
	// Gestion des flags ONCE/NOT ALWAYS/REPEAT/NO MORE
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if ( pEvg->evgFlags & EVGFLAGS_LIMITED )   				// Les actions limitees et validees
	{
		// Flag SHUFFLE
		if ((pEvg->evgFlags & EVGFLAGS_SHUFFLE) != 0)
		{
			rh2ShuffleBuffer = [[CArrayList alloc] init];
		}
		
		// Flag NOT ALWAYS
		if ( pEvg->evgFlags & EVGFLAGS_NOTALWAYS )
		{
			DWORD w_cx = (WORD)rhPtr->rhLoopCount;
			DWORD w_dx = pEvg->evgInhibit;
			pEvg->evgInhibit = w_cx;
			if ( w_cx == w_dx ) return;
			w_cx -= 1;
			if ( w_cx == w_dx ) return;
		}
		
		// Flag REPEAT
		if ( pEvg->evgFlags & EVGFLAGS_REPEAT )
		{
			if ( pEvg->evgInhibitCpt != 0 )
				pEvg->evgInhibitCpt--;
			else
				return;
		}
		
		// Flag NO MORE during
		if ( (pEvg->evgFlags & EVGFLAGS_NOMORE) != 0 )
		{
			DWORD dwt = ((DWORD)rhPtr->rhTimer / 10);		// Timer courant / 10
			DWORD dwmax = pEvg->evgInhibitCpt;			// Timer maximum
			if ( dwmax != 0 &&		// Premiere fois?
				dwt < dwmax )		// Pas encore pret!
				return;
			pEvg->evgInhibitCpt = (dwt+pEvg->evgInhibit);		// Plus timer possible= timer maxi
		}
	}
	
	// Premiere execution : toutes les actions
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	LPEVT pe = pActions;					// Debut des actions
	LPEVT pActionStart=rh4ActionStart;
	
	rh2ActionCount ++;				// Marqueur de boucle d'actions
	rh2ActionLoop = NO;				// Flag boucle
	rh2ActionLoopCount = 0;		// Numero de boucle d'actions
	rh2ActionOn = YES;			 	// On est dans les actions
	int nAct = pEvg->evgNAct;				// Nombre d'actions
	do 
	{
		if ( (pe->evtFlags & (EVFLAGS_BADOBJECT|EVFLAGS_DONEBEFOREFADEIN)) == 0 )		// Une action BAD?
		{
			//			rhPtr->rh4.rh4StringWork = 0;
			rh4ActionStart=pe;
            pe->evtFlags &= ~ACTFLAGS_REPEAT;
			callTable_Action[pe->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](pe, rhPtr);
		}
		nAct--;
		if ( nAct == 0 )
			break;
		pe = EVTNEXT(pe);
	} while(YES);

	if ( rh2ActionLoop )		// Encore des actions a faire?
	{
		// Deuxieme execution : juste les actions avec un flag
		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		do 
		{
			pe = pActions;
			rh2ActionLoop = NO;				// Flag boucle
			rh2ActionLoopCount ++;			// Numero de boucle
			nAct = pEvg->evgNAct;				// Nombre d'actions
			do 
			{
				if ( (pe->evtFlags & EVFLAGS_BADOBJECT) == 0 &&		// Une action BAD?
					(pe->evtFlags & EVFLAGS_REPEAT) != 0 )			// Action repeat?
				{
					//					rhPtr->rh4.rh4StringWork = 0;
					rh4ActionStart=pe;
                    pe->evtFlags &= ~ACTFLAGS_REPEAT;
					callTable_Action[pe->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](pe, rhPtr);
				}
				nAct--;
				if ( nAct == 0 )
					break;
				pe = EVTNEXT(pe);
			} while(YES);
			
		} while (rh2ActionLoop);			// Encore des actions a faire?
	}
	
	// Appeler la routine de fin?
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~
	rh2ActionOn = NO;			 	// On est plus les actions
	if (rh2ShuffleBuffer != nil)
	{
		[self endShuffle];
	}
    if (bEndForEach)
    {
        endForEach(rhPtr);
    }
	rh4ActionStart=pActionStart;
}

// Fin des actions : melange!
// ~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void)endShuffle
{
	if ([rh2ShuffleBuffer size]<=1)
	{
		[rh2ShuffleBuffer release];
		rh2ShuffleBuffer=nil;
		return;
	}
	
	int num1=[rhPtr random:[rh2ShuffleBuffer size]];
	int num2;
	do
	{
		num2=[rhPtr random:[rh2ShuffleBuffer size]];
	}while(num1==num2);
	
			  
	LPHO pHo1=(CObject*)[rh2ShuffleBuffer get:num1];
	LPHO pHo2=(CObject*)[rh2ShuffleBuffer get:num2];
	
	// Echange les sprites
	int x1=pHo1->hoX;
	int y1=pHo1->hoY;
	int x2=pHo2->hoX;
	int y2=pHo2->hoY;
	[pHo1 setPosition:x2 withY:y2];
	[pHo2 setPosition:x1 withY:y1];
	[rh2ShuffleBuffer release];
	rh2ShuffleBuffer=nil;
}

// ---------------------------------------------------------------------------
// EXECUTION UNIQUEMENT DES ACTIONS STOP ET BOUNCE POUR UN SEUL OBJET ESI
// ---------------------------------------------------------------------------
-(void)call_Stops:(LPEVT)pActions withObject:(CObject*)pHo
{
	WORD	oi;
	int	nAct;
	
	// On ne traite qu'un seul objet!
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	oi = pHo->hoOi;							// L'Oi en question
	//	rhPtr->rh2.rh2PickFlags = 1;				// Un seul objet dans l'exploration
	rh2EventCount++;			// des actions...
	[self evt_AddCurrentObject:pHo];
	
	// Premiere execution : toutes les actions STOP
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	LPEVG pEvg = rhEventGroup;		// Pointeur sur le groupe
	rh2ActionCount ++;					// Marqueur de boucle d'actions
	rh2ActionLoop = NO;					// Flag boucle
	rh2ActionLoopCount = 0;			// Numero de boucle d'actions
	rh2ActionOn = YES;					// On est dans les actions
	
	nAct = pEvg->evgNAct;						// Nombre d'actions
	LPEVT pe=pActions;
	do 
	{
		if ( pe->evtCode.evtSCode.evtNum  == (ACTL_EXTSTOP>>16) ||				// Le bon code?
			pe->evtCode.evtSCode.evtNum == (ACTL_EXTBOUNCE>>16) )
		{
			if ( oi == pe->evtOi )
			{
				callTable_Action[pe->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](pe, rhPtr);
			}
			else
			{
				int oil = pe->evtOiList;			// Un qualifier?
				if ( (oil & 0x8000) != 0 )
				{
					CQualToOiList* pq = qualToOiList[oil & 0x7FFF];
					int numOi = 0;
					while (numOi < pq->nQoi)
					{
						if (pq->qoiList[numOi] == oi)
						{
							callTable_Action[pe->evtCode.evtSCode.evtType+NUMBEROF_SYSTEMTYPES](pe, rhPtr);
							break;
						}
						numOi += 2;
					};
				}
			}
		}
		nAct--;
		if ( nAct == 0 ) break;
		pe = EVTNEXT(pe);
	} while(YES);
	rh2ActionOn = NO;					// On est plus dans les actions
}


// --------------------------------------------------------------------------
// EXTERN EVENTS ENTRY
// --------------------------------------------------------------------------
-(void)onMouseButton:(int)nClicks
{
	if (rhPtr == nil || rhPtr->rh2PauseCompteur != 0 || bReady == NO)
		return;
	
	// Un evenement a traiter?
	// -----------------------
	int mouse = 0;
	if (nClicks == 2)
	{
		mouse += PARAMCLICK_DOUBLE;
	}
	
	rhPtr->rh4TimeOut = 0;							// Plus de time-out!
	
	// Genere les evenements dans le jeu
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	rhCurParam[0] = mouse;
	rh2CurrentClick = (short) mouse;			// Pour les evenements II
	[self handle_GlobalEvents:((-5 << 16) | 0xFFFA)];		// CNDL_MCLICK Evenement click normal
	[self handle_GlobalEvents:((-6 << 16) | 0xFFFA)];		// CNDL_MCLICKINZONE Evenement click sur une zone
	
	// Explore les sprites en collision
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	//TODO do inverse mouse coordinate lookup based on layer rotation
	int mx = rhPtr->rh2MouseX;
	int my = rhPtr->rh2MouseY;
	
	CSprite* spr = nil;
	CArrayList* list = [[CArrayList alloc] init];
	while (YES)
	{
		spr = [rhPtr->spriteGen spriteCol_TestPoint:spr withLayer:LAYER_ALL andX:mx andY:my andFlags:0];
		if (spr == nil)
		{
			break;
		}
		[list add:spr];
	}
	
	int count;
	CObject* pHo;
	for (count = 0; count < [list size]; count++)
	{
		spr = (CSprite*) [list get:count];
		pHo = spr->sprExtraInfo;
		if ((pHo->hoFlags & HOF_DESTROYED) == 0)
		{
			rhCurParam[1] = pHo->hoOi;
			rh4_2ndObject = pHo;
			[self handle_GlobalEvents:((-7 << 16) | 0xFFFA)];		// CNDL_MCLICKONOBJECT
		}
	}
	[list release];
	
	// Explore les autres objets en collision
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	count = 0;
	for (int nObjects = 0; nObjects < rhPtr->rhNObjects; nObjects++)
	{
		while (rhPtr->rhObjectList[count] == nil)
		{
			count++;
		}
		pHo = rhPtr->rhObjectList[count];
		count++;
		if ((pHo->hoFlags & (HOF_REALSPRITE | HOF_OWNERDRAW)) == 0)
		{
			int x = pHo->hoX - pHo->hoImgXSpot;
			if (rhPtr->rh2MouseX <= mx && (x + pHo->hoImgWidth > rhPtr->rh2MouseX))
			{
				int y = pHo->hoY - pHo->hoImgYSpot;
				if (y <= rhPtr->rh2MouseY && (y + pHo->hoImgHeight > rhPtr->rh2MouseY))
				{
					if ((pHo->hoFlags & HOF_DESTROYED) == 0)
					{
						rhCurParam[1] = pHo->hoOi;
						rh4_2ndObject = pHo;
						[self handle_GlobalEvents:((-7 << 16) | 0xFFFA)];		// CNDL_MCLICKONOBJECT
					}
				}
			}
		}
	}
}

-(void)onMouseMove
{
	if (rhPtr != nil)
	{
		if (bReady == NO)
		{
			return;
		}
		if (rhPtr->rh2PauseCompteur != 0)
		{
			return;
		}
		rhPtr->rh4TimeOut = 0;
	}
}


// Fonction utilitaire pour les conditions
/////////////////////////////////////////////////////////////////////////////////

-(BOOL)ctoCompare:(short*)pZone withObject:(CObject*)pHo
{
	if (pHo->hoImgWidth == 0 || pHo->hoImgHeight == 0)
	{
		return NO;
	}
	if (pHo->hoX < *pZone || pHo->hoX >= *(pZone+2))
	{
		return NO;
	}
	if (pHo->hoY < *(pZone+1) || pHo->hoY >= *(pZone+3))
	{
		return NO;
	}
	return YES;
}

-(CObject*)count_ZoneTypeObjects:(short*)pZone withStop:(int)stop andType:(short)type
{
	stop++;
	evtNSelectedObjects = 0;
	
	int oil = 0;
	CObjInfo* poilLoop = nil;
	CObject* pHo;
	do
	{
		for (; oil < rhPtr->rhMaxOI; oil++)
		{
			poilLoop = rhPtr->rhOiList[oil];
			if (type == 0 || (type != 0 && type == poilLoop->oilType))
			{
				break;
			}
		}
		if (oil == rhPtr->rhMaxOI)
		{
			return nil;
		}
		
		CObjInfo* poil = poilLoop;
		oil++;
		
		if (poil->oilEventCount != rh2EventCount)
		{
			if (rh4ConditionsFalse == NO)
			{
				// Explore la liste entiere des objets
				short num = poil->oilObject;
				while (num >= 0)
				{
					pHo = rhPtr->rhObjectList[num];
					if (pHo == nil)
					{
						return nil;
					}
					if ((pHo->hoFlags & HOF_DESTROYED) == 0)		// Deja detruit?
					{
						if ([self ctoCompare:pZone withObject:pHo])
						{
							evtNSelectedObjects++;
							if (evtNSelectedObjects == stop)
							{
								return pHo;
							}
						}
					}
					num = pHo->hoNumNext;
				}
			}
		}
		else
		{
			// Explore la liste des objets selectionnes
			short num = poil->oilListSelected;
			while (num >= 0)
			{
				pHo = rhPtr->rhObjectList[num];
				if (pHo == nil)
				{
					return nil;
				}
				if ((pHo->hoFlags & HOF_DESTROYED) == 0)		// Deja detruit?
				{
					if ([self ctoCompare:pZone withObject:pHo])
					{
						evtNSelectedObjects++;
						if (evtNSelectedObjects == stop)
						{
							return pHo;
						}
					}
				}
				num = pHo->hoNextSelected;
			}
		}
	} while (YES);
}

// ----------------------------------------
// Compte / Trouve des objets de type AX
// ----------------------------------------
-(CObject*)count_ObjectsFromType:(short)type withStop:(int)stop
{
	stop++;									// BX a partir de 1!
	evtNSelectedObjects = 0;
	
	int oil = 0;
	CObjInfo* poilLoop = nil;
	CObject* pHo;
	do
	{
		for (; oil < rhPtr->rhMaxOI; oil++)
		{
			poilLoop = rhPtr->rhOiList[oil];
			if (type == 0 || (type != 0 && type == poilLoop->oilType))
			{
				break;
			}
		}
		if (oil == rhPtr->rhMaxOI)
		{
			return nil;
		}
		
		CObjInfo* poil = poilLoop;
		oil++;
		
		if (poil->oilEventCount != rh2EventCount)
		{
			if (rh4ConditionsFalse == NO)
			{
				// Explore la liste entiere des objets
				short num = poil->oilObject;
				while (num >= 0)
				{
					pHo = rhPtr->rhObjectList[num];
					if (pHo == nil)
					{
						return nil;
					}
					if ((pHo->hoFlags & HOF_DESTROYED) == 0)		// Deja detruit?
					{
						evtNSelectedObjects++;
						if (evtNSelectedObjects == stop)
						{
							return pHo;
						}
					}
					num = pHo->hoNumNext;
				}
			}
		}
		else
		{
			// Explore la liste des objets selectionnes
			short num = poil->oilListSelected;
			while (num >= 0)
			{
				pHo = rhPtr->rhObjectList[num];
				if (pHo == nil)
				{
					return nil;
				}
				if ((pHo->hoFlags & HOF_DESTROYED) == 0)		// Deja detruit?
				{
					evtNSelectedObjects++;
					if (evtNSelectedObjects == stop)
					{
						return pHo;
					}
				}
				num = pHo->hoNextSelected;
			}
		}
	} while (YES);
}

// Routine de test de la zone
// ~~~~~~~~~~~~~~~~~~~~~~~~~~
-(BOOL)czaCompare:(short*)pZone withObject:(CObject*)pHo
{
	if (pHo->hoX < *pZone || pHo->hoX >= *(pZone+2))
	{
		return NO;
	}
	if (pHo->hoY < *(pZone+1) || pHo->hoY >= *(pZone+3))
	{
		return NO;
	}
	return YES;
}

-(int)select_ZoneTypeObjects:(short*)p withType:(short)type
{
	int cpt = 0;
	
	int oil = 0;
	CObjInfo* poilLoop = nil;
	CObject* pHoLoop;
	CObject* pHoFound;
	short num;
	do
	{
		for (; oil < rhPtr->rhMaxOI; oil++)
		{
			poilLoop = rhPtr->rhOiList[oil];
			if (type == 0 || (type != 0 && type == poilLoop->oilType))
			{
				break;
			}
		}
		if (oil == rhPtr->rhMaxOI)
		{
			return cpt;
		}
		
		CObjInfo* poil = poilLoop;
		oil++;
		
		if (poil->oilEventCount != rh2EventCount)
		{
			// Explore la liste entiere des objets, et branche les objets dans la zone
			pHoLoop = nil;
			poil->oilNumOfSelected = 0;
			poil->oilEventCount = rh2EventCount;
			poil->oilListSelected = -1;
			if (rh4ConditionsFalse == NO)
			{
				num = poil->oilObject;
				while (num >= 0)
				{
					pHoFound = rhPtr->rhObjectList[num];
					if (pHoFound == nil)
					{
						break;
					}
					if ((pHoFound->hoFlags & HOF_DESTROYED) == 0)		// Deja detruit?
					{
						if ([self czaCompare:p withObject:pHoFound])
						{
							cpt++;
							poil->oilNumOfSelected++;
							pHoFound->hoNextSelected = -1;
							if (pHoLoop == nil)
							{
								poil->oilListSelected = pHoFound->hoNumber;
							}
							else
							{
								pHoLoop->hoNextSelected = pHoFound->hoNumber;
							}
							pHoLoop = pHoFound;
						}
					}
					num = pHoFound->hoNumNext;
				}
				;
			}
			continue;
		}
		
		// Explore la liste des objets selectionnes, et vire les objets non dans la zone
		pHoLoop = nil;								// Pour le premier!
		num = poil->oilListSelected;
		while (num >= 0)
		{
			pHoFound = rhPtr->rhObjectList[num];
			if (pHoFound == nil)
			{
				break;
			}
			if ((pHoFound->hoFlags & HOF_DESTROYED) == 0)			// Deja detruit?
			{
				if ([self czaCompare:p withObject:pHoFound] == NO)
				{
					poil->oilNumOfSelected--;					// Un de moins!
					if (pHoLoop == nil)
					{
						poil->oilListSelected = pHoFound->hoNextSelected;
					}
					else
					{
						pHoLoop->hoNextSelected = pHoFound->hoNextSelected;	//; oil.oilListSelected IDEM!
					}
				}
				else
				{
					cpt++;
					pHoLoop = pHoFound;
				}
			}
			num = pHoFound->hoNextSelected;
		}
		;
		continue;
	} while (true);
}

// ---------------------------------------------------
// Ligne de vue : selectionne les objets sur une ligne
// ---------------------------------------------------
-(BOOL)losCompare:(double)x1 withY1:(double)y1 andX2:(double)x2 andY2:(double)y2 andObject:(CObject*)pHo
{
	double delta;
	int x, y;
	
	int xLeft = pHo->hoX - pHo->hoImgXSpot;
	int xRight = xLeft + pHo->hoImgWidth;
	int yTop = pHo->hoY - pHo->hoImgYSpot;
	int yBottom = yTop + pHo->hoImgHeight;
	
	if (x2 - x1 > y2 - y1)
	{
		delta = (double) (y2 - y1) / (double) (x2 - x1);
		if (x2 > x1)
		{
			if (xRight < x1 || xLeft >= x2)
			{
				return NO;
			}
		}
		else
		{
			if (xRight < x2 || xLeft >= x1)
			{
				return NO;
			}
		}
		y = (int) (delta * (xLeft - x1) + y1);
		if (y >= yTop && y < yBottom)
		{
			return YES;
		}
		
		y = (int) (delta * (xRight - x1) + y1);
		if (y >= yTop && y < yBottom)
		{
			return true;
		}
		
		return NO;
	}
	else
	{
		delta = (double) (x2 - x1) / (double) (y2 - y1);
		if (y2 > y1)
		{
			if (yBottom < y1 || yTop >= y2)
			{
				return NO;
			}
		}
		else
		{
			if (yBottom < y2 || yTop >= y1)
			{
				return NO;
			}
		}
		x = (int) (delta * (yTop - y1) + x1);
		if (x >= xLeft && x < xRight)
		{
			return YES;
		}
		
		x = (int) (delta * (yTop - y1) + x1);
		if (x >= xLeft && x < xRight)
		{
			return YES;
		}
		
		return NO;
	}
}

-(int)select_LineOfSight:(int)x1 withY1:(int)y1 andX2:(int)x2 andY2:(int)y2
{
	int cpt = 0;
	
	// Exploration de la liste des objets
	CObjInfo* poil;
	int oil;
	CObject* pHoLoop;
	CObject* pHoFound;
	short num;
	for (oil = 0; oil < rhPtr->rhMaxOI; oil++)
	{
		poil = rhPtr->rhOiList[oil];
		if (poil->oilEventCount != rh2EventCount)
		{
			// Explore la liste entiere des objets, et branche les objets dans la zone
			pHoLoop = nil;
			poil->oilNumOfSelected = 0;
			poil->oilEventCount = rh2EventCount;
			poil->oilListSelected = -1;
			
			// Si condition OR et conditions fausse, ne selectionne aucun objet
			if (rh4ConditionsFalse == NO)
			{
				num = poil->oilObject;
				while (num >= 0)
				{
					pHoFound = rhPtr->rhObjectList[num];
					if (pHoFound == nil)
					{
						break;
					}
					if ((pHoFound->hoFlags & HOF_DESTROYED) == 0)		// Deja detruit?
					{
						if ([self losCompare:x1 withY1:y1 andX2:x2 andY2:y2 andObject:pHoFound])
						{
							cpt++;
							poil->oilNumOfSelected++;
							pHoFound->hoNextSelected = -1;
							if (pHoLoop == nil)
							{
								poil->oilListSelected = pHoFound->hoNumber;
							}
							else
							{
								pHoLoop->hoNextSelected = pHoFound->hoNumber;		//; Car idem oilListSelected!
							}
							pHoLoop = pHoFound;
						}
					}
					num = pHoFound->hoNumNext;
				}
			}
			continue;
		}
		
		// Explore la liste des objets selectionnes, et vire les objets non dans la zone
		pHoLoop = nil;								// Pour le premier!
		num = poil->oilListSelected;
		while (num >= 0)
		{
			pHoFound = rhPtr->rhObjectList[num];
			if (pHoFound == nil)
			{
				break;
			}
			if ((pHoFound->hoFlags & HOF_DESTROYED) == 0)			// Deja detruit?
			{
				if ([self losCompare:x1 withY1:y1 andX2:x2 andY2:y2 andObject:pHoFound] == NO)
				{
					poil->oilNumOfSelected--;					// Un de moins!
					if (pHoLoop == nil)
					{
						poil->oilListSelected = pHoFound->hoNextSelected;
					}
					else
					{
						pHoLoop->hoNextSelected = pHoFound->hoNextSelected;
					}
				}
				else
				{
					cpt++;
					pHoLoop = pHoFound;
				}
			}
			num = pHoFound->hoNextSelected;
		}
		
	}
	return cpt;
}


// ----------------------------------------
// Compte / Trouve un objet dans une zone
// ----------------------------------------
-(int)czoCountThem:(short)oil withZone:(short*)pZone
{
	int count = 0;
	CObjInfo* poil = rhPtr->rhOiList[oil];
	CObject* pHo;
	if (poil->oilEventCount != rh2EventCount)
	{
		if (rh4ConditionsFalse == NO)
		{
			// Explore la liste entiere des objets
			short num = poil->oilObject;
			while (num >= 0)
			{
				pHo = rhPtr->rhObjectList[num];
				if (pHo == nil)
				{
					return 0;
				}
				if ((pHo->hoFlags & HOF_DESTROYED) == 0)		// Deja detruit?
				{
					if ([self czaCompare:pZone withObject:pHo])
					{
						count++;
					}
				}
				num = pHo->hoNumNext;
			}
			;
		}
		return count;
	}
	
	// Explore la liste des objets selectionnes
	short num = poil->oilListSelected;
	while (num >= 0)
	{
		pHo = rhPtr->rhObjectList[num];
		if (pHo == nil)
		{
			return 0;
		}
		if ((pHo->hoFlags & HOF_DESTROYED) == 0)		// Deja detruit?
		{
			if ([self czaCompare:pZone withObject:pHo])
			{
				count++;
			}
		}
		num = pHo->hoNextSelected;
	}
	;
	return count;
}

-(int)count_ZoneOneObject:(short)oil withZone:(short*)pZone
{
	// Un objet normal
	if ((oil&0x8000)==0)
	{
		return [self czoCountThem:oil withZone:pZone];
	}
	
	// Un qualifier
	if (oil == -1)
	{
		return 0;
	}
	CQualToOiList* pqoi = qualToOiList[oil & 0x7FFF];
	int qoi;
	int count = 0;
	for (qoi = 0; qoi < pqoi->nQoi; qoi += 2)
	{
		count += [self czoCountThem:pqoi->qoiList[qoi + 1] withZone:pZone];
	}
	return count;
}

// ----------------------------------------
// Compte / Trouve de objets definiss
// ----------------------------------------
// Routine de comptage
// ~~~~~~~~~~~~~~~~~~~
-(CObject*)countThem:(short)oil withStop:(int)stop
{
	CObjInfo* poil = rhPtr->rhOiList[oil];		// Pointe la liste
	CObject* pHo;
	if (poil->oilEventCount != rh2EventCount)
	{
		// Si condition OU
		if (rh4ConditionsFalse)
		{
			evtNSelectedObjects = 0;
			return nil;
		}
		
		// Explore la liste entiere des objets
		short num = poil->oilObject;
		while (num >= 0)
		{
			pHo = rhPtr->rhObjectList[num];
			if (pHo == nil)
			{
				return nil;
			}
			if ((pHo->hoFlags & HOF_DESTROYED) == 0)		// Deja detruit?
			{
				evtNSelectedObjects++;
				if (evtNSelectedObjects == stop)
				{
					return pHo;
				}
			}
			num = pHo->hoNumNext;
		}
		;
		return nil;
	}
	
	// Explore la liste des objets selectionnes
	short num = poil->oilListSelected;
	while (num >= 0)
	{
		pHo = rhPtr->rhObjectList[num];
		if (pHo == nil)
		{
			return nil;
		}
		if ((pHo->hoFlags & HOF_DESTROYED) == 0)			// Deja detruit?
		{
			evtNSelectedObjects++;
			if (evtNSelectedObjects == stop)
			{
				return pHo;
			}
		}
		num = pHo->hoNextSelected;
	}
	;
	return nil;
}

-(CObject*)count_ObjectsFromOiList:(short)oil withStop:(int)stop
{
	stop++;									// BX a partir de 1!
	evtNSelectedObjects = 0;
	if ((oil&0x8000)==0)
	{
		// Un identifier normal
		return [self countThem:oil withStop:stop];
	}
	
	// Un qualifier
	if (oil == -1)
	{
		return nil;
	}
	CQualToOiList* pqoi = qualToOiList[oil & 0x7FFF];
	int qoi;
	for (qoi = 0; qoi < pqoi->nQoi; qoi += 2)
	{
		CObject* pHo = [self countThem:pqoi->qoiList[qoi + 1] withStop:stop];
		if (pHo != nil)
		{
			return pHo;
		}
	}
	return nil;
}

// Pick un objet a partir de son fixed value
// -----------------------------------------
-(BOOL)pickFromId:(int)value
{
	int number = value & 0xFFFF;
	if (number > rhPtr->rhMaxObjects)
	{
		return NO;
	}
	CObject* pHo = rhPtr->rhObjectList[number];
	if (pHo == nil)
	{
		return NO;
	}
	
	int code = (value >> 16)&0xFFFF;
	if (code != pHo->hoCreationId)
	{
		return NO;
	}
	
	// Dans une liste selectionnee ou pas?
	CObjInfo* poil = pHo->hoOiList;
	if (poil->oilEventCount == rh2EventCount)
	{
		short next = poil->oilListSelected;
		CObject* pHoFound = nil;
		while (next >= 0)
		{
			pHoFound = rhPtr->rhObjectList[next];
			if (pHo == pHoFound)
			{
				break;
			}
			next = pHoFound->hoNextSelected;
		}
		;
		if (pHo != pHoFound)
		{
			return NO;
		}
	}
	poil->oilEventCount = rh2EventCount;			// Seul sur la liste!
	poil->oilListSelected = -1;
	poil->oilNumOfSelected = 0;
	pHo->hoNextSelected = -1;
	[self evt_AddCurrentObject:pHo];
	return YES;
}

// ---------------------------------------------------------------------------
// Pousse un evenement pour la fin du cycle
// ---------------------------------------------------------------------------
-(void)push_Event:(int)routine withCode:(int)code andParam:(int)lParam andObject:(CObject*)pHo andOI:(short)oi
{
	PushedEvent* p = (PushedEvent*)malloc(sizeof(PushedEvent));
	p->routine=routine;
	p->code=code;
	p->param=lParam;
	p->object=pHo;
	p->oi=oi;
	if (rh2PushedEvents == nil)
	{
		rh2PushedEvents = [[CArrayList alloc] init];
	}
	[rh2PushedEvents add:p];
}

// ---------------------------------------------------------------------------
// Traite tous les evenements pousse
// ---------------------------------------------------------------------------
-(void)handle_PushedEvents
{
	if (rh2PushedEvents != nil)
	{
		int index;
		for (index = 0; index < [rh2PushedEvents size]; index++)
		{
			PushedEvent* pEvt = (PushedEvent*)[rh2PushedEvents get:index];
			if (pEvt != nil)
			{
				if (pEvt->code != 0)
				{
					// Effectue l'un des evenements
					// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					rhCurParam[0] = pEvt->param;
					rhCurOi = pEvt->oi;
					switch (pEvt->routine)
					{
						case 0:
							[self handle_GlobalEvents:pEvt->code];
							break;
						case 1:
							[self handle_Event:pEvt->object withCode:pEvt->code];
							break;
					}
				}
			}
		}
		[rh2PushedEvents freeRelease];
	}
}



@end
