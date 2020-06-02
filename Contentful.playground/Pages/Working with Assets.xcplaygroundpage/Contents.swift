//: [Previous](@previous)
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
import Contentful
import AppKit

//: In order to execute this playground, please build the "Contentful_macOS" scheme to build the SDK.
//: We again create an instance of `Client` connected to the space of interest.
let client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1")
//: Assets represent any kind of media you are storing in Contentful. The API is similar to fetching entries.
client.fetchAssets { (result: Result<ArrayResponse<Asset>, Error>) in
    switch result {
    case .success(let assets):
        guard let assetTitle = assets.items.first?.fields["title"] as? String else { return }
        print("The first asset in the response has a 'title' of '\(assetTitle)'")

    case .failure:
        break
    }
}
//: Also similar to entries, assets can be queried using IDs or search parameters.
client.fetchAsset(id: "nyancat") { (result: Result<Asset, Error>) in
    switch result {
    case .success(let asset):
        // ...
    case .failure:
        // ...
    }
//: Fetching the underlying binary data of an asset is simple.
    client.fetchData(for: asset).then { data in
        let base64EncodedString = data.base64EncodedString()
        let substring = base64EncodedString.substring(to: base64EncodedString.index(base64EncodedString.startIndex, offsetBy: 8))
        print("The first 8 characters of the base64EncodedString for the data are '" + substring + "'")
    }
//: Since many assets will be images, there is a short-hand API for them.
//: On iOS, tvOS, and watchOS the resulting value will be a `UIImage` on success.
    client.fetchImage(for: asset).then { (image: NSImage) in
        let imageView = NSImageView(frame: CGRect(x: 0, y: 0, width: 600, height: 600))
        imageView.image = image
        DispatchQueue.main.async {
//: Open the playground 'Timeline' in the assistant editor to view the image file for 'nyancat'
            PlaygroundPage.current.liveView = imageView
        }

    }
}
//: [Next](@next)
