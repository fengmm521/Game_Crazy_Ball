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
// CVALUE : classe de calcul et de stockage de valeurs
//
//----------------------------------------------------------------------------------
#import "CValue.h"

@implementation CValue

-(id)init
{
	self = [super init];
	type=TYPE_INT;
	intValue=0;
	stringValue=@"";
	return self;
}

-(void)dealloc
{
	if (stringValue!=nil)
	{
		[stringValue release];
		stringValue=nil;
	}
	[super dealloc];
}

-(id)initWithInt:(int)value
{
	self = [super init];
	type=TYPE_INT;
	intValue=value;
	doubleValue=0;
	stringValue=@"";
	return self;
}
-(id)initWithDouble:(double)value
{
	self = [super init];
	type=TYPE_DOUBLE;
	intValue=0;
	doubleValue=value;
	stringValue=@"";
	return self;
}
-(id)initWithString:(NSString*)string
{
	self = [super init];
	type=TYPE_STRING;
	intValue=0;
	doubleValue=0;
	stringValue=[[NSString alloc] initWithString:string];
	return self;
}
-(id)initWithValue:(CValue*)value
{
	self = [super init];
	stringValue=@"";
	switch (value->type)
	{
		case 0:
			intValue = value->intValue;
			doubleValue=0;
			break;
		case 1:
			doubleValue = value->doubleValue;
			break;
		case 2:
			stringValue=[[NSString alloc] initWithString:value->stringValue];
			break;
	}
	type = value->type;
	return self;
}
-(void)releaseString
{
	if (stringValue!=nil)
	{
		[stringValue release];
		stringValue=@"";
	}
}
-(short)getType
{
	return type;
}
-(int)getInt
{
	switch (type)
	{
		case 0:
			return intValue;
		case 1:
			return (int)doubleValue;
	}
	return 0;
}

-(double)getDouble
{
	switch (type)
	{
		case 0:
			return (double) intValue;
		case 1:
			return doubleValue;
	}
	return 0;
}

-(NSString*)getString
{
	if (type == TYPE_STRING)
	{
		return stringValue;
	}
	return @"";
}
-(void)forceInt:(int)value
{
	if (stringValue!=nil)
	{
		[stringValue release];
		stringValue=@"";
	}
	type = TYPE_INT;
	intValue = value;
}
-(void)forceDouble:(double)value
{
	if (stringValue!=nil)
	{
		[stringValue release];
		stringValue=@"";
	}
	type = TYPE_DOUBLE;
	doubleValue = value;
}
-(void)forceString:(NSString*)value
{
	if (stringValue!=nil)
	{
		[stringValue release];
		stringValue=@"";
	}
	type = TYPE_STRING;
	stringValue = [[NSString alloc] initWithString:value];
}
-(void)forceValue:(CValue*)value
{
	type = value->type;
	if (stringValue!=nil)
	{
		[stringValue release];
		stringValue=@"";
	}
	switch (type)
	{
		case 0:
			intValue = value->intValue;
			break;
		case 1:
			doubleValue = value->doubleValue;
			break;
		case 2:
			stringValue = [[NSString alloc] initWithString:value->stringValue];
			break;
	}
}
-(void)setValue:(CValue*)value
{
	switch (type)
	{
		case 0:
			intValue = [value getInt];
			break;
		case 1:
			doubleValue = [value getDouble];
			break;
		case 2:
			if (stringValue!=nil)
			{
				[stringValue release];
				stringValue=@"";
			}
			stringValue = [[NSString alloc] initWithString:[value getString]];
			break;
	}
}

-(void)convertToDouble
{
	if (type == TYPE_INT)
	{
		doubleValue = (double) intValue;
		type = TYPE_DOUBLE;
	}
}
-(void)convertToInt
{
	if (type == TYPE_DOUBLE)
	{
		intValue = (int) doubleValue;
		type = TYPE_INT;
	}
}
-(void)add:(CValue*)value
{
	switch (type)
	{
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				intValue += value->intValue;
			else if ( value->type == TYPE_DOUBLE )
			{
				doubleValue = (double)intValue;
				type = TYPE_DOUBLE;
				doubleValue += value->doubleValue;
			}
			break;
		case TYPE_DOUBLE:
			if ( value->type == TYPE_DOUBLE )
				doubleValue += value->doubleValue;
			else if ( value->type == TYPE_INT )
				doubleValue += (double)value->intValue;
			break;
		case TYPE_STRING:
		{
			NSString* temp=[stringValue stringByAppendingString:value->stringValue];
			if (stringValue!=nil)
			{
				[stringValue release];
				stringValue=@"";
			}
			stringValue=[[NSString alloc] initWithString:temp];
			break;
		}
	}
}
-(void)addInt:(int)lvalue
{
	switch (type)
	{
		case TYPE_INT:
			intValue += lvalue;
			break;
		case TYPE_DOUBLE:
			doubleValue += (double)lvalue;
			break;
	}
}
-(void)addDouble:(double)dvalue
{
	switch (type)
	{
		case TYPE_INT:
			doubleValue = (double)intValue;
			type = TYPE_DOUBLE;
			doubleValue += dvalue;
			break;
		case TYPE_DOUBLE:
			doubleValue += dvalue;
			break;
	}
}
-(void)sub:(CValue*)value
{
	switch (type)
	{
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				intValue -= value->intValue;
			else if ( value->type == TYPE_DOUBLE )
			{
				doubleValue = (double)intValue;
				type = TYPE_DOUBLE;
				doubleValue -= value->doubleValue;
			}
			break;
		case TYPE_DOUBLE:
			if ( value->type == TYPE_DOUBLE )
				doubleValue -= value->doubleValue;
			else if ( value->type == TYPE_INT )
				doubleValue -= (double)value->intValue;
			break;
	}
}
-(void)subInt:(int)lvalue
{
	switch (type)
	{
		case TYPE_INT:
			intValue -= lvalue;
			break;
		case TYPE_DOUBLE:
			doubleValue -= (double)lvalue;
			break;
	}
}
-(void)subDouble:(double)dvalue
{
	switch (type)
	{
		case TYPE_INT:
			doubleValue = (double)intValue;
			type = TYPE_DOUBLE;
			doubleValue -= dvalue;
			break;
		case TYPE_DOUBLE:
			doubleValue -= dvalue;
			break;
	}
}
-(void)negate
{
	switch (type)
	{
		case TYPE_INT:
			intValue = -intValue;
			break;
		case TYPE_DOUBLE:
			doubleValue = -doubleValue;
			break;
	}
}
-(void)mul:(CValue*)value
{
	switch (type)
	{
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				intValue *= value->intValue;
			else if ( value->type == TYPE_DOUBLE )
			{
				doubleValue = (double)intValue;
				type = TYPE_DOUBLE;
				doubleValue *= value->doubleValue;
			}
			break;
		case TYPE_DOUBLE:
			if ( value->type == TYPE_DOUBLE )
				doubleValue *= value->doubleValue;
			else if ( value->type == TYPE_INT )
				doubleValue *= (double)value->intValue;
			break;
	}
}
-(void)div:(CValue*)value
{
	switch (type)
	{
		case TYPE_INT:
			if ( value->type == TYPE_INT )
			{
				if ( value->intValue != 0 )
					intValue /= value->intValue;
				else
					intValue = 0;
			}
			else if ( value->type == TYPE_DOUBLE )
			{
				doubleValue = (double)intValue;
				type = TYPE_DOUBLE;
				if ( value->doubleValue != 0.0 )
					doubleValue /= value->doubleValue;
				else
					doubleValue = 0.0;
			}
			break;
		case TYPE_DOUBLE:
			if ( value->type == TYPE_DOUBLE )
			{
				if ( value->doubleValue != 0.0 )
					doubleValue /= value->doubleValue;
				else
					doubleValue = 0.0;
			}
			else if ( value->type == TYPE_INT )
			{
				if ( value->intValue != 0 )
					doubleValue /= (double)value->intValue;
				else
					doubleValue = 0.0;
			}
			break;
	}
}
-(void)pow:(CValue*)value
{
	doubleValue = pow([self getDouble], [value getDouble]);
	type = TYPE_DOUBLE;
}
-(void)mod:(CValue*)value
{
	switch (type)
	{
	case TYPE_INT:
		if ( value->type == TYPE_INT )
		{
			if ( value->intValue != 0 )
				intValue %= value->intValue;
			else
				intValue = 0;
		}
		else if ( value->type == TYPE_DOUBLE )
		{
			doubleValue = (double)intValue;
			type = TYPE_DOUBLE;
			if ( value->doubleValue != 0.0 )
				doubleValue = fmod(doubleValue, value->doubleValue);
			else
				doubleValue = 0.0;
		}
		break;
	case TYPE_DOUBLE:
		if ( value->type == TYPE_DOUBLE )
		{
			if ( value->doubleValue != 0.0 )
				doubleValue = fmod(doubleValue, value->doubleValue);
			else
				doubleValue = 0.0;
		}
		else if ( value->type == TYPE_INT )
		{
			if ( value->intValue != 0 )
				doubleValue = fmod(doubleValue, (double)value->intValue);
			else
				doubleValue = 0.0;
		}
		break;
	}
}
-(void)andLog:(CValue*)value
{
	switch (type)
	{
		case TYPE_DOUBLE:
			intValue = (int)doubleValue;
			type = TYPE_INT;
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				intValue &= value->intValue;
			else if ( value->type == TYPE_DOUBLE )
				intValue &= (int)value->doubleValue;
			break;
	}
}
-(void)orLog:(CValue*)value
{
	switch (type)
	{
		case TYPE_DOUBLE:
			intValue = (int)doubleValue;
			type = TYPE_INT;
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				intValue |= value->intValue;
			else if ( value->type == TYPE_DOUBLE )
				intValue |= (int)value->doubleValue;
			break;
	}
}
-(void)xorLog:(CValue*)value
{
	switch (type)
	{
		case TYPE_DOUBLE:
			intValue = (int)doubleValue;
			type = TYPE_INT;
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				intValue ^= value->intValue;
			else if ( value->type == TYPE_DOUBLE )
				intValue ^= (int)value->doubleValue;
			break;
	}
}
-(BOOL)equal:(CValue*)value
{
	switch (type)
	{
	case TYPE_INT:
		if ( value->type == TYPE_INT )
			return (intValue == value->intValue);
		else if ( value->type == TYPE_DOUBLE )
			return ((double)intValue == value->doubleValue);
		break;
	case TYPE_DOUBLE:
		if ( value->type == TYPE_DOUBLE )
			return (doubleValue == value->doubleValue);
		else if ( value->type == TYPE_INT )
			return (doubleValue == (double)value->intValue);
		break;
	case TYPE_STRING:
		if ( value->type == TYPE_STRING )
			return [stringValue compare:value->stringValue] == 0;
		break;
	}
	return NO;
}
-(BOOL)equalInt:(int)lvalue
{
	switch (type) {
		case TYPE_INT:
			return (intValue==lvalue);
		case TYPE_DOUBLE:
			return (doubleValue==(double)lvalue);
	}
	return NO;
}
-(BOOL)equalDouble:(double)dvalue
{
	switch (type) {
		case TYPE_INT:
			return ((double)intValue==dvalue);
		case TYPE_DOUBLE:
			return (doubleValue==dvalue);
	}
	return NO;
}
-(BOOL)greater:(CValue*)value
{
	switch (type)
	{
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				return (intValue >= value->intValue);
			else if ( value->type == TYPE_DOUBLE )
				return ((double)intValue >= value->doubleValue);
			break;
		case TYPE_DOUBLE:
			if ( value->type == TYPE_DOUBLE )
				return (doubleValue >= value->doubleValue);
			else if ( value->type == TYPE_INT )
				return (doubleValue >= (double)value->intValue);
			break;
		case TYPE_STRING:
			if ( value->type == TYPE_STRING )
				return [stringValue compare:value->stringValue] >= 0;
			break;
	}
	return NO;
}
-(BOOL)greaterInt:(int)lvalue
{
	switch (type) {
	case TYPE_INT:
		return (intValue>=lvalue);
	case TYPE_DOUBLE:
		return (doubleValue>=(double)lvalue);
	}
	return NO;
}
-(BOOL)greaterDouble:(double)dvalue
{
	switch (type) {
		case TYPE_INT:
			return ((double)intValue>=dvalue);
		case TYPE_DOUBLE:
			return (doubleValue>=dvalue);
	}
	return NO;
}
-(BOOL)lower:(CValue*)value
{
	switch (type)
	{
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				return (intValue <= value->intValue);
			else if ( value->type == TYPE_DOUBLE )
				return ((double)intValue <= value->doubleValue);
			break;
		case TYPE_DOUBLE:
			if ( value->type == TYPE_DOUBLE )
				return (doubleValue <= value->doubleValue);
			else if ( value->type == TYPE_INT )
				return (doubleValue <= (double)value->intValue);
			break;
		case TYPE_STRING:
			if ( value->type == TYPE_STRING )
				return [stringValue compare:value->stringValue] <= 0;
			break;
	}
	return NO;
}
-(BOOL)lowerInt:(int)lvalue
{
	switch (type) {
		case TYPE_INT:
			return (intValue<=lvalue);
		case TYPE_DOUBLE:
			return (doubleValue<=(double)lvalue);
	}
	return NO;
}
-(BOOL)lowerDouble:(double)dvalue
{
	switch (type) {
		case TYPE_INT:
			return ((double)intValue<=dvalue);
		case TYPE_DOUBLE:
			return (doubleValue<=dvalue);
	}
	return NO;
}
-(BOOL)greaterThan:(CValue*)value
{
	switch (type)
	{
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				return (intValue > value->intValue);
			else if ( value->type == TYPE_DOUBLE )
				return ((double)intValue > value->doubleValue);
			break;
		case TYPE_DOUBLE:
			if ( value->type == TYPE_DOUBLE )
				return (doubleValue > value->doubleValue);
			else if ( value->type == TYPE_INT )
				return (doubleValue > (double)value->intValue);
			break;
		case TYPE_STRING:
			if ( value->type == TYPE_STRING )
				return [stringValue compare:value->stringValue] > 0;
			break;
	}
	return NO;
}
-(BOOL)greaterThanInt:(int)lvalue
{
	switch (type) {
		case TYPE_INT:
			return (intValue>lvalue);
		case TYPE_DOUBLE:
			return (doubleValue>(double)lvalue);
	}
	return NO;
}
-(BOOL)greaterThanDouble:(double)dvalue
{
	switch (type) {
		case TYPE_INT:
			return ((double)intValue>dvalue);
		case TYPE_DOUBLE:
			return (doubleValue>dvalue);
	}
	return NO;
}
-(BOOL)lowerThan:(CValue*)value
{
	switch (type)
	{
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				return (intValue < value->intValue);
			else if ( value->type == TYPE_DOUBLE )
				return ((double)intValue < value->doubleValue);
			break;
		case TYPE_DOUBLE:
			if ( value->type == TYPE_DOUBLE )
				return (doubleValue < value->doubleValue);
			else if ( value->type == TYPE_INT )
				return (doubleValue < (double)value->intValue);
			break;
		case TYPE_STRING:
			if ( value->type == TYPE_STRING )
				return [stringValue compare:value->stringValue] < 0;
			break;
	}
	return NO;
}
-(BOOL)lowerThanInt:(int)lvalue
{
	switch (type) {
		case TYPE_INT:
			return (intValue<lvalue);
		case TYPE_DOUBLE:
			return (doubleValue<(double)lvalue);
	}
	return NO;
}
-(BOOL)lowerThanDouble:(double)dvalue
{
	switch (type) {
		case TYPE_INT:
			return ((double)intValue<dvalue);
		case TYPE_DOUBLE:
			return (doubleValue<dvalue);
	}
	return NO;
}
-(BOOL)notEqual:(CValue*)value
{
	switch (type)
	{
		case TYPE_INT:
			if ( value->type == TYPE_INT )
				return (intValue != value->intValue);
			else if ( value->type == TYPE_DOUBLE )
				return ((double)intValue != value->doubleValue);
			break;
		case TYPE_DOUBLE:
			if ( value->type == TYPE_DOUBLE )
				return (doubleValue != value->doubleValue);
			else if ( value->type == TYPE_INT )
				return (doubleValue != (double)value->intValue);
			break;
		case TYPE_STRING:
			if ( value->type == TYPE_STRING )
				return [stringValue compare:value->stringValue] != 0;
			break;
	}
	return YES;
}
-(BOOL)notEqualInt:(int)lvalue
{
	switch (type) {
		case TYPE_INT:
			return (intValue!=lvalue);
		case TYPE_DOUBLE:
			return (doubleValue!=(double)lvalue);
	}
	return YES;
}
-(BOOL)notEqualDouble:(double)dvalue
{
	switch (type) {
		case TYPE_INT:
			return ((double)intValue!=dvalue);
		case TYPE_DOUBLE:
			return (doubleValue!=dvalue);
	}
	return YES;
}


-(NSString*)description
{
	switch (type)
	{
		case 0:
			return [NSString stringWithFormat:@"CValue int: '%i'", intValue];
		case 1:
			return [NSString stringWithFormat:@"CValue double: '%f'", (float)doubleValue];
		case 2:
			return [NSString stringWithFormat:@"CValue string: '%@'", stringValue];
	}
	return nil;
}


@end
