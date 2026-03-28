//
//  GameViewController.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }

        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill

        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        true
    }
}
