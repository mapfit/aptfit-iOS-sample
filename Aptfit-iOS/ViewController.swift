//
//  ViewController.swift
//  Aptfit-iOS
//
//  Created by Zain N. on 4/16/18.
//  Copyright © 2018 Mapfit. All rights reserved.
//

import UIKit
import Mapfit
import CoreLocation


//Color used in demo application
enum AptfitColors: String {
    case black = "#000000"
    case transparentBlack = "#274A4A4A"
    case purple = "#8a94ff"
    case transparentPurple = "#404353FF"
    
}

//Default font
let aptfitFont = "HarmoniaSansStd-SemiBd"

class ViewController: UIViewController {

    var neighborhoodCollectionView: UICollectionView?
    var listingVerticalCollectionView: UICollectionView?
    
    var listingHorizontalCollectionView: UICollectionView?
    var listingDetailView: ListingDetailView = ListingDetailView()
    var scrollView: UIScrollView = UIScrollView()
    
    
    var layout = SnappingCollectionViewLayout()
    var toggleViewButton: UIButton?
    var mapViewIsEnabled: Bool = true
    var initialCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 40.741611201768606, longitude: -73.979310412348568)
    
    lazy var listings: [Listing] = [Listing]()
    lazy var currentlyShowingArea = String()
    lazy var currentlyShowingMakers = [MFTMarker]()
    lazy var markers: [Listing : MFTMarker] = [:]
    var selectedMarker: MFTMarker?
    
    
    lazy var neighborhoods: [String] = ["New York City", "Chelsea"]
    lazy var mapView: MFTMapView = MFTMapView()
    lazy var areaPolygons: [String : MFTPolygon] = [:]
    var currentAreaPolygon: MFTPolygon?
    var firstTap = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showNeighborhoods()
        setUpNavBar()
        setUpNeighborhoodCollectionView()
        setUpMap()
        setUpVerticalCollectionView()
        setUpFilterToggle()
        mapView.polygonSelectDelegate = self
        mapView.markerSelectDelegate = self
        mapView.doubleTapGestureDelegate = self
    }
    
    func setUpMap(){
    
        
        view.addSubview(mapView)
        view.sendSubview(toBack: mapView)
        mapView.mapOptions.setTheme(theme: .grayScale)
        if let path = Bundle.main.path(forResource: "mapfit-grayscale", ofType: "yaml")  {
            mapView.mapOptions.setCustomTheme("file:\\\(path)")
        }
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        mapView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        guard let neighborhoodCollectionView = self.neighborhoodCollectionView else { return }
        mapView.topAnchor.constraint(equalTo: neighborhoodCollectionView.bottomAnchor).isActive = true
        mapView.setZoom(zoomLevel: 12)
        mapView.setCenter(position: initialCenter)
        mapView.mapOptions.isTransitEnabled = true
        
        mapView.addBorders(edges: [.top], color: .darkGray, thickness: 0.5)
    }
    
    func setUpNavBar(){
        
        let AptfitButton = UIBarButtonItem(title: "Aptfit", style: .plain, target: self, action: #selector(leftBarItemTapped))
        let attrs = [
            NSAttributedStringKey.foregroundColor: UIColor.black,
            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)
        ]
        AptfitButton.setTitleTextAttributes(attrs, for: .normal)
        let image : UIImage? = UIImage.init(named: "github")!.withRenderingMode(.alwaysOriginal)
        
        let githubButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(rightBarItemTapped))
        self.navigationItem.leftBarButtonItem = AptfitButton
        self.navigationItem.rightBarButtonItem = githubButton
        
        let navAttrs = [
            NSAttributedStringKey.foregroundColor: UIColor.darkGray,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)
        ]
        self.navigationItem.title = "Sample Apartment Finder"
        self.navigationController?.navigationBar.titleTextAttributes = navAttrs
        
    }
    
    
    
    func setUpNeighborhoodCollectionView(){
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        self.neighborhoodCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        guard let neighborhoodCollectionView = self.neighborhoodCollectionView else { return }
        neighborhoodCollectionView.delegate = self
        neighborhoodCollectionView.dataSource = self
        neighborhoodCollectionView.register(NeighborhoodCollectionViewCell.self, forCellWithReuseIdentifier: "neighborhoodCell")
        view.addSubview(neighborhoodCollectionView)
        neighborhoodCollectionView.translatesAutoresizingMaskIntoConstraints = false
        neighborhoodCollectionView.heightAnchor.constraint(equalToConstant: 40.5).isActive = true
        neighborhoodCollectionView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        neighborhoodCollectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        neighborhoodCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        neighborhoodCollectionView.backgroundColor = UIColor.white
        
        
        //neighborhoodCollectionView.layer.borderWidth = 1
        //neighborhoodCollectionView.layer.borderColor = UIColor.darkGray.cgColor
        
        self.toggleViewButton = UIButton()
        guard let toggleViewButton = self.toggleViewButton else { return }
        view.addSubview(toggleViewButton)
        view.bringSubview(toFront: toggleViewButton)
        toggleViewButton.translatesAutoresizingMaskIntoConstraints = false
        //toggleViewButton.leadingAnchor.constraint(equalTo: neighborhoodCollectionView.trailingAnchor, constant: -10).isActive = true
        toggleViewButton.heightAnchor.constraint(equalTo: neighborhoodCollectionView.heightAnchor).isActive = true
        toggleViewButton.centerYAnchor.constraint(equalTo: neighborhoodCollectionView.centerYAnchor).isActive = true
        toggleViewButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        toggleViewButton.imageView?.contentMode = .scaleAspectFit
        toggleViewButton.setImage(#imageLiteral(resourceName: "listView"), for: .normal)
        toggleViewButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        
        
    }
    
    func setUpListingDetailView(){
        
        view.addSubview(listingDetailView)
        listingDetailView.translatesAutoresizingMaskIntoConstraints = false
        //listingDetailView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height)
        
        listingDetailView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        listingDetailView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        listingDetailView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        listingDetailView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        //listingDetailView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        //listingDetailView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
    }
    
    func setUpFilterToggle(){
       
    }
    
  @objc func filterButtonTapped(){
    guard let vCollectionView = self.listingVerticalCollectionView else { return }
    guard let hCollectionView = self.listingHorizontalCollectionView else { return }

    
    if mapViewIsEnabled {
        mapViewIsEnabled = false
        toggleViewButton?.setImage(#imageLiteral(resourceName: "mapView"), for: .normal)
        vCollectionView.reloadData()
        UIView.animate(withDuration: 0.2) {
            self.view.sendSubview(toBack: hCollectionView)
            self.view.sendSubview(toBack: self.mapView)
            
        }
    } else {
        listingHorizontalCollectionView?.reloadData()
        mapViewIsEnabled = true
        toggleViewButton?.setImage(#imageLiteral(resourceName: "listView"), for: .normal)
        UIView.animate(withDuration: 0.2) {
         self.view.sendSubview(toBack: vCollectionView)
        }
    }
    }
    
    func setUpVerticalCollectionView(){
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        listingVerticalCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        guard let collectionView = self.listingVerticalCollectionView else { return }
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(ListingCollectionViewCell.self, forCellWithReuseIdentifier: "VerticalListingCell")
        view.addSubview(collectionView)
        view.sendSubview(toBack: collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        collectionView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1.05).isActive = true
        guard let neighborhoodCollectionView = self.neighborhoodCollectionView else { return }
        collectionView.topAnchor.constraint(equalTo: neighborhoodCollectionView.bottomAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        //collectionView.addBorders(edges: [.top], color: .darkGray, thickness: 1)
        collectionView.layer.borderWidth = 0.5
        collectionView.layer.borderColor = UIColor.darkGray.cgColor
        collectionView.backgroundColor = UIColor.white
        
    }
    
    func setUpHorizontalCollectionView(){
        self.layout.scrollDirection = .horizontal
        listingHorizontalCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        guard let collectionView = self.listingHorizontalCollectionView else { return }
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ListingCollectionViewCell.self, forCellWithReuseIdentifier: "VerticalListingCell")
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5).isActive = true
        collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        collectionView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        collectionView.decelerationRate = 2
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        //collectionView.isPagingEnabled = true
        
        
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.showsHorizontalScrollIndicator = false
    }
    
   @objc func leftBarItemTapped(){

    }
    
    
   @objc func rightBarItemTapped(){
    if let url = URL(string: "https://github.com/mapfit/Aptfit-iOS"){
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
   
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == neighborhoodCollectionView {
             return neighborhoods.count
        }else{
            return listings.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == neighborhoodCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "neighborhoodCell",
                                                          for: indexPath) as! NeighborhoodCollectionViewCell
            cell.neighborhood.text = neighborhoods[indexPath.row]
            cell.setUpCell()
            return cell
        }else {//if collectionView == listingVerticalCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VerticalListingCell",
                                                          for: indexPath) as! ListingCollectionViewCell
            
            
            if collectionView == listingVerticalCollectionView {
                cell.setUpCellVericalScrollingCell(listing: listings[indexPath.row])
            }else if collectionView == listingHorizontalCollectionView {
                cell.setUpCellHorizontalScrollingCell(listing: listings[indexPath.row])
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == neighborhoodCollectionView {
            return CGSize(width: self.view.frame.width * 0.2, height: 50)
        }else if collectionView == listingVerticalCollectionView {
            return CGSize(width: self.view.frame.width * 0.9, height: 280)
        }else {
            return CGSize(width: 350, height: 200)
        }
    }
//
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

        
        return UIEdgeInsetsMake(0, 18, 0, 18)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == listingHorizontalCollectionView || collectionView == listingVerticalCollectionView{
            self.setUpListingDetailView()
            listingDetailView.setUpView(listing: listings[indexPath.row])
        }
    }

 
}

extension ViewController {
    func showNeighborhoods(){
        if let path = Bundle.main.path(forResource: "wof_nyc", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                let locationJson = try! decoder.decode(LocationJson.self, from: data)
                
                for feature in locationJson.features {
                    var polygon = [CLLocationCoordinate2D]()
                    
                    for coordinate in feature.geometry.coordinates[0][0]{
                        polygon.append(getCoordinateFromDouble(coordinate))
                    }
                    let areaPolygon = mapView.addPolygon([polygon])
                    guard let neighborhood = feature.properties["name"] else { return }
                    areaPolygons[neighborhood] = areaPolygon
                    
                    areaPolygon?.polygonOptions?.strokeColor = "#8a94ff"
                    areaPolygon?.polygonOptions?.fillColor = "#404353FF"
                    areaPolygon?.polygonOptions?.strokeWidth = 3
                }
            } catch {
                // handle error
            }
        }
    }
    
    func getCoordinateFromDouble(_ double: [Double]) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: double[1], longitude: double[0])
    }
    
   
    func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.white
        let textFont = UIFont(name: aptfitFont, size: 10)!
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .center
        
        let textFontAttributes = [
            NSAttributedStringKey.font: textFont,
            NSAttributedStringKey.foregroundColor: textColor,
            NSAttributedStringKey.paragraphStyle: titleParagraphStyle,
            NSAttributedStringKey.kern : 0.5
            
            ] as [NSAttributedStringKey : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
}


extension ViewController : MapDoubleTapGestureDelegate {
    func mapView(_ view: MFTMapView, recognizer: UIGestureRecognizer, shouldRecognizeDoubleTapGesture location: CGPoint) -> Bool {
        return false
    }
    
    func mapView(_ view: MFTMapView, recognizer: UIGestureRecognizer, didRecognizeDoubleTapGesture location: CGPoint) {
        print("Double Tap Disabled")
    }
    
    
}

extension ViewController: MapMarkerSelectDelegate {
    func mapView(_ view: MFTMapView, didSelectMarker marker: MFTMarker, atScreenPosition position: CGPoint) {
        
        DispatchQueue.main.async {
            if let oldMarker = self.selectedMarker {
                if let listing = self.markers.someKey(forValue: oldMarker){
                    let backToBlack = self.textToImage(drawText: listing.price, inImage: #imageLiteral(resourceName: "customBlackMarker"), atPoint: CGPoint(x: 0, y: 3))
                    oldMarker.setIcon(backToBlack)
                }

                oldMarker.getBuildingPolygon()?.polygonOptions?.strokeColor = AptfitColors.black.rawValue
                oldMarker.getBuildingPolygon()?.polygonOptions?.fillColor = AptfitColors.transparentBlack.rawValue
            }
      
            
            if let newMarker = self.markers.someKey(forValue: marker) {
                let image = self.textToImage(drawText: newMarker.price, inImage: #imageLiteral(resourceName: "customBlueMarker"), atPoint: CGPoint(x: 0, y: 3))
                marker.setIcon(image)
            
                let row = self.listings.index(of: newMarker) as! Int
                self.listingHorizontalCollectionView?.scrollToItem(at: IndexPath(row: row, section: 0), at: .centeredHorizontally, animated: true)
                
                
            }

            marker.getBuildingPolygon()?.polygonOptions?.strokeColor = AptfitColors.purple.rawValue
            marker.getBuildingPolygon()?.polygonOptions?.fillColor = AptfitColors.transparentPurple.rawValue
            let center = self.computeOffsetToPoint(from: marker.getPosition(), distance: -10, heading: 0)
            self.mapView.setZoom(zoomLevel: 18, duration: 0.4)
            self.mapView.setCenter(position: center, duration: 0.4)
            self.mapView.setRotation(rotationValue: 0, duration: 0.4)
            
            self.selectedMarker = marker
        }
    }
}



extension Dictionary where Value: Equatable {
    func someKey(forValue val: Value) -> Key? {
        return first(where: { $1 == val })?.key
    }
}


extension ViewController {
    
    func removeHighlightFromCells(){
        guard let collectionView = self.listingHorizontalCollectionView else { return }
        
        for case let cell as ListingCollectionViewCell in collectionView.visibleCells {
            cell.removeHighlight()
            
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

    }
    
    
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        //self.removeHighlightFromCells()
        self.scrollAndHighlight(scrollView)
    }
    
    
    @objc func snapToCell(){
        guard let collectionView = self.listingVerticalCollectionView else { return }
        
        let center = self.view.convert(collectionView.center, to: collectionView)
        
        if let index = collectionView.indexPathForItem(at: center) {
            collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
    }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.removeHighlightFromCells()
        self.scrollAndHighlight(scrollView)
    }
    
    
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.removeHighlightFromCells()
        self.scrollAndHighlight(scrollView)
 
    }
    
    func scrollAndHighlight(_ scrollView: UIScrollView){
        
        if scrollView.panGestureRecognizer.velocity(in: view).x > 300 {
            guard let collectionView = self.listingHorizontalCollectionView else { return }
            
            let center = self.view.convert(collectionView.center, to: collectionView)
            
            if var index = collectionView.indexPathForItem(at: center) {
                
                if index.row != 0 {
                    index.row -= 1
                }
                
                collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
                if let marker = markers[listings[index.row]] {
                    let cell = collectionView.cellForItem(at: index) as? ListingCollectionViewCell
                    cell?.hightlight()
                    mapView(self.mapView, didSelectMarker: marker, atScreenPosition: collectionView.center)
                }
                
            }else {
                if let marker = markers[listings[collectionView.indexPathsForVisibleItems[0].row]] {
                    let cell = collectionView.cellForItem(at: collectionView.indexPathsForVisibleItems[0]) as? ListingCollectionViewCell
                    cell?.hightlight()
                    mapView(self.mapView, didSelectMarker: marker, atScreenPosition: collectionView.center)
                }
            }
        }else if scrollView.panGestureRecognizer.velocity(in: view).x < -100 {
            
            guard let collectionView = self.listingHorizontalCollectionView else { return }
            
            let center = self.view.convert(collectionView.center, to: collectionView)
            
            if var index = collectionView.indexPathForItem(at: center) {
                if index.row != listings.count - 1 {
                    index.row += 1
                }
                collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
                
                if let marker = markers[listings[index.row]] {
                    let cell = collectionView.cellForItem(at: index) as? ListingCollectionViewCell
                    cell?.hightlight()
                    mapView(self.mapView, didSelectMarker: marker, atScreenPosition: collectionView.center)
                }
                
            }else {
                if let marker = markers[listings[collectionView.indexPathsForVisibleItems[0].row]] {
                    let cell = collectionView.cellForItem(at: collectionView.indexPathsForVisibleItems[0]) as? ListingCollectionViewCell
                    cell?.hightlight()
                    mapView(self.mapView, didSelectMarker: marker, atScreenPosition: collectionView.center)
                }
            }
            
        }
    
    }
    
    func zoomAndCenter(zoom: Float, coordinate: CLLocationCoordinate2D, duration: Float){
        let queue: OperationQueue = OperationQueue()
        queue.maxConcurrentOperationCount = (2)
        queue.addOperation({self.mapView.setCenter(position: coordinate, duration: duration)})
        queue.addOperation({self.mapView.setZoom(zoomLevel: zoom, duration: duration)})
    }

}


extension ViewController {
    
    func inwood() -> [Listing] {
        return [
            Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$2,400", address: "639 W 204th St, New York, NY 10034", neighborhood: "Inwood, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 350, availableDate: "July 14th, 2018"),
            Listing(name: "apt2", imageUrl:  "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$3,200", address: "124 Fulton St, New York, NY 10038", neighborhood: "Inwood, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018"),
            Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$5,300", address: "112 Sherman Ave, New York, NY 10034", neighborhood: "Inwood, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018"),
            Listing(name: "apt4", imageUrl: "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$5,300", address: "585 W 214th St, New York, NY 10034", neighborhood: "Inwood, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018")
        ]
    }

    
    
    
    
    func financialDistrict() -> [Listing] {
        return [
            Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$2,400", address: "65 Broadway, New York, NY 10006", neighborhood: "Financial District, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 350, availableDate: "July 14th, 2018"),
            Listing(name: "apt2", imageUrl:  "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$3,200", address: "124 Fulton St, New York, NY 10038", neighborhood: "Financial District, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018"),
            Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$5,300", address: "48 Wall St, New York, NY 10005", neighborhood: "Financial District, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018"),
            Listing(name: "apt4", imageUrl: "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$5,300", address: "16 Beaver St, New York, NY 10004", neighborhood: "Financial District, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018")
        ]
    }
    
    func greenwichVillage() -> [Listing] {
        return [
            Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$2,400", address: "23 E 9th St, New York, NY 10003", neighborhood: "Greenwich Village, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 350, availableDate: "July 14th, 2018"),
            Listing(name: "apt2", imageUrl:  "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$3,200", address: "566 LaGuardia Pl, New York, NY 10012", neighborhood: "Greenwich Village, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018"),
        ]
    }
    
    func batteryParkCity() -> [Listing] {
        return [
            Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$2,400", address: "98 Battery Pl New York, NY 10280",
                       neighborhood: "Battery Park City, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 350, availableDate: "July 14th, 2018"),
            Listing(name: "apt2", imageUrl:  "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$3,200", address: "380 Rector Pl, New York, NY 10280", neighborhood: "Battery Park City, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018"),
            Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$5,300", address: "211 North End Ave, New York, NY 10282", neighborhood: "Battery Park City, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018"),
        ]
    }
    
    func littleItaly() -> [Listing] {
        return [
            Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$2,400", address: "199 Hester St, New York, NY 10013",
                       neighborhood: "Little Italy, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 350, availableDate: "July 14th, 2018"),
            Listing(name: "apt2", imageUrl:  "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$3,200", address: "197 Grand St, New York, NY 10013", neighborhood: "Little Italy, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018"),
            Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1494526585095-c41746248156?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=fd170b4cebb0b97e6337529754defcf7&auto=format&fit=crop&w=1024&q=80", price: "$5,300", address: "225 Canal St New York, NY 10013", neighborhood: "Little Italy, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 900, availableDate: "June 16th, 2018"),
        ]
    }
    
    func chelsea() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "312 W 23rd St, New York, NY 10011", neighborhood: "Chelsea, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "626 W 28th St New York, NY 10001", neighborhood: "Chelsea, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "170 8th Ave, New York, NY 10011", neighborhood: "Chelsea, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
        ]
    }
    
    func eastVillage() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "222A E 11th St New York, NY 10003", neighborhood: "East Village, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "309 E 5th St, New York, NY 10003", neighborhood: "East Village, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "709 E 6th St, New York, NY 10009", neighborhood: "East Village, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
        ]
    }
    
    
    
    func tribeca() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "60 Vestry St, New York, NY 10013", neighborhood: "Tribeca, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "110 Chambers St, New York, NY 10007", neighborhood: "Tribeca, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1900", address: "65 Worth St, New York, NY 10013", neighborhood: "Tribeca, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 550, availableDate: "June 11th, 2018"),
        ]
    }
    
    func chinaTown() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "110 Centre St, New York, NY 10013", neighborhood: "Chinatown, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "25 Allen St, New York, NY 10002", neighborhood: "Chinatown, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018")
        ]
    }
    
    func murrayHill() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "593 3rd Ave, New York, NY 10016", neighborhood: "Murray Hill, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "248 E 35th St, New York, NY 10016", neighborhood: "Murray Hill, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "139 E 36th St, New York, NY 10016", neighborhood: "Murray Hill, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
        ]
    }
    

    func stuyesantTown() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "285 Avenue C Loop New York, NY 10009", neighborhood: "Stuyvesant Town, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "510 E 20th St, New York, NY 10009", neighborhood: "Stuyvesant Town, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                  Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "451 E 14th St, New York, NY 10009", neighborhood: "Stuyvesant Town, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
        ]
    }
    
    
    func washingtonHeights() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "720 W 173rd St New York, NY 10032", neighborhood: "Washington Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "521 W 157th St New York, NY 10032", neighborhood: "Washington Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "643 W 172nd St New York, NY 10032", neighborhood: "Washington Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                   Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "120 Cabrini Blvd New York, NY 10032", neighborhood: "Washington Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                   Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "615 W 184th St New York, NY 10032", neighborhood: "Washington Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
        ]
    }
    
    func hamiltonHeights() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "610 W 145th St, New York, NY 10031", neighborhood: "Hamilton Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "618 W 143rd St, New York, NY 10031", neighborhood: "Hamilton Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "501 W 138th St, New York, NY 10031", neighborhood: "Hamilton Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
        ]
    }
    
    
    
    func centralHarlem() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "2538 Adam Clayton Powell Jr Blvd, New York, NY 10039", neighborhood: "Central Harlem, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "300 W 135th St, New York, NY 10027", neighborhood: "Central Harlem, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "8 Mt Morris Park W, New York, NY 10027", neighborhood: "Central Harlem, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
        ]
    }
    
    func soho() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "34 Macdougal St, New York, NY 10012", neighborhood: "Soho, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "55 Vandam St, New York, NY 10013", neighborhood: "Soho, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "463 Broome St New York, NY 10013", neighborhood: "Soho, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
        ]
    }
    
    func spanishHarlem() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "102 E 125th St, New York, NY 10035", neighborhood: "Spanish Harlem, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "315 103rd St, New York, NY 10029", neighborhood: "Spanish Harlem, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "168 E 104th St New York, NY 10029", neighborhood: "Spanish Harlem, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
                  Listing(name: "apt4", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "351 E 119th St New York, NY 10035", neighborhood: "Spanish Harlem, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
        ]
    }
    
    func morningsideHeights() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "3133 Broadway, New York, NY 10027", neighborhood: "Morningside Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "536 W 113th St, New York, NY 10025", neighborhood: "Morningside Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "380 Riverside Dr New York, NY 10025", neighborhood: "Morningside Heights, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018")
        ]
    }
    
    func hellsKitchen() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "519 W 36th St, New York, NY 10018", neighborhood: "Hell's Kitchen, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "365 W 36th St, New York, NY 10018", neighborhood: "Hell's Kitchen, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "353 W 39th St, New York, NY 10025", neighborhood: "Hell's Kitchen, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018")
        ]
    }
    
    func flatironDistrict() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "44 W 24th St, New York, NY 10010", neighborhood: "Flatiron District, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "21 E 22nd St, New York, NY 10010", neighborhood: "Flatiron District, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "48 W 21st St, New York, NY 10010", neighborhood: "Flatiron District, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018")
        ]
    }
    
    func midtownWest() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "532 W 43rd St, New York, NY 10036", neighborhood: "Midtown West, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "428 W 44th St, New York, NY 10036", neighborhood: "Midtown West, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "353 W 48th St, New York, NY 10036", neighborhood: "Midtown West, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
               Listing(name: "apt4", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "1023 6th Ave, New York, NY 10018", neighborhood: "Midtown West, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
               Listing(name: "apt5", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "145 W 46th St, New York, NY 10036", neighborhood: "Midtown West, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018")
        ]
    }
    
    func midtownEast() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "111 E 56th St, New York, NY 10022", neighborhood: "Midtown East, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "253 E 50th St, New York, NY 10022", neighborhood: "Midtown East, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1900", address: "120 E 47th St, New York, NY 10017", neighborhood: "Midtown East, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 550, availableDate: "June 11th, 2018"),
        ]
    }
    
    func lowerEastside() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "74-100 Ridge St, New York, NY 10002", neighborhood: "Lower East Side, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "67-1 Norfolk St, New York, NY 10002", neighborhood: "Lower East Side, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1900", address: "350 Grand St, New York, NY 10002", neighborhood: "Lower East Side, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 550, availableDate: "June 11th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1900", address: "219-229 Clinton St, New York, NY 10002", neighborhood: "Lower East Side, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 550, availableDate: "June 11th, 2018")
        ]
    }
    
    func gramercy() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "179 3rd Ave, New York, NY 10003", neighborhood: "Gramercy, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "152 E 21st St, New York, NY 10010", neighborhood: "Gramercy, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018")
        ]
    }
    
    func upperWestSide() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "215 W 106th St, New York, NY 10025", neighborhood: "Noho, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "328 W 86th St New York, NY 10024", neighborhood: "Upper West Side, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "835 Columbus Ave, New York, NY 10025", neighborhood: "Upper West Side, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "261 W 70th St, New York, NY 10023", neighborhood: "Upper West Side, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "216 W 62nd St, New York, NY 10023", neighborhood: "Upper West Side, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
                  Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "433 W 66th St, New York, NY 10069", neighborhood: "Upper West Side, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
        ]
    }
    
    func westVillage() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "173 Christopher St, New York, NY 10014", neighborhood: "West Village, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "55 Bethune St, New York, NY 10014", neighborhood: "West Village, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "220 W 13th St, New York, NY 10012", neighborhood: "West Village, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
        ]
    }

    func noho() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "430 Lafayette St, New York, NY 10003", neighborhood: "Noho, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "9 Great Jones St, New York, NY 10003", neighborhood: "Noho, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "7 Bleecker St, New York, NY 10012", neighborhood: "Noho, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 750, availableDate: "June 11th, 2018"),
        ]
    }
    
    func twoBridges() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "34 Monroe St, New York, NY 10002", neighborhood: "Two Bridges, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "51 Monroe St, New York, NY 10002", neighborhood: "Two Bridges, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1900", address: "89 Catherine St, New York, NY 10038", neighborhood: "Two Bridges, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 550, availableDate: "June 11th, 2018"),
        ]
    }
    
    func nolita() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "31 Prince St\n" +
            "New York, NY 10012", neighborhood: "Nolita, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "85 Kenmare St, New York, NY 10012", neighborhood: "Nolita, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1900", address: "6 Spring St, New York, NY 10012", neighborhood: "Nolita, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 550, availableDate: "June 11th, 2018"),
        ]
    }
    
    func kipsBay() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "229 E 29th St\n" +
            "New York, NY 10016", neighborhood: "Kips Bay, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "238 E 24th St, New York, NY 10010", neighborhood: "Kips Bay, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1900", address: "522 1st Avenue\n" +
                    "New York, NY 10016", neighborhood: "Kips Bay, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 550, availableDate: "June 11th, 2018"),
        ]
    }
    
    func upperEastSide() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "121 E 81st St\n" +
            "New York, NY 10028\n", neighborhood: "Upper East Side, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "179 E 94th St\n" +
                    "New York, NY 10128", neighborhood: "Upper East Side, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt3", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1900", address: "47 E 90th St\n" +
                    "New York, NY 10128", neighborhood: "Upper East Side, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 550, availableDate: "June 11th, 2018"),
                 Listing(name: "apt4", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "307 E 87th St\n" +
                    "New York, NY 10128", neighborhood: "Upper East Side, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt5", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "9 E 77th St, New York, NY 10075", neighborhood: "Nolita, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt6", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1900", address: "405 E 72nd St\n" +
                    "New York, NY 10021\n", neighborhood: "Upper East Side, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 550, availableDate: "June 11th, 2018"),
                 Listing(name: "apt6", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1900", address: "167 E 64th St\n" +
                    "New York, NY 10065\n", neighborhood: "Upper East Side, Manhattan", bedroomCount: 2, bathroomCount: 1, area: 550, availableDate: "June 11th, 2018"),
        ]
    }
    
    func rooseveltIsland() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "625 Main St, New York, NY 10044", neighborhood: "Roosevelt Island, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "501 Main St, New York, NY 10044", neighborhood: "Roosevelt Island, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "30 River Rd, New York, NY 10044", neighborhood: "Roosevelt Island, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
              
        ]
    }
    
    func cityHallArea() -> [Listing] {
        return [ Listing(name: "apt1", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$3400", address: "49 Chambers St\n" +
            "New York, NY 10007", neighborhood: "City Hall Area, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 13th, 2018"),
                 Listing(name: "apt2", imageUrl: "https://images.unsplash.com/photo-1505873242700-f289a29e1e0f?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=91b874ce453385d8867cc98ee582fee3&auto=format&fit=crop&w=1024&q=80", price: "$1500", address: "141 Worth St, New York, NY 10013", neighborhood: "City Hall Area, Manhattan", bedroomCount: 3, bathroomCount: 2, area: 350, availableDate: "June 16th, 2018"),
                 
        ]
    }
    
}


extension ViewController {
    func computeOffsetToPoint(from: CLLocationCoordinate2D, distance: Double, heading: Double) -> CLLocationCoordinate2D {
    let dist = distance / 6371009
    let radHeading = heading.degreesToRadians
    // http://williams.best.vwh.net/avform.htm#LL
    let fromLat = from.latitude.degreesToRadians
    let fromLng = from.longitude.degreesToRadians
    let cosDistance = cos(dist)
    let sinDistance = sin(dist)
    let sinFromLat = sin(fromLat)
    let cosFromLat = cos(fromLat)
    let sinLat = cosDistance * sinFromLat + sinDistance * cosFromLat * cos(radHeading)
    let dLng = atan2(sinDistance * cosFromLat * sin(radHeading), cosDistance - sinFromLat * sinLat)
    
    return CLLocationCoordinate2D(latitude: asin(sinLat).radiansToDegrees, longitude: (fromLng + dLng).radiansToDegrees)
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}



    
    extension UIView {
        
        @discardableResult func addBorders(edges: UIRectEdge, color: UIColor = .darkGray, thickness: CGFloat = 5.0) -> [UIView] {
            
            var borders = [UIView]()
            
            func border() -> UIView {
                let border = UIView(frame: CGRect.zero)
                border.backgroundColor = color
                border.translatesAutoresizingMaskIntoConstraints = false
                return border
            }
            
            if edges.contains(.top) || edges.contains(.all) {
                let top = border()
                addSubview(top)
                addConstraints(
                    NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[top(==thickness)]",
                                                   options: [],
                                                   metrics: ["thickness": thickness],
                                                   views: ["top": top]))
                addConstraints(
                    NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[top]-(0)-|",
                                                   options: [],
                                                   metrics: nil,
                                                   views: ["top": top]))
                borders.append(top)
            }
            
            if edges.contains(.left) || edges.contains(.all) {
                let left = border()
                addSubview(left)
                addConstraints(
                    NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[left(==thickness)]",
                                                   options: [],
                                                   metrics: ["thickness": thickness],
                                                   views: ["left": left]))
                addConstraints(
                    NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[left]-(0)-|",
                                                   options: [],
                                                   metrics: nil,
                                                   views: ["left": left]))
                borders.append(left)
            }
            
            if edges.contains(.right) || edges.contains(.all) {
                let right = border()
                addSubview(right)
                addConstraints(
                    NSLayoutConstraint.constraints(withVisualFormat: "H:[right(==thickness)]-(0)-|",
                                                   options: [],
                                                   metrics: ["thickness": thickness],
                                                   views: ["right": right]))
                addConstraints(
                    NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[right]-(0)-|",
                                                   options: [],
                                                   metrics: nil,
                                                   views: ["right": right]))
                borders.append(right)
            }
            
            if edges.contains(.bottom) || edges.contains(.all) {
                let bottom = border()
                addSubview(bottom)
                addConstraints(
                    NSLayoutConstraint.constraints(withVisualFormat: "V:[bottom(==thickness)]-(0)-|",
                                                   options: [],
                                                   metrics: ["thickness": thickness],
                                                   views: ["bottom": bottom]))
                addConstraints(
                    NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[bottom]-(0)-|",
                                                   options: [],
                                                   metrics: nil,
                                                   views: ["bottom": bottom]))
                borders.append(bottom)
            }
            
            return borders
        }
        
}

extension UICollectionView {
    
    var centerPoint : CGPoint {
        
        get {
            return CGPoint(x: self.center.x + self.contentOffset.x, y: self.center.y + self.contentOffset.y);
        }
    }
    
    var centerCellIndexPath: IndexPath? {
        
        if let centerIndexPath: IndexPath  = self.indexPathForItem(at: self.centerPoint) {
            return centerIndexPath
        }
        return nil
    }
}

extension ViewController: MapPolygonSelectDelegate {
    
    func mapView(_ view: MFTMapView, didSelectPolygon polygon: MFTPolygon, atScreenPosition position: CGPoint) {
        //change color not working
        self.mapView.setZoom(zoomLevel: 13, duration: 0.5)
        
        if firstTap {
            setUpHorizontalCollectionView()
            if let key = areaPolygons.someKey(forValue: polygon) {
                currentlyShowingArea = key
            }
            firstTap = false
        }
        
        if currentlyShowingArea == areaPolygons.someKey(forValue: polygon) && firstTap {
            return
        }
        
        DispatchQueue.main.async(execute: {
            self.currentAreaPolygon?.polygonOptions?.strokeColor = "#8a94ff"
            self.currentAreaPolygon?.polygonOptions?.fillColor = "#404353FF"
            self.currentAreaPolygon = polygon
        })
        
        
        
        for marker in self.currentlyShowingMakers {
            mapView.removeMarker(marker)
            
        }
        
        currentlyShowingMakers = []
        
        guard let key = areaPolygons.someKey(forValue: polygon) else { return }
        currentlyShowingArea = key
        
        var builder = MFTLatLngBounds.Builder()
        for location in areaPolygons[currentlyShowingArea]!.points[0] {
            builder.add(latLng: location)
        }
        let bounds = builder.build()
        
        let offsetCenter = computeOffsetToPoint(from: bounds.center, distance: -1000, heading: 0)
        mapView.setCenter(position: offsetCenter, duration: 0.4)
        
        
        neighborhoods[1] = key
        neighborhoodCollectionView?.reloadData()
        
        var listingsToShow = [Listing]()
        
        switch key {
        case "Financial District":
            listingsToShow = financialDistrict()
        case "Greenwich Village":
            listingsToShow = greenwichVillage()
        case "Battery Park City District":
            listingsToShow = batteryParkCity()
        case "Little Italy":
            listingsToShow = littleItaly()
        case "Chelsea":
            listingsToShow = chelsea()
        case "East Village":
            listingsToShow = eastVillage()
        case "Tribeca":
            listingsToShow = tribeca()
        case "Chinatown":
            listingsToShow = chinaTown()
        case "Murray Hill":
            listingsToShow = murrayHill()
        case "Stuyvesant Town":
            listingsToShow = stuyesantTown()
        case "Washington Heights":
            listingsToShow = washingtonHeights()
        case "Hamilton Heights":
            listingsToShow = hamiltonHeights()
        case "Central Harlem":
            listingsToShow = centralHarlem()
        case "SoHo":
            listingsToShow = soho()
        case "Spanish Harlem":
            listingsToShow = spanishHarlem()
        case "Morningside Heights":
            listingsToShow = morningsideHeights()
        case "Hell's Kitchen":
            listingsToShow = hellsKitchen()
        case "Midtown West":
            listingsToShow = midtownWest()
        case "Midtown East":
            listingsToShow = midtownEast()
        case "Lower East Side":
            listingsToShow = lowerEastside()
        case "Gramercy":
            listingsToShow = gramercy()
        case "West Side":
            listingsToShow = upperWestSide()
        case "West Village":
            listingsToShow = westVillage()
        case "NoHo":
            listingsToShow = noho()
        case "Two Bridges":
            listingsToShow = twoBridges()
        case "Nolita":
            listingsToShow = nolita()
        case "Kips Bay":
            listingsToShow = kipsBay()
        case "Upper East Side":
            listingsToShow = upperEastSide()
        case "City Hall Area":
            listingsToShow = cityHallArea()
        case "Roosevelt Island":
            listingsToShow = rooseveltIsland()
        case "Flatiron District":
            listingsToShow = flatironDistrict()
        case "Inwood":
            listingsToShow = inwood()
        default:
            print("polygon not found")
        }
        
        listings = listingsToShow
        listingHorizontalCollectionView?.reloadData()
        
        
        for listing in listingsToShow {
            
            self.mapView.addMarker(address: listing.address) { (marker, error) in
                let image = self.textToImage(drawText: listing.price, inImage: #imageLiteral(resourceName: "customBlackMarker"), atPoint: CGPoint(x: 0, y: 5))
                marker?.setIcon(image)
                marker?.markerOptions?.anchorPosition = .center
                
                marker?.markerOptions?.setWidth(width: 67)
                marker?.markerOptions?.setHeight(height: 40)
                if let marker = marker { self.currentlyShowingMakers.append(marker)}
                
                guard let options = marker?.getBuildingPolygon()?.polygonOptions else { return }
                options.strokeColor = "#000000"
                options.fillColor = "#274A4A4A"
                polygon.polygonOptions?.drawOrder = 900
                polygon.polygonOptions?.strokeColor = "#000000"
                polygon.polygonOptions?.fillColor = "#274A4A4A"
                self.markers[listing] = marker
            }
        }
    }
}




