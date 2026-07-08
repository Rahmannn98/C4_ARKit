//
//  ARViewPort.swift
//  C4_ARKit
//
//  Created by Saifulloh Rahman on 07/07/26.
//

import SwiftUI
import RealityKit
import ARKit

// MARK: - Unified View Layout
struct ARViewportView: View {
    @StateObject private var viewModel = ARSessionViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            // Pass the state manager downward into our system representable framework bridge
            ARKitViewRepresentable(viewModel: viewModel)
                .ignoresSafeArea()
            
            // Pass properties directly into our HUD view component
            CinematographyHUDOverlay(
                statusMessage: viewModel.trackingStatusMessage,
                statusColor: viewModel.trackingStatusColor,
                featureCount: viewModel.featurePointCount
            )
        }
    }
}

// MARK: - Updated UIViewRepresentable
struct ARKitViewRepresentable: UIViewRepresentable {
    let viewModel: ARSessionViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = [.horizontal]
        
        // Connect the lifecycle coordinator directly into the running engine session instance
        viewModel.connectSession(arView.session)
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

// MARK: - Updated Cinematography HUD Overlay
struct CinematographyHUDOverlay: View {
    let statusMessage: String
    let statusColor: Color
    let featureCount: Int
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AR SCENE STUDIO")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("STATUS: \(statusMessage)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(statusColor)
                    
                    Text("TRACKED FEATURES: \(featureCount)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.black.opacity(0.75))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(statusColor.opacity(0.5), lineWidth: 1)
                )
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            Spacer()
        }
    }
}

#Preview {
    ARViewportView()
}
