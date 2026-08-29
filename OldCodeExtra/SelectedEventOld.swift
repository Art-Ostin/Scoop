//
//  SelectedEvent.swift
//  Scoop
//
//  Created by Art Ostin on 27/08/2026.
//

import SwiftUI


/*
 
 
 enum SelectedEventFormat {
     case noMessage, smallMessage, largeMessage
 }



 struct SelectedEvent: View {

     //Injected
     let event: EventProfile

     //Local view state
     @State private var messageWidth: CGFloat = 0
     @State private var selectedEventFormat: SelectedEventFormat = .noMessage

     private static let imageWidth: CGFloat = 92 //Geometry: the photo column, measured against the text beside it

     var body: some View {
         InviteListCard(insetsContent: false) { //Bare card: the padding below is the whole story
             eventView
         }
         .padding(.horizontal, Spacing.gutter) //Screen edge → the card
     }
 }

 //The card's one row: the photo, and the text column beside it
 extension SelectedEvent {

     private var eventView: some View {
         //.top in every format: a short message leaves its slack below the photo, never above it
         HStack(alignment: .top, spacing: horizontalSpacing) {
             eventImage
             
             VStack(alignment: .leading, spacing: sectionSpacing) {
                 nameTitle

                 //Without a message the three rows spread down the photo rather than bunching at its top
                 if selectedEventFormat == .noMessage { Spacer() }
                 timeRow

                 if selectedEventFormat == .noMessage { Spacer() }
                 placeRow

                 if let message = displayMessage {
                     messageSection(message)
                 }
             }
             .padding(.vertical, Spacing.xs)
         }
         .padding(.leading, Spacing.xs) //The photo sits nearer the card edge than the text column does
         .padding(.trailing, Spacing.md)
         .padding(.vertical, cardVerticalPadding)
         .onAppear { resolveFormat() }
         .onChange(of: messageWidth) { _, _ in resolveFormat() } //The first pass measures 0 — the format can only settle once the column has a width
     }
 }


 //The three formats: the metrics each one sets, and how one is chosen
 extension SelectedEvent {

     private var horizontalSpacing: CGFloat {
         switch selectedEventFormat {
         case .noMessage: 20
         default: Spacing.md
         }
     }

     private var sectionSpacing: CGFloat {
         switch selectedEventFormat {
         case .noMessage: 0
         case .smallMessage: 10
         case .largeMessage: 14
         }
     }

     private var imageRatio: CGFloat {
         switch selectedEventFormat {
         case .noMessage: AspectRatio.square.ratio //Square: nothing below the place row to stand beside
         default: AspectRatio.card.ratio //Taller, to stand beside the message the card gains
         }
     }

     //Spacing.xs matches the leading inset, so the photo wears an even frame and its corner is
     //exactly concentric; the tall card takes one step more air around a message that long
     private var cardVerticalPadding: CGFloat {
         switch selectedEventFormat {
         case .largeMessage: Spacing.sm
         default: Spacing.xs
         }
     }

     //Which format the card wears: no message, one that fits two lines, or a longer one
     private func resolveFormat() {
         if displayMessage == nil {
             selectedEventFormat = .noMessage
         } else if messageFitsTwoLines {
             selectedEventFormat = .smallMessage
         } else {
             selectedEventFormat = .largeMessage
         }
     }
     
     private var displayMessage: String? {
         guard let text = event.event.message?
             .replacingOccurrences(of: "\n", with: " ")
             .trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty else { return nil }
         return text
     }

     private var messageFitsTwoLines: Bool {
         let metrics = displayMessage?.lineMetrics(
             font: .body(14, .regularItalic), //lineMetrics' contract: must match the drawn Text exactly
             lineSpacing: 0, //The drawn Text sets none
             width: messageWidth
         )
         return (metrics?.count ?? 0) <= 2
     }
 }

 //The components
 extension SelectedEvent {
     
     @ViewBuilder
     private var eventImage: some View {
         if let image = event.image {
             Color.clear
                 .frame(width: Self.imageWidth, height: Self.imageWidth / imageRatio)
                 .overlay {
                     Image(uiImage: image)
                         .resizable()
                         .scaledToFill()
                 }
                 //Concentric inside the card's own CornerRadius.md corner, at the Spacing.xs the photo is inset by
                 .clipShape(.rect(cornerRadius: CornerRadius.concentric(in: CornerRadius.md, inset: Spacing.xs)))
         }
     }
     
     private var nameTitle: some View {
         Text(event.profile.name)
             .font(.title(18, .bold))
             .foregroundStyle(Color.textPrimary)
             .frame(maxWidth: .infinity, alignment: .leading)
             .overlay(alignment: .topTrailing) {
                 typeIcon
             }
     }
     
     private var typeIcon: some View {
         HStack(alignment: .center, spacing: Spacing.xxs) {
             Text(event.event.type.emoji)
                 .font(.body(11, .medium))
             
             Text(event.event.type.longTitle)
         }
         .font(.body(13, .bold))
         .foregroundStyle(Color.textPrimary)
         .frame(height: 24)
         .padding(.trailing, Spacing.xs)
         .padding(.leading, 6) //Geometry: the emoji glyph carries its own leading air, so 2pt less than the trailing inset
         .capsuleStroke(lineWidth: 0.75, color: Color.textPrimary)
         .scaleEffect(0.8, anchor: .topTrailing)
     }
     
     @ViewBuilder
     private var timeRow: some View {
         let times = event.event.proposedTimes

         if times.sharesOneHour {
             times.invitedDayPieces()
                 .map { Text($0.text).foregroundStyle($0.lapsed ? Color.textPlaceholder : .textSecondary) }
                 .reduce(Text(""), +)
                 .font(.body(14, .regular))
                 .oneLineLimitAndShrink() //Three long days shrink as one line, as the expired row does
         } else {
             VStack(alignment: .leading, spacing: Spacing.xxs) {
                 ForEach(times.invitedDayHourPieces(), id: \.text) { piece in
                     Text(piece.text)
                         .foregroundStyle(piece.lapsed ? Color.textPlaceholder : .textSecondary)
                 }
             }
             .font(.body(14, .regular))
             .oneLineLimitAndShrink() //Each day keeps one line, shrinking rather than truncating
         }
     }
     
     private var placeRow: some View {
         Button {
             MapsRouter.openMaps(item: event.event.location.mapItem)
         } label: {
             Text(FormatEvent.placeName(event.event.location))
                 .font(.body(14, .bold))
                 .foregroundStyle(Color.textAccent)
                 .lineLimit(1)
                 .contentShape(Rectangle())
         }
         .shrinkButton() //Not shrinkPress: its raw DragGesture would claim the scroll's pan
         .instantPressDelivery()
     }
     
     private func messageSection(_ message: String) -> some View {
         Text(message)
             .font(.body(14, .regularItalic))
             .foregroundStyle(Color.textSecondary)
             .frame(maxWidth: .infinity, alignment: .leading) //Measure the column, not the widest line
             .getWidth($messageWidth)
     }
 }
 */




/*
 
 
 /*
  if let selectedEvent {
      HeaderRow(title: "Invites", note: acceptanceNote)
          .padding(.bottom, Spacing.sm)
          .padding(.horizontal, Spacing.gutter)

      ZStack(alignment: .top) { //One slot: the leaving and arriving card overlap instead of stacking
          SelectedEvent(event: selectedEvent)
              .transition(.blurReplace)
              .id(selectedEvent.id)
      }
      .animation(.transition, value: selectedEvent.id) //Outside the .id, or the swap is instant
      .padding(.bottom, Spacing.lg) //The card → the section that follows it
  }

  
  
  
  */

 */
