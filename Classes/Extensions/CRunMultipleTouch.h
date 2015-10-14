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
// CRUNMultipleTOuch
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"
#import "ITouches.h"
#import "CArrayList.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CObject;

double dMax(double d1, double d2);
double dMin(double d1, double d2);

#define MAX_TOUCHES 10
#define MTFLAG_RECOGNITION	0x0001
#define MTFLAG_AUTO			0x0002

typedef struct
{
    UITouch* touche;
    int x;
    int y;
    int xPrevious;
    int yPrevious;
    int startX;
    int startY;
    int dragX;
    int dragY;
    int tNew;
    int tEnd;
}touche;

@class PDollarRecognizer;
@interface GPoint:NSObject
{
@public
    double X;
    double Y;
    int ID;
}
-(id)initWithX:(double)x andY:(double)y andID:(double)id;
@end

@interface PointCloud : NSObject
{
@public
    NSString* Name;
    CArrayList* Points;
}
-(id)initWithRecognizer:(PDollarRecognizer*)pRec andName:(NSString*)pName andPoints:(CArrayList*)points;
-(void)dealloc;
@end

@interface PDollarRecognizer : NSObject
{
@public
    int NumPoints;
    GPoint* Origin;
    double gesturePercent;
    int gestureNumber;
    NSString* gestureName;
    CArrayList* PointClouds;
}
-(id)init;
-(void)dealloc;
-(void)Recognize:(CArrayList*)points withName:(NSString*)name;
-(int)AddGesture:(NSString*)name withPoints:(CArrayList*)points;
-(void)ClearGestures;
-(double)GreedyCloudMatch:(CArrayList*)points withPointCloud:(PointCloud*)P;
-(double)CloudDistance:(CArrayList*)pts1 withPoints:(CArrayList*)pts2 andIndex:(int)start;
-(CArrayList*)Resample:(CArrayList*)points withNum:(int)n;
-(CArrayList*)Scale:(CArrayList*)points;
-(CArrayList*)TranslateTo:(CArrayList*)points withPoint:(GPoint*)pt;
-(void)Centroid:(GPoint*)point withPoints:(CArrayList*)points;
-(double)PathDistance:(CArrayList*)pts1 withPoints:(CArrayList*)pts2;
-(double)PathLength:(CArrayList*)points;
-(double)Distance:(GPoint*)p1 withPoint:(GPoint*)p2;
@end

@interface CRunMultipleTouch : CRunExtension <ITouches>
{
	int newTouchCount;
	int endTouchCount;
	int movedTouchCount;
	int numberOfTouches;
    int newGestureCount;
    touche touches[MAX_TOUCHES];
	int lastTouch;
	int lastNewTouch;
	int lastEndTouch;
    NSString* gestureName;
	double gesturePercent;
	int	gestureNumber;
    CArrayList* touchArray;
	PDollarRecognizer* recognizer;
	int pitch1;
	int	pitch2;
	int	depth;
	unsigned int flags;
	NSString* pGesture;
	int	pitchDistance;
	int	touchCaptured;
	short OiUnder;
	int hoUnder;
	int	newPitchCount;

}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)touchBegan:(UITouch*)touch;
-(void)touchMoved:(UITouch*)touch;
-(void)touchEnded:(UITouch*)touch;
-(void)touchCancelled:(UITouch*)touch;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(void)setOriginX:(CActExtension*)act;
-(void)setOriginY:(CActExtension*)act;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(BOOL)cndNewTouch:(CCndExtension*)cnd;
-(BOOL)cndEndTouch:(CCndExtension*)cnd;
-(BOOL)cndNewTouchAny:(CCndExtension*)cnd;
-(BOOL)cndEndTouchAny:(CCndExtension*)cnd;
-(BOOL)cndTouchMoved:(CCndExtension*)cnd;
-(BOOL)cndTouchActive:(CCndExtension*)cnd;
-(BOOL)cndNewPitch:(CCndExtension*)cnd;
-(BOOL)cndNewGesture:(CCndExtension*)cnd;
-(BOOL)cndPitchActive:(CCndExtension*)cnd;
-(BOOL)cndNewTouchObject:(CCndExtension*)cnd;
-(CValue*)expression:(int)num;
-(CValue*)expGetNumber;
-(CValue*)expGetX;
-(CValue*)expGetY;
-(CValue*)expGetOriginX;
-(CValue*)expGetOriginY;
-(CValue*)expGetDeltaX;
-(CValue*)expGetDeltaY;
-(CValue*)expGetAngle;
-(CValue*)expGetDistance;
-(void)callObjectConditions:(int)x withY:(int)y;
-(void)actSetZone:(CActExtension*)act;
-(void)actSetZoneCoords:(CActExtension*)act;
-(void)actLoadIni:(CActExtension*)act;
-(void)actClearGestures;
-(void)actRecognize:(CActExtension*)act;
-(void)actRecognizeG:(CActExtension*)act;
-(void)actSetRecognition:(CActExtension*)act;
-(CValue*)expPitchAngle;
-(int)getDistance;
-(CValue*)expPitchDistance;
-(CValue*)expPitchPercentage;
-(BOOL)isActiveRoutine:(int)touch withOiList:(short)oiList;
-(BOOL)isObjectUnder:(CObject*)pHox withX:(int)x andY:(int)y;



@end
