/* SOGoSAML2Actions.m - this file is part of SOGo
 *
 * Copyright (C) 2012-2014 Inverse inc
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#import <Foundation/NSCalendarDate.h>
#import <Foundation/NSTimeZone.h>

#import <NGObjWeb/SoApplication.h>
#import <NGObjWeb/WOContext.h>
#import <NGObjWeb/SoObject.h>
#import <NGObjWeb/WOContext+SoObjects.h>
#import <NGObjWeb/WOCookie.h>
#import <NGObjWeb/WODirectAction.h>
#import <NGObjWeb/WORequest.h>
#import <NGObjWeb/WOResponse.h>
#import <NGExtensions/NSCalendarDate+misc.h>
#import <NGExtensions/NSString+misc.h>

#import <SOGo/SOGoSAML2Session.h>
#import <SOGo/SOGoWebAuthenticator.h>

@interface SOGoSAML2Actions : WODirectAction
@end

@implementation SOGoSAML2Actions

- (WOResponse *) saml2MetadataAction
{
  WOResponse *response;
  NSString *metadata;

  response = [context response];
  [response setHeader: @"application/xml; charset=utf-8"
               forKey: @"content-type"];

  metadata = [SOGoSAML2Session metadataInContext: context];
  [response setContentEncoding: NSUTF8StringEncoding];
  [response appendContentString: metadata];

  return response;
}

- (WOCookie *) _authLocationResetCookieWithName: (NSString *) cookieName
{
  WOCookie *locationCookie;
  NSString *appName;
  WORequest *rq;
  NSCalendarDate *date;

  rq = [context request];
  locationCookie = [WOCookie cookieWithName: cookieName value: [rq uri]];
  appName = [rq applicationName];
  [locationCookie setPath: [NSString stringWithFormat: @"/%@/", appName]];
  date = [NSCalendarDate calendarDate];
  [date setTimeZone: [NSTimeZone timeZoneWithAbbreviation: @"GMT"]];
  [locationCookie setExpires: [date yesterday]];

  return locationCookie;
}

- (WOResponse *) saml2SignOnPOSTAction
{
  WORequest *rq;
  WOResponse *response;
  SoApplication *application;
  SOGoSAML2Session *newSession;
  WOCookie *authCookie;
  NSString *login, *oldLocation, *newLocation;
  SOGoWebAuthenticator *auth;

  rq = [context request];
  if ([[rq method] isEqualToString: @"POST"])
    {
      newSession = [SOGoSAML2Session SAML2SessionInContext: context];
      [newSession processAuthnResponse: [rq formValueForKey: @"SAMLResponse"]];
      login = [newSession login];

      application = [SoApplication application];
      auth = [application authenticatorInContext: context];
      authCookie = [auth cookieWithUsername: login
                                andPassword: [newSession identifier]
                                  inContext: context];

      oldLocation = [[context clientObject] baseURLInContext: context];
      newLocation = [NSString stringWithFormat: @"%@/%@",
                              oldLocation, [login stringByEscapingURL]];

      response = [context response];
      [response setStatus: 302];
      [response setHeader: @"text/plain; charset=utf-8"
                   forKey: @"content-type"];
      [response setHeader: newLocation forKey: @"location"];
      [response addCookie: authCookie];
    }

  return response;
}

@end
