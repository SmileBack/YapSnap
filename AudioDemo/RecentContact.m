//
//  RecentContact.m
//  YapSnap
//
//  Created by Jon Deokule on 1/27/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "RecentContact.h"

@implementation RecentContact

# pragma mark - Persistence
- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:self.contactID forKey:@"contactID"];
    [encoder encodeObject:self.contactTime forKey:@"contactTime"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        self.contactID = [decoder decodeObjectForKey:@"contactID"];
        self.contactTime = [decoder decodeObjectForKey:@"contactTime"];
    }
    return self;
}



@end
