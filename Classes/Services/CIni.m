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
//  CIni.m
//  RuntimeIPhone
//

#import "CIni.h"
#import "CFile.h"
#import "CArrayList.h"
#import "CRunApp.h"

static NSMutableDictionary* openINIFiles = nil;

// CINI ///////////////////////////////////////////////////////////////////////

@implementation CIni

+(CIni*)getINIforFile:(NSString*)filename
{
	if(openINIFiles == nil)
		openINIFiles = [[NSMutableDictionary alloc] init];

	//Use the actual file-writing filename as a key to look up the global INI data (so "myini.ini" and "C:/mygame/myini.ini) are identical)
	NSString* actualfilename = [[CRunApp getRunApp] getPathForWriting:filename];
	CIni* ini = [openINIFiles objectForKey:actualfilename];
	if(ini == nil)
	{
		//The INI is initialized without the writable filename to give it a chance to load a potential resource-based version
		//before attempting the actual physical file.
		ini = [[CIni alloc] initWithFilename:filename];
		[openINIFiles setObject:ini forKey:actualfilename];
	}
	return ini;
}

+(void)closeIni:(CIni*)ini
{
	[ini saveIni];
	NSString* iniFilename = [[CRunApp getRunApp] getPathForWriting:ini->currentFileName];
	[openINIFiles removeObjectForKey:iniFilename];
}

+(void)saveAllOpenINIfiles
{
	for (NSString* key in openINIFiles)
	{
		CIni* ini = [openINIFiles objectForKey:key];
		[ini saveIni];
	}
}

-(id)initWithFilename:(NSString*)filename
{
	if(self = [super init])
	{
		groups = [[NSMutableDictionary alloc] init];
		currentFileName = [filename retain];
		hasUnsavedChanges = NO;

		//The empty '[]' group as the default group
		NSMutableDictionary* currentGroupItems = [[NSMutableDictionary alloc] init];
		[groups setObject:currentGroupItems forKey:@""];
		[currentGroupItems release];

		if([[CRunApp getRunApp] resourceFileExists:filename])
		{
			CRunApp* app = [CRunApp getRunApp];
			NSData* myData = [app loadResourceData:filename];
			if (myData != nil && [myData length]!=0)
			{
				NSString* guess = [app stringGuessingEncoding:myData];
				if(guess != nil)
				{
					guess = [guess stringByReplacingOccurrencesOfString:@"\r" withString:@""];
					NSArray* lines = [guess componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

					for(NSString* s in lines)
					{
						//Is the current line empty?
						if([[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
							continue;

						//Is the current line a key-value pair?
						NSRange equalsRange = [s rangeOfString:@"="];
						if(equalsRange.location != NSNotFound)
						{
							NSString* key = [s substringToIndex:equalsRange.location];
							NSString* value = [s substringFromIndex:equalsRange.location+equalsRange.length];
							key = [[key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
							value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
							[currentGroupItems setObject:value forKey:key];
						}

						//Does the current line define a group?
						else if([s hasPrefix:@"["] && [s hasSuffix:@"]"])
						{
							NSString* groupname = [[s substringWithRange:NSMakeRange(1, [s length]-2)] lowercaseString];
							NSMutableDictionary* items = [groups objectForKey:groupname];

							//Does the group already exist? Just use this one as the current group
							if(items != nil)
								currentGroupItems = items;
							else
							{	//Else create a new one
								currentGroupItems = [[NSMutableDictionary alloc] init];
								[groups setObject:currentGroupItems forKey:groupname];
								[currentGroupItems release];
							}
						}
						else
						{
							//Invalid data. Ignoring...
							NSLog(@"Invalid INI data: '%@'", s);
						}
					}
				}
			}
		}
	}
	return self;
}

-(void)dealloc
{
	if (groups!=nil)
	{
		[groups release];
	}
	if (currentFileName!=nil)
	{
		[currentFileName release];
	}
	[super dealloc];
}

-(void)saveIni
{
	if(hasUnsavedChanges == NO)
		return;

	NSMutableString* ini = [[NSMutableString alloc] initWithCapacity:512];
	for (NSString* groupname in groups)
	{
		[ini appendFormat:@"\n[%@]\n", groupname];

		NSMutableDictionary* groupItems = [groups objectForKey:groupname];
		if(groupItems != nil)
		{
			for (NSString* key in groupItems)
			{
				NSString* value = [groupItems objectForKey:key];
				[ini appendFormat:@"%@ = %@\n", key, value];
			}
		}
	}

	NSString* path = [[CRunApp getRunApp] getPathForWriting:currentFileName];
	NSError* error = nil;
	[ini writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&error];
	if(error != nil)
		NSLog(@"INI file write error: %@", error);
	else
		hasUnsavedChanges = NO;
}


-(NSString*)getValueFromGroup:(NSString*)groupName withKey:(NSString*)keyName andDefaultValue:(NSString*)defaultString
{
	groupName = [groupName lowercaseString];
	keyName = [keyName lowercaseString];

	NSMutableDictionary* group = [groups objectForKey:groupName];
	if(group != nil)
	{
		NSString* value = [group objectForKey:keyName];
		if(value != nil)
			return [[value retain] autorelease];
	}

	if(defaultString == nil)
		return @"";
	return defaultString;
}

-(void)writeValueToGroup:(NSString*)groupName withKey:(NSString*)keyName andValue:(NSString*)newValue
{
	groupName = [groupName lowercaseString];
	keyName = [keyName lowercaseString];
	[newValue retain];

	NSMutableDictionary* group = [groups objectForKey:groupName];
	if(group == nil)
	{
		group = [[NSMutableDictionary alloc] init];
		[groups setObject:group forKey:groupName];
		[group release];
	}

	NSString* value = [group objectForKey:keyName];
	if(value != nil)
	{
		if(![value isEqualToString:newValue])
		{
			[group removeObjectForKey:keyName];
			[group setObject:newValue forKey:keyName];
			hasUnsavedChanges = YES;
		}
		//Ignores setting the value again if it is identical to the previous value
	}
	else
	{
		[group setObject:newValue forKey:keyName];
		hasUnsavedChanges = YES;
	}
}

-(void)deleteItemFromGroup:(NSString*)groupName withKey:(NSString*)keyname
{
	NSMutableDictionary* group = [groups objectForKey:[groupName lowercaseString]];
	if(group == nil)
		[group removeObjectForKey:[keyname lowercaseString]];
}

-(void)deleteGroup:(NSString*)groupName
{
	[groups removeObjectForKey:[groupName lowercaseString]];
}

@end
