
#import <UIKit/UIKit.h>

@protocol AlbumSelectViewControllerDelegate <NSObject>

- (void) imagesSelected:(NSArray *)array;

@end

@interface AlbumSelectViewController : UITableViewController

@property (nonatomic, weak) id<AlbumSelectViewControllerDelegate> delegate;

@end
