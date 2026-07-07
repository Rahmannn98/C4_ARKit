
//
//  AR.swift
//  C4_ARKit
//
//  Created by Saifulloh Rahman on 07/07/26.
//
//
//  ARSessionManager.swift
//  C4_ARKit
//
//  Lesson 2 — Mengelola siklus hidup ARSession secara manual.
//
//  CATATAN STATUS: class ini belum dipakai oleh ARViewportView saat ini,
//  karena ARViewportView memakai `content.camera = .worldTracking` yang
//  membuat RealityKit mengelola ARSession-nya SENDIRI secara internal.
//  Kita simpan class ini karena akan kita hubungkan kembali di lesson
//  berikutnya untuk mendapatkan akses ke trackingState.
//

import SwiftUI
import ARKit
import Combine

// MARK: - AR Session ViewModel
/// A production-ready ViewModel that translates low-level ARKit session changes
/// into clean, declarative states for the SwiftUI user interface overlay.
final class ARSessionViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Interface States
    @Published private(set) var trackingStatusMessage: String = "INITIALIZING PIPELINE..."
    @Published private(set) var trackingStatusColor: Color = .orange
    @Published private(set) var featurePointCount: Int = 0
    
    // MARK: - Core Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    override init() {
        super.init()
    }
    
    // MARK: - Public Pipeline Connection
    /// Hooks into the active ARView session to monitor events via the delegate pattern.
    /// - Parameter session: The active underlying ARSession running on the device.
    func connectSession(_ session: ARSession) {
        session.delegate = self
    }
}

// MARK: - ARSessionDelegate Implementation
extension ARSessionViewModel: ARSessionDelegate {
    
    /// Called automatically every time the ARSession processes a new hardware frame.
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Capture raw feature points from the environment map
        // rawFeaturePoints contains the 3D cloud coordinates found by the computer vision engine
        if let points = frame.rawFeaturePoints {
            let count = points.points.count
            
            // To prevent blocking the main render thread, ensure state updates occur on the main queue
            DispatchQueue.main.async {
                self.featurePointCount = count
            }
        }
    }
    
    /// Called automatically when the camera's spatial tracking quality shifts.
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        DispatchQueue.main.async {
            switch camera.trackingState {
            case .notAvailable:
                self.trackingStatusMessage = "TRACKING UNAVAILABLE"
                self.trackingStatusColor = .red
                
            case .limited(let reason):
                self.trackingStatusColor = .orange
                switch reason {
                case .initializing:
                    self.trackingStatusMessage = "INITIALIZING: MOVE DEVICE"
                case .excessiveMotion:
                    self.trackingStatusMessage = "TRACKING LIMITED: SLOW DOWN"
                case .insufficientFeatures:
                    self.trackingStatusMessage = "TRACKING LIMITED: NEED LIGHT/TEXTURE"
                case .relocalizing:
                    self.trackingStatusMessage = "RELOCALIZING SCENE..."
                @unknown default:
                    self.trackingStatusMessage = "TRACKING LIMITED: UNKNOWN"
                }
                
            case .normal:
                self.trackingStatusMessage = "TRACKING ACCURATE"
                self.trackingStatusColor = .green
            }
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async {
            self.trackingStatusMessage = "SESSION INTERRUPTED (APP BACKGROUNDED)"
            self.trackingStatusColor = .red
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async {
            self.trackingStatusMessage = "RESUMING TRACKING..."
            self.trackingStatusColor = .orange
            
            // Best Practice: Gently request the engine to attempt to map back to its known coordinates
            session.run(session.configuration ?? ARWorldTrackingConfiguration(), options: [])
        }
    }
}
