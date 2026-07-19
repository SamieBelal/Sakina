//
//  SakinaWidgetBundle.swift
//  SakinaWidget
//
//  Created by Ibby on 7/14/26.
//

import WidgetKit
import SwiftUI

@main
struct SakinaWidgetBundle: WidgetBundle {
    var body: some Widget {
        SakinaWidget()
        SakinaCompanionWidget()
        SakinaDuaTimesWidget()
        // The duʿā-times Live Activity (Lock Screen + Dynamic Island). Gated so
        // the extension still compiles + runs below iOS 16.2 (ActivityKit floor);
        // below 16.2 the bundle simply omits it. The type itself also carries
        // `@available(iOS 16.2, *)` (plan correction #1) so it compiles under a
        // lower deployment target.
        if #available(iOS 16.2, *) {
            SakinaDuaTimesLiveActivity()
        }
    }
}
