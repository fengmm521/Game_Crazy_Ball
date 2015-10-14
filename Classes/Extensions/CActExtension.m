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
// -----------------------------------------------------------------------------
//
// CACTEXTENSION
//
// -----------------------------------------------------------------------------
#import "CActExtension.h"
#import "CRun.h"
#import "CValue.h"
#import "CServices.h"
#import "CObject.h"
#import "CFile.h"
#import "CEventProgram.h"
#import "CRunApp.h"

BOOL read_Position(CRun* rhPtr, LPPOS pPos, DWORD getDir, int* pX, int* pY, int* pDir, BOOL* pBRepeat, int* pLayer);

@implementation CActExtension

-(void)initialize:(LPEVT)evtPtr
{
	pEvent=evtPtr;
	
	pParams[0]=EVTPARAMS(evtPtr);
	
	int n;	
	for (n=1; n<evtPtr->evtNParams; n++)
	{
		pParams[n]=EVPNEXT(pParams[n-1]);
	}
}

// Recolte des parametres
// ----------------------
-(CObject*)getParamObject:(CRun*)rhPtr withNum:(int)num
{
	return [rhPtr->rhEvtProg get_ParamActionObjects:pParams[num]->evp.evpW.evpW0 withAction:pEvent];
}

-(int)getParamTime:(CRun*)rhPtr withNum:(int)num
{
	if (pParams[num]->evpCode == 2)	    // PARAM_TIME
	{
		return pParams[num]->evp.evpL.evpL0;
	}
	return [rhPtr get_EventExpressionInt:pParams[num]];
}

-(short)getParamBorder:(CRun*)rhPtr withNum:(int)num
{
	return pParams[num]->evp.evpW.evpW0;
}

-(short)getParamAltValue:(CRun*)rhPtr withNum:(int)num
{
	return pParams[num]->evp.evpW.evpW0;
}

-(short)getParamDirection:(CRun*)rhPtr withNum:(int)num
{
	return pParams[num]->evp.evpW.evpW0;
}

-(int)getParamAnimation:(CRun*)rhPtr withNum:(int)num
{
	if (pParams[num]->evpCode == 10)	    // PARAM_TIME
	{
		return pParams[num]->evp.evpW.evpW0;
	}
	return [rhPtr get_EventExpressionInt:pParams[num]];
}

-(short)getParamPlayer:(CRun*)rhPtr withNum:(int)num
{
	return pParams[num]->evp.evpW.evpW0;
}

-(LPEVP)getParamEvery:(CRun*)rhPtrw withNum:(int)num
{
	return pParams[num];
}

-(int)getParamSpeed:(CRun*)rhPtr withNum:(int)num
{
	return [rhPtr get_EventExpressionInt:pParams[num]];
}

-(unsigned int)getParamPosition:(CRun*)rhPtr withNum:(int)num
{
	int x, y, dir, layer;
	BOOL bRepeat;
	read_Position(rhPtr, (LPPOS)(&pParams[num]->evp.evpW.evpW0), 0, &x, &y, &dir, &bRepeat, &layer);	
	return MAKELONG(x, y);
}

-(short)getParamJoyDirection:(CRun*)rhPtr withNum:(int)num
{
	return pParams[num]->evp.evpW.evpW0;
}

-(int)getParamExpression:(CRun*)rhPtr withNum:(int)num
{
	return [rhPtr get_EventExpressionInt:pParams[num]];
}

-(int)getParamColour:(CRun*)rhPtr withNum:(int)num
{
	if (pParams[num]->evpCode == 24)	    // PARAM_COLOUR
	{
		return swapRGB(pParams[num]->evp.evpL.evpL0);
	}
	return swapRGB([rhPtr get_EventExpressionInt:pParams[num]]);
}

-(short)getParamFrame:(CRun*)rhPtr withNum:(int)num
{
	return pParams[num]->evp.evpW.evpW0;
}

-(int)getParamNewDirection:(CRun*)rhPtr withNum:(int)num
{
	if (pParams[num]->evpCode == 29)	    // PARAM_NEWDIRECTION
	{
		return pParams[num]->evp.evpW.evpW0;
	}
	return [rhPtr get_EventExpressionInt:pParams[num]];
}

-(short)getParamClick:(CRun*)rhPtr withNum:(int)num
{
	return pParams[num]->evp.evpW.evpW0;
}

-(short)getParamObjectType:(CRun*)rhPt withNum:(int)num
{
	return pParams[num]->evp.evpW.evpW0;
}


-(NSString*)getParamFilename:(CRun*)rhPtr withNum:(int)num
{
	if (pParams[num]->evpCode == 40)	    // PARAM_FILENAME
	{
		if (rhPtr->rhTempString!=nil)
			[rhPtr->rhTempString release];
		char* str = (char*)&pParams[num]->evp.evpW.evpW0;
		
		if(rhPtr->rhApp->bUnicode)
			rhPtr->rhTempString = [[NSString alloc] initWithCharacters:(unichar*)str length:strUnicharLen((unichar*)str)];
		else
			rhPtr->rhTempString = [[NSString alloc] initWithCString:str encoding:NSWindowsCP1252StringEncoding];
		
		return rhPtr->rhTempString;
	}
	return [rhPtr get_EventExpressionString:pParams[num]];
}

-(NSString*)getParamExpString:(CRun*)rhPtr withNum:(int)num
{
	return [rhPtr get_EventExpressionString:pParams[num]];
}

-(double)getParamExpDouble:(CRun*)rhPtr withNum:(int)num
{
	CValue* value = [rhPtr get_EventExpressionAny:pParams[num]];
	return [value getDouble];
}

-(NSString*)getParamFilename2:(CRun*)rhPtr withNum:(int)num
{
	if (pParams[num]->evpCode == 63)	    // PARAM_FILENAME2
	{
		size_t l=strlen((char*)&pParams[num]->evp.evpW.evpW0);
		if (rhPtr->rhTempString!=nil)
		{
			[rhPtr->rhTempString release];
		}
		rhPtr->rhTempString=[[NSString alloc] initWithBytes:&pParams[num]->evp.evpW.evpW0 length:l encoding:NSWindowsCP1252StringEncoding];
		return rhPtr->rhTempString;
	}
	return [rhPtr get_EventExpressionString:pParams[num]];
}

-(CFile*)getParamExtension:(CRun*)rhPtr withNum:(int)num
{
	int size=pParams[num]->evp.evpW.evpW0;
	if (size>6)
	{
		CFile* file=[[CFile alloc] initWithBytes:(unsigned char*)&pParams[num]->evp.evpW.evpW3 length:size-6];
		return file;
	}
	return nil;
}

-(short*)getParamZone:(CRun*)rhPtr withNum:(int)num
{
	return &pParams[num]->evp.evpW.evpW0;
}




@end
