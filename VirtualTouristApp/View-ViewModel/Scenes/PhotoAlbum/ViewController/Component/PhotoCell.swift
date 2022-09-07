import UIKit
import Kingfisher


//MARK: - CollectionViewCell

struct PhotoCell {
//    let imageUrl: String?
    let image: UIImage?
}

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var cellActivityIndicator: UIActivityIndicatorView!

    var viewModel: PhotoAlbumViewModelProtocol!

    override var isSelected: Bool {
        didSet {
            if isSelected {
                checkMark.isHidden = false
                checkMark.image = UIImage(systemName: "checkmark.circle.fill")
                cellImageView.alpha = 0.5
            } else {
                checkMark.isHidden = true
                cellImageView.alpha = 1
            }
        }
    }

    var onReuse: () -> Void = {}

    override func prepareForReuse() {
      super.prepareForReuse()
        cellImageView.image = nil
        cellImageView.cancelImageLoad()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        isSelected = false
    }

    private func updateActivityIndicatorStatus(isLoading: Bool) {
        if isLoading {
            cellActivityIndicator.isHidden = false
            cellActivityIndicator.startAnimating()
        } else {
            self.cellActivityIndicator.stopAnimating()
            self.cellActivityIndicator.isHidden = true
        }
    }

    func fill(_ cell: PhotoCell) {
        updateActivityIndicatorStatus(isLoading: true)
        DispatchQueue.main.async {
            if let image = cell.image {
                self.cellImageView.image = image
                self.updateActivityIndicatorStatus(isLoading: false)
                self.setNeedsLayout()
            } else {
                print("there is no image saved is CoreData")
            }
        }
    }

    func loadData(completion: @escaping () -> Void) {
        viewModel.loadPhotosUrls { result in
            switch result {
            case .success(let photosUrl):
                for photoUrl in photosUrl {
                    self.cellImageView.loadImage(at: photoUrl)
                    self.updateActivityIndicatorStatus(isLoading: false)
                }
            case .failure(let error):
                print("error to catch the photosUrl \(error)")
                break
//                    self.delegate?.didLoadWithError(error)
            }
        }
    }    
}

extension UIImageView {
  func loadImage(at url: String) {
    UIImageLoader.loader.load(url, for: self)
  }

  func cancelImageLoad() {
    UIImageLoader.loader.cancel(for: self)
  }
}
