//
//  i360ViewController.swift
//  SceneKitDemo
//
//  Created by Tomoya Hirano on 4/4/16.
//  Copyright (c) 2016 Tomoya Hirano. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import AVFoundation
import SpriteKit

final class i360ViewController: UIViewController {
  private let manager = CMMotionManager()
  private var videoNode: SKVideoNode?
  private var spritescene: SKScene?
  private var player: AVPlayer? = nil
  private var scnView: SCNView {
    return self.view as! SCNView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let scene = SCNScene()
    scnView.scene = scene
    
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3Zero
    scene.rootNode.addChildNode(cameraNode)
    
    let sphereGeometry = SCNSphere(radius: 20)
    let material = SCNMaterial()
    material.doubleSided = true
    sphereGeometry.firstMaterial = material
    let sphereNode = SCNNode(geometry: sphereGeometry)
    scene.rootNode.addChildNode(sphereNode)
    sphereNode.position = SCNVector3Zero
    
    guard let queue = NSOperationQueue.currentQueue() else { return }
    manager.startDeviceMotionUpdatesToQueue(queue) { (motion, error) in
      guard let motion = motion else { return }
      cameraNode.orientation = self.orientationFromCMQuaternion(motion.attitude.quaternion)
    }
    
    spritescene = SKScene()
    spritescene?.backgroundColor = UIColor.greenColor()
    resetVideo()
    
    material.diffuse.contents = spritescene
    
    let size = CGSize(width: 1920,height: 960)
    spritescene?.size = size
    videoNode?.position = CGPointMake(size.width/2, size.height/2)
    videoNode?.size.width = size.width
    videoNode?.size.height = size.height
    videoNode?.play()
  }
  
  private func orientationFromCMQuaternion(q: CMQuaternion) -> SCNVector4 {
    let gq1 = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(-90), 1, 0, 0)
    let gq2 = GLKQuaternionMake(Float(q.x), Float(q.y), Float(q.z), Float(q.w))
    let qp  = GLKQuaternionMultiply(gq1, gq2)
    let rq  = CMQuaternion(x: Double(qp.x), y: Double(qp.y), z: Double(qp.z), w: Double(qp.w))
    return SCNVector4Make(Float(rq.x), Float(rq.y), Float(rq.z), Float(rq.w))
  }
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if keyPath == "presentationSize" {
      if let item = object as? AVPlayerItem {
        let size = item.presentationSize
        
        //Set size of geometry here
        spritescene?.size = size
        videoNode?.position = CGPointMake(size.width/2, size.height/2)
        videoNode?.size.width = size.width
        videoNode?.size.height = size.height
        
        return
      }
    }
    super.observeValueForKeyPath(keyPath,
                                 ofObject: object,
                                 change: change,
                                 context: context)
  }
  
  private func resetVideo() {
    videoNode?.pause()
    videoNode?.removeFromParent()
    videoNode = nil
    
    player?.currentItem?.removeObserver(self, forKeyPath: "presentationSize")
    player = AVPlayer(URL: NSBundle.mainBundle().URLForResource("movie1", withExtension: "mp4")!)
    player?.currentItem?.addObserver(self, forKeyPath: "presentationSize", options: .New, context: nil)
    
    videoNode = SKVideoNode(AVPlayer: player!)
    videoNode?.xScale = -1.0
    videoNode?.yScale = -1.0
    if let videoNode = videoNode {
      spritescene?.addChild(videoNode)
    }
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    resetVideo()
  }
  
}
