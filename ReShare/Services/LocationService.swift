import Foundation
import Combine
import CoreLocation
import SwiftUI

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationText: String = "Определяем местоположение..."

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 200
    }

    func requestLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            locationText = "Службы геолокации отключены"
            return
        }

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            locationText = "Геопозиция отключена — включите в настройках"
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        @unknown default:
            locationText = "Геопозиция недоступна"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            Task {
                manager.requestLocation()
            }
        case .restricted, .denied:
            locationText = "Геопозиция отключена — включите в настройках"
        case .notDetermined:
            locationText = "Определяем местоположение..."
        @unknown default:
            locationText = "Геопозиция недоступна"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationText = "Не удалось получить координаты"
            return
        }
        reverseGeocode(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationText = "Ошибка геолокации"
        print("LocationService: Ошибка геолокации: \(error.localizedDescription)")
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let error = error {
                self.locationText = "Координаты: \(location.coordinate.latitude.rounded(toPlaces: 3)), \(location.coordinate.longitude.rounded(toPlaces: 3))"
                print("LocationService: Ошибка обратного геокодирования: \(error.localizedDescription)")
                return
            }
            guard let placemark = placemarks?.first else {
                self.locationText = "Координаты: \(location.coordinate.latitude.rounded(toPlaces: 3)), \(location.coordinate.longitude.rounded(toPlaces: 3))"
                return
            }
            self.locationText = self.formatPlacemark(placemark)
        }
    }

    private func formatPlacemark(_ placemark: CLPlacemark) -> String {
        if let city = placemark.locality {
            if let district = placemark.subLocality {
                return "\(city), \(district)"
            }
            return city
        }
        if let name = placemark.name {
            return name
        }
        return "Координаты: \(placemark.location?.coordinate.latitude.rounded(toPlaces: 3) ?? 0), \(placemark.location?.coordinate.longitude.rounded(toPlaces: 3) ?? 0)"
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
