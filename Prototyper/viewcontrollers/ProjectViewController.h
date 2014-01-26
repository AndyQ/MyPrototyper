//
//  ProjectViewController.h
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProjectViewController : UIViewController<UICollectionViewDataSource>

@property (nonatomic, strong) NSString *projectName;

@end
