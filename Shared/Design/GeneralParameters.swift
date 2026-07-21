//
//  GeneralParameters.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2026.
//

//All cornerRadius, spacing, shadows, aspectRatios (and later when added animations) standardised here
import SwiftUI

// MARK: Corner Radius

enum CornerRadius {
    // Standardised scale
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24

    //Specific uses
    static let smallImage = sm
    static let image = lg
    static let alert: CGFloat = 36
    static let customMenu: CGFloat = 26
    static let customMenuRowHighlight: CGFloat = 14

    //To construct concentric corners
    static func concentric(in parent: CGFloat, inset: CGFloat) -> CGFloat {
        max(parent - inset, 4)
    }
}





// MARK: Shadow
enum Elevation {
    case card, image, button, softFloating, floating

    //liquid glass shadow for fallback components & onPress shadowreduce
    static let glass: Elevation = .card
    static let pressedStrength: Double = 0.4

    struct Layer {
        let opacity: Double
        let radius: CGFloat
        let y: CGFloat

        var halved: Layer { Layer(opacity: opacity / 2, radius: radius, y: y) }
    }
    
    //Two layered shadows -> modern method
    var layers: (contact: Layer, ambient: Layer) {
        switch self {
        case .card:         (Layer(opacity: 0.03, radius: 8,  y: 3), Layer(opacity: 0.01, radius: 24, y: 9))
        case .image:        (Layer(opacity: 0.1, radius: 3,  y: 3), Layer(opacity: 0.12, radius: 12, y: 8))
        case .button:       (Layer(opacity: 0.12, radius: 4,  y: 2), Layer(opacity: 0.08, radius: 16, y: 8))
        case .softFloating: (Elevation.floating.layers.contact.halved, Elevation.floating.layers.ambient.halved)
        case .floating:     (Layer(opacity: 0.06, radius: 10, y: 2), Layer(opacity: 0.14, radius: 24, y: 14))
        }
    }
}






// MARK: Spacing
enum Spacing {
    // Standardised scale — 4pt grid up to 16, then a 12pt rhythm (×1.5 steps)
    static let xxs: CGFloat = 4   //tightest pair: a glyph and its caption/count
    static let xs: CGFloat  = 8   //icon ↔ label, chip content
    static let sm: CGFloat  = 12  //related rows/controls inside one block
    static let md: CGFloat  = 16  //default gap between blocks; standard inner padding
    static let lg: CGFloat  = 24  //component ↔ component
    static let xl: CGFloat  = 36  //section ↔ section within a screen
    static let xxl: CGFloat = 48  //major section break
    static let xxxl: CGFloat = 72 //hero break: between full-screen-scale blocks

    //Specific uses
    static let hairline: CGFloat = 2   //optical nudge between touching glyphs
    static let titlePadding = xl        //Bettween navigation title and start of content
    static let gutter = md             //full-bleed surface (card, notification) ↔ screen edge
    static let margin = lg             //text/content column ↔ screen edge
    static let titleGap = xxxl         //screen title → its first content block
    static let clearance: CGFloat = 96 //content ↔ the screen edge or floating chrome it must clear
}




// MARK:  Aspect Ratio
enum AspectRatio {
    case square, card, `default`, inviteCard, invitedImage, confirmInviteImage

    var ratio: CGFloat {
        switch self {
        case .square:             1 / 1
        case .card:               1 / 1.05
        case .default:            1 / 1.12
        case .inviteCard:         1 / 1.5
        case .invitedImage:       1 / 0.97
        case .confirmInviteImage: 1 / 0.88
        }
    }
}




// MARK: - Motion
//
// One closed vocabulary for every animation in the app, named by the ROLE the
// motion plays — never by its duration. Call sites read `.animation(.toggle, value:)`
// or `withAnimation(.present) { … }`; the *feel* of a role is retuned here, once.
//
// Spring-first, per Apple's guidance ("Animate with springs"): `.smooth` carries no
// bounce, `.snappy` a small one, `.bouncy` more. A duration-based ease survives only
// where a precise, bounce-free timing is the whole point (micro-feedback ticks).
//
// This is the vocabulary for generic chrome. Measured system replications
// (CustomAlert, the in-app banner, the Liquid-Glass menu morphs) and geometry-matched
// hero flights (ProfileMorph, SendInviteCard) keep their own measured curves in their
// own files — never flatten those into a role. Press feedback is owned by
// `PressEffect`. Need a curve that isn't one of these roles? Add a role here; never
// inline a one-off.
extension Animation {

    /// Discrete state flips — selection fills, chips, validity, checkmarks, small on/off toggles. Crisp, faintly sprung.
    static let toggle = Animation.snappy(duration: 0.2)

    /// Content swaps & crossfades — opacity, `.blurReplace`, `.id` content, text/number swaps. Even, never bounces.
    static let transition = Animation.smooth(duration: 0.25)

    /// Disclosure & grow-in-place — info rows, height reveals, content reflow inside a container.
    static let expand = Animation.snappy(duration: 0.3)

    /// Overlays, sheets, menus and cards appearing. Gentle settle on arrival.
    static let present = Animation.spring(duration: 0.42, bounce: 0.12)

    /// …and their dismissal. Quicker than `.present`, flat, never bounces — gets out of the way.
    static let dismiss = Animation.smooth(duration: 0.22)

    /// Position & offset settles — drag-release, programmatic scroll, layout shifts, list insert/remove. Physical, lightly sprung.
    static let move = Animation.spring(duration: 0.4, bounce: 0.08)

    /// Micro-feedback below the `.toggle` threshold — near-instant dims and per-tick updates.
    static let quick = Animation.easeOut(duration: 0.12)
}



// MARK: - View Conveniences
extension View {
    
    //To call the shadow with my in built parameters
    func shadow(_ elevation: Elevation?, tint: Color = .black, strength: Double = 1) -> some View {
        let (contact, ambient) = (elevation ?? .card).layers
        let s = (elevation == nil) ? 0 : strength.clamped(to: 0...1) //optional shadow possible (i.e. strength 0)
        return self
            .shadow(color: .black.opacity(contact.opacity * s), radius: contact.radius, x: 0, y: contact.y)
            .shadow(color: tint.opacity(ambient.opacity * s), radius: ambient.radius, x: 0, y: ambient.y)
    }
}
