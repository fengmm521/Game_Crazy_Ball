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
//
//  CRunScreenZoom.h
//  RuntimeIPhone
//
//  Created by Francois Lionet on 07/10/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunExtension.h"
#import "CLayer.h"

@interface CRunScreenZoomAnim : NSObject
{
@public
    CLayer* layer;
    BOOL completed;
}
-(float)animate;
@end

@interface CRunScreenZoomAnimLinear : CRunScreenZoomAnim
{
@private
    float initial;
    float end;
    double duration;
    float current;
    double initialTime;
}
-(id)initAnim:(float)initial withEnd:(float)end andDuration:(double)duration;
-(float)animate;
@end

@interface CRunScreenZoomAnimSmooth : CRunScreenZoomAnim
{
@private
    float end;
    double duration;
    float current;
    double initialTime;
    float middle;
    float length;
}
-(id)initAnim:(float)initial withEnd:(float)end andDuration:(double)duration;
-(float)animate;
@end

@interface CRunScreenZoomAnimElastic : CRunScreenZoomAnim
{
@private
    float middle;
    float end;
    float factor;
    float initial;
    float length;
    double duration;
    float current;
    int position;
    double initialTime;
}
-(id)initAnim:(float)initial withEnd:(float)end andDuration:(double)duration andFactor:(double)f;
-(float)animate;
@end

@interface CRunScreenZoomAnimShake : CRunScreenZoomAnim
{
@private
    float middle;
    float length;
    double total;
    double duration;
    float current;
    double initialTime;
}
-(id)initAnim:(float)middle withLength:(float)length andDuration:(double)duration andTotal:(double)total;
-(float)animate;
@end


@interface CRunScreenZoom : CRunExtension
{
    enum
    {
        CND_SCANGLEOVER,
        CND_SCSCALEOVER,
        CND_LAANGLEOVER,
        CND_LASCALEOVER,
        CND_SCSHAKEOVER,
        CND_LASHAKEOVER,
        CND_LAST
    };
    enum
    {
        ACT_SCANGLE=0,
        ACT_SCSCALE=1,
        ACT_SCXSCALE=2,
        ACT_SCYSCALE=3,
        ACT_SCSMANGLE=4,
        ACT_SCSMSCALE=5,
        ACT_SCSMXSCALE=6,
        ACT_SCSMYSCALE=7,
        ACT_SCELANGLE=8,
        ACT_SCELSCALE=9,
        ACT_SCELXSCALE=10,
        ACT_SCELYSCALE=11,
        ACT_SCPIVOT=12,
        ACT_SCXPIVOT=13,
        ACT_SCYPIVOT=14,
        ACT_SCLIANGLE=15,
        ACT_SCLISCALE=16,
        ACT_SCLIXSCALE=17,
        ACT_SCLIYSCALE=18,
        ACT_LAANGLE=19,
        ACT_LASCALE=20,
        ACT_LAXSCALE=21,
        ACT_LAYSCALE=22,
        ACT_LASMANGLE=23,
        ACT_LASMSCALE=24,
        ACT_LASMXSCALE=25,
        ACT_LASMYSCALE=26,
        ACT_LAELANGLE=27,
        ACT_LAELSCALE=28,
        ACT_LAELXSCALE=29,
        ACT_LAELYSCALE=30,
        ACT_LAPIVOT=31,
        ACT_LAXPIVOT=32,
        ACT_LAYPIVOT=33,
        ACT_LALIANGLE=34,
        ACT_LALISCALE=35,
        ACT_LALIXSCALE=36,
        ACT_LALIYSCALE=37,
        ACT_SCDEST=38,
        ACT_SCXDEST=39,
        ACT_SCYDEST=40,
        ACT_LADEST=41,
        ACT_LAXDEST=42,
        ACT_LAYDEST=43,
        ACT_SCSHAKEX=44,
        ACT_SCSHAKEY=45,
        ACT_LASHAKEX=46,
        ACT_LASHAKEY=47
    };
    enum
    {
        EXP_SCANGLE=0,
        EXP_SCXSCALE=1,
        EXP_SCYSCALE=2,
        EXP_SCXPIVOT=3,
        EXP_SCYPIVOT=4,
        EXP_SCSCALE=5,
        EXP_SCXDEST=6,
        EXP_SCYDEST=7,
        EXP_LAANGLE=8,
        EXP_LAXSCALE=9,
        EXP_LAYSCALE=10,
        EXP_LAXPIVOT=11,
        EXP_LAYPIVOT=12,
        EXP_LASCALE=13,
        EXP_LAXDEST=14,
        EXP_LAYDEST=15
    };
    
@private
    CRunScreenZoomAnim* scAngleAnim;
    CRunScreenZoomAnim* scScaleAnim;
    CRunScreenZoomAnim* scScaleXAnim;
    CRunScreenZoomAnim* scScaleYAnim;
    CRunScreenZoomAnim* scShakeXAnim;
    CRunScreenZoomAnim* scShakeYAnim;
    CArrayList* laAngleAnim;
    CArrayList* laScaleAnim;
    CArrayList* laScaleXAnim;
    CArrayList* laScaleYAnim;
    CArrayList* laShakeXAnim;
    CArrayList* laShakeYAnim;
    CLayer* currentLayer;
    
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(int)handleRunObject;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(CLayer*)getLayer:(NSString*)pName;

@end
