/*
 Copyright 2015 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXKTableViewCell.h"

@implementation MXKTableViewCell

+ (UINib *)nib
{
    // Check whether a nib file is available
    NSBundle *mainBundle = [NSBundle bundleForClass:self.class];
    if ([[mainBundle.bundleURL pathExtension] isEqualToString:@"appex"]) {
        // For App extensions, peel off two levels
        mainBundle = [NSBundle bundleWithURL:[[mainBundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
    }
    
    NSString *path = [mainBundle pathForResource:NSStringFromClass([self class]) ofType:@"nib"];
    if (path)
    {
        return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:mainBundle];
    }
    return nil;
}

+ (NSString*)defaultReuseIdentifier
{
    return NSStringFromClass([self class]);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    // Check whether a xib is defined
    if ([[self class] nib])
    {
        self = [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
    }
    else
    {
        self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    }
    
    if (reuseIdentifier.length)
    {
        // The provided identifier is not always conserved in the new created cell.
        // This depends how the method [initWithStyle:reuseIdentifier:] is trigerred.
        // Trick: we store a copy of this identifier.
        mxkReuseIdentifier = reuseIdentifier;
    }
    else
    {
        mxkReuseIdentifier = [[self class] defaultReuseIdentifier];
    }
    
    return self;
}

- (NSString*)reuseIdentifier
{
    NSString *identifier = super.reuseIdentifier;
    
    if (!identifier.length)
    {
        identifier = mxkReuseIdentifier;
    }
    
    return identifier;
}

@end

