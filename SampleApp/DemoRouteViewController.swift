//
//  DemoRouteViewController.swift
//  ios-sdk
//
//  Created by Matt Smollinger on 4/10/17.
//  Copyright © 2017 Mapzen. All rights reserved.
//

import OnTheRoad
import Mapzen_ios_sdk

class DemoRouteViewController: SampleMapViewController, MapSingleTapGestureDelegate {
  let routeListSegueId = "routeListSegueId"
  var currentRouteResult: OTRRoutingResult?
  var lastRoutingPoint: OTRGeoPoint?
  var costingModel: OTRRoutingCostingModel = .auto

  private var routingLocale = Locale.current {
    didSet {
      if let point = lastRoutingPoint {
        requestRoute(toPoint: point)
      }
    }
  }
  private var destination : OTRGeoPoint?

  //MARK:- ViewController life cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    try? loadStyleSheetAsync(appDelegate.selectedMapStyle) { [unowned self] (style) in
      self.singleTapGestureDelegate = self
      self.sceneDidLoad = true
      _ = self.showCurrentLocation(true)
      self.showFindMeButon(true)
      if self.firstTimeZoomToCurrentLocation { self.shouldZoomToCurrentLocation() }
    }
    setupSwitchLocaleBtn()
    setupStyleNotification()
    setupSwitchRoutingButton()
    let alert = UIAlertController(title: "Tap to Route", message: "Tap anywhere on the map to route!", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Ok!", style: UIAlertActionStyle.default, handler: nil))
    present(alert, animated: true, completion: nil)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard let identifier = segue.identifier else {
      return
    }
    switch identifier {
    case routeListSegueId:
      guard let routeResult = currentRouteResult else { return }
      if let vc = segue.destination as? DemoRoutingResultTableVC {
        vc.routingResult = routeResult
      }
    default:
      break
    }
  }

  //MARK:- Private

  private func setupSwitchRoutingButton() {
    let button = UIBarButtonItem.init(title: "Route Type", style: .plain, target: self, action: #selector(changeRouterCostingModel))
    navigationItem.leftBarButtonItem = button
  }

  @objc private func changeRouterCostingModel() {
    let costingModels:[String : OTRRoutingCostingModel] = [
      "Auto" : .auto,
      "Shorter Distance Auto" : .autoShorter,
      "Bicycle" : .bicycle,
      "Bus" : .bus,
      "Multimodal" : .multimodal,
      "Walking" : .pedestrian
    ]

    let actionSheet = UIAlertController.init(title: "Route Type", message: "Choose a route type", preferredStyle: .actionSheet)
    for (actionTitle, costModel) in costingModels {
      actionSheet.addAction(UIAlertAction.init(title: actionTitle, style: .default, handler: { [unowned self] (action) in
        self.costingModel = costModel
        if let point = self.lastRoutingPoint {
          self.requestRoute(toPoint: point)
        }
      }))
    }

    let presentationController = actionSheet.popoverPresentationController
    presentationController?.barButtonItem = navigationItem.leftBarButtonItem
    navigationController?.present(actionSheet, animated: true, completion: nil)
  }

  private func setupSwitchLocaleBtn() {
    let btn = UIBarButtonItem.init(title: "Router Language", style: .plain, target: self, action: #selector(changeRouterLanguage))
    navigationItem.rightBarButtonItem = btn
  }

  @objc private func changeRouterLanguage() {
    let languageIdByActionSheetTitle = [
      "English": "en-US",
      "French": "fr-FR",
      "Catalan": "ca-ES",
      "Hindi": "hi-IN",
      "Spanish": "es-ES",
      "Czech": "cs-CZ",
      "Italian": "it-IT",
      "German": "de-DE",
      "Slovenian": "sl-SI",
      "Pirate": "pirate",
      ]
    let actionSheet = UIAlertController.init(title: "Router Language", message: "Choose a language", preferredStyle: .actionSheet)
    for (actionTitle, languageIdentifier) in languageIdByActionSheetTitle {
      actionSheet.addAction(UIAlertAction.init(title: actionTitle, style: .default, handler: { [unowned self] (action) in
        self.routingLocale = Locale.init(identifier: languageIdentifier)
      }))
    }
    actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { [unowned self] (action) in
      self.dismiss(animated: true, completion: nil)
    }))
    let presentationController = actionSheet.popoverPresentationController
    presentationController?.barButtonItem = navigationItem.rightBarButtonItem
    navigationController?.present(actionSheet, animated: true, completion: nil)
  }

  private func requestRoute(toPoint: OTRGeoPoint) {
    guard let routingController = try? RoutingController.controller() else { return }
    routingController.updateLocale(routingLocale)

    guard let currentLocation = locationManager.currentLocation  else { return }
    lastRoutingPoint = toPoint
    let startingPoint = OTRRoutingPoint(coordinate: OTRGeoPointMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude), type: .break)
    let endingPoint = OTRRoutingPoint(coordinate: lastRoutingPoint!, type: .break)

    _ = routingController.requestRoute(withLocations: [startingPoint, endingPoint],
                                       costingModel: costingModel,
                                       costingOption: nil,
                                       directionsOptions: ["units" : "miles" as NSObject]) { (routingResult, token, error) in
                                        print("Error:\(String(describing: error))")
                                        self.currentRouteResult = routingResult
                                        if let result = routingResult {
                                          let _ = try? self.display(result)
                                        }


    }
  }

  //MARK:- Single Tap Gesture Recognizer Delegate
  func mapController(_ controller: MZMapViewController, recognizer: UIGestureRecognizer, shouldRecognizeSingleTapGesture location: CGPoint) -> Bool {
    return true
  }

  func mapController(_ controller: MZMapViewController, recognizer: UIGestureRecognizer, didRecognizeSingleTapGesture location: CGPoint) {
    let point = tgViewController.screenPosition(toLngLat: location)
    requestRoute(toPoint: OTRGeoPoint(coordinate: point))
  }
}
