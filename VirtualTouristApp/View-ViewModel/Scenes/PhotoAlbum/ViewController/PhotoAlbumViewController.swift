import UIKit
import Kingfisher
import CoreLocation

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var seeMoreButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var viewModel: PhotoAlbumViewModelProtocol!

    private let images: [UIImage] = Array(1...11).map { UIImage(named: String($0))! }
    private var page: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self
        collectionView.delegate = self
        viewModel.loadData()
        activityIndicator.isHidden = true
        collectionView.collectionViewLayout = createLayout()
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {

        let item = CompositionalLayout.createItem(
            width: .fractionalWidth(1),
            height: .fractionalHeight(1),
            spacing: 1)

        let group = CompositionalLayout.createGroup(
            aligment: .horizontal,
            width: .fractionalWidth(1),
            height: .absolute(200),
            item: item,
            count: 3)

        let section = NSCollectionLayoutSection(group: group)

        return UICollectionViewCompositionalLayout(section: section)
    }
    
    @IBAction func seeMoreButtonPressed(_ sender: UIButton) {
        collectionView.isScrollEnabled = false
        seeMoreButton.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        viewModel.loadMoreData()
    }

    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: collectionView.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "SF", size: 15)
        messageLabel.sizeToFit()
        collectionView.backgroundView = messageLabel
    }

    func checkIfIsEmpty() {
        if viewModel.imagesUrlString.isEmpty {
            setEmptyMessage("There is no photos in the location")
            seeMoreButton.isEnabled = false
        } else {
            seeMoreButton.isEnabled = true
            setEmptyMessage("")
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.imagesUrlString.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as? CollectionViewCell else {
            fatalError("Unexpected Index Path")
        }
        viewModel.updateImage(imageView: cell.cellImageView, imageUrl: viewModel.imagesUrlString[indexPath.row])
        return cell
    }
}

    //MARK: - UiCollectionViewDelegate

extension PhotoAlbumViewController: UICollectionViewDelegate {

}

    //MARK: - PhotoAlbumViewModelDelegate

extension PhotoAlbumViewController: PhotoAlbumViewModelDelegate {

    func didLoad() {
        let indexPath = IndexPath(item: viewModel.imagesUrlString.count - 15, section: 0)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.viewModel.isLoading {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.seeMoreButton.isHidden = false
                self.collectionView.isScrollEnabled = true
                self.collectionView.reloadData()
                self.checkIfIsEmpty()
                self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
        }
    }

    func didLoadWithError() {
        //
    }
}


    //MARK: - CollectionViewCell

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cellImageView: UIImageView!

}
