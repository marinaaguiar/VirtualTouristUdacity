import UIKit
import Kingfisher


//MARK: - CollectionViewCell

struct PhotoCell {
    let imageUrl: String?
}

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var cellActivityIndicator: UIActivityIndicatorView!

    private var currentLoadID: UUID?

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

    override func awakeFromNib() {
        super.awakeFromNib()
        isSelected = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.currentLoadID = nil
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

        self.currentLoadID = PhotoCache.shared.fetchImage(urlString: cell.imageUrl!) { loadResult in
            DispatchQueue.main.async {
                self.handleLoad(loadResult: loadResult)
            }
        }
    }

    func handleLoad(loadResult: PhotoLoadResult) {
        updateActivityIndicatorStatus(isLoading: false)

        switch loadResult.result {
        case .success(let image):
            self.cellImageView.image = image
            self.cellImageView.contentMode = .scaleAspectFill
        case .failure:
            let image = UIImage(systemName: "exclamationmark.triangle.fill")
            self.cellImageView.image = image
            self.cellImageView.tintColor = .darkGray
            self.cellImageView.contentMode = .center
        }
    }
}
