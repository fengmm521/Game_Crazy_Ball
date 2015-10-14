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
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CFontInfo;
@class CBitmap;
@class CArrayList;
@class CFont;
@class CScrollBar;
@class CTextSurface;
@class CObject;

NSUInteger WriteAString(char* ptr, NSString* text);
NSUInteger WriteAByte(char* ptr, char value);
NSUInteger WriteAShort(char* buffer, short value);
NSUInteger WriteAnInt(char* ptr, int value);
void invDrawRect(CRenderer* renderer, CRect rc, int color);
void invFillRect(CRenderer* renderer, CRect rc, int color);
void swap(CArrayList* array, int index1, int index2);
void swapItems(CArrayList* array, id obj1, id obj2);

@interface CInventoryProperty : NSObject 
{
@public     
    NSString* pName;
    int value;
    int maximum;
    int minimum;    
}
-(id)initWithParam1:(NSString*)name andParam2:(int)v andParam3:(int)mn andParam4:(int)mx;
-(void)dealloc;
-(int)Save:(char*)ptr;
-(void)Load:(CFile*)file;
-(void)AddValue:(int)v;
-(void)SetMinimum:(int)m;
-(void)SetMaximum:(int)m;
-(int)GetValue;

@end

@interface CInventoryItem : NSObject 
{
@public
    int number;
    NSString* pName;
    NSString* pDisplayString;
    int flags;
    int quantity;
    int maximum;
    int x;
    int y;
    CArrayList* properties;
    
}
-(id)initWithParam1:(int)n andParam2:(NSString*)ptr andParam3:(int)q andParam4:(int)mx andParam5:(NSString*)displayString;
-(void)dealloc;
-(void)Reset;
-(void)SetFlags:(int)mask withParam1:(int)flag;
-(NSString*)GetName;
-(NSString*)GetDisplayString;
-(int)GetQuantity;
-(int)GetMaximum;
-(int)GetNumber;
-(int)GetFlags;
-(int)Save:(char*)ptr;
-(void)Load:(CFile*)file;
-(void)SetDisplayString:(NSString*)displayString;
-(void)SetQuantity:(int)q;
-(void)AddQuantity:(int)q;
-(void)SubQuantity:(int)q;
-(void)SetMaximum:(int)m;
-(CInventoryProperty*)FindProperty:(NSString*)pName;
-(void)AddProperty:(NSString*)pName withParam1:(int)value;
-(void)SetPropertyMinimum:(NSString*)pName withParam1:(int)mn;
-(void)SetPropertyMaximum:(NSString*)pName withParam1:(int)mx;
-(int)GetProperty:(NSString*)pName;
@end



@interface CInventoryList : NSObject 
{
@public 
    CArrayList* list;
    int position;
}
-(id)init;
-(void)dealloc;
-(void)Reset;
-(CInventoryItem*)GetItem:(int)number withParam1:(NSString*)pName;
-(int)GetItemIndex:(int)number withParam1:(NSString*)pName;
-(CInventoryItem*)FirstItem:(int)number;
-(CInventoryItem*)NextItem:(int)number;
-(void)Load:(CFile*)file;
-(int)Save:(char*)ptr;
-(CInventoryItem*)AddItem:(int)number withParam1:(NSString*)pName andParam2:(int)quantity andParam3:(int)maximum andParam4:(NSString*)pDisplayString;
-(CInventoryItem*)AddItemToPosition:(int)number withParam1:(NSString*)insert andParam2:(NSString*)pName andParam3:(int)quantity andParam4:(int)maximum andParam5:(NSString*)pDisplayString;
-(BOOL)SubQuantity:(int)number withParam1:(NSString*)pName andParam2:(int)quantity;
-(void)SetMaximum:(int)number withParam1:(NSString*)pName andParam2:(int)max;
-(int)GetQuantity:(int)number withParam1:(NSString*)pName;
-(int)GetMaximum:(int)number withParam1:(NSString*)pName;
-(void)DelItem:(int)number withParam1:(NSString*)pName;
-(void)SetFlags:(int)number withParam1:(NSString*)pName andParam2:(int)mask andParam3:(int)flag;
-(int)GetFlags:(int)number withParam1:(NSString*)pName;
-(void)SetDisplayString:(int)number withParam1:(NSString*)pName andParam2:(NSString*)pDisplayString;
-(NSString*)GetDisplayString:(int)number withParam1:(NSString*)pName;
-(void)AddProperty:(int)number withParam1:(NSString*)pName andParam2:(NSString*)propName andParam3:(int)value;
-(void)SetPropertyMinimum:(int) number withParam1:(NSString*)pName andParam2:(NSString*)propName andParam3:(int)value;
-(void)SetPropertyMaximum:(int)number withParam1:(NSString*)pName andParam2:(NSString*)propName andParam3:(int)value;
-(int)GetProperty:(int)number withParam1:(NSString*)pName andParam2:(NSString*)propName;


@end

#define INVFLAG_VISIBLE 1
#define INVSX_SLIDER 8
#define INVSY_SLIDER 8
#define ZONE_NONE 0
#define ZONE_TOPARROW 1
#define ZONE_TOPCENTER 2
#define ZONE_SLIDER 3
#define ZONE_BOTTOMCENTER 4
#define ZONE_BOTTOMARROW 5
#define SCROLL_UP 0
#define SCROLL_PAGEUP 1
#define SCROLL_SLIDE 2
#define SCROLL_PAGEDOWN 3
#define SCROLL_DOWN 4

@interface CRunInventory : CRunExtension 
{
@private
    int				type;
    int				number;
    int				itemSx;
    int				itemSy;
    int				flags;
    int				textAlignment;
    CFontInfo*		logFont;
    int				fontColor;
    int				scrollColor;
    int				scrollColor2;
    int				cursorColor;
    int				gridColor;
    int				cursorType;
    NSString*		pDisplayString;
    
    CArrayList*		displayList;
    CArrayList*		objectList;
    CScrollBar*		slider;
    int				nColumns;
    int				nLines;
    int				position;
    int				xCursor;
    int				yCursor;
    BOOL			bUpdateList;
    BOOL			bRedraw;
    int				displayQuantity;
    int				showQuantity;
    int				oldKey;
    int				selectedCount;
    BOOL			oldBMouse;
    BOOL			bActivated;
    NSString*		pNameSelected;
    NSString*		pNameHilighted;
    int             maximum;
    int             numSelected;
    int             numHilighted;
    int*            pGrid;
    CRect           rcDrop;
    BOOL            bDropItem;
    int             scrollX;
    int             scrollY;
    int             scrollPosition;
    BOOL            oldBHidden;
    CFont*          font;
    NSString*       conditionString;    
    CTextSurface*   textSurface;
    CValue*         tempValue;
}

-(id)init;
-(void)dealloc;
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(void)SetSlider;
-(void)obHide:(CObject*)hoPtr;
-(void)obShow:(CObject*)hoPtr;
-(int)GetFixedValue:(CObject*)pho;
-(CObject*)GetHO:(int)fixedValue;
-(void)showHide:(BOOL)bHidden;
-(void)CenterDisplay:(int)pos;
-(void)UpdateDisplayList;
-(void)SetPosition:(CObject*)pho withX:(int)x andY:(int)y;
-(BOOL)CheckDisplayList;
-(int)GetGridRect:(int)x withParam1:(int)y andParam2:(CRect*)pRc;
-(int)handleRunObject;
-(void)displayRunObject:(CRenderer*)renderer;
-(CFontInfo*)getRunObjectFont;
-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect*)rc;
-(int)getRunObjectTextColor;
-(void)setRunObjectTextColor:(int)rgb;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(BOOL)RCND_NAMEDITEMSELECTED:(CCndExtension*)cnd;
-(BOOL)RCND_NAMEDCOMPARENITEMS:(CCndExtension*)cnd;
-(BOOL)RCND_ITEMSELECTED:(CCndExtension*)cnd;
-(BOOL)RCND_COMPARENITEMS:(CCndExtension*)cnd;
-(BOOL)RCND_NAMEDITEMPRESENT:(CCndExtension*)cnd;
-(BOOL)RCND_ITEMPRESENT:(CCndExtension*)cnd;
-(BOOL)RCND_NAMEDHILIGHTED:(CCndExtension*)cnd;
-(BOOL)RCND_HILIGHTED:(CCndExtension*)cnd;
-(BOOL)RCND_CANADD:(CCndExtension*)cnd;
-(BOOL)GridCanAdd:(NSString*)pName withParam1:(int)xx andParam2:(int)yy andParam3:(BOOL)bDrop;
-(BOOL)RCND_NAMEDCANADD:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CInventoryItem*)FindItem:(NSString*)pName;
-(CObject*)FindHO:(NSString*)pName;
-(void)RACT_NAMEDADDPROPERTY:(CActExtension*)act;		
-(void)RACT_NAMEDSETPROPMINMAX:(CActExtension*)act;		
-(void)RACT_NAMEDADDLISTITEM:(CActExtension*)act;	
-(void)RACT_NAMEDADDLISTNITEMS:(CActExtension*)act;		
-(void)RACT_NAMEDADDITEM:(CActExtension*)act;		
-(void)RACT_NAMEDADDNITEMS:(CActExtension*)act;		
-(void)RACT_NAMEDSETMAXIMUM:(CActExtension*)act;		
-(void)RACT_NAMEDDELITEM:(CActExtension*)act;		
-(void)RACT_NAMEDDELNITEMS:(CActExtension*)act;		
-(void)RACT_NAMEDHIDEITEM:(CActExtension*)act;		
-(void)RACT_NAMEDSHOWITEM:(CActExtension*)act;		
-(void)RACT_ADDLISTITEM:(CActExtension*)act;		
-(void)RACT_ADDLISTNITEMS:(CActExtension*)act;		
-(void)RACT_ADDITEM:(CActExtension*)act;		
-(void)RACT_ADDPROPERTY:(CActExtension*)act;		
-(void)RACT_SETPROPMINMAX:(CActExtension*)act;		
-(void)RACT_ADDNITEMS:(CActExtension*)act;		
-(void)RACT_SETMAXIMUM:(CActExtension*)act;		
-(void)RACT_DELITEM:(CActExtension*)act;		
-(void)RACT_DELNITEMS:(CActExtension*)act;		
-(void)RACT_HIDEITEM:(CActExtension*)act;		
-(void)RACT_SHOWITEM:(CActExtension*)act;		
-(void)RACT_LEFT:(CActExtension*)act;		
-(void)RACT_RIGHT:(CActExtension*)act;		
-(void)RACT_UP:(CActExtension*)act;		
-(void)RACT_DOWN:(CActExtension*)act;		
-(void)RACT_SELECT:(CActExtension*)act;		
-(void)RACT_CURSOR:(CActExtension*)act;		
-(void)RACT_ACTIVATE:(CActExtension*)act;		
-(void)RACT_NAMEDSETSTRING:(CActExtension*)act;		
-(void)RACT_SETSTRING:(CActExtension*)act;		
-(void)RACT_SETPOSITION:(CActExtension*)act;		
-(void)RACT_SETPAGE:(CActExtension*)act;		
-(void)RACT_ADDGRIDITEM:(CActExtension*)act;		
-(void)RACT_ADDGRIDNITEMS:(CActExtension*)act;		
-(void)RACT_NAMEDADDGRIDITEM:(CActExtension*)act;		
-(void)RACT_NAMEDADDGRIDNITEMS:(CActExtension*)act;		
-(void)HilightDrop:(NSString*)pName withParam1:(int)xx andParam2:(int)yy;
-(void)RACT_HILIGHTDROP:(CActExtension*)act;		
-(void)RACT_NAMEDHILIGHTDROP:(CActExtension*)act;		
-(NSString*)cleanName:(NSString*)fileName;
-(void)RACT_SAVE:(CActExtension*)act;		
-(void)RACT_LOAD:(CActExtension*)act;		
-(CValue*)expression:(int)num;
-(CValue*)REXP_NITEM;
-(CValue*)REXP_GETPROPERTY;
-(CValue*)REXP_MAXITEM;
-(CValue*)REXP_NUMBERNITEM;
-(CValue*)REXP_NUMBERGETPROPERTY;
-(CValue*)REXP_NUMBERMAXITEM;
-(CValue*)REXP_NAMEOFHILIGHTED;
-(CValue*)REXP_NAMEOFSELECTED;
-(CValue*)REXP_POSITION;
-(CValue*)REXP_PAGE;
-(CValue*)REXP_TOTAL;
-(CValue*)REXP_DISPLAYED;
-(CValue*)REXP_NUMOFSELECTED;
-(CValue*)REXP_NUMOFHILIGHTED;
-(CValue*)REXP_NAMEOFNUM;
-(void)cleanList;
@end

@interface CScrollBar : NSObject 
{
@public
    int position;
    int length;
    int total;
    int color;
    int colorHilight;
    CRun* rhPtr;
//    CRect* topArrow;
    CRect slider;
    CRect center;
//    CRect* bottomArrow;
    CRect surface;
//    int zone;
//    BOOL oldBDown;
//    int xStart;
//    int yStart;
//    BOOL bDragging;
    BOOL bInitialised;
    BOOL bHorizontal;    
}
-(id)init;
-(void)Initialise:(CRun*)rh withParam1:(int)x andParam2:(int)y andParam3:(int)sx andParam4:(int)sy andParam5:(int)c andParam6:(int)ch;
-(void)SetPosition:(int)p withParam1:(int)l andParam2:(int)t;
-(void)DrawBar:(CRenderer*)renderer;

@end
