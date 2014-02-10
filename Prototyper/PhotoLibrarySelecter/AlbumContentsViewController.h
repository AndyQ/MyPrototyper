
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol AlbumContentsViewControllerDelegate <NSObject>

- (void) imagesSelected:(NSArray *)array;

@end

@interface AlbumContentsViewController : UICollectionViewController

@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) ALAssetsGroup *assetsGroup;

@property (nonatomic, weak) id<AlbumContentsViewControllerDelegate> delegate;

@end
