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
// CRUNKCBOXA Active system box
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"
#import "CExtStorage.h"

@class CObject;
@class CRun;
@class CActExtension;
@class CCndExtension;
@class CBitmap;
@class CCreateObjectInfo;
@class CSprite;
@class CSortData;
@class CObjInfo;
@class CValue;
@class CFile;
@class CFontInfo;
@class KcBoxACData;
@class KcBoxACData1;
@class CArrayList;
@class CRunApp;
@class CTextSurface;
@class CImageBank;
class CRenderer;

#define FLAG_HYPERLINK 0x00004000
#define FLAG_CONTAINER 0x00001000
#define FLAG_CONTAINED 0x00002000
#define COLOR_NONE 0xFFFF
#define FLAG_BUTTON_PRESSED 0x10000000
#define FLAG_BUTTON_HIGHLIGHTED 0x20000000
#define FLAG_HIDEIMAGE 0x01000000
#define COLORFLAG_RGB  0x80000000
#define COLOR_FLAGS (COLORFLAG_RGB)
#define FLAG_CHECKED 0x80000000
#define COLOR_BTNFACE 15
#define COLOR_3DLIGHT 22
#define FLAG_BUTTON 0x00100000
#define FLAG_CHECKBOX 0x00200000
#define FLAG_IMAGECHECKBOX 0x00800000
#define FLAG_DISABLED 0x40000000
#define FLAG_FORCECLIPPING 0x02000000
#define ALIGN_IMAGE_TOPLEFT 0x00010000
#define ALIGN_IMAGE_CENTER 0x00020000
#define ALIGN_IMAGE_PATTERN 0x00040000
#define ALIGN_TOP 0x00000001
#define ALIGN_VCENTER 0x00000002
#define ALIGN_BOTTOM 0x00000004
#define ALIGN_LEFT 0x00000010
#define ALIGN_HCENTER 0x00000020
#define ALIGN_RIGHT 0x00000040
#define ALIGN_MULTILINE 0x00000100
#define ALIGN_NOPREFIX 0x00000200
#define ALIGN_ENDELLIPSIS 0x00000400
#define ALIGN_PATHELLIPSIS 0x00000800
#define FLAG_SHOWBUTTONBORDER 0x00400000
#define COLOR_GRADIENTINACTIVECAPTION 25
#define DOCK_LEFT 0x00000001
#define DOCK_RIGHT 0x00000002
#define DOCK_TOP 0x00000004
#define DOCK_BOTTOM 0x00000008
#define DOCK_FLAGS (DOCK_LEFT | DOCK_RIGHT | DOCK_TOP | DOCK_BOTTOM)
#define PARAMFLAG_SYSTEMCOLOR 0x80000000

#define BOP_COPY 0
#define BOP_BLEND 1
#define BOP_INVERT 2
#define BOP_XOR 3
#define BOP_AND 4
#define BOP_OR 5
#define BOP_BLEND_REPLACETRANSP 6
#define BOP_DWROP 7
#define BOP_ANDNOT 8
#define BOP_ADD 9
#define BOP_MONO 10
#define BOP_SUB 11
#define BOP_BLEND_DONTREPLACECOLOR 12
#define BOP_MAX 13
#define CND_CLICKED  0
#define CND_ENABLED  1
#define CND_CHECKED  2
#define CND_LEFTCLICK  3
#define CND_RIGHTCLICK  4
#define CND_MOUSEOVER  5
#define CND_IMAGESHOWN  6
#define CND_DOCKED  7
#define ACT_ACTION_SETDIM  0
#define ACT_ACTION_SETPOS  1

#define ACT_ACTION_ENABLE  2
#define ACT_ACTION_DISABLE  3
#define ACT_ACTION_CHECK  4
#define ACT_ACTION_UNCHECK  5

#define ACT_ACTION_SETCOLOR_NONE	 6
#define ACT_ACTION_SETCOLOR_3DDKSHADOW  7
#define ACT_ACTION_SETCOLOR_3DFACE  8
#define ACT_ACTION_SETCOLOR_3DHILIGHT  9
#define ACT_ACTION_SETCOLOR_3DLIGHT  10
#define ACT_ACTION_SETCOLOR_3DSHADOW  11
#define ACT_ACTION_SETCOLOR_ACTIVECAPTION  12
#define ACT_ACTION_SETCOLOR_APPWORKSPACE  13 //mdi
#define ACT_ACTION_SETCOLOR_DESKTOP  14
#define ACT_ACTION_SETCOLOR_HIGHLIGHT  15
#define ACT_ACTION_SETCOLOR_INACTIVECAPTION  16
#define ACT_ACTION_SETCOLOR_INFOBK  17
#define ACT_ACTION_SETCOLOR_MENU  18
#define ACT_ACTION_SETCOLOR_SCROLLBAR  19
#define ACT_ACTION_SETCOLOR_WINDOW  20
#define ACT_ACTION_SETCOLOR_WINDOWFRAME  21

#define ACT_ACTION_SETB1COLOR_NONE  22
#define ACT_ACTION_SETB1COLOR_3DDKSHADOW	 23
#define ACT_ACTION_SETB1COLOR_3DFACE  24
#define ACT_ACTION_SETB1COLOR_3DHILIGHT  25
#define ACT_ACTION_SETB1COLOR_3DLIGHT  26
#define ACT_ACTION_SETB1COLOR_3DSHADOW  27
#define ACT_ACTION_SETB1COLOR_ACTIVEBORDER  28
#define ACT_ACTION_SETB1COLOR_INACTIVEBORDER  29
#define ACT_ACTION_SETB1COLOR_WINDOWFRAME  30

#define ACT_ACTION_SETB2COLOR_NONE  31
#define ACT_ACTION_SETB2COLOR_3DDKSHADOW	 32
#define ACT_ACTION_SETB2COLOR_3DFACE  33
#define ACT_ACTION_SETB2COLOR_3DHILIGHT  34
#define ACT_ACTION_SETB2COLOR_3DLIGHT  35
#define ACT_ACTION_SETB2COLOR_3DSHADOW  36
#define ACT_ACTION_SETB2COLOR_ACTIVEBORDER  37
#define ACT_ACTION_SETB2COLOR_INACTIVEBORDER  38
#define ACT_ACTION_SETB2COLOR_WINDOWFRAME  39

#define ACT_ACTION_TEXTCOLOR_NONE  40
#define ACT_ACTION_TEXTCOLOR_3DHILIGHT  41
#define ACT_ACTION_TEXTCOLOR_3DSHADOW  42
#define ACT_ACTION_TEXTCOLOR_BTNTEXT  43
#define ACT_ACTION_TEXTCOLOR_CAPTIONTEXT  44
#define ACT_ACTION_TEXTCOLOR_GRAYTEXT  45
#define ACT_ACTION_TEXTCOLOR_HIGHLIGHTTEXT  46
#define ACT_ACTION_TEXTCOLOR_INACTIVECAPTIONTEXT  47
#define ACT_ACTION_TEXTCOLOR_INFOTEXT  48
#define ACT_ACTION_TEXTCOLOR_MENUTEXT  49
#define ACT_ACTION_TEXTCOLOR_WINDOWTEXT  50

#define ACT_ACTION_SETCOLOR_OTHER  51
#define ACT_ACTION_SETB1COLOR_OTHER  52
#define ACT_ACTION_SETB2COLOR_OTHER  53
#define ACT_ACTION_TEXTCOLOR_OTHER  54

#define ACT_ACTION_SETTEXT  55
#define ACT_ACTION_SETTOOLTIPTEXT  56

#define ACT_ACTION_UNDOCK  57
#define ACT_ACTION_DOCK_LEFT  58
#define ACT_ACTION_DOCK_RIGHT  59
#define ACT_ACTION_DOCK_TOP  60
#define ACT_ACTION_DOCK_BOTTOM  61

#define ACT_ACTION_SHOWIMAGE  62
#define ACT_ACTION_HIDEIMAGE  63

#define ACT_ACTION_RESETCLICKSTATE  64

#define ACT_ACTION_HYPERLINKCOLOR_NONE  65
#define ACT_ACTION_HYPERLINKCOLOR_3DHILIGHT  66
#define ACT_ACTION_HYPERLINKCOLOR_3DSHADOW  67
#define ACT_ACTION_HYPERLINKCOLOR_BTNTEXT  68
#define ACT_ACTION_HYPERLINKCOLOR_CAPTIONTEXT  69
#define ACT_ACTION_HYPERLINKCOLOR_GRAYTEXT  70
#define ACT_ACTION_HYPERLINKCOLOR_HIGHLIGHTTEXT  71
#define ACT_ACTION_HYPERLINKCOLOR_INACTIVECAPTIONTEXT  72
#define ACT_ACTION_HYPERLINKCOLOR_INFOTEXT  73
#define ACT_ACTION_HYPERLINKCOLOR_MENUTEXT  74
#define ACT_ACTION_HYPERLINKCOLOR_WINDOWTEXT  75
#define ACT_ACTION_HYPERLINKCOLOR_OTHER  76

#define ACT_ACTION_SETCMDID  77

#define EXP_COLOR_BACKGROUND  0
#define EXP_COLOR_BORDER1  1
#define EXP_COLOR_BORDER2  2
#define EXP_COLOR_TEXT  3

#define EXP_COLOR_3DDKSHADOW  4
#define EXP_COLOR_3DFACE  5
#define EXP_COLOR_3DHILIGHT  6
#define EXP_COLOR_3DLIGHT  7
#define EXP_COLOR_3DSHADOW  8
#define EXP_COLOR_ACTIVEBORDER  9
#define EXP_COLOR_ACTIVECAPTION  10
#define EXP_COLOR_APPWORKSPACE  11
#define EXP_COLOR_DESKTOP  12
#define EXP_COLOR_BTNTEXT  13
#define EXP_COLOR_CAPTIONTEXT  14
#define EXP_COLOR_GRAYTEXT  15
#define EXP_COLOR_HIGHLIGHT  16
#define EXP_COLOR_HIGHLIGHTTEXT  17
#define EXP_COLOR_INACTIVEBORDER  18
#define EXP_COLOR_INACTIVECAPTION  19
#define EXP_COLOR_INACTIVECAPTIONTEXT  20
#define EXP_COLOR_INFOBK  21
#define EXP_COLOR_INFOTEXT  22
#define EXP_COLOR_MENU  23
#define EXP_COLOR_MENUTEXT  24
#define EXP_COLOR_SCROLLBAR  25
#define EXP_COLOR_WINDOW  26
#define EXP_COLOR_WINDOWFRAME  27
#define EXP_COLOR_WINDOWTEXT  28
#define EXP_GETTEXT  29
#define EXP_GETTOOLTIPTEXT  30
#define EXP_GETWIDTH  31
#define EXP_GETHEIGHT  32
#define EXP_COLOR_HYPERLINK  33
#define EXP_GETX  34
#define EXP_GETY  35
#define EXP_SYSTORGB  36

@interface CRunKcBoxA : CRunExtension
{
@public	
    CFontInfo* wFont;
    CFontInfo* wUnderlinedFont;
    KcBoxACData* rData;
    KcBoxACData1* rData1;
    int dwRtFlags;
    NSString* pText;
    int rNumInObjList;		// Index of this object in objects list
    int rNumInContList;		// Index of this object in container list
    int rContNum;			// Index of the container of this object in container list
    short rContDx;			// Coordinates
    short rContDy;
    int rNumInBtnList;		// Index of this object in button list
    int rClickCount;
    int rLeftClickCount;
	BOOL oldKMouse;
	int sysColorTab[COLOR_GRADIENTINACTIVECAPTION];
	BOOL bSysColorTab;
	CTextSurface* textSurface;
	BOOL updated;
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(void)mouseClicked;
-(void)mousePressed;
-(void)mouseReleased;
-(int)handleRunObject;
-(void)displayRunObject:(CRenderer*)renderer;
-(void)BuildSysColorTable;
-(int)myGetSysColor:(int)colorIndex;
-(void)DisplayObject:(CRenderer*)renderer withParam1:(CRunApp*)idApp andParam2:(CRect)rc andParam3:(KcBoxACData*)pc andParam4:(NSString*)pText andParam5:(CFontInfo*)hFnt andParam6:(KcBoxACData1*)pdata1;
-(CFontInfo*)getRunObjectFont;
-(void)setRunObjectFont:(CFontInfo*)font withRect:(CRect)rc;
-(int)getRunObjectTextColor;
-(void)setRunObjectTextColor:(int)rgb;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(BOOL)IsClicked;
-(BOOL)IsEnabled;
-(BOOL)IsChecked;
-(BOOL)LeftClick;
-(BOOL)RightClick;
-(BOOL)MouseOver;
-(BOOL)IsImageShown;
-(BOOL)IsDocked;
-(void)SetDimensions :(int)w withParam1:(int)h;
-(void)SetPosition :(int)x withParam1:(int)y;
-(void)Enable;
-(void)Disable;
-(void)Check;
-(void)Uncheck;
-(void)SetFillColor_None;
-(void)SetFillColor_3DDKSHADOW;
-(void)SetFillColor_3DFACE;
-(void)SetFillColor_3DHIGHLIGHT;
-(void)SetFillColor_3DLIGHT;
-(void)SetFillColor_3DSHADOW;
-(void)SetFillColor_ACTIVECAPTION;
-(void)SetFillColor_APPWORKSPACE;
-(void)SetFillColor_DESKTOP;
-(void)SetFillColor_HIGHLIGHT;
-(void)SetFillColor_INACTIVECAPTION;
-(void)SetFillColor_INFOBK;
-(void)SetFillColor_MENU;
-(void)SetFillColor_SCROLLBAR;
-(void)SetFillColor_WINDOW;
-(void)SetFillColor_WINDOWFRAME;
-(void)SetFillColor_Other :(int)c;
-(void)SetB1Color_None;
-(void)SetB1Color_3DDKSHADOW;
-(void)SetB1Color_3DFACE;
-(void)SetB1Color_3DHIGHLIGHT;
-(void)SetB1Color_3DLIGHT;
-(void)SetB1Color_3DSHADOW;
-(void)SetB1Color_ACTIVEBORDER;
-(void)SetB1Color_INACTIVEBORDER;
-(void)SetB1Color_WINDOWFRAME;
-(void)SetB1Color_Other :(int)c;
-(void)SetB2Color_None;
-(void)SetB2Color_3DDKSHADOW;
-(void)SetB2Color_3DFACE;
-(void)SetB2Color_3DHIGHLIGHT;
-(void)SetB2Color_3DLIGHT;
-(void)SetB2Color_3DSHADOW;
-(void)SetB2Color_ACTIVEBORDER;
-(void)SetB2Color_INACTIVEBORDER;
-(void)SetB2Color_WINDOWFRAME;
-(void)SetB2Color_Other :(int)c;
-(void)SetTxtColor_None;
-(void)SetTxtColor_3DHIGHLIGHT;
-(void)SetTxtColor_3DSHADOW;
-(void)SetTxtColor_BTNTEXT;
-(void)SetTxtColor_CAPTIONTEXT;
-(void)SetTxtColor_GRAYTEXT;
-(void)SetTxtColor_HIGHLIGHTTEXT;
-(void)SetTxtColor_INACTIVECAPTIONTEXT;
-(void)SetTxtColor_INFOTEXT;
-(void)SetTxtColor_MENUTEXT;
-(void)SetTxtColor_WINDOWTEXT;
-(void)SetTxtColor_Other :(int)c;
-(void)SetHyperlinkColor_None;
-(void)SetHyperlinkColor_3DHIGHLIGHT;
-(void)SetHyperlinkColor_3DSHADOW;
-(void)SetHyperlinkColor_BTNTEXT;
-(void)SetHyperlinkColor_CAPTIONTEXT;
-(void)SetHyperlinkColor_GRAYTEXT;
-(void)SetHyperlinkColor_HIGHLIGHTTEXT;
-(void)SetHyperlinkColor_INACTIVECAPTIONTEXT;
-(void)SetHyperlinkColor_INFOTEXT;
-(void)SetHyperlinkColor_MENUTEXT;
-(void)SetHyperlinkColor_WINDOWTEXT;
-(void)SetHyperlinkColor_Other :(int)c;
-(void)SetText :(NSString*)s;
-(void)SetToolTipText :(NSString*)s;
-(void)Undock;
-(void)DockLeft;
-(void)DockRight;
-(void)DockTop;
-(void)DockBottom;
-(void)ShowImage;
-(void)HideImage;
-(void)ResetClickState;
-(void)AttachMenuCmd;
-(CValue*)ExpColorBackground;
-(CValue*)ExpColorBorder1;
-(CValue*)ExpColorBorder2;
-(CValue*)ExpColorText;
-(CValue*)ExpColorHyperlink;
-(CValue*)ExpColor_3DDKSHADOW;
-(CValue*)ExpColor_3DFACE;
-(CValue*)ExpColor_3DHILIGHT;
-(CValue*)ExpColor_3DLIGHT;
-(CValue*)ExpColor_3DSHADOW;
-(CValue*)ExpColor_ACTIVEBORDER;
-(CValue*)ExpColor_ACTIVECAPTION;
-(CValue*)ExpColor_APPWORKSPACE;
-(CValue*)ExpColor_DESKTOP;
-(CValue*)ExpColor_BTNTEXT;
-(CValue*)ExpColor_CAPTIONTEXT;
-(CValue*)ExpColor_GRAYTEXT;
-(CValue*)ExpColor_HIGHLIGHT;
-(CValue*)ExpColor_HIGHLIGHTTEXT;
-(CValue*)ExpColor_INACTIVEBORDER;
-(CValue*)ExpColor_INACTIVECAPTION;
-(CValue*)ExpColor_INACTIVECAPTIONTEXT;
-(CValue*)ExpColor_INFOBK;
-(CValue*)ExpColor_INFOTEXT;
-(CValue*)ExpColor_MENU;
-(CValue*)ExpColor_MENUTEXT;
-(CValue*)ExpColor_SCROLLBAR;
-(CValue*)ExpColor_WINDOW;
-(CValue*)ExpColor_WINDOWFRAME;
-(CValue*)ExpColor_WINDOWTEXT;
-(CValue*)ExpGetText;
-(CValue*)ExpGetToolTipText;
-(CValue*)ExpGetWidth;
-(CValue*)ExpGetHeight;
-(CValue*)ExpGetX;
-(CValue*)ExpGetY;
-(CValue*)ExpSysToRGB;

@end

@interface KcBoxACData : NSObject
{
@public
    unsigned int dwFlags;
    unsigned int fillColor;
    unsigned int borderColor1;
    unsigned int borderColor2;
    CImage*  wImage;
    int  wFree;
    unsigned int textColor;
    short textMarginLeft;
    short textMarginTop;
    short textMarginRight;
    short textMarginBottom;	
}
@end

@interface KcBoxACData1 : NSObject
{
@public 
    unsigned int dwVersion;
    unsigned int dwUnderlinedColor;	
}
@end

#define FLAG_CONTAINED 0x00002000
#define TYPE_OBJECT 0
#define TYPE_CONTAINER 1
#define TYPE_BUTTON 2
@interface KcBoxACFrameData : CExtStorage
{
@public
    // Global list of objects
    CArrayList* pObjects;
    CArrayList*	pContainers;
    CArrayList* pButtons;
    
    int			gClickedButton;
    int			gHighlightedButton;
}
-(void)dealloc;
-(BOOL)IsEmpty;
-(int)AddObjAddr:(int)t withParam1:(CRunKcBoxA*)reObject;
-(void)RemoveObjAddr:(int)t withParam1:(CRunKcBoxA*)reObject;
-(int)AddContainer:(CRunKcBoxA*)re;
-(int)AddObject:(CRunKcBoxA*)re;
-(int)AddButton:(CRunKcBoxA*)re;
-(void)RemoveContainer:(CRunKcBoxA*)re;
-(void)RemoveObjectFromList:(CRunKcBoxA*)re;
-(void)RemoveButton:(CRunKcBoxA*)re;
-(int)GetContainer:(CRunKcBoxA*)re;
-(int)GetObjectFromList:(int)x withParam1:(int)y;
-(void)UpdateContainedPos;
@end
