//
//  DocumentSource.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import UIKit

/// Source of document import
enum DocumentSource {
    case camera([UIImage])
    case file(URL)
    case photos([UIImage])
}
