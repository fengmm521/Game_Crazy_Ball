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
// CRunInventory
//
//----------------------------------------------------------------------------------
#import "CRenderer.h"
#import "CRunInventory.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CActExtension.h"
#import "CImageBank.h"
#import "CServices.h"
#import "CArrayList.h"
#import "CFont.h"
#import "CRun.h"
#import "CRSpr.h"
#import "CObject.h"
#import "CSprite.h"
#import "CRCom.h"
#import "CSpriteGen.h"
#import "CObjInfo.h"
#import "CRMvt.h"
#import "CTextSurface.h"
#import "CCndExtension.h"
#import "CEventProgram.h"


#define CND_NAMEDITEMSELECTED 0
#define CND_NAMEDCOMPARENITEMS 1
#define CND_ITEMSELECTED 2
#define CND_COMPARENITEMS 3
#define CND_NAMEDITEMPRESENT 4
#define CND_ITEMPRESENT 5
#define CND_NAMEDHILIGHTED 6
#define CND_HILIGHTED 7
#define CND_CANADD 8
#define CND_NAMEDCANADD 9
#define CND_LAST 10
#define ACT_NAMEDADDITEM 0
#define ACT_NAMEDADDNITEMS 1
#define ACT_NAMEDDELITEM 2
#define ACT_NAMEDDELNITEMS 3
#define ACT_NAMEDHIDEITEM 4
#define ACT_NAMEDSHOWITEM 5
#define ACT_ADDITEM 6
#define ACT_ADDNITEMS 7
#define ACT_DELITEM 8
#define ACT_DELNITEMS 9
#define ACT_HIDEITEM 10
#define ACT_SHOWITEM 11
#define ACT_LEFT 12
#define ACT_RIGHT 13
#define ACT_UP 14
#define ACT_DOWN 15
#define ACT_SELECT 16
#define ACT_CURSOR 17
#define ACT_NAMEDSETSTRING 18
#define ACT_SETSTRING 19
#define ACT_ACTIVATE 20
#define ACT_NAMEDSETMAXIMUM 21
#define ACT_SETMAXIMUM 22
#define ACT_SETPOSITION 23
#define ACT_SETPAGE 24
#define ACT_ADDPROPERTY 25
#define ACT_NAMEDSETPROPMINMAX 26
#define ACT_SETPROPMINMAX 27
#define ACT_NAMEDADDPROPERTY 28
#define ACT_ADDGRIDITEM 29
#define ACT_ADDGRIDNITEMS 30
#define ACT_NAMEDADDGRIDITEM 31
#define ACT_NAMEDADDGRIDNITEMS 32
#define ACT_HILIGHTDROP 33
#define ACT_NAMEDHILIGHTDROP 34
#define ACT_SAVE 35
#define ACT_LOAD 36
#define ACT_ADDLISTITEM 37
#define ACT_ADDLISTNITEMS 38
#define ACT_NAMEDADDLISTITEM 39
#define ACT_NAMEDADDLISTNITEMS 40
#define EXP_NITEM 0
#define EXP_NAMEOFHILIGHTED 1
#define EXP_NAMEOFSELECTED 2
#define EXP_POSITION 3
#define EXP_PAGE 4
#define EXP_TOTAL 5
#define EXP_DISPLAYED 6
#define EXP_NUMOFSELECTED 7
#define EXP_NUMOFHILIGHTED 8
#define EXP_NAMEOFNUM 9
#define EXP_MAXITEM 10
#define EXP_NUMBERMAXITEM 11
#define EXP_NUMBERNITEM 12
#define EXP_GETPROPERTY 13
#define EXP_NUMBERGETPROPERTY 14

#define IFLAG_CURSOR 0x0001
#define IFLAG_HSCROLL 0x0002
#define IFLAG_VSCROLL 0x0004
#define IFLAG_SORT 0x0010
#define IFLAG_MOUSE 0x0020
#define IFLAG_FORCECURSOR 0x0040
#define IFLAG_CURSORBYACTION 0x0080
#define IFLAG_DISPLAYGRID 0x0100
#define INVTYPE_LIST 0
#define INVTYPE_GRID 1

#define VK_LEFT   1
#define VK_RIGHT   2
#define VK_UP   3
#define VK_DOWN   4
#define VK_RETURN   5
#define SX_SLIDER 8
#define SY_SLIDER 8

CInventoryList* inventory=nil;

@implementation CRunInventory

-(id)init
{
	if(self = [super init])
	{
		if (inventory==nil)
		{
			inventory=[[CInventoryList alloc] init];
		}
		displayList=[[CArrayList alloc] init];
		objectList=[[CArrayList alloc] init];
	}
    return self;
}

-(void)dealloc
{
    [displayList release];
    [objectList release];
    [super dealloc];
}

-(int)getNumberOfConditions
{
	return CND_LAST;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    ho->hoImgWidth=[file readAInt];
    ho->hoImgHeight=[file readAInt];
    number=[file readAShort];
    itemSx=[file readAShort];
    itemSy=[file readAShort];
    flags=[file readAInt];
    textAlignment=[file readAInt];
    logFont=[file readLogFont];
   	font = [CFont createFromFontInfo:logFont];
    [font createFont]; 
    fontColor=[file readAColor];
    scrollColor=[file readAColor];
    displayQuantity=[file readAInt];
    showQuantity=[file readAInt];
    scrollColor2=[file readAColor];
    maximum=[file readAInt];
    cursorColor=[file readAColor];
    cursorType=[file readAInt];
    type=[file readAShort];
    gridColor=[file readAColor];
    pDisplayString=[file readAString];
    nColumns=MAX(ho->hoImgWidth/itemSx, 1);
    nLines=MAX(ho->hoImgHeight/itemSy, 1);
    selectedCount=-1;
    numSelected=-1;
    numHilighted=-1;
    position=0;
    bDropItem=NO;
    if (type==INVTYPE_LIST)
    {
        slider=[[CScrollBar alloc] init];
        [self SetSlider];
    }
    [self UpdateDisplayList];
    oldBHidden=NO;
    bUpdateList=YES;
    font=[CFont createFromFontInfo:logFont];
	textSurface = [[CTextSurface alloc] initWidthWidth:ho->hoImgWidth andHeight:ho->hoImgHeight];
    tempValue=[[CValue alloc] initWithInt:0];
    return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
    [tempValue release];
	[textSurface release];
    [slider release];
}

-(void)SetSlider
{
    if ((flags&IFLAG_HSCROLL)!=0)
    {
        int x=ho->hoX;
        int y=ho->hoY+ho->hoImgHeight-SY_SLIDER;
        [slider Initialise:rh withParam1:x andParam2:y andParam3:ho->hoImgWidth andParam4:SY_SLIDER andParam5:scrollColor andParam6:scrollColor2];
    }
    else if ((flags&IFLAG_VSCROLL)!=0)
    {
        int x=ho->hoX-ho->hoImgWidth-SX_SLIDER;
        int y=ho->hoY;
        [slider Initialise:rh withParam1:x andParam2:y andParam3:SX_SLIDER andParam4:ho->hoImgHeight andParam5:scrollColor andParam6:scrollColor2];
    }
}
-(void)obHide:(CObject*)hoPtr
{
    if ((hoPtr->ros->rsFlags&RSFLAG_HIDDEN)==0)
    {
        hoPtr->ros->rsFlags|=RSFLAG_HIDDEN;
        hoPtr->ros->rsCreaFlags|=SF_HIDDEN;
        hoPtr->ros->rsFadeCreaFlags|=SF_HIDDEN;
        hoPtr->roc->rcChanged=YES;
        if (hoPtr->roc->rcSprite!=nil)
        {
            [rh->spriteGen showSprite:hoPtr->roc->rcSprite withFlag:NO];
        }
    }
}

-(void)obShow:(CObject*)hoPtr
{
    if ((hoPtr->ros->rsFlags&RSFLAG_HIDDEN)!=0)
    {
        hoPtr->ros->rsCreaFlags&=~SF_HIDDEN;
        hoPtr->ros->rsFadeCreaFlags&=~SF_HIDDEN;
        hoPtr->ros->rsFlags&=~RSFLAG_HIDDEN;
        hoPtr->hoFlags&=~HOF_NOCOLLISION;	
        hoPtr->roc->rcChanged=YES;
        if (hoPtr->roc->rcSprite!=nil)
        {
            [rh->spriteGen showSprite:hoPtr->roc->rcSprite withFlag:YES];
        }
    }
}

-(int)GetFixedValue:(CObject*)pho
{
    return (pho->hoCreationId<<16)|(pho->hoNumber&0xFFFF);
}

-(CObject*)GetHO:(int)fixedValue
{
    CObject* hoPtr=rh->rhObjectList[fixedValue&0xFFFF];
    if (hoPtr!=nil && hoPtr->hoCreationId==fixedValue>>16)
    {
        return hoPtr;
    }
    return nil;
}

-(void)showHide:(BOOL)bHidden
{
    int n;
    if (!bHidden)
    {
        for (n=0; n<[objectList size]; n++)
        {
            CObject* hoPtr=[self GetHO:[objectList getInt:n]];
            if (hoPtr!=nil)
            {
                [self obShow:hoPtr];
            }
        }
    }
    else
    {
        for (n=0; n<[objectList size]; n++)
        {
            CObject* hoPtr=[self GetHO:[objectList getInt:n]];
            if (hoPtr!=nil)
            {
                [self obHide:hoPtr];
            }
        }
    }
}

-(void)CenterDisplay:(int)pos
{
    int size=nColumns*nLines;
    if (pos<position)
    {
        position=pos;
    }
    else if (pos>=position+size)
    {
        position=MAX(0, pos-size+1);
    }
}

-(void)UpdateDisplayList
{
    [displayList clear];
    [objectList clear];
    if (type==INVTYPE_GRID)
    {
        if (pGrid==nil)
        {
            pGrid=(int*)malloc(nColumns*nLines*sizeof(int));
        }
        int n;
        for (n=nColumns*nLines-1; n>=0; n--)
            pGrid[n]=0;
    }
    
    CInventoryItem* pItem;
    for (pItem=[inventory FirstItem:number]; pItem!=nil; pItem=[inventory NextItem:number])
    {
        NSString* pName=[pItem GetName];
        int objectNum=0;
        for (int nObject=0; nObject<rh->rhNObjects; objectNum++, nObject++)
        {
            while(rh->rhObjectList[objectNum]==nil) objectNum++;
            CObject* hoPtr=rh->rhObjectList[objectNum];
            if (hoPtr->hoType==2)
            {
                CObjInfo* pOiList=hoPtr->hoOiList;
                if ([pOiList->oilName compare:pName]==0)
                {
                    if ([pItem GetQuantity]>=showQuantity)
                    {
                        if (([pItem GetFlags]&INVFLAG_VISIBLE)!=0)
                        {
                            [displayList add:pItem];
                            int fix=[self GetFixedValue:hoPtr];
                            [objectList addInt:fix];
                            if (type==INVTYPE_GRID)
                            {
                                int sx=(hoPtr->hoImgWidth+itemSx-1)/itemSx;
                                int sy=(hoPtr->hoImgHeight+itemSy-1)/itemSy;
                                int x, y;
                                for (y=0; y<sy; y++)
                                {
                                    for (x=0; x<sx; x++)
                                    {
                                        pGrid[(pItem->y+y)*nColumns+pItem->x+x]=fix;
                                    }
                                }
                                [rh->spriteGen moveSpriteToFront:hoPtr->roc->rcSprite];
                            }
                        }
                        else
                        {
                            [self obHide:hoPtr];
                        }
                        break;
                    }
                    else
                    {
                        [self obHide:hoPtr];
                    }
                }
            }
        }
    }
    if (type==INVTYPE_LIST && [displayList size]>2 && (flags&IFLAG_SORT)!=0)
    {
        int n;
        BOOL bFlag=YES;
        while(bFlag==YES)
        {
            bFlag=NO;
            for (n=0; n<[displayList size]-1; n++)
            {
                CInventoryItem* pItem1=(CInventoryItem*)[displayList get:n];
                CInventoryItem* pItem2=(CInventoryItem*)[displayList get:n+1];
                NSString* pName1=[pItem1 GetName];
                NSString* pName2=[pItem2 GetName];
                if ([pName1 compare:pName2]>0)
                {
                    swap(displayList, n, n+1);
                    swap(objectList, n, n+1);
                    bFlag=YES;
                }
            }
        }
    }
    bUpdateList=YES;
    [ho redraw];
}


-(void)SetPosition:(CObject*)pho withX:(int)x andY:(int)y
{
    pho->hoX=x+pho->hoImgXSpot;
    pho->hoY=y+pho->hoImgYSpot;
    pho->rom->rmMoveFlag=YES;	
    pho->roc->rcChanged=YES;
    pho->roc->rcCheckCollides=YES;
}

-(BOOL)CheckDisplayList
{
    BOOL bRet=NO;
    int o;
    for (o=0; o<[displayList size]; o++)
    {
        int fixedValue=[objectList getInt:o];
        CObject* hoPtr=[self GetHO:fixedValue];
        if (hoPtr==nil)
        {
            [displayList removeIndex:o];
            [objectList removeIndex:o];
            o--;
            bRet=YES;
        }
    }
    return bRet;
}

-(int)GetGridRect:(int)x withParam1:(int)y andParam2:(CRect*)pRc
{
    int fix=pGrid[y*nColumns+x];
    if (fix!=0)
    {
        int xx, yy;
        for (xx=0; xx<x; xx++)
        {
            if (pGrid[y*nColumns+xx]==fix)
            {
                break;
            }
        }
        pRc->left=ho->hoX + xx*itemSx;
        for (xx=x; xx<nColumns; xx++)
        {
            if (pGrid[y*nColumns+xx]!=fix)
            {
                break;
            }
        }
        pRc->right=ho->hoX + xx*itemSx;
        for (yy=0; yy<y; yy++)
        {
            if (pGrid[yy*nColumns+x]==fix)
            {
                break;
            }
        }
        pRc->top=ho->hoY + yy*itemSy;
        for (yy=y; yy<nLines; yy++)
        {
            if (pGrid[yy*nColumns+x]!=fix)
            {
                break;
            }
        }
        pRc->bottom=ho->hoY + yy*itemSy;
    }
    else
    {
        pRc->left=ho->hoX + x*itemSx;
        pRc->right=pRc->left+itemSx;
        pRc->top=ho->hoY + y*itemSy;
        pRc->bottom=pRc->top+itemSy;
    }
    return fix;
}
-(void)cleanList
{
    int n;
    for (n=0; n<[objectList size]; n++)
    {
        int fixed=[objectList getInt:n];
        if ([self GetHO:fixed]==nil)
        {
            CInventoryItem* pItem=(CInventoryItem*)[displayList get:n];
            [inventory->list removeObject:pItem];
        }
    }
}

-(int)handleRunObject
{
    short ret=0;
    BOOL bUpdate=NO;
    
    [self cleanList];
    if (bUpdateList)
    {
        [self UpdateDisplayList];
        ret=REFLAG_DISPLAY;
    }
    else
    {
        if ([self CheckDisplayList])
        {
            ret=REFLAG_DISPLAY;
        }
    }
    if (bRedraw)
    {
        ret=REFLAG_DISPLAY;
        bRedraw = NO;
    }
    
    BOOL bHidden=(ho->ros->rsFlags&RSFLAG_HIDDEN)!=0;
    if (bHidden!=oldBHidden)
    {
        oldBHidden=bHidden;
        [self showHide:bHidden];
    }
    if (bHidden)
    {
        return ret;
    }
    
    int fix;
    int x, y, xx, yy;
    BOOL bFlag;
    if (type == INVTYPE_LIST)
    {
        if (position>0 && position>MAX(0, [displayList size]-nLines*nColumns))
        {
            position=(int)MAX([displayList size]-nLines*nColumns, 0);
            bUpdate=YES;
        }
        if (position+yCursor*nColumns+xCursor>=[displayList size])
        {
            xCursor=0;
            yCursor=0;
            bUpdate=YES;
        }
        if ([displayList size]>0)
        {
            xx=rh->rh2MouseX-ho->hoX;
            yy=rh->rh2MouseY-ho->hoY;
            x=xx;
            y=yy;
            bFlag=NO;
            if ((flags&IFLAG_MOUSE)!=0)
            {
                if (x>=0 && y>=0 && x<ho->hoImgWidth && y<ho->hoImgHeight)
                {
                    x/=itemSx;
                    y/=itemSy;
                    if (x<nColumns && y<nLines)
                    {
                        int o=position+y*nColumns+x;
                        if (o<position+[displayList size])
                        {
                            bFlag=YES;
                            if (xCursor!=x || yCursor!=y)
                            {
                                xCursor=x;
                                yCursor=y;
                                bUpdate=YES;
                            }
                            CInventoryItem* pItem=(CInventoryItem*)[displayList get:o];
                            pNameHilighted=[pItem GetName];
                            numHilighted=o;
                        }
                    }
                }
            }
            BOOL bMouse=rh->rhApp->bMouseDown;
            if (bMouse!=oldBMouse)
            {
                oldBMouse=bMouse;
                if (bMouse==YES && (flags&IFLAG_MOUSE)!=0)
                {
                    scrollX=x*itemSx;
                    scrollY=y*itemSy;
                    scrollPosition=position;
                    pNameSelected=pNameHilighted;
                    numSelected=position+yCursor*nColumns+xCursor;
                    selectedCount=rh->rh4EventCount;
                    CInventoryItem* pItem=(CInventoryItem*)[displayList get:position+yCursor*nColumns+xCursor];
                    CObject* hoPtr=[self GetHO:[objectList getInt:position+yCursor*nColumns+xCursor]];
                    conditionString=[pItem GetName];
                    [ho generateEvent:CND_NAMEDITEMSELECTED withParam:0];
                    [ho generateEvent:CND_ITEMSELECTED withParam:hoPtr->hoOi];
                }
                if ((flags&IFLAG_CURSOR)!=0 && x>=0 && y>=0 && x<ho->hoImgWidth && y<ho->hoImgHeight)
                {
                    bActivated=YES;
                    xCursor=x/itemSx;
                    yCursor=y/itemSy;
                    bUpdate=YES;
                }
                else
                {
                    bActivated=NO;
                    bUpdate=YES;
                }
            }
            if (bMouse)
            {
                if ((flags&IFLAG_VSCROLL)!=0)
                {
                    if (yy<scrollY)
                        position=scrollPosition-((yy-scrollY-itemSy)/itemSy)*nColumns;
                    else
                        position=scrollPosition-((yy-scrollY)/itemSy)*nColumns;
                    if (position<0)
                        position=0;
                    if (position>MAX(0, [displayList size]-nLines*nColumns))
                        position=(int)MAX([displayList size]-nLines*nColumns, 0);
                    bUpdate=YES;
                }
                else if ((flags&IFLAG_HSCROLL)!=0)
                {
                    if (xx<scrollX)
                        position=scrollPosition-((xx-scrollX-itemSx)/itemSx)*nLines;
                    else
                        position=scrollPosition-((xx-scrollX)/itemSx)*nLines;
                    if (position<0)
                        position=0;
                    if (position>MAX(0, [displayList size]-nLines*nColumns))
                        position=(int)MAX([displayList size]-nLines*nColumns, 0);
                    bUpdate=YES;
                }
            }
            if (bActivated)
            {
                bFlag=YES;
            }
            if ((flags&IFLAG_CURSORBYACTION)==0)
            {
                if (bFlag)
                {
                    if ((flags&IFLAG_FORCECURSOR)==0)
                    {
                        flags|=IFLAG_FORCECURSOR;
                        bUpdate=YES;
                    }
                }
                else
                {
                    if ((flags&IFLAG_FORCECURSOR)!=0)
                    {
                        flags&=~IFLAG_FORCECURSOR;
                        bUpdate=YES;
                    }
                }
            }
        }
        
        if (bUpdate)
        {
            if (slider->bInitialised)
            {
                [slider SetPosition:position withParam1:(int)MIN([displayList size]-position, nLines*nColumns) andParam2:(int)[displayList size]];
            }
        }
    }
    else
    {
        // Grid display
        x=rh->rh2MouseX-ho->hoX;
        y=rh->rh2MouseY-ho->hoY;
        bFlag=NO;
        if ((flags&IFLAG_MOUSE)!=0)
        {
            if (x>=0 && y>=0 && x<ho->hoImgWidth && y<ho->hoImgHeight)
            {
                x/=itemSx;
                y/=itemSy;
                if (x<nColumns && y<nLines)
                {
                    bFlag=YES;
                    if (xCursor!=x || yCursor!=y)
                    {
                        xCursor=x;
                        yCursor=y;
                        ret=REFLAG_DISPLAY;
                    }                    
                    int oo=y*nColumns+x;
                    int fixo=pGrid[oo];
                    
                    if (fixo!=0)
                    {
                        
                        int nn;
                        for (nn=0; nn<[objectList size]; nn++)
                            if (fixo==[objectList getInt:nn])
                                break;
                        if (nn<[objectList size])
                        {
                            CInventoryItem* pItemm=(CInventoryItem*)[displayList get:nn];
                            pNameHilighted=[pItemm GetName];
                            numHilighted=oo;
                        }
                    }
                }
            }
        }
        BOOL bMouse=rh->rhApp->bMouseDown;
        if (bMouse!=oldBMouse)
        {
            oldBMouse=bMouse;
            if (bMouse && (flags&IFLAG_MOUSE)!=0)
            {
                fix=pGrid[yCursor*nColumns+xCursor];
                if (fix!=0)
                {
                    pNameSelected=pNameHilighted;
                    numSelected=yCursor*nColumns+xCursor;
                    selectedCount=rh->rh4EventCount;
                    CObject* hoPtr=[self GetHO:fix];
                    conditionString=hoPtr->hoOiList->oilName;
                    [ho generateEvent:CND_NAMEDITEMSELECTED withParam:0];
                    [ho generateEvent:CND_ITEMSELECTED withParam:hoPtr->hoOi];
                }
            }
            if ((flags&IFLAG_CURSOR)!=0 && x>=0 && y>=0 && x<ho->hoImgWidth && y<ho->hoImgHeight)
            {
                bActivated=YES;
                xCursor=x/itemSx;
                yCursor=y/itemSy;
                ret=REFLAG_DISPLAY;
            }
            else
            {
                bActivated=NO;
                ret=REFLAG_DISPLAY;
            }
        }
        if (bActivated)
        {
            bFlag=YES;
        }
        if ((flags&IFLAG_CURSORBYACTION)==0)
        {
            if (bFlag)
            {
                if ((flags&IFLAG_FORCECURSOR)==0)
                {
                    flags|=IFLAG_FORCECURSOR;
                    ret=REFLAG_DISPLAY;
                }
            }
            else
            {
                if ((flags&IFLAG_FORCECURSOR)!=0)
                {
                    flags&=~IFLAG_FORCECURSOR;
                    ret=REFLAG_DISPLAY;
                }
            }
        }
    }
    if (bUpdate)
    {
        bUpdateList=YES;
        ret=REFLAG_DISPLAY;
    }
    return ret;
}


#define SX_SEPARATION 8
#define SY_SEPARATION 8

-(void)displayRunObject:(CRenderer*)renderer
{
    if (type==INVTYPE_LIST)
    {
        if ([displayList size]==0)
        {
            return;
        }

        if (bUpdateList)
        {
            [textSurface manualClear:fontColor];            
        }
        
        int o;
        pNameHilighted=nil;
        numHilighted=-1;
		bool uploadTexture = NO;
        for (o=0; o<[displayList size]; o++)
        {
            CObject* hoPtr=[self GetHO:[objectList getInt:o]];
            if (hoPtr!=nil && o>=position && o<position+nLines*nColumns)
            {
                CInventoryItem* pItem=(CInventoryItem*)[displayList get:o];
                [self obShow:hoPtr];
                
                int line=(o-position)/nColumns;
                int column=(o-position)-line*nColumns;		
                int xObject=column*itemSx+itemSx/2-hoPtr->hoImgWidth/2;
                int yObject=line*itemSy+itemSy/2-hoPtr->hoImgHeight/2;
                int sy;
                
                if (o==position+xCursor+yCursor*nColumns)
                {
                    CRect rc;
                    rc.left=ho->hoX + column*itemSx;
                    rc.top=ho->hoY + line*itemSy;
                    rc.right=rc.left+itemSx-1;
                    rc.bottom=rc.top+itemSy-1;
                    pNameHilighted=[pItem GetName];
                    numHilighted=o;
                    if ((flags&IFLAG_FORCECURSOR)!=0 && cursorType>0) 
                    {
                        if (cursorType==1)
                            invDrawRect(renderer, rc, cursorColor);
                        else
                            invFillRect(renderer, rc, cursorColor);
                    }
                }
                
                if (maximum>1 && bUpdateList==YES)
                {

                    CRect rcText;
                    int dtFlags;
                    NSString* text=[pItem GetDisplayString];
                    NSString* temp=nil;
                    NSUInteger pos=[text rangeOfString:@"%q"].location;
                    if (pos != NSNotFound)
                    {
                        temp=[text substringToIndex:pos];
                        temp=[temp stringByAppendingFormat:@"%i", [pItem GetQuantity]];
                        temp=[temp stringByAppendingString:[text substringFromIndex:pos+2]];
                        text = temp;
                    }
                    pos=[text rangeOfString:@"%m"].location;
                    if (pos != NSNotFound)
                    {
                        temp=[text substringToIndex:pos];
                        temp=[temp stringByAppendingFormat:@"%i", [pItem GetMaximum]];
                        temp=[temp stringByAppendingString:[text substringFromIndex:pos+2]];
                    }
                    text=temp;
                    rcText.left=0;
                    rcText.top=0;
                    rcText.right=1000;
                    rcText.bottom=1000;
                    int syText=[CServices drawText:nil withString:text andFlags:DT_LEFT|DT_TOP|DT_CALCRECT andRect:rcText andColor:0 andFont:font andEffect:0 andEffectParam:0];
                    
                    if ((textAlignment&0x00000001)!=0)       // TEXT_ALIGN_LEFT)
                    {
                        rcText.left=column*itemSx;
                        rcText.right=rcText.left+itemSx;
                        dtFlags=DT_LEFT;
                        xObject=(column+1)*itemSx-hoPtr->hoImgWidth;
                    }
                    else if ((textAlignment&0x00000002)!=0)  //TEXT_ALIGN_HCENTER)
                    {
                        rcText.left=column*itemSx;
                        rcText.right=rcText.left+itemSx;
                        dtFlags=DT_CENTER;
                    }
                    else											// (textAlignment&TEXT_ALIGN_RIGHT)
                    {
                        xObject=column*itemSx;
                        rcText.left=xObject+hoPtr->hoImgWidth+SX_SEPARATION;
                        rcText.right=xObject+itemSx;
                        dtFlags=DT_LEFT;
                    }
                    if ((textAlignment&0x00000008)!=0)       //TEXT_ALIGN_TOP)
                    {
                        sy=hoPtr->hoImgHeight+SY_SEPARATION+syText;
                        rcText.top=line*itemSy+itemSy/2-sy/2;
                        rcText.bottom=rcText.top+syText;
                        yObject=(int)(rcText.top+syText+SY_SEPARATION);
                        dtFlags|=DT_TOP;
                    }
                    else if ((textAlignment&0x00000010)!=0)  //TEXT_ALIGN_VCENTER)
                    {
                        rcText.top=line*itemSy+itemSy/2-syText/2;
                        rcText.bottom=rcText.top+syText;
                        yObject=line*itemSy+itemSy/2-hoPtr->hoImgHeight/2;
                        dtFlags|=DT_VCENTER;
                    }
                    else											// (textAlignment&TEXT_ALIGN_BOTTOM)
                    {
                        sy=hoPtr->hoImgHeight+SY_SEPARATION+syText;
                        yObject=line*itemSy+itemSy/2-sy/2;
                        rcText.top=yObject+hoPtr->hoImgHeight+SY_SEPARATION;
                        rcText.bottom=rcText.top+syText;
                        dtFlags|=DT_TOP;
                    }
                    if ([pItem GetQuantity]>=displayQuantity)
                    {
                        [textSurface manualDrawText:text withFlags:0 andRect:rcText andColor:fontColor andFont:font];
						uploadTexture = YES;
                    }
                }
                if (bUpdateList)
                {
                    [self SetPosition:hoPtr withX:ho->hoX+xObject andY:ho->hoY+yObject];
                }
            }
            else
            {
                [self obHide:hoPtr];
            }
        }
		if(uploadTexture)
			[textSurface manualUploadTexture];
		[textSurface draw:renderer withX:ho->hoX andY:ho->hoY andEffect:0 andEffectParam:0];
        [self SetSlider];
		[slider DrawBar:renderer];
    }
    else
    {
        if ((flags&IFLAG_DISPLAYGRID)!=0)
        {
            CRect rc;
            int x, y;
            for (y=0; y<nLines; y++)
            {
                for (x=0; x<nColumns; x++)
                {
                    [self GetGridRect:x withParam1:y andParam2:&rc];
                    invDrawRect(renderer, rc, gridColor);
                }
            }		
            
            if (bDropItem==NO)
            {
                [self GetGridRect:xCursor withParam1:yCursor andParam2:&rc];
            }
            else
            {
				rc = rcDrop;
            }
            if (bDropItem || ((flags&IFLAG_FORCECURSOR)!=0 && cursorType>0)) 
            {
                invFillRect(renderer, rc, cursorColor);
            }
        }
        if (bUpdateList)
        {
            int o;
            for (o=0; o<[displayList size]; o++)
            {
                CObject* hoPtr=[self GetHO:[objectList getInt:o]];
                if (hoPtr!=nil)
                {
                    CInventoryItem* pItem=(CInventoryItem*)[displayList get:o];
                    [self obShow:hoPtr];
                    
                    int sx=(hoPtr->hoImgWidth+itemSx-1)/itemSx;
                    int sy=(hoPtr->hoImgHeight+itemSy-1)/itemSy;
                    CRect rc;
                    [self GetGridRect:pItem->x withParam1:pItem->y andParam2:&rc];
                    int xObject=(int)((rc.left+rc.right)/2 - sx - hoPtr->hoImgWidth/2);
                    int yObject=(int)((rc.top+rc.bottom)/2 - sy - hoPtr->hoImgHeight/2);
                    [self SetPosition:hoPtr withX:xObject andY:yObject];
                }
            }
        }
    }
    bUpdateList=NO;
    bDropItem=NO;
}

-(CFontInfo*)getRunObjectFont
{
    return logFont;
}

-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect*)rc
{
    logFont = fi;
    font = [CFont createFromFontInfo:fi];
    if (rc!=nil)
    {
        ho->hoImgWidth=(int)(rc->right-rc->left);
        ho->hoImgHeight=(int)(rc->bottom-rc->top);
    }
    [ho redraw];
}

-(int)getRunObjectTextColor
{
    return fontColor;
}

-(void)setRunObjectTextColor:(int)rgb
{
    fontColor = rgb;
    [ho redraw];
}



-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
    switch(num)
    {
        case CND_NAMEDITEMSELECTED:
            return [self RCND_NAMEDITEMSELECTED:cnd];
        case CND_NAMEDCOMPARENITEMS:
            return [self RCND_NAMEDCOMPARENITEMS:cnd];
        case CND_ITEMSELECTED:
            return [self RCND_ITEMSELECTED:cnd];
        case CND_COMPARENITEMS:
            return [self RCND_COMPARENITEMS:cnd];
        case CND_NAMEDITEMPRESENT:
            return [self RCND_NAMEDITEMPRESENT:cnd];
        case CND_ITEMPRESENT:
            return [self RCND_ITEMPRESENT:cnd];
        case CND_NAMEDHILIGHTED:
            return [self RCND_NAMEDHILIGHTED:cnd];
        case CND_HILIGHTED:
            return [self RCND_HILIGHTED:cnd];
        case CND_CANADD:
            return [self RCND_CANADD:cnd];
        case CND_NAMEDCANADD:
            return [self RCND_NAMEDCANADD:cnd];												
    }
    return NO;
}

-(BOOL)RCND_NAMEDITEMSELECTED:(CCndExtension*)cnd
{
    NSString* pName=[cnd getParamExpString:rh withNum:0];
    if ([pName compare:conditionString]==0)
    {
        if ((ho->hoFlags & HOF_TRUEEVENT)!=0)
        {
            return YES;
        }
        
        if (rh->rh4EventCount == selectedCount)
        {
            return YES;
        }
    }
    return NO;
}
-(BOOL)RCND_NAMEDCOMPARENITEMS:(CCndExtension*)cnd
{
    CInventoryItem* pItem=[inventory GetItem:number withParam1:[cnd getParamExpString:rh withNum:0]];
    if (pItem!=nil)
    {
        [tempValue forceInt:[pItem GetQuantity]];
        return [cnd compareValues:rh withNum:0 andValue:tempValue];
    }
    return NO;
}
-(BOOL)RCND_ITEMSELECTED:(CCndExtension*)cnd
{
    short oi=[cnd getParamObject:rh withNum:0]->evp.evpW.evpW0;
    
    if (oi==rh->rhEvtProg->rhCurParam[0])
    {
        if ((ho->hoFlags & HOF_TRUEEVENT)!=0)
        {
            return YES;
        }
        
        if (rh->rh4EventCount == selectedCount)
        {
            return YES;
        }
    }
    return NO;
}
-(BOOL)RCND_COMPARENITEMS:(CCndExtension*)cnd
{
    short oi=[cnd getParamObject:rh withNum:0]->evp.evpW.evpW0;
    
    int n;
    for (n=0; n<[objectList size]; n++)
    {
        CObject* hoPtr=[self GetHO:[objectList getInt:n]];
        if (hoPtr->hoOi==oi)
        {
            CInventoryItem* pItem=(CInventoryItem*)[displayList get:n];
            [tempValue forceInt:[pItem GetQuantity]];
            return [cnd compareValues:rh withNum:1 andValue:tempValue];
        }
    }
    return NO;
}
-(BOOL)RCND_NAMEDITEMPRESENT:(CCndExtension*)cnd
{
    CInventoryItem* pItem=[inventory GetItem:number withParam1:[cnd getParamExpString:rh withNum:0]];
    if (pItem!=nil)
    {
        if ([pItem GetQuantity]>0)
        {
            return YES;
        }
    }
    return NO;
}
-(BOOL)RCND_ITEMPRESENT:(CCndExtension*)cnd
{
    short oi=[cnd getParamObject:rh withNum:0]->evp.evpW.evpW0;
    
    int n;
    for (n=0; n<[objectList size]; n++)
    {
        CObject* hoPtr=[self GetHO:[objectList getInt:n]];
        if (hoPtr->hoOi==oi)
        {
            CInventoryItem* pItem=(CInventoryItem*)[displayList get:n];
            if ([pItem GetQuantity]>0)
            {
                return YES;
            }
        }
    }
    return NO;
}
-(BOOL)RCND_NAMEDHILIGHTED:(CCndExtension*)cnd
{
    NSString* pName=[cnd getParamExpString:rh withNum:0];
    if (pNameHilighted!=nil)
    {
        if ([pName compare:pNameHilighted]==0)
        {
            return YES;
        }
    }
    return NO;
}
-(BOOL)RCND_HILIGHTED:(CCndExtension*)cnd
{
    short oiList=[cnd getParamObject:rh withNum:0]->evp.evpW.evpW1;
    CObjInfo* pOiList=rh->rhOiList[oiList];
    if (pNameHilighted!=nil)
    {
        if ([pOiList->oilName compare:pNameHilighted]==0)
        {
            return YES;
        }
    }
    return NO;
}

-(BOOL)RCND_CANADD:(CCndExtension*)cnd
{
    if (type!=INVTYPE_GRID)
    {
        return NO;
    }
    
    int xx=[cnd getParamExpression:rh withNum:1];
    int yy=[cnd getParamExpression:rh withNum:2];
    
    if (xx<0 || xx>=nColumns || yy<0 || yy>=nLines)
    {
        return NO;
    }
    
    CObject* hoPtr;
    CObjInfo* pOiList=rh->rhOiList[[cnd getParamObject:rh withNum:0]->evp.evpW.evpW1];
    short numb=pOiList->oilObject;
    if (numb>=0)
    {
        hoPtr=rh->rhObjectList[numb];
        int sx=(hoPtr->hoImgWidth+itemSx-1)/itemSx;
        int sy=(hoPtr->hoImgHeight+itemSy-1)/itemSy;
        if (xx+sx>nColumns || yy+sy>nLines)
        {
            return NO;
        }
        int x, y;
        for (y=0; y<sy; y++)
        {
            for (x=0; x<sx; x++)
            {
                if (pGrid[(yy+y)*nColumns+xx+x]!=0)
                {
                    return NO;
                }
            }
        }
        rcDrop.left=ho->hoX + xx*itemSx;
        rcDrop.right=rcDrop.left+itemSx;
        rcDrop.top=ho->hoY + yy*itemSy;
        rcDrop.bottom=rcDrop.top+itemSy;
        bDropItem=YES;
        return YES;
    }
    return NO;
}
-(BOOL)GridCanAdd:(NSString*)pName withParam1:(int)xx andParam2:(int)yy andParam3:(BOOL)bDrop
{
    if (type!=INVTYPE_GRID)
    {
        return NO;
    }
    if (xx<0 || xx>=nColumns || yy<0 || yy>=nLines)
    {
        return NO;
    }
    
    CObject* hoPtr;
    int n;
    for (n=0; n<rh->rhMaxOI; n++)
    {
        if (rh->rhOiList[n]->oilName==pName)
        {
            short numb = rh->rhOiList[n]->oilObject;
            if (numb>=0)
            {
                hoPtr=rh->rhObjectList[numb];
                int sx=(hoPtr->hoImgWidth+itemSx-1)/itemSx;
                int sy=(hoPtr->hoImgHeight+itemSy-1)/itemSy;
                if (xx+sx>nColumns || yy+sy>nLines)
                {
                    return NO;
                }
                int x, y;
                for (y=0; y<sy; y++)
                {
                    for (x=0; x<sx; x++)
                    {
                        if (pGrid[(yy+y)*nColumns+xx+x]!=0)
                        {
                            return NO;
                        }
                    }
                }
                if (bDrop)
                {
                    rcDrop.left=ho->hoX + xx*itemSx;
                    rcDrop.right=rcDrop.left+itemSx;
                    rcDrop.top=ho->hoY + yy*itemSy;
                    rcDrop.bottom=rcDrop.top+itemSy;
                    bDropItem=YES;
                }
                return YES;
            }
        }
    }
    return NO;
}
-(BOOL)RCND_NAMEDCANADD:(CCndExtension*)cnd
{
    if (type==INVTYPE_GRID)
    {
        NSString* name=[cnd getParamExpString:rh withNum:0];
        int xx=[cnd getParamExpression:rh withNum:1];
        int yy=[cnd getParamExpression:rh withNum:2];
        return [self GridCanAdd:name withParam1:xx andParam2:yy andParam3:YES];
    }
    return NO;
}





-(void)action:(int)num withActExtension:(CActExtension*)act
{
    switch (num)
    {
        case ACT_NAMEDADDITEM:
            [self RACT_NAMEDADDITEM:act];
            break;
        case ACT_NAMEDADDNITEMS:
            [self RACT_NAMEDADDNITEMS:act];
            break;
        case ACT_NAMEDDELITEM:
            [self RACT_NAMEDDELITEM:act];
            break;
        case ACT_NAMEDDELNITEMS:
            [self RACT_NAMEDDELNITEMS:act];
            break;
        case ACT_NAMEDHIDEITEM:
            [self RACT_NAMEDHIDEITEM:act];
            break;
        case ACT_NAMEDSHOWITEM:
            [self RACT_NAMEDSHOWITEM:act];
            break;
        case ACT_ADDITEM:
            [self RACT_ADDITEM:act];
            break;
        case ACT_ADDNITEMS:
            [self RACT_ADDNITEMS:act];
            break;
        case ACT_DELITEM:
            [self RACT_DELITEM:act];
            break;
        case ACT_DELNITEMS:
            [self RACT_DELNITEMS:act];
            break;
        case ACT_HIDEITEM:
            [self RACT_HIDEITEM:act];
            break;
        case ACT_SHOWITEM:
            [self RACT_SHOWITEM:act];
            break;
        case ACT_LEFT:
            [self RACT_LEFT:act];
            break;
        case ACT_RIGHT:
            [self RACT_RIGHT:act];
            break;
        case ACT_UP:
            [self RACT_UP:act];
            break;
        case ACT_DOWN:
            [self RACT_DOWN:act];
            break;
        case ACT_SELECT:
            [self RACT_SELECT:act];
            break;
        case ACT_CURSOR:
            [self RACT_CURSOR:act];
            break;
        case ACT_NAMEDSETSTRING:
            [self RACT_NAMEDSETSTRING:act];
            break;
        case ACT_SETSTRING:
            [self RACT_SETSTRING:act];
            break;
        case ACT_ACTIVATE:
            [self RACT_ACTIVATE:act];
            break;
        case ACT_NAMEDSETMAXIMUM:
            [self RACT_NAMEDSETMAXIMUM:act];
            break;
        case ACT_SETMAXIMUM:
            [self RACT_SETMAXIMUM:act];
            break;
        case ACT_SETPOSITION:
            [self RACT_SETPOSITION:act];
            break;
        case ACT_SETPAGE:
            [self RACT_SETPAGE:act];
            break;
        case ACT_ADDPROPERTY:
            [self RACT_ADDPROPERTY:act];
            break;
        case ACT_NAMEDSETPROPMINMAX:
            [self RACT_NAMEDSETPROPMINMAX:act];
            break;
        case ACT_SETPROPMINMAX:
            [self RACT_SETPROPMINMAX:act];
            break;
        case ACT_NAMEDADDPROPERTY:
            [self RACT_NAMEDADDPROPERTY:act];
            break;
        case ACT_ADDGRIDITEM:
            [self RACT_ADDGRIDITEM:act];
            break;
        case ACT_ADDGRIDNITEMS:
            [self RACT_ADDGRIDNITEMS:act];
            break;
        case ACT_NAMEDADDGRIDITEM:
            [self RACT_NAMEDADDGRIDITEM:act];
            break;
        case ACT_NAMEDADDGRIDNITEMS:
            [self RACT_NAMEDADDGRIDNITEMS:act];
            break;
        case ACT_HILIGHTDROP:
            [self RACT_HILIGHTDROP:act];
            break;
        case ACT_NAMEDHILIGHTDROP:
            [self RACT_NAMEDHILIGHTDROP:act];
            break;
        case ACT_SAVE:
            [self RACT_SAVE:act];
            break;
        case ACT_LOAD:
            [self RACT_LOAD:act];
            break;
        case ACT_ADDLISTITEM:
            [self RACT_ADDLISTITEM:act];
            break;
        case ACT_ADDLISTNITEMS:
            [self RACT_ADDLISTNITEMS:act];
            break;
        case ACT_NAMEDADDLISTITEM:
            [self RACT_NAMEDADDLISTITEM:act];
            break;
        case ACT_NAMEDADDLISTNITEMS:
            [self RACT_NAMEDADDLISTNITEMS:act];
            break;
    }
}

-(CInventoryItem*)FindItem:(NSString*)pName
{
    int n;
    CObject* hoPtr;
    for (n=0; n<[objectList size]; n++)
    {
        hoPtr=[self GetHO:[objectList getInt:n]];
        if (pName==hoPtr->hoOiList->oilName)
        {
            return (CInventoryItem*)[displayList get:n];
        }
    }
    return nil;
}
-(CObject*)FindHO:(NSString*)pName
{
    int n;
    CObject* hoPtr;
    for (n=0; n<[objectList size]; n++)
    {
        hoPtr=[self GetHO:[objectList getInt:n]];
        if (pName==hoPtr->hoOiList->oilName)
        {
            return hoPtr;
        }
    }
    return nil;
}

-(void)RACT_NAMEDADDPROPERTY:(CActExtension*)act		
{
    NSString* pItem=[act getParamExpString:rh withNum:0];
    NSString* pProperty=[act getParamExpString:rh withNum:1];
    int value=[act getParamExpression:rh withNum:2];
    [inventory AddProperty:number withParam1:pItem andParam2:pProperty andParam3:value];
    return;
}
-(void)RACT_NAMEDSETPROPMINMAX:(CActExtension*)act		
{
    NSString* pItem=[act getParamExpString:rh withNum:0];
    NSString* pProperty=[act getParamExpString:rh withNum:1];
    int min=[act getParamExpression:rh withNum:2];
    int max=[act getParamExpression:rh withNum:3];
    [inventory SetPropertyMinimum:number withParam1:pItem andParam2:pProperty andParam3:min];
    [inventory SetPropertyMaximum:number withParam1:pItem andParam2:pProperty andParam3:max];
    return;
}

-(void)RACT_NAMEDADDLISTITEM:(CActExtension*)act		
{
    if (type==INVTYPE_LIST)
    {
        NSString* pName=[act getParamExpString:rh withNum:0];
        int pos=[act getParamExpression:rh withNum:1];
        NSString* namePos=@"";
        CInventoryItem* pItem;
        if (pos>=0 && pos<[displayList size])
        {
            pItem=(CInventoryItem*)[displayList get:pos];
            namePos=pItem->pName;
        }
        pItem=[inventory AddItemToPosition:number withParam1:namePos andParam2:pName andParam3:1 andParam4:maximum andParam5:pDisplayString];
        BOOL bAbsent=YES;
        int n;
        for (n=0; n<[displayList size]; n++)
        {
            if (pItem==(CInventoryItem*)[displayList get:n])
            {
                bAbsent=NO;
                break;
            }
        }
        [self UpdateDisplayList];
        if (bAbsent)
        {
            for (n=0; n<[displayList size]; n++)
            {
                if (pItem==(CInventoryItem*)[displayList get:n])
                {
                    [self CenterDisplay:n];
                    break;
                }
            }
        }
    }
    return;
}
-(void)RACT_NAMEDADDLISTNITEMS:(CActExtension*)act		
{
    if (type==INVTYPE_LIST)
    {
        NSString* pName=[act getParamExpString:rh withNum:0];
        int pos=[act getParamExpression:rh withNum:1];
        int numb=[act getParamExpression:rh withNum:2];
        NSString* namePos=@"";
        CInventoryItem* pItem;
        if (pos>=0 && pos<[displayList size])
        {
            pItem=(CInventoryItem*)[displayList get:pos];
            namePos=pItem->pName;
        }
        pItem=[inventory AddItemToPosition:number withParam1:namePos andParam2:pName andParam3:numb andParam4:maximum andParam5:pDisplayString];
        BOOL bAbsent=YES;
        int n;
        for (n=0; n<[displayList size]; n++)
        {
            if (pItem==(CInventoryItem*)[displayList get:n])
            {
                bAbsent=NO;
                break;
            }
        }
        [self UpdateDisplayList];
        if (bAbsent)
        {
            for (n=0; n<[displayList size]; n++)
            {
                if (pItem==(CInventoryItem*)[displayList get:n])
                {
                    [self CenterDisplay:n];
                    break;
                }
            }
        }
    }
    return;
}
-(void)RACT_NAMEDADDITEM:(CActExtension*)act		
{
    CInventoryItem* pItem;
    NSString* param1=[act getParamExpString:rh withNum:0];
    if (type==INVTYPE_LIST)
    {
        pItem=[inventory AddItem:number withParam1:param1 andParam2:1 andParam3:maximum andParam4:pDisplayString];
        BOOL bAbsent=YES;
        int n;
        for (n=0; n<[displayList size]; n++)
        {
            if (pItem==(CInventoryItem*)[displayList get:n])
            {
                bAbsent=NO;
                break;
            }
        }
        [self UpdateDisplayList];
        if (bAbsent)
        {
            for (n=0; n<[displayList size]; n++)
            {
                if (pItem==(CInventoryItem*)[displayList get:n])
                {
                    [self CenterDisplay:n];
                    break;
                }
            }
        }
    }
    else
    {
        int x, y;
        for (y=0; y<nLines; y++)
        {
            for (x=0; x<nColumns; x++)
            {
                if ([self GridCanAdd:param1 withParam1:x andParam2:y andParam3:NO])
                {
                    pItem=[inventory AddItem:number withParam1:param1 andParam2:1 andParam3:maximum andParam4:pDisplayString];
                    pItem->x=x;
                    pItem->y=y;
                    [self UpdateDisplayList];
                    return;
                }
            }
        }
    }
    return;
}

-(void)RACT_NAMEDADDNITEMS:(CActExtension*)act		
{
    NSString* param1=[act getParamExpString:rh withNum:0];
    int param2=[act getParamExpression:rh withNum:1];
    if (param2>=0)
    {
        CInventoryItem* pItem;
        if (type==INVTYPE_LIST)
        {
            pItem=[inventory AddItem:number withParam1:param1 andParam2:param2 andParam3:maximum andParam4:pDisplayString];
            BOOL bAbsent=YES;
            int n;
            for (n=0; n<[displayList size]; n++)
            {
                if (pItem==(CInventoryItem*)[displayList get:n])
                {
                    bAbsent=NO;
                    break;
                }
            }
            [self UpdateDisplayList];
            if (bAbsent)
            {
                for (n=0; n<[displayList size]; n++)
                {
                    if (pItem==(CInventoryItem*)[displayList get:n])
                    {
                        [self CenterDisplay:n];
                        break;
                    }
                }
            }
        }
        else
        {
            int x, y;
            for (y=0; y<nLines; y++)
            {
                for (x=0; x<nColumns; x++)
                {
                    if ([self GridCanAdd:param1 withParam1:x andParam2:y andParam3:NO])
                    {
                        pItem=[inventory AddItem:number withParam1:param1 andParam2:param2 andParam3:maximum andParam4:pDisplayString];
                        pItem->x=x;
                        pItem->y=y;
                        [self UpdateDisplayList];
                        return;
                    }
                }
            }
        }
    }
    return;
}

-(void)RACT_NAMEDSETMAXIMUM:(CActExtension*)act		
{
    NSString* param1=[act getParamExpString:rh withNum:0];
    int param2=[act getParamExpression:rh withNum:1];
    if (param2>=0)
    {
        [inventory SetMaximum:number withParam1:param1 andParam2:param2];
        [self UpdateDisplayList];
    }
    return;
}

-(void)RACT_NAMEDDELITEM:(CActExtension*)act		
{
    NSString* param1=[act getParamExpString:rh withNum:0];
    CObject* hoPtr=[self FindHO:param1];
    if ([inventory SubQuantity:number withParam1:param1 andParam2:1])
    {
        if (hoPtr!=nil)
        {
            [self obHide:hoPtr];
        }
    }
    [self UpdateDisplayList];
    return;
}

-(void)RACT_NAMEDDELNITEMS:(CActExtension*)act		
{
    NSString* param1=[act getParamExpString:rh withNum:0];
    int param2=[act getParamExpression:rh withNum:1];
    if (param2>=0)
    {
        CObject* hoPtr=[self FindHO:param1];
        if ([inventory SubQuantity:number withParam1:param1 andParam2:param2])
        {
            if (hoPtr!=nil)
            {
                [self obHide:hoPtr];
            }
        }
        [self UpdateDisplayList];
    }
    return;
}
-(void)RACT_NAMEDHIDEITEM:(CActExtension*)act		
{
    NSString* param1=[act getParamExpString:rh withNum:0];
    [inventory SetFlags:number withParam1:param1 andParam2:~INVFLAG_VISIBLE andParam3:0];
    [self UpdateDisplayList];
    return;
}
-(void)RACT_NAMEDSHOWITEM:(CActExtension*)act		
{
    NSString* param1=[act getParamExpString:rh withNum:0];
    [inventory SetFlags:number withParam1:param1 andParam2:-1 andParam3:INVFLAG_VISIBLE];
    [self UpdateDisplayList];
    return;
}
-(void)RACT_ADDLISTITEM:(CActExtension*)act		
{
    if (type==INVTYPE_LIST)
    {
        CObject* hoPtr=[act getParamObject:rh withNum:0];
        NSString* pName=hoPtr->hoOiList->oilName;
        
        int pos=[act getParamExpression:rh withNum:1];
        NSString* namePos=@"";
        CInventoryItem* pItem;
        if (pos>=0 && pos<[displayList size])
        {
            pItem=(CInventoryItem*)[displayList get:pos];
            namePos=pItem->pName;
        }
        pItem=[inventory AddItemToPosition:number withParam1:namePos andParam2:pName andParam3:1 andParam4:maximum andParam5:pDisplayString];
        BOOL bAbsent=YES;
        int n;
        for (n=0; n<[displayList size]; n++)
        {
            if (pItem==(CInventoryItem*)[displayList get:n])
            {
                bAbsent=NO;
                break;
            }
        }
        [self UpdateDisplayList];
        if (bAbsent)
        {
            for (n=0; n<[displayList size]; n++)
            {
                if (pItem==(CInventoryItem*)[displayList get:n])
                {
                    [self CenterDisplay:n];
                    break;
                }
            }
        }
    }
    return;
}
-(void)RACT_ADDLISTNITEMS:(CActExtension*)act		
{
    if (type==INVTYPE_LIST)
    {
        CObject* hoPtr=[act getParamObject:rh withNum:0];
        NSString* pName=hoPtr->hoOiList->oilName;
        int pos=[act getParamExpression:rh withNum:1];
        int numb=[act getParamExpression:rh withNum:2];
        NSString* namePos=@"";
        CInventoryItem* pItem;
        if (pos>=0 && pos<[displayList size])
        {
            pItem=(CInventoryItem*)[displayList get:pos];
            namePos=pItem->pName;
        }
        pItem=[inventory AddItemToPosition:number withParam1:namePos andParam2:pName andParam3:numb andParam4:maximum andParam5:pDisplayString];
        BOOL bAbsent=YES;
        int n;
        for (n=0; n<[displayList size]; n++)
        {
            if (pItem==(CInventoryItem*)[displayList get:n])
            {
                bAbsent=NO;
                break;
            }
        }
        [self UpdateDisplayList];
        if (bAbsent)
        {
            for (n=0; n<[displayList size]; n++)
            {
                if (pItem==(CInventoryItem*)[displayList get:n])
                {
                    [self CenterDisplay:n];
                    break;
                }
            }
        }
    }
    return;
}
-(void)RACT_ADDITEM:(CActExtension*)act		
{
    CObject* hoPtr=[act getParamObject:rh withNum:0];
    CObjInfo* pOiList=hoPtr->hoOiList;
    CInventoryItem* pItem;
    if (type==INVTYPE_LIST)
    {
        pItem=[inventory AddItem:number withParam1:pOiList->oilName andParam2:1 andParam3:maximum andParam4:pDisplayString];
        BOOL bAbsent=YES;
        int n;
        for (n=0; n<[displayList size]; n++)
        {
            if (pItem==(CInventoryItem*)[displayList get:n])
            {
                bAbsent=NO;
                break;
            }
        }
        [self UpdateDisplayList];
        if (bAbsent)
        {
            for (n=0; n<[displayList size]; n++)
            {
                if (pItem==(CInventoryItem*)[displayList get:n])
                {
                    [self CenterDisplay:n];
                    break;
                }
            }
        }
    }
    else
    {
        int x, y;
        for (y=0; y<nLines; y++)
        {
            for (x=0; x<nColumns; x++)
            {
                if ([self GridCanAdd:pOiList->oilName withParam1:x andParam2:y andParam3:NO])
                {
                    pItem=[inventory AddItem:number withParam1:pOiList->oilName andParam2:1 andParam3:maximum andParam4:pDisplayString];
                    pItem->x=x;
                    pItem->y=y;
                    [self UpdateDisplayList];
                    return;
                }
            }
        }
    }
    return;
}
-(void)RACT_ADDPROPERTY:(CActExtension*)act		
{
    CObject* hoPtr=(CObject*)[act getParamObject:rh withNum:0];
    NSString* pProperty=[act getParamExpString:rh withNum:1];
    int value=[act getParamExpression:rh withNum:2];
    
    CObjInfo* pOiList=hoPtr->hoOiList;
    [inventory AddProperty:number withParam1:pOiList->oilName andParam2:pProperty andParam3:value];
    return;
}
-(void)RACT_SETPROPMINMAX:(CActExtension*)act		
{
    CObject* hoPtr=[act getParamObject:rh withNum:0];
    NSString* pProperty=[act getParamExpString:rh withNum:1];
    int mn=[act getParamExpression:rh withNum:2];
    int mx=[act getParamExpression:rh withNum:3];
    
    CObjInfo* pOiList=hoPtr->hoOiList;
    [inventory SetPropertyMinimum:number withParam1:pOiList->oilName andParam2:pProperty andParam3:mn];
    [inventory SetPropertyMaximum:number withParam1:pOiList->oilName andParam2:pProperty andParam3:mx];
    return;
}
-(void)RACT_ADDNITEMS:(CActExtension*)act		
{
    int param2 = [act getParamExpression:rh withNum:1];
    if (param2 >= 0)
    {
        CObject* hoPtr=[act getParamObject:rh withNum:0];
        CObjInfo* pOiList=hoPtr->hoOiList;
        CInventoryItem* pItem;
        if (type==INVTYPE_LIST)
        {
            pItem=[inventory AddItem:number withParam1:pOiList->oilName andParam2:param2 andParam3:maximum andParam4:pDisplayString];
            BOOL bAbsent=YES;
            int n;
            for (n=0; n<[displayList size]; n++)
            {
                if (pItem==(CInventoryItem*)[displayList get:n])
                {
                    bAbsent=NO;
                    break;
                }
            }
            [self UpdateDisplayList];
            if (bAbsent)
            {
                for (n=0; n<[displayList size]; n++)
                {
                    if (pItem==(CInventoryItem*)[displayList get:n])
                    {
                        [self CenterDisplay:n];
                        break;
                    }
                }
            }
        }
        else
        {
            int x, y;
            for (y=0; y<nLines; y++)
            {
                for (x=0; x<nColumns; x++)
                {
                    if ([self GridCanAdd:pOiList->oilName withParam1:x andParam2:y andParam3:NO])
                    {
                        pItem=[inventory AddItem:number withParam1:pOiList->oilName andParam2:param2 andParam3:maximum andParam4:pDisplayString];
                        pItem->x=x;
                        pItem->y=y;
                        [self UpdateDisplayList];
                        return;
                    }
                }
            }
        }
    }
    return;
}
-(void)RACT_SETMAXIMUM:(CActExtension*)act		
{
    int param2 = [act getParamExpression:rh withNum:1];
    if (param2>=0)
    {
        CObject* hoPtr=[act getParamObject:rh withNum:0];
        CObjInfo* pOiList=hoPtr->hoOiList;
        [inventory SetMaximum:number withParam1:pOiList->oilName andParam2:param2];
        [self UpdateDisplayList];
    }
    return;
}
-(void)RACT_DELITEM:(CActExtension*)act		
{
    CObject* hoPtr=[act getParamObject:rh withNum:0];
    CObjInfo* pOiList=hoPtr->hoOiList;
    hoPtr=[self FindHO:pOiList->oilName];
    if ([inventory SubQuantity:number withParam1:pOiList->oilName andParam2:1])
    {
        if (hoPtr!=nil)
        {
            [self obHide:hoPtr];
        }
    }
    [self UpdateDisplayList];
    return;
}
-(void)RACT_DELNITEMS:(CActExtension*)act		
{
    int param2=[act getParamExpression:rh withNum:1];
    if (param2>=0)
    {
        CObject* hoPtr=[act getParamObject:rh withNum:0];
        CObjInfo* pOiList=hoPtr->hoOiList;
        hoPtr=[self FindHO:pOiList->oilName];
        if ([inventory SubQuantity:number withParam1:pOiList->oilName andParam2:param2])
        {
            if (hoPtr!=nil)
            {
                [self obHide:hoPtr];
            }
        }
        [self UpdateDisplayList];
    }
    return;
}
-(void)RACT_HIDEITEM:(CActExtension*)act		
{
    CObject* hoPtr=[act getParamObject:rh withNum:0];
    CObjInfo* pOiList=hoPtr->hoOiList;
    [inventory SetFlags:number withParam1:pOiList->oilName andParam2:~INVFLAG_VISIBLE andParam3:0];
    [self UpdateDisplayList];
    return;
}
-(void)RACT_SHOWITEM:(CActExtension*)act		
{
    CObject* hoPtr=[act getParamObject:rh withNum:0];
    CObjInfo* pOiList=hoPtr->hoOiList;
    [inventory SetFlags:number withParam1:pOiList->oilName andParam2:-1 andParam3:INVFLAG_VISIBLE];
    [self UpdateDisplayList];
    return;
}

-(void)RACT_LEFT:(CActExtension*)act		
{
    if ([displayList size]>0)
    {
        xCursor--;
        if (xCursor<0)
        {
            xCursor++;
            position=MAX(position-1, 0);
        }
        bRedraw=YES;
    }
    return;
}
-(void)RACT_RIGHT:(CActExtension*)act		
{
    if ([displayList size]>0)
    {
        xCursor++;
        if (xCursor>=nColumns)
        {
            xCursor--;
            position=(int)MIN(position+1, [displayList size]-nColumns*nLines);
        }
        bRedraw=YES;
    }
    return;
}
-(void)RACT_UP:(CActExtension*)act		
{
    if ([displayList size]>0)
    {
        yCursor--;
        if (yCursor<0)
        {
            yCursor++;
            position=MAX(position-nColumns, 0);
        }
        bRedraw=YES;
    }
    return;
}
-(void)RACT_DOWN:(CActExtension*)act		
{
    if ([displayList size]>0)
    {
        yCursor++;
        if (yCursor>=nLines)
        {
            yCursor--;
            position=(int)MIN(position+nColumns, [displayList size]-nColumns*nLines);
        }
        bRedraw=YES;
    }
    return;
}
-(void)RACT_SELECT:(CActExtension*)act		
{
    if ([displayList size]>0)
    {
        selectedCount=rh->rh4EventCount;
        CInventoryItem* pItem=(CInventoryItem*)[displayList get:position+yCursor*nColumns+xCursor];
        CObject* hoPtr=[self GetHO:[objectList getInt:position+yCursor*nColumns+xCursor]];
        conditionString=[pItem GetName];
        [ho generateEvent:CND_NAMEDITEMSELECTED withParam:0];
        [ho generateEvent:CND_ITEMSELECTED withParam:hoPtr->hoOi];
        bRedraw=YES;
    }
    return;
}
-(void)RACT_CURSOR:(CActExtension*)act		
{
    int param1 = [act getParamExpression:rh withNum:0];
    if (param1==0)
    {
        flags&=~(IFLAG_FORCECURSOR|IFLAG_CURSORBYACTION);
    }
    else
    {
        flags|=IFLAG_FORCECURSOR|IFLAG_CURSORBYACTION;
    }
    bRedraw=YES;
    return;
}
-(void)RACT_ACTIVATE:(CActExtension*)act		
{
    int param1 = [act getParamExpression:rh withNum:0];
    if (param1 != 0)
    {
        bActivated=YES;
        flags|=IFLAG_CURSOR|IFLAG_FORCECURSOR;
    }
    else
    {
        bActivated=NO;
        flags&=~(IFLAG_CURSOR|IFLAG_FORCECURSOR);
    }
    bRedraw=YES;
    return;
}
-(void)RACT_NAMEDSETSTRING:(CActExtension*)act		
{
    [inventory SetDisplayString:number withParam1:[act getParamExpString:rh withNum:0] andParam2:[act getParamExpString:rh withNum:1]];
    [self UpdateDisplayList];
    return;
}
-(void)RACT_SETSTRING:(CActExtension*)act		
{
    CObject* hoPtr=[act getParamObject:rh withNum:0];
    CObjInfo* pOiList=hoPtr->hoOiList;
    [inventory SetDisplayString:number withParam1:pOiList->oilName andParam2:[act getParamExpString:rh withNum:1]];
    [self UpdateDisplayList];
    return;
}
-(void)RACT_SETPOSITION:(CActExtension*)act		
{
    int param1=[act getParamExpression:rh withNum:1];
    if (type==INVTYPE_LIST)
    {
        if (param1<0)
            param1=0;
        int last=(int)MAX([displayList size]-nLines*nColumns, 0);
        if (param1>last)
            param1=last;
        position=last;
        bRedraw=YES;
    }
    return;
}
-(void)RACT_SETPAGE:(CActExtension*)act		
{
    int param1=[act getParamExpression:rh withNum:1];
    if (type==INVTYPE_LIST)
    {
        param1=nLines*nColumns;
        if (param1<0)
            param1=0;
        int last=(int)MAX([displayList size]-nLines*nColumns, 0);
        if (param1>last)
            param1=last;
        position=last;
        bRedraw=YES;
    }
    return;
}
-(void)RACT_ADDGRIDITEM:(CActExtension*)act		
{
    if (type==INVTYPE_GRID)
    {
        CObject* hoPtr=[act getParamObject:rh withNum:0];
        int x=[act getParamExpression:rh withNum:1];
        int y=[act getParamExpression:rh withNum:2];
        CObjInfo* pOiList=hoPtr->hoOiList;
        if ([self GridCanAdd:pOiList->oilName withParam1:x andParam2:y andParam3:NO])
        {
            CInventoryItem* pItem=[self FindItem:pOiList->oilName];
            if (pItem==nil)
            {
                pItem=[inventory AddItem:number withParam1:pOiList->oilName andParam2:1 andParam3:maximum andParam4:pDisplayString];
            }
            else if (pItem->x==x && pItem->y==y)
            {
                [inventory AddItem:number withParam1:pOiList->oilName andParam2:1 andParam3:maximum andParam4:pDisplayString];
            }
            pItem->x=x;
            pItem->y=y;
            [self UpdateDisplayList];
        }
    }
    return;
}
-(void)RACT_ADDGRIDNITEMS:(CActExtension*)act		
{
    if (type==INVTYPE_GRID)
    {
        CObject* hoPtr=[act getParamObject:rh withNum:0];
        int numb=[act getParamExpression:rh withNum:1];
        int x=[act getParamExpression:rh withNum:2];
        int y=[act getParamExpression:rh withNum:3];
        CObjInfo* pOiList=hoPtr->hoOiList;
        if ([self GridCanAdd:pOiList->oilName withParam1:x andParam2:y andParam3:NO])
        {
            CInventoryItem* pItem=[self FindItem:pOiList->oilName];
            if (pItem==nil)
            {
                pItem=[inventory AddItem:number withParam1:pOiList->oilName andParam2:numb andParam3:maximum andParam4:pDisplayString];
            }
            else if (pItem->x==x && pItem->y==y)
            {
                [inventory AddItem:number withParam1:pOiList->oilName andParam2:numb andParam3:maximum andParam4:pDisplayString];
            }
            pItem->x=x;
            pItem->y=y;
            [self UpdateDisplayList];
        }
    }
    return;
}
-(void)RACT_NAMEDADDGRIDITEM:(CActExtension*)act		
{
    if (type==INVTYPE_GRID)
    {
        NSString* pName=[act getParamExpString:rh withNum:0];
        int x=[act getParamExpression:rh withNum:1];
        int y=[act getParamExpression:rh withNum:2];
        if ([self GridCanAdd:pName withParam1:x andParam2:y andParam3:NO])
        {
            CInventoryItem* pItem=[self FindItem:pName];
            if (pItem==nil)
            {
                pItem=[inventory AddItem:number withParam1:pName andParam2:1 andParam3:maximum andParam4:pDisplayString];
            }
            else if (pItem->x==x && pItem->y==y)
            {
                [inventory AddItem:number withParam1:pName andParam2:1 andParam3:maximum andParam4:pDisplayString];
            }
            pItem->x=x;
            pItem->y=y;
            [self UpdateDisplayList];
        }
    }
    return;
}
-(void)RACT_NAMEDADDGRIDNITEMS:(CActExtension*)act		
{
    if (type==INVTYPE_GRID)
    {
        NSString* pName=[act getParamExpString:rh withNum:0];
        int numb=[act getParamExpression:rh withNum:1];
        int x=[act getParamExpression:rh withNum:2];
        int y = [act getParamExpression:rh withNum:3];
        if ([self GridCanAdd:pName withParam1:x andParam2:y andParam3:NO])
        {
            CInventoryItem* pItem=[self FindItem:pName];
            if (pItem==nil)
            {
                pItem=[inventory AddItem:number withParam1:pName andParam2:numb andParam3:maximum andParam4:pDisplayString];
            }
            else if (pItem->x==x && pItem->y==y)
            {
                [inventory AddItem:number withParam1:pName andParam2:numb andParam3:maximum andParam4:pDisplayString];
            }
            pItem->x=x;
            pItem->y=y;
            [self UpdateDisplayList];
        }
    }
    return;
}

-(void)HilightDrop:(NSString*)pName withParam1:(int)xx andParam2:(int)yy
{
    if (xx<0 || xx>=nColumns || yy<0 || yy>=nLines)
    {
        return;
    }
    
    CObject* hoPtr;
    int n;
    for (n=0; n<rh->rhMaxOI; n++)
    {
        if (rh->rhOiList[n]->oilName==pName)
        {
            short numb=rh->rhOiList[n]->oilObject;
            if (numb>=0)
            {
                hoPtr=rh->rhObjectList[numb];
                int sx=(hoPtr->hoImgWidth+itemSx-1)/itemSx;
                int sy=(hoPtr->hoImgHeight+itemSy-1)/itemSy;
                if (xx+sx<=nColumns && yy+sy<=nLines)
                {
                    rcDrop.left=ho->hoX + xx*itemSx;
                    rcDrop.right=rcDrop.left+itemSx*sx;
                    rcDrop.top = ho->hoY + yy*itemSy;
                    rcDrop.bottom=rcDrop.top+itemSy*sy;
                    bDropItem=YES;
                    xCursor=xx;
                    yCursor=yy;
                    [ho redraw];
                }
            }
        }
    }
}				
-(void)RACT_HILIGHTDROP:(CActExtension*)act		
{
    if (type==INVTYPE_GRID)
    {
        CObject* hoPtr=[act getParamObject:rh withNum:0];
        int x=[act getParamExpression:rh withNum:1];
        int y=[act getParamExpression:rh withNum:2];
        CObjInfo* pOiList=hoPtr->hoOiList;
        [self HilightDrop:pOiList->oilName withParam1:x andParam2:y];
    }
    return;
}
-(void)RACT_NAMEDHILIGHTDROP:(CActExtension*)act		
{
    if (type==INVTYPE_GRID)
    {
        NSString* pName=[act getParamExpString:rh withNum:0];
        int x=[act getParamExpression:rh withNum:1];
        int y=[act getParamExpression:rh withNum:2];
        [self HilightDrop:pName withParam1:x andParam2:y];
    }
    return;
}

-(NSString*)cleanName:(NSString*)fileName
{
    NSRange ret;
    NSCharacterSet* c=[NSCharacterSet characterSetWithCharactersInString:@"/\\"];
    ret=[fileName rangeOfCharacterFromSet:c options:NSBackwardsSearch];
    if (ret.location!=NSNotFound && ret.location+1<[fileName length])
    {
        fileName=[fileName substringFromIndex:ret.location+1];
    }
    return fileName;
}

-(void)RACT_SAVE:(CActExtension*)act		
{
    NSString* fileName = [self cleanName:[act getParamFilename:rh withNum:0]];

    int length=[inventory Save:nil];
    char* buffer=(char*)malloc(length);
    [inventory Save:buffer];
    
    NSData* data=[[NSData alloc] initWithBytes:buffer length:length];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    [data writeToFile:appFile atomically:NO];
    [data release];
    free(buffer);
    return;
}

-(void)RACT_LOAD:(CActExtension*)act		
{
    NSString* fileName=[self cleanName:[act getParamExpString:rh withNum:0]];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSError* errorPtr;
    NSData *myData = [[[NSData alloc] initWithContentsOfFile:appFile options:NSMappedRead error:&errorPtr] autorelease];
    if ([myData length]==0)
    {
        NSString* name=fileName;
        NSString* extension=@"inv";
        NSRange range=[fileName rangeOfString:@"."];
        if (range.location!=NSNotFound)
        {
            name=[fileName substringToIndex:range.location];
            extension=[fileName substringFromIndex:range.location+1];
        }
        appFile=[[NSBundle mainBundle] pathForResource:name ofType:extension];
        @try 
        {
            myData = [[[NSData alloc] initWithContentsOfFile:appFile options:NSMappedRead error:&errorPtr] autorelease];
        }
        @catch (NSException *exception) 
        {
            return;
        }
    }
    if ([myData length]!=0)
    {
        CFile* file=[[CFile alloc] initWithNSDataNoRelease:myData];

        [inventory Load:file];
        position=0;
        xCursor=0;
        yCursor=0;
        [self UpdateDisplayList];
        [file release];
    }
    return;
}					






-(CValue*)expression:(int)num
{
    switch (num)
    {
        case EXP_NITEM:
            return [self REXP_NITEM];
        case EXP_NAMEOFHILIGHTED:
            return [self REXP_NAMEOFHILIGHTED];
        case EXP_NAMEOFSELECTED:
            return [self REXP_NAMEOFSELECTED];
        case EXP_POSITION:
            return [self REXP_POSITION];
        case EXP_PAGE:
            return [self REXP_PAGE];
        case EXP_TOTAL:
            return [self REXP_TOTAL];
        case EXP_DISPLAYED:
            return [self REXP_DISPLAYED];
        case EXP_NUMOFSELECTED:
            return [self REXP_NUMOFSELECTED];
        case EXP_NUMOFHILIGHTED:
            return [self REXP_NUMOFHILIGHTED];
        case EXP_NAMEOFNUM:
            return [self REXP_NAMEOFNUM];
        case EXP_MAXITEM:
            return [self REXP_MAXITEM];
        case EXP_NUMBERMAXITEM:
            return [self REXP_NUMBERMAXITEM];
        case EXP_NUMBERNITEM:
            return [self REXP_NUMBERNITEM];
        case EXP_GETPROPERTY:
            return [self REXP_GETPROPERTY];
        case EXP_NUMBERGETPROPERTY:
            return [self REXP_NUMBERGETPROPERTY];
    }
    return [rh getTempValue:0];
}



-(CValue*)REXP_NITEM
{
    NSString* pName=[[ho getExpParam] getString];
    CInventoryItem* pItem=[inventory GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        return [rh getTempValue:[pItem GetQuantity]];
    }
    return [rh getTempValue:0];
}

-(CValue*)REXP_GETPROPERTY
{
    NSString* pName=[[ho getExpParam] getString];
    NSString* pProperty=[[ho getExpParam] getString];
    CInventoryItem* pItem=[inventory GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        return [rh getTempValue:[pItem GetProperty:pProperty]];
    }
    return [rh getTempValue:0];
}

-(CValue*)REXP_MAXITEM
{
    NSString* pName = [[ho getExpParam] getString];
    CInventoryItem* pItem=[inventory GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        return [rh getTempValue:[pItem GetMaximum]];
    }
    return [rh getTempValue:0];
}
-(CValue*)REXP_NUMBERNITEM
{
    int num = [[ho getExpParam] getInt];
    if (num>=0 && num<[displayList size])
    {
        CInventoryItem* pItem=(CInventoryItem*)[displayList get:num];
        if (pItem!=nil)
        {
            return [rh getTempValue:[pItem GetQuantity]];
        }
    }
    return [rh getTempValue:0];
}
-(CValue*)REXP_NUMBERGETPROPERTY
{
    int num = [[ho getExpParam] getInt];
    NSString* pProperty = [[ho getExpParam] getString];
    if (num>=0 && num<[displayList size])
    {
        CInventoryItem* pItem=(CInventoryItem*)[displayList get:num];
        if (pItem!=nil)
        {
            return [rh getTempValue:[pItem GetProperty:pProperty]];
        }
    }
    return [rh getTempValue:0];
}
                
-(CValue*)REXP_NUMBERMAXITEM
{
    int num = [[ho getExpParam] getInt];
    if (num>=0 && num<[displayList size])
    {
        CInventoryItem* pItem=(CInventoryItem*)[displayList get:num];
        if (pItem!=nil)
        {
            return [rh getTempValue:[pItem GetMaximum]];
        }
    }
    return [rh getTempValue:0];
}
-(CValue*)REXP_NAMEOFHILIGHTED
{
    CValue* value=[rh getTempValue:0];
    if (pNameHilighted!=nil)
    {
        [value forceString:pNameHilighted];
        return value;
    }
    [value forceString:@""];
    return value;
}
-(CValue*)REXP_NAMEOFSELECTED
{
    CValue* value=[rh getTempValue:0];
    if (pNameSelected!=nil)
    {
        [value forceString:pNameSelected];
        return value;
    }
    [value forceString:@""];
    return value;
}
                
-(CValue*)REXP_POSITION
{
    return [rh getTempValue:position];
}
-(CValue*)REXP_PAGE
{
    return [rh getTempValue:position/(nLines*nColumns)];
}
-(CValue*)REXP_TOTAL
{
    return [rh getTempValue:(int)[displayList size]];
}
-(CValue*)REXP_DISPLAYED
{
    return [rh getTempValue:(int)MIN([displayList size]-position, nLines*nColumns)];
}
-(CValue*)REXP_NUMOFSELECTED
{
    return [rh getTempValue:numSelected];
}
-(CValue*)REXP_NUMOFHILIGHTED
{
    return [rh getTempValue:numHilighted];
}
         
-(CValue*)REXP_NAMEOFNUM
{
    CValue* value=[rh getTempValue:0];
    int num = [[ho getExpParam] getInt];
    if (num>=0 && num<[displayList size])
    {
        CInventoryItem* pItem=(CInventoryItem*)[displayList get:num];        
        [value forceString:[pItem GetName]];
        return value;
    }
    return value;
}
         
@end
                        
NSUInteger WriteAString(char* ptr, NSString* text)
{
    NSUInteger l=[text lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (ptr!=nil)
    {
        [text getCString:ptr maxLength:l+1 encoding:NSUTF8StringEncoding];
        ptr+=l;
        *ptr=0;
    }       
    return l+1;
}
NSUInteger WriteAByte(char* ptr, char value)
{
    if (ptr!=nil)
    {
        *ptr=value;
    }
    return 1;
}
NSUInteger WriteAShort(char* ptr, short value)
{
    if (ptr!=nil)
    {
        *(ptr++)=value&0xFF;
        *(ptr++)=(value>>8)&0xFF;
    }
    return 4;
}
NSUInteger WriteAnInt(char* ptr, int value)
{
    if (ptr!=nil)
    {
        *(ptr++)=value&0xFF;
        *(ptr++)=(value>>8)&0xFF;
        *(ptr++)=(value>>16)&0xFF;
        *(ptr++)=(value>>24)&0xFF;
    }
    return 4;
}

void invDrawRect(CRenderer* renderer, CRect rc, int color)
{
	int rcW = rc.width();
	int rcH = rc.height();
	renderer->renderSolidColor(color, CRectCreateAtPosition(rc.left, rc.top, rcW, 1), 0, 0);
	renderer->renderSolidColor(color, CRectCreateAtPosition(rc.right, rc.top, 1, rcH), 0, 0);
	renderer->renderSolidColor(color, CRectCreateAtPosition(rc.left, rc.top, 1, rcH), 0, 0);
	renderer->renderSolidColor(color, CRectCreateAtPosition(rc.left, rc.bottom, rcW, 1), 0, 0);
}
void invFillRect(CRenderer* renderer, CRect rc, int color)
{
	renderer->renderSolidColor(color, rc, 0, 0);
}

void swap(CArrayList* array, int index1, int index2)
{
    id temp= (id)[array get:index1];
    [array set:index1 object:[array get:index2]];
    [array set:index2 object:temp];
}
void swapItems(CArrayList* array, id obj1, id obj2)
{
    NSInteger index1=[array indexOf:obj1];
    NSInteger index2=[array indexOf:obj2];
    [array set:index1 object:obj2];
    [array set:index2 object:obj1];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// 																							    //
//		InventoryList																			//
// 																							    //
//////////////////////////////////////////////////////////////////////////////////////////////////
@implementation CInventoryList

-(id)init
{
	if(self = [super init])
	{
		list=[[CArrayList alloc] init];
	}
    return self;
}
-(void)dealloc
{
    [list clearRelease];
    [list release];
    [super dealloc];
}
-(void)Reset
{
    [list clearRelease];
    position=0;
}
-(CInventoryItem*)GetItem:(int)number withParam1:(NSString*)pName
{
    int n;
    for (n=0; n<[list size]; n++)
    {
        CInventoryItem* pItem=(CInventoryItem*)[list get:n];
        if ([pItem GetNumber]==number)
        {
            if ([[pItem GetName] compare:pName]==0)
            {
                return pItem;
            }
        }
    }
    return nil;
}
-(int)GetItemIndex:(int)number withParam1:(NSString*)pName
{
    int n;
    for (n=0; n<[list size]; n++)
    {
        CInventoryItem* pItem=(CInventoryItem*)[list get:n];
        if ([pItem GetNumber]==number)
        {
            if ([[pItem GetName] compare:pName]==0)
            {
                return n;
            }
        }
    }
    return 0;
}
-(CInventoryItem*)FirstItem:(int)number
{
    for (position=0; position<[list size]; position++)
    {
        CInventoryItem* pItem=(CInventoryItem*)[list get:position];
        if ([pItem GetNumber]==number)
        {
            position++;
            return pItem;
        }
    }
    return nil;
}
-(CInventoryItem*)NextItem:(int)number
{
    for (; position<[list size]; position++)
    {
        CInventoryItem* pItem=(CInventoryItem*)[list get:position];
        if ([pItem GetNumber]==number)
        {
            position++;
            return pItem;
        }
    }
    return nil;
}

-(void)Load:(CFile*)file
{
    [self Reset];
    short size;
    size=[file readAShort];
    int n;
    for (n=0; n<size; n++)
    {
        CInventoryItem* pItem=[[CInventoryItem alloc] initWithParam1:0 andParam2:@"" andParam3:0 andParam4:1 andParam5:@""];
        [pItem Load:file];
        [list add:pItem];
    }
}

-(int)Save:(char*)ptr
{
    int n;
    int size=0;
    CInventoryItem* pItem;
    if (ptr==nil)
    {
        size+=WriteAShort(nil, [list size]);
        for (n=0; n<[list size]; n++)
        {
            pItem=(CInventoryItem*)[list get:n];
            size+=[pItem Save:nil];
        }
        return size;
    }
    size+=WriteAShort(ptr+size, [list size]);
    for (n=0; n<[list size]; n++)
    {
        pItem=(CInventoryItem*)[list get:n];
        size+=[pItem Save:ptr+size];
    }
    return size;
}

-(CInventoryItem*)AddItem:(int)number withParam1:(NSString*)pName andParam2:(int)quantity andParam3:(int)maximum andParam4:(NSString*)pDisplayString
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem==nil)
    {
        pItem=[[CInventoryItem alloc] initWithParam1:number andParam2:pName andParam3:quantity andParam4:maximum andParam5:pDisplayString];
        [list add:pItem];
    }
    else
    {
        [pItem AddQuantity:quantity];
        if (pItem->quantity==0)
        {
            [pItem release];
            [list removeObject:pItem];
        }
    }
    return pItem;
}
-(CInventoryItem*)AddItemToPosition:(int)number withParam1:(NSString*)insert andParam2:(NSString*)pName andParam3:(int)quantity andParam4:(int)maximum andParam5:(NSString*) pDisplayString
{
    int n;
    CInventoryItem* pItem2=nil;
    for (n=0; n<[list size]; n++)
    {
        pItem2=(CInventoryItem*)[list get:n];
        if ([insert compare:pItem2->pName]==0)
        {
            break;
        }
    }
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem==nil)
    {
        pItem=[[CInventoryItem alloc] initWithParam1:number andParam2:pName andParam3:quantity andParam4:maximum andParam5:pDisplayString];
        [list addIndex:n object:pItem];
    }
    else
    {
        swapItems(list, pItem, pItem2);
    }
    return pItem;
}

-(BOOL)SubQuantity:(int)number withParam1:(NSString*)pName andParam2:(int)quantity
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        [pItem SubQuantity:quantity];
        if (pItem->quantity==0)
        {
            [pItem release];
            [list removeObject:pItem];
            return true;
        }
    }
    return false;
}
-(void)SetMaximum:(int)number withParam1:(NSString*)pName andParam2:(int)max
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        [pItem SetMaximum:max];
    }
}
-(int)GetQuantity:(int)number withParam1:(NSString*)pName
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        return [pItem GetQuantity];
    }
    return -1;
}
-(int)GetMaximum:(int)number withParam1:(NSString*)pName
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        return [pItem GetMaximum];
    }
    return -1;
}
-(void)DelItem:(int)number withParam1:(NSString*)pName
{
    int index=[self GetItemIndex:number withParam1:pName];
    if (index>=0)
    {
        [list removeIndexRelease:index];
    }
}
-(void)SetFlags:(int)number withParam1:(NSString*)pName andParam2:(int)mask andParam3:(int)flag
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        [pItem SetFlags:mask withParam1:flag];
    }
}
-(int)GetFlags:(int)number withParam1:(NSString*)pName
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        return [pItem GetFlags];
    }
    return 0;
}
-(void)SetDisplayString:(int)number withParam1:(NSString*)pName andParam2:(NSString*)pDisplayString
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        [pItem SetDisplayString:pDisplayString];
    }
}
-(NSString*)GetDisplayString:(int)number withParam1:(NSString*)pName
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        return [pItem GetDisplayString];
    }
    return nil;
}
-(void)AddProperty:(int)number withParam1:(NSString*)pName andParam2:(NSString*)propName andParam3:(int)value
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        [pItem AddProperty:propName withParam1:value];
    }
}
-(void)SetPropertyMinimum:(int) number withParam1:(NSString*)pName andParam2:(NSString*)propName andParam3:(int)value
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        [pItem SetPropertyMinimum:propName withParam1:value];
    }
}
-(void)SetPropertyMaximum:(int)number withParam1:(NSString*)pName andParam2:(NSString*)propName andParam3:(int)value
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        [pItem SetPropertyMinimum:propName withParam1:value];
    }
}
-(int)GetProperty:(int)number withParam1:(NSString*)pName andParam2:(NSString*)propName
{
    CInventoryItem* pItem=[self GetItem:number withParam1:pName];
    if (pItem!=nil)
    {
        return [pItem GetProperty:propName];
    }
    return 0;
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////
// 																							    //
//		InventoryItem																			//
// 																							    //
//////////////////////////////////////////////////////////////////////////////////////////////////
@implementation CInventoryItem

-(id)initWithParam1:(int)n andParam2:(NSString*)ptr andParam3:(int)q andParam4:(int)mx andParam5:(NSString*)displayString
{
	if(self = [super init])
	{
		number=n;
		pName=[[NSString alloc] initWithString:ptr];
		pDisplayString=[[NSString alloc] initWithString:displayString];
		maximum=MAX(mx, 1);
		quantity=MIN(q, maximum);
		quantity=MAX(quantity, 0);
		flags=INVFLAG_VISIBLE;
		properties=[[CArrayList alloc] init];
		x=0;
		y=0;
	}
    return self;
}
-(void)dealloc
{
    [properties clearRelease];
    [properties release];
    [pName release];
    [pDisplayString release];
    [super dealloc];
}

-(void)Reset
{
    [properties clearRelease];
}
-(void)SetFlags:(int)mask withParam1:(int)flag
{
    flags = (flags & mask) | flag;
}
-(NSString*)GetName
{
    return pName;
}
-(NSString*)GetDisplayString
{
    return pDisplayString;
}
-(int)GetQuantity
{
    return quantity;
}
-(int)GetMaximum
{
    return maximum;
}
-(int)GetNumber
{
    return number;
}
-(int)GetFlags
{
    return flags;
}
-(int)Save:(char*)ptr
{
    CInventoryProperty* pProperty;
    int n, l;
    int size=0;
    if (ptr==nil)
    {
        size+=WriteAnInt(nil, number);
        size+=WriteAnInt(nil, flags);
        size+=WriteAnInt(nil, quantity);
        size+=WriteAnInt(nil, maximum);
        size+=WriteAnInt(nil, x);
        size+=WriteAnInt(nil, y);        
        size+=WriteAString(nil, pName);
        size+=WriteAString(nil, pDisplayString);        
        l=(int)[properties size];
        size+=WriteAShort(nil, (short)l);
        for (n=0; n<l; n++)
        {
            pProperty=(CInventoryProperty*)[properties get:n];
            size+=[pProperty Save:nil];                                  
        }                                  
        return size;
    }
    
    size+=WriteAnInt(ptr+size, number);
    size+=WriteAnInt(ptr+size, flags);
    size+=WriteAnInt(ptr+size, quantity);
    size+=WriteAnInt(ptr+size, maximum);
    size+=WriteAnInt(ptr+size, x);
    size+=WriteAnInt(ptr+size, y);    
    size+=WriteAString(ptr+size, pName);    
    size+=WriteAString(ptr+size, pDisplayString);
    
    l=(int)[properties size];
    size+=WriteAShort(ptr+size, (short)l);
    for (n=0; n<l; n++)
    {
        pProperty=(CInventoryProperty*)[properties get:n];
        size+=[pProperty Save:ptr+size];
    }
    return size;
}
-(void)Load:(CFile*)file
{
    [self Reset];
    number=[file readAInt];
    flags=[file readAInt];
    quantity=[file readAInt];
    maximum=[file readAInt];
    x=[file readAInt];
    y=[file readAInt];
    
    pName=[file readAString];
    pDisplayString=[file readAString];
    
    int l=[file readAShort];
    int n;
    for (n=0; n<l; n++)
    {
        CInventoryProperty* pProperty=[[CInventoryProperty alloc] initWithParam1:@"" andParam2:0 andParam3:0 andParam4:0];
        [pProperty Load:file];
        [properties add:pProperty];
    }
}
-(void)SetDisplayString:(NSString*)displayString
{
    [pDisplayString release];
    pDisplayString=[[NSString alloc] initWithString:displayString];
}
-(void)SetQuantity:(int)q
{
    q=MAX(q, 0);
    q=MIN(q, maximum);
    quantity=q;
}
-(void)AddQuantity:(int)q
{
    q=MAX(q+quantity, 0);
    q=MIN(q, maximum);
    quantity=q;
}
-(void)SubQuantity:(int)q
{
    q=MAX(quantity-q, 0);
    q=MIN(q, maximum);
    quantity=q;
}
-(void)SetMaximum:(int)m
{
    maximum=MAX(m, 1);
    quantity=MIN(quantity, maximum);
}
-(CInventoryProperty*)FindProperty:(NSString*)pNme
{
    int n;
    for (n=0; n<[properties size]; n++)
    {
        CInventoryProperty* pProperty=(CInventoryProperty*)[properties get:n];
        if ([pNme compare:pProperty->pName]==0)
        {
            return pProperty;
        }
    }
    return nil;
}
-(void)AddProperty:(NSString*)pNme withParam1:(int)value
{
    CInventoryProperty* pProperty=[self FindProperty:pNme];
    if (pProperty!=nil)
    {
        [pProperty AddValue:value];
    }
    else
    {
        pProperty=[[CInventoryProperty alloc] initWithParam1:pName andParam2:value andParam3:0x80000000 andParam4:0x7FFFFFFF];
        [properties add:pProperty];
    }
}
-(void)SetPropertyMinimum:(NSString*)pNme withParam1:(int)mn
{
    CInventoryProperty* pProperty=[self FindProperty:pNme];
    if (pProperty!=nil)
    {
        [pProperty SetMinimum:mn];
    }
    else
    {
        pProperty=[[CInventoryProperty alloc] initWithParam1:pName andParam2:0 andParam3:mn andParam4:0x7FFFFFFF];
        [properties add:pProperty];
    }
}
-(void)SetPropertyMaximum:(NSString*)pNme withParam1:(int)mx
{
    CInventoryProperty* pProperty=[self FindProperty:pNme];
    if (pProperty!=nil)
    {
        [pProperty SetMaximum:mx];
    }
    else
    {
        pProperty=[[CInventoryProperty alloc] initWithParam1:pName andParam2:0 andParam3:0x80000000 andParam4:mx];
        [properties add:pProperty];
    }
}
-(int)GetProperty:(NSString*)pNme
{
    CInventoryProperty* pProperty=[self FindProperty:pNme];
    if (pProperty!=nil)
    {
        return [pProperty GetValue];
    }
    return 0;
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////
// 																							    //
//		Inventory property																		//
// 																							    //
//////////////////////////////////////////////////////////////////////////////////////////////////
@implementation CInventoryProperty

-(id)initWithParam1:(NSString*)name andParam2:(int)v andParam3:(int)mn andParam4:(int)mx
{
	if(self = [super init])
	{
		pName=[[NSString alloc] initWithString:name];
		value=v;
		minimum=mn;
		maximum=mx;
	}
    return self;
}

-(void)dealloc
{
    [pName release];
    [super dealloc];
}

-(int)Save:(char*)ptr
{
    int size=0;
    if (ptr==nil)
    {
        size+=WriteAString(nil, pName);
        size+=WriteAnInt(nil, value);
        size+=WriteAnInt(nil, minimum);
        size+=WriteAnInt(nil, maximum);
        return size;
    }
    size+=WriteAString(ptr+size, pName);
    size+=WriteAnInt(ptr+size, value);
    size+=WriteAnInt(ptr+size, minimum);
    size+=WriteAnInt(ptr+size, maximum);
    return size;
}

-(void)Load:(CFile*)file
{
    pName=[file readAString];
    value=[file readAInt];
    minimum=[file readAInt];
    maximum=[file readAInt];
}
  
-(void)AddValue:(int)v
{
    value=MAX(MIN(value+v, maximum), minimum);
}

-(void)SetMinimum:(int)m
{
    minimum=m;
    value=MAX(MIN(value, maximum), minimum);
}
-(void)SetMaximum:(int)m
{
    maximum=m;
    value=MAX(MIN(value, maximum), minimum);
}
-(int)GetValue
{
    return value;
}

@end


//////////////////////////////////////////////////////////////////////////////////////////////////
// 																							    //
//		CScrollBar      																		//
// 																							    //
//////////////////////////////////////////////////////////////////////////////////////////////////
@implementation CScrollBar

-(id)init
{
    bInitialised=NO;
    return self;
}

-(void)Initialise:(CRun*)rh withParam1:(int)x andParam2:(int)y andParam3:(int)sx andParam4:(int)sy andParam5:(int)c andParam6:(int)ch 
{
    rhPtr=rh;
    color=c;
    colorHilight=ch;
    
    surface.left=x;
    surface.top=y;
    surface.right=x+sx;
    surface.bottom=y+sy;
    if (sx>sy)
    {
        bHorizontal=true;
//        topArrow.left=x;
//        topArrow.top=y;
//        topArrow.right=x+SX_SLIDER;
//        topArrow.bottom=y+sy;
        
        center.left=x;
        center.top=y;
        center.right=x+sx;
        center.bottom=y+sy;
        
//        bottomArrow.left=x+sx-SX_SLIDER;
//        bottomArrow.top=y;
//        bottomArrow.right=x+sx;
//        bottomArrow.bottom=y+sy;
    }
    else
    {
        bHorizontal=false;
//        topArrow.left=x;
//        topArrow.top=y;
//        topArrow.right=x+sx-1;
//        topArrow.bottom=y+SY_SLIDER-1;
        
        center.left=x;
        center.top=y;
        center.right=x+sx;
        center.bottom=y+sy;
        
//        bottomArrow.left=x;
//        bottomArrow.top=y+sy-SY_SLIDER;
//        bottomArrow.right=x+sx-1;
//        bottomArrow.bottom=y+sy-1;
    }
    [self SetPosition:position withParam1:length andParam2:total];
    bInitialised=true;
}
-(void)SetPosition:(int)p withParam1:(int)l andParam2:(int)t
{
    position=p;
    length=l;
    total=t;
    
    if (total>0)
    {
        if (bHorizontal)
        {
            slider.left=MIN(center.left+(position*center.width())/total, center.right);
            slider.right=MIN(slider.left+(length*center.width())/total, center.right);
            slider.top=center.top;
            slider.bottom=center.bottom;
        }
        else
        {
            slider.top=MIN(center.top+(position*center.height())/total, center.bottom);
            slider.bottom=MIN(slider.top+(length*center.height())/total, center.bottom);
            slider.left=center.left;
            slider.right=center.right;
        }
    }
}
-(void)DrawBar:(CRenderer*)renderer
{
    if (bInitialised==true&& length<total)
    {
        invDrawRect(renderer, center, color);
        invFillRect(renderer, slider, color);
    }
}


@end
