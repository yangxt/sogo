/* NGVCardPhoto.m - this file is part of NGCards
 *
 * Copyright (C) 2010 Inverse inc.
 *
 * Author: Wolfgang Sourdeau <wsourdeau@inverse.ca>
 *
 * NGCards is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the
 * Free Software Foundation; either version 2, or (at your option) any
 * later version.
 *
 * NGCards is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with NGCards; see the file COPYING.  If not, write to the
 * Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 */

#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

#import <NGExtensions/NGBase64Coding.h>
#import <NGExtensions/NSObject+Logs.h>

#import "NGVCardPhoto.h"

@implementation NGVCardPhoto

- (BOOL) isInline
{
  return ![[self value: 0 ofAttribute: @"value"] isEqualToString: @"uri"];
}

- (NSString *) type
{
  NSString *type;

  type = [[self value: 0 ofAttribute: @"type"] uppercaseString];
  if (!type)
    type = @"JPEG";

  return type;
}

- (NSData *) decodedContent
{
  NSString *encoding, *value;
  NSData *decodedContent;

  decodedContent = nil;

  if ([self isInline])
    {
      encoding = [[self value: 0 ofAttribute: @"encoding"] uppercaseString];
      if ([encoding isEqualToString: @"B"]
          || [encoding isEqualToString: @"BASE64"])
        {
          /* We bypass -[values:] because we want to obtain the undecoded
             value first. */
          if ([values count] > 0)
            {
              value = [values objectAtIndex: 0];
              decodedContent = [value dataByDecodingBase64];
            }
          else
            [self errorWithFormat: @"attempt to decode empty value"];
        }
      else
        [self errorWithFormat:
                @"decoded content requested with an unknown encoding: '%@'",
              encoding];
    }
  else
    [self errorWithFormat:
            @"decoded content requested on a PHOTO of type 'uri'"];

  return decodedContent;
}

@end