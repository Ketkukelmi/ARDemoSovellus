//
//  MeasureNode.swift
//  ARDemoApp
//
//  Created by CubiCasa Office on 19/01/2019.
//  Copyright © 2019 CubiCasa Office. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class MeasureNode {
    var node = SCNNode()
    var endNode = SCNNode()
    var text = SCNText()
    var textNode = SCNNode()
    var lineNode = SCNNode()
    var sceneView = ARSCNView()
    var startVector = SCNVector3()
    
    init(scene: ARSCNView, vector: SCNVector3){
        self.sceneView = scene
        self.startVector = vector
        
        
        let box = SCNBox.init(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0)
        box.firstMaterial?.diffuse.contents = UIColor.blue
        box.firstMaterial?.lightingModel = .constant
        box.firstMaterial?.isDoubleSided = true
        node = SCNNode(geometry: box)
        //node.scale = SCNVector3(1/2, 1/2, 1/2)
        node.position = startVector
        sceneView.scene.rootNode.addChildNode(node)
        
        endNode = SCNNode(geometry: box)
        //endNode.scale = SCNVector3(1/800, 1/800, 1/800)
        
        text = SCNText(string: "", extrusionDepth: 0.1)
        text.font = .systemFont(ofSize: 5)
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.alignmentMode  = CATextLayerAlignmentMode.center.rawValue
        text.truncationMode = CATextLayerTruncationMode.middle.rawValue
        text.firstMaterial?.isDoubleSided = true
        
        let textWrapperNode = SCNNode(geometry: text)
        textWrapperNode.eulerAngles = SCNVector3Make(0, .pi, 0)
        textWrapperNode.scale = SCNVector3(1/500.0, 1/500.0, 1/500.0)
        
        textNode = SCNNode()
        textNode.addChildNode(textWrapperNode)
        let constraint = SCNLookAtConstraint(target: sceneView.pointOfView)
        constraint.isGimbalLockEnabled = true
        textNode.constraints = [constraint]
        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    func update(to vector: SCNVector3) {
        lineNode.removeFromParentNode()
        lineNode = startVector.line(to: vector, color: UIColor.white)
        sceneView.scene.rootNode.addChildNode(lineNode)
        
        text.string = distance(to: vector)
        textNode.position = SCNVector3((startVector.x+vector.x)/2.0, (startVector.y+vector.y)/2.0, (startVector.z+vector.z)/2.0)
        
        endNode.position = vector
        if endNode.parent == nil {
            sceneView.scene.rootNode.addChildNode(endNode)
        }
    }
    
    func distance(to vector: SCNVector3) -> String {
        return String(format: "%.2f%@", startVector.distance(from: vector), "meters")
    }
    
    func removeFromParentNode() {
        node.removeFromParentNode()
        lineNode.removeFromParentNode()
        endNode.removeFromParentNode()
        textNode.removeFromParentNode()
    }
}
