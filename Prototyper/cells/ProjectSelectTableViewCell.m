//
//  ProjectSelectTableViewCell.m
//  Prototyper
//
//  Created by Andy Qua on 29/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ProjectSelectTableViewCell.h"

@interface ProjectSelectTableViewCell ()

@end

@implementation ProjectSelectTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
