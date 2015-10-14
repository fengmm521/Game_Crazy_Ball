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
// CRunMTTandom: MT random object
// fin 3rd feb 2010
//
//----------------------------------------------------------------------------------
#import "CRunMTRandom.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CServices.h"

#define AID_aSeedClock		0
#define AID_aSeedOne		1
#define AID_aSeedTwo		2
#define AID_aSeedThree 	3
#define AID_aSeedFour 	4
#define AID_aSeedSix 	5
#define AID_aSeedEight 	6
#define AID_aSeedTen 	7
#define AID_aExpire 	8
#define AID_aExpireX 	9
#define EID_eRandDbl1					0
#define EID_eRandDbl1Ex			1
#define EID_eRandDbl				2
#define EID_eRandDblEx			3
#define EID_eRandInt			4
#define EID_eRandIntEx				5

int START_TIME=-1;

@implementation CRunMTRandom

-(id)init
{
	if (START_TIME == -1)
	{
		START_TIME = (int)time(nil);
	}
	return self;
}

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    [file skipBytes:8];
	BOOL seedvalues = ([file readAByte] != 0) ? YES: NO;
	
	int seed[10];
	int n;
	for (n=0; n<10; n++)
	{
		seed[n]=[file readAInt];
	}
	rand = [[MTRandomMersenne alloc] init];
	if (seedvalues)
	{
		[rand setSeed:seed length:10];
	}
    else
    {
        [rand setSeed:(int)time(nil)];
    }
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	[rand release];
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{        
		case AID_aSeedClock:
			[rand setSeed:(int)time(nil)];
			break;        
		case AID_aSeedOne:
			[rand setSeed:[act getParamExpression:rh withNum:0]];
			break;
		case AID_aSeedTwo:
		{
			int randvals2[2];
			for (int i = 0; i < 2; i++)
			{
				randvals2[i] = [act getParamExpression:rh withNum:i];
			}
			[rand setSeed:randvals2 length:2];
			break;
		}
		case AID_aSeedThree:
		{
			int randvals3[3];
			for (int i = 0; i < 3; i++)
			{
				randvals3[i] = [act getParamExpression:rh withNum:i];
			}
			[rand setSeed:randvals3 length:3];
			break;
		}
		case AID_aSeedFour:
		{
			int randvals4[4];
			for (int i = 0; i < 4; i++)
			{
				randvals4[i] = [act getParamExpression:rh withNum:i];
			}
			[rand setSeed:randvals4 length:4];
			break;
		}
		case AID_aSeedSix:
		{
			int randvals6[6];
			for (int i = 0; i < 6; i++)
			{
				randvals6[i] = [act getParamExpression:rh withNum:i];
			}
			[rand setSeed:randvals6 length:6];
			break;
		}
		case AID_aSeedEight:
		{
			int randvals8[8];
			for (int i = 0; i < 8; i++)
			{
				randvals8[i] = [act getParamExpression:rh withNum:i];
			}
			[rand setSeed:randvals8 length:8];
			break;
		}
		case AID_aSeedTen:
		{
			int randvals10[10];
			for (int i = 0; i < 10; i++)
			{
				randvals10[i] = [act getParamExpression:rh withNum:i];
			}
			[rand setSeed:randvals10 length:10];
			break;
		}
		case AID_aExpire:
			[rand nextDouble];
			break;
		case AID_aExpireX:
		{
			int x = [act getParamExpression:rh withNum:0];
			for (int i=0; i<x; i++)
				[rand nextDouble];
			break;
		}
	}
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	CValue* ret=[rh getTempValue:0];
	switch (num)
	{
		case EID_eRandDbl1:
			[ret forceDouble:[rand nextDouble]];
			break;
		case EID_eRandDbl1Ex:
			[ret forceDouble:[rand nextDouble]];
			break;
		case EID_eRandDbl:
		{
			double p1 = [[ho getExpParam] getDouble];
			double p2 = [[ho getExpParam] getDouble];
			[ret forceDouble:[rand nextDouble:p1 withMax:p2]];
			break;
		}
		case EID_eRandDblEx:
		{
			double p1ex = [[ho getExpParam] getDouble];
			double p2ex = [[ho getExpParam] getDouble];
			[ret forceDouble:[rand nextDouble:p1ex withMax:p2ex]];
			break;
		}
		case EID_eRandInt:
		{
			int p1int = [[ho getExpParam] getInt];
			int p2int = [[ho getExpParam] getInt] + 1;
			[ret forceInt:[rand nextIntEx:p2int - p1int]+p1int];
			break;
		}
		case EID_eRandIntEx:
		{
			int p1intex = [[ho getExpParam] getInt];
			int p2intex = [[ho getExpParam] getInt];
			[ret forceInt:[rand nextIntEx:p2intex - p1intex]+p1intex];
			break;
		}
	}
	return ret;
}

@end

@implementation MTRandomMersenne

-(void)setSeed:(int)seed 
{	
	mag01[0] = 0x0;
	mag01[1] = MTRAND_MATRIX_A;
	
	mt[0] = seed;
	for (mti = 1; mti < MTRAND_N; mti++) 
	{
		mt[mti] = (1812433253 * (mt[mti - 1] ^ ((mt[mti - 1] >> 30)&0x7FFFFFFF)) + mti);
		mt[mti] &= 0xffffffff;
	}
}

-(void)setSeed:(int*)array length:(int)length
{
	if (length == 0) 
	{
		return;
	}
	int i, j, k;
	[self setSeed:19650218];
	i = 1;
	j = 0;
	k = (MTRAND_N > length ? MTRAND_N : length);
	for (; k != 0; k--) 
	{
		mt[i] = (mt[i] ^ ((mt[i - 1] ^ ((mt[i - 1] >> 30)&0x7FFFFFFF)) * 1664525)) + array[j] + j; /* non linear */
		mt[i] &= 0xffffffff; /* for WORDSIZE > 32 machines */
		i++;
		j++;
		if (i >= MTRAND_N) 
		{
			mt[0] = mt[MTRAND_N - 1];
			i = 1;
		}
		if (j >= length) 
		{
			j = 0;
		}
	}
	for (k = MTRAND_N - 1; k != 0; k--) 
	{
		mt[i] = (mt[i] ^ ((mt[i - 1] ^ ((mt[i - 1] >> 30)&0x7FFFFFFF)) * 1566083941)) - i; /* non linear */
		mt[i] &= 0xffffffff; /* for WORDSIZE > 32 machines */
		i++;
		if (i >= MTRAND_N) 
		{
			mt[0] = mt[MTRAND_N - 1];
			i = 1;
		}
	}
	mt[0] = 0x80000000; /* MSB is 1; assuring non-zero initial array */
}     

-(int)next:(int)bits
{
	int y;

	if (mti >= MTRAND_N) // generate N words at one time
	{
		int kk;
		
		for (kk = 0; kk < MTRAND_N - MTRAND_M; kk++) 
		{
			y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK);
			mt[kk] = mt[kk + MTRAND_M] ^ (y >> 1) ^ mag01[y & 0x1];
		}
		for (; kk < MTRAND_N - 1; kk++) {
			y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK);
			mt[kk] = mt[kk + (MTRAND_M - MTRAND_N)] ^ (y >> 1) ^ mag01[y & 0x1];
		}
		y = (mt[MTRAND_N - 1] & UPPER_MASK) | (mt[0] & LOWER_MASK);
		mt[MTRAND_N - 1] = mt[MTRAND_M - 1] ^ (y >> 1) ^ mag01[y & 0x1];
		
		mti = 0;
	}
	
	y = mt[mti++];
	y ^= (y >> 11);                          // TEMPERING_SHIFT_U(y)
	y ^= (y << 7) & TEMPERING_MASK_B;       // TEMPERING_SHIFT_S(y)
	y ^= (y << 15) & TEMPERING_MASK_C;      // TEMPERING_SHIFT_T(y)
	y ^= (y >> 18);                        // TEMPERING_SHIFT_L(y)
	
	return y >> (32-bits);
}

-(double)nextDouble
{
	int64_t over = (((int64_t)[self next:26] << 27) + [self next:27]) ;
	double divisor = (double)((int64_t)1 << 53);
	double ret = over/divisor ;
	return ret;
}

-(double)nextDouble:(double)min withMax:(double)max
{
	return [self nextDouble]*(max-min) + min;
}

-(int)nextIntEx:(int)n
{
	n = MAX(0, n);
	
	/*if ((n & -n) == n) // i.e., n is a power of 2
	{
		int y;
		
		if (mti >= MTRAND_N) // generate N words at one time
		{
			int kk;
			
			for (kk = 0; kk < MTRAND_N - MTRAND_M; kk++) 
			{
				y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK);
				mt[kk] = mt[kk + MTRAND_M] ^ ((y >> 1)&0x7FFFFFFF) ^ mag01[y & 0x1];
			}
			for (; kk < MTRAND_N - 1; kk++) 
			{
				y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK);
				mt[kk] = mt[kk + (MTRAND_M - MTRAND_N)] ^ ((y >> 1)&0x7FFFFFFF) ^ mag01[y & 0x1];
			}
			y = (mt[MTRAND_N - 1] & UPPER_MASK) | (mt[0] & LOWER_MASK);
			mt[MTRAND_N - 1] = mt[MTRAND_M - 1] ^ ((y >> 1)&0x7FFFFFFF) ^ mag01[y & 0x1];
			
			mti = 0;
		}
		
		y = mt[mti++];
		y ^= (y >> 11)&0x7FFFFFFF;                          // TEMPERING_SHIFT_U(y)
		y ^= (y << 7) & TEMPERING_MASK_B;       // TEMPERING_SHIFT_S(y)
		y ^= (y << 15) & TEMPERING_MASK_C;      // TEMPERING_SHIFT_T(y)
		y ^= (y >> 18)&0x7FFFFFFF;                        // TEMPERING_SHIFT_L(y)
		
		int ret = (int) ((n *  ((y >> 1)&0x7FFFFFFF)) >> 31);
		return ret;
	}*/
	
	int bits, val;
	do 
	{
		int y;
		
		if (mti >= MTRAND_N) // generate N words at one time
		{
			int kk;
			
			for (kk = 0; kk < MTRAND_N - MTRAND_M; kk++) 
			{
				y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK);
				mt[kk] = mt[kk + MTRAND_M] ^ ((y >> 1)&0x7FFFFFFF) ^ mag01[y & 0x1];
			}
			for (; kk < MTRAND_N - 1; kk++) 
			{
				y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK);
				mt[kk] = mt[kk + (MTRAND_M - MTRAND_N)] ^ ((y >> 1)&0x7FFFFFFF) ^ mag01[y & 0x1];
			}
			y = (mt[MTRAND_N - 1] & UPPER_MASK) | (mt[0] & LOWER_MASK);
			mt[MTRAND_N - 1] = mt[MTRAND_M - 1] ^ ((y >> 1)&0x7FFFFFFF) ^ mag01[y & 0x1];
			
			mti = 0;
		}
		
		y = mt[mti++];
		y ^= (y >> 11)&0x7FFFFFFF;                          // TEMPERING_SHIFT_U(y)
		y ^= (y << 7) & TEMPERING_MASK_B;       // TEMPERING_SHIFT_S(y)
		y ^= (y << 15) & TEMPERING_MASK_C;      // TEMPERING_SHIFT_T(y)
		y ^= (y >> 18)&0x7FFFFFFF;                        // TEMPERING_SHIFT_L(y)
		
		bits = (y >> 1)&0x7FFFFFFF;
		val = bits % n;
	} while (bits - val + (n - 1) < 0);
	return val;
}




@end