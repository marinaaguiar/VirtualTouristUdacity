import UIKit
import Kingfisher
import CoreLocation

class PhotoAlbumViewController: UIViewController {

    enum State {
        case loading
        case loaded
        case noImages
        case error
    }

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var toolBarActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var trashButton: UIButton!

    var viewModel: PhotoAlbumViewModelProtocol!

    var selectedPhotos: [String] = []
    var selectedPhotosIndex: [IndexPath] = []
    var selectedPhotosDic: [String: Int] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        navigationController?.isToolbarHidden = true
        updateActivityIndicator(loading: true)
        viewModel.refreshItems()
        viewModel.checkIfAlbumHasImages()
        updateToolBarButton(loading: false)
        trashButton.isHidden = true
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
    
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
        collectionView.isScrollEnabled = false
        updateToolBarButton(loading: true)
        viewModel.updateAlbumCollection()
    }

    @IBAction func trashButtonPressed(_ sender: Any) {
        let deleteAlert = buildDeleteAlert {
            self.viewModel.deleteSelectedImages(indexPath: self.collectionView.indexPathsForSelectedItems!)
            self.viewModel.refreshItems()
        }

        self.show(deleteAlert, sender: nil)
    }

    func buildDeleteAlert(onDelete: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "", message: "Are you sure you want to delete this photos permanently?", preferredStyle: .actionSheet
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak alert] _ in
            onDelete()
        }
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        return alert
    }



    func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()
        collectionView.allowsMultipleSelection = true
    }

    func setEmptyMessage(_ status: Bool) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: collectionView.bounds.size.height))
        if status == true {
            messageLabel.isHidden = false
            messageLabel.text = "There is no photos in the location"
            messageLabel.textColor = .black
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont(name: "SF", size: 15)
            messageLabel.sizeToFit()
            collectionView.backgroundView = messageLabel
        } else {
            messageLabel.isHidden = true
        }

    }

    func updateButtonsStatus() {
        if collectionView.indexPathsForSelectedItems != [] {
            newCollectionButton.isHidden = true
            trashButton.isHidden = false
        } else {
            newCollectionButton.isHidden = false
            trashButton.isHidden = true
        }
    }

    func updateActivityIndicator(loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }

    func updateToolBarButton(loading: Bool) {
        if loading {
            newCollectionButton.isHidden = true
            toolBarActivityIndicator.isHidden = false
            toolBarActivityIndicator.startAnimating()

        } else {
            toolBarActivityIndicator.stopAnimating()
            toolBarActivityIndicator.isHidden = true
            newCollectionButton.isHidden = false
            newCollectionButton.isEnabled = true 
        }
    }

    func cell(_ collectionView: UICollectionView, indexPath: IndexPath, photoCell: PhotoCell) -> UICollectionViewCell {

        let cell = collectionView.dequeCell(CollectionViewCell.self, indexPath)
        cell.fill(photoCell)
        return cell
    }
}

//MARK: - UICollectionViewDataSource

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cell(collectionView, indexPath: indexPath, photoCell: viewModel.fillCell(atIndexPath: indexPath.row))
    }
}

    //MARK: - UiCollectionViewDelegate

extension PhotoAlbumViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let selectedPhoto = viewModel.imagesUrlString[indexPath.item]
//        selectedPhotos.append(selectedPhoto)
        updateButtonsStatus()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        let selectedPhoto = viewModel.imagesUrlString[indexPath.item]
//        if selectedPhotos.contains(selectedPhoto) {
//            selectedPhotos = selectedPhotos.filter { !$0.contains(selectedPhoto) }
//        }
        updateButtonsStatus()
    }
}

    //MARK: - PhotoAlbumViewModelDelegate

extension PhotoAlbumViewController: PhotoAlbumViewModelDelegate {

    func didLoad() {
        let indexPath = IndexPath(item: viewModel.imagesUrlString.count - 15, section: 0)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.viewModel.isLoading {
                self.updateActivityIndicator(loading: false)
                self.updateToolBarButton(loading: false)
                self.collectionView.isScrollEnabled = true
                self.collectionView.reloadData()
                self.newCollectionButton.isEnabled = true
                self.setEmptyMessage(false)
//                self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
        }
    }

    func didLoadWithNoImages() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                self.updateActivityIndicator(loading: false)
                self.updateToolBarButton(loading: false)
                self.collectionView.isScrollEnabled = false
                self.collectionView.reloadData()
                self.setEmptyMessage(true)
            print("there is no image in this location")
        }
    }

    func didLoadWithError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)

        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
}



