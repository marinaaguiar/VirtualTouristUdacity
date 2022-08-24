import UIKit

extension UICollectionView {

    func dequeCell<T: UICollectionViewCell>(_ : T.Type, _ indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: String(describing: T.self), for: indexPath) as? T else {
            return T()
        }
        return cell
    }
}
