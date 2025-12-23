//
//  FollowerImmersiveView.swift
//  Sila
//
//  Created by Adam Gastineau on 12/15/25.
//

import SwiftUI
import RealityKit
import ARKit

// MARK: - Lazy Follow

struct LazyFollowComponent: Component {
    var rotationThreshold: Float = 0.52     // ~30°
    var translationThreshold: Float = 0.6   // ~2ft
    var stationaryThreshold: Float = 0.005  // Yaw change per frame to consider "stationary"
    var followSpeed: Float = 8.0            // Lerp speed when following
    var simulatorHeightOffset: Float = 1.3
    
    var lastYaw: Float = 0
    var lastPositionXZ: SIMD2<Float> = .zero
    var isInitialized = false
    var isDragging = false
    var isFollowing = false                 // Currently tracking head (vs stationary)
    var previousDeviceYaw: Float = 0        // For detecting when head stops moving
    
    // Current device state (updated every frame by system)
    var currentDeviceYaw: Float = 0
    var currentDeviceXZ: SIMD2<Float> = .zero
    var currentDeviceTransform: Transform = Transform.identity
}

@MainActor
class LazyFollowSystem: System {
    static let query = EntityQuery(where: .has(LazyFollowComponent.self))
    
    private let arSession = ARKitSession()
    private let worldTracking = WorldTrackingProvider()

    required init(scene: RealityKit.Scene) {
        Task {
            try? await self.arSession.run([self.worldTracking])
        }
    }
    
    func update(context: SceneUpdateContext) {
        guard let anchor = self.worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            return
        }

        let deviceTransform = Transform(matrix: anchor.originFromAnchorTransform)
        let forward = deviceTransform.rotation.act(SIMD3<Float>(0, 0, -1))
        let deviceYaw = atan2(forward.x, -forward.z)
        let deviceXZ = SIMD2<Float>(deviceTransform.translation.x, deviceTransform.translation.z)
        let deltaTime = Float(context.deltaTime)
        
        // We explicitly exclude pitch and roll
        let yawOnlyRotation = simd_quatf(angle: -deviceYaw, axis: SIMD3<Float>(0, 1, 0))
        var targetTransform = Transform(rotation: yawOnlyRotation, translation: deviceTransform.translation)
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var component = entity.components[LazyFollowComponent.self] else {
                continue
            }
            
            #if targetEnvironment(simulator)
            targetTransform.translation.y += component.simulatorHeightOffset
            #endif
            
            // Store current device state in component for access outside system
            component.currentDeviceYaw = deviceYaw
            component.currentDeviceXZ = deviceXZ
            component.currentDeviceTransform = targetTransform

            if component.isDragging {
                component.previousDeviceYaw = deviceYaw
                entity.components[LazyFollowComponent.self] = component
                continue
            }
            
            // Initialize
            if !component.isInitialized {
                entity.transform = targetTransform
                component.lastYaw = deviceYaw
                component.lastPositionXZ = deviceXZ
                component.previousDeviceYaw = deviceYaw
                component.isInitialized = true
                entity.components[LazyFollowComponent.self] = component
                continue
            }
            
            // Check if head is moving
            let yawDeltaThisFrame = abs(atan2(sin(deviceYaw - component.previousDeviceYaw), cos(deviceYaw - component.previousDeviceYaw)))
            let headIsStationary = yawDeltaThisFrame < component.stationaryThreshold
            
            if component.isFollowing {
                // Smoothly follow the head
                let currentTranslation = entity.transform.translation
                let currentRotation = entity.transform.rotation
                
                let t = min(1.0, component.followSpeed * deltaTime)
                let newTranslation = mix(currentTranslation, targetTransform.translation, t: t)
                let newRotation = simd_slerp(currentRotation, targetTransform.rotation, t)
                
                entity.transform = Transform(rotation: newRotation, translation: newTranslation)
                
                // Check if we've caught up to the target
                let dotProduct = abs(simd_dot(currentRotation.vector, targetTransform.rotation.vector))
                let rotationDiff = acos(min(1.0, dotProduct)) * 2.0
                let translationDiff = length(currentTranslation - targetTransform.translation)
                let caughtUp = rotationDiff < 0.01 && translationDiff < 0.01
                
                // Stop following when head is stationary AND we've caught up
                if headIsStationary && caughtUp {
                    component.isFollowing = false
                    component.lastYaw = deviceYaw
                    component.lastPositionXZ = deviceXZ
                }
            } else {
                // Stationary mode - check thresholds
                let yawDiff = atan2(sin(deviceYaw - component.lastYaw), cos(deviceYaw - component.lastYaw))
                let translationDist = length(deviceXZ - component.lastPositionXZ)
                
                if abs(yawDiff) > component.rotationThreshold || translationDist > component.translationThreshold {
                    component.isFollowing = true
                }
            }
            
            component.previousDeviceYaw = deviceYaw
            entity.components[LazyFollowComponent.self] = component
        }
    }
}

// MARK: - Views

struct FollowerImmersiveView: View {
    let streamableVideo: StreamableVideo

    @State private var playerModel: WebViewPlayer? = nil

    var contentId: String {
        PlaybackPresentableController.contentId(for: self.streamableVideo)
    }

    var body: some View {
        VStack {
            if let playerModel = self.playerModel {
                FollowerImmersiveRealityView(playerModel: playerModel, streamableVideo: self.streamableVideo)
            }
        }
        .presentableTracking(contentId: self.contentId, role: .standalone, factory: {
            PlaybackPresentableController(contentId: self.contentId, model: WebViewPlayer())
        }) { (controller: PlaybackPresentableController) in
            self.playerModel = controller.model
        }
    }
}

private struct FollowerImmersiveRealityView: View {
    static let GrabberAttachmentId: String = "GrabberAttachment"
    
    /// Distance from follower root to content (sphere radius)
    static let sphereRadius: Float = 1.7

    @Bindable var playerModel: WebViewPlayer

    let streamableVideo: StreamableVideo

    @State private var followerRoot: Entity = Entity()
    @State private var windowEntity: Entity = Entity()

    @State private var isDragging = false
    /// Current offset from follower root (point on sphere in local space)
    @State private var currentOffset: SIMD3<Float> = SIMD3<Float>(0, 0, -sphereRadius)

    var body: some View {
        RealityView { content, attachments in
            content.add(self.followerRoot)
            
            self.windowEntity.position = self.currentOffset
            self.followerRoot.addChild(self.windowEntity)

            if let attachment = attachments.entity(for: Self.GrabberAttachmentId) {
                let bounds = attachment.attachment.bounds

                attachment.components.set(CollisionComponent(shapes: [.generateBox(width: 2 * bounds.max.x, height: 2 * bounds.max.y, depth: 0.05)]))
                attachment.components.set(InputTargetComponent())
                attachment.components.set(HoverEffectComponent(.highlight(.init(color: .white, opacityFunction: .mask))))
                attachment.components.set(BillboardComponent())

                self.windowEntity.addChild(attachment)
            }
            
            self.followerRoot.components.set(LazyFollowComponent())
        } attachments: {
            Attachment(id: Self.GrabberAttachmentId) {
                ZStack(alignment: .center) {
                    ImmersiveGrabberPillView(isHeld: self.$isDragging)
                }
                .frame(width: 400, height: 140)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .targetedToEntity(where: .has(CollisionComponent.self))
                .onChanged({ value in
                    if !self.isDragging {
                        self.isDragging = true
                        
                        if var component = self.followerRoot.components[LazyFollowComponent.self] {
                            // Snap followerRoot to device transform so dragging is calculated relative to this transform
                            self.followerRoot.transform = component.currentDeviceTransform
                            component.isDragging = true
                            component.lastYaw = component.currentDeviceYaw
                            component.lastPositionXZ = component.currentDeviceXZ
                            component.isFollowing = false
                            self.followerRoot.components[LazyFollowComponent.self] = component
                        }
                    }

                    let dragWorldPosition = value.convert(value.location3D, from: .global, to: .scene)
                    let dragStartWorldPosition = value.convert(value.startLocation3D, from: .global, to: .scene)
                    let dragDelta = SIMD3<Float>(dragWorldPosition - dragStartWorldPosition)
                    
                    // Transform world delta into follower root's local space
                    let localDelta = self.followerRoot.convert(direction: dragDelta, from: nil)
                    
                    // Project onto sphere
                    let newPosition = self.currentOffset + localDelta
                    let direction = normalize(newPosition)
                    self.windowEntity.position = direction * Self.sphereRadius
                })
                .onEnded({ value in
                    // Save the final position as the new base offset
                    self.currentOffset = self.windowEntity.position
                    
                    if var component = self.followerRoot.components[LazyFollowComponent.self] {
                        component.isDragging = false
                        self.followerRoot.components[LazyFollowComponent.self] = component
                    }
                    
                    self.isDragging = false
                })
        )
    }
}

extension Transform {
    private static let windowZDepth: Float = -1.7
    private static let xOffset: Float = 0.5
    private static let yOffset: Float = 0.25

    static let topLeft = Transform(translation: .init(x: -xOffset, y: yOffset, z: windowZDepth))
    static let topRight = Transform(translation: .init(x: xOffset, y: yOffset, z: windowZDepth))
    static let bottomLeft = Transform(translation: .init(x: -xOffset, y: -yOffset, z: windowZDepth))
    static let bottomRight = Transform(translation: .init(x: xOffset, y: -yOffset, z: windowZDepth))
}
