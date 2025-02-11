//
//  DiscoverView.swift
//  MovieSwift
//
//  Created by Thomas Ricouard on 19/06/2019.
//  Copyright © 2019 Thomas Ricouard. All rights reserved.
//

import SwiftUI

struct DiscoverView : View {
    @EnvironmentObject var store: AppStore
    @State var draggedViewState = DraggableCover.DragState.inactive
    @State var previousMovie: Int? = nil
    
    var movies: [Int] {
        store.state.moviesState.discover
    }
    
    var currentMovie: Movie {
        return store.state.moviesState.movies[store.state.moviesState.discover.reversed()[0].id]!
    }
    
    func dragResistance() -> CGFloat {
        abs(draggedViewState.translation.width) / 5
    }
    
    func opacityResistance() -> Double {
        Double(abs(draggedViewState.translation.width) / 800)
    }
    
    func leftZoneResistance() -> CGFloat {
        -draggedViewState.translation.width / 1000
    }
    
    func rightZoneResistance() -> CGFloat {
        draggedViewState.translation.width / 1000
    }
    
    func doneGesture(handler: DraggableCover.EndState) {
        if handler == .left || handler == .right {
            previousMovie = currentMovie.id
            if handler == .left {
                store.dispatch(action: MoviesActions.addToWishlist(movie: currentMovie.id))
            } else if handler == .right {
                store.dispatch(action: MoviesActions.addToSeenlist(movie: currentMovie.id))
            }
            store.dispatch(action: MoviesActions.PopRandromDiscover())
            fetchRandomMovies()
        }
    }
    
    func fetchRandomMovies() {
        if movies.count < 10 {
            store.dispatch(action: MoviesActions.FetchRandomDiscover())
        }
    }
    
    var filterView: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Year: \(store.state.moviesState.discoverParams["year"] ?? "loading")")
                .color(.secondary)
                .font(.footnote)
            Text("Sort: \(store.state.moviesState.discoverParams["sort_by"] ?? "loading")")
                .color(.secondary)
                .font(.footnote)
            Text("Page: \(store.state.moviesState.discoverParams["page"] ?? "loading")")
                .color(.secondary)
                .font(.footnote)
            Button(action: {
                self.store.dispatch(action: MoviesActions.ResetRandomDiscover())
                self.fetchRandomMovies()
            }, label: {
                Image(systemName: "arrow.clockwise")
            })
            }
            .fixedSize()
    }
    
    var zonesButtons: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                if !self.movies.isEmpty {
                    Text(self.currentMovie.original_title)
                        .color(.primary)
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .lineLimit(2)
                        .opacity(self.draggedViewState.isDragging ? 0.0 : 1.0)
                        .position(x: geometry.frame(in: .global).midX,
                                  y: geometry.frame(in: .global).midY + 150)
                        .animation(.basic())
                    
                    PresentationButton(destination:
                        NavigationView { MovieDetail(movieId: self.currentMovie.id) }.environmentObject(self.store),
                                       label: {
                                        Text("See detail").color(.blue)
                                        
                    })
                        .opacity(self.draggedViewState.isDragging ? 0.0 : 0.7)
                        .position(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).midY + 180)
                        .animation(.fluidSpring())
                        .environmentObject(self.store)
                }
                
                Circle()
                    .strokeBorder(Color.pink, lineWidth: 1)
                    .background(Image(systemName: "heart.fill").foregroundColor(.pink))
                    .frame(width: 50, height: 50)
                    .position(x: geometry.frame(in: .global).midX - 50, y: geometry.frame(in: .global).midY + 200)
                    .opacity(self.draggedViewState.isDragging ? 0.3 + Double(self.leftZoneResistance()) : 0)
                    .animation(.fluidSpring())
                
                Circle()
                    .strokeBorder(Color.green, lineWidth: 1)
                    .background(Image(systemName: "eye.fill").foregroundColor(.green))
                    .frame(width: 50, height: 50)
                    .position(x: geometry.frame(in: .global).midX + 50, y: geometry.frame(in: .global).midY + 200)
                    .opacity(self.draggedViewState.isDragging ? 0.3 + Double(self.rightZoneResistance()) : 0)
                    .animation(.fluidSpring())
                
                
                Circle()
                    .strokeBorder(Color.red, lineWidth: 1)
                    .background(Image(systemName: "xmark").foregroundColor(.red))
                    .frame(width: 50, height: 50)
                    .position(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).midY + 230)
                    .opacity(self.draggedViewState.isDragging ? 0.0 : 1)
                    .animation(.fluidSpring())
                    .tapAction {
                        self.previousMovie = self.currentMovie.id
                        self.store.dispatch(action: MoviesActions.PopRandromDiscover())
                        self.fetchRandomMovies()
                }
                
                Circle()
                    .foregroundColor(.clear)
                    .background(Image(systemName: "gobackward").foregroundColor(.blue))
                    .frame(width: 50, height: 50)
                    .position(x: geometry.frame(in: .global).midX - 50,
                              y: geometry.frame(in: .global).midY + 230)
                    .opacity(self.previousMovie != nil && !self.draggedViewState.isActive ? 1 : 0)
                    .animation(.fluidSpring())
                    .tapAction {
                        self.store.dispatch(action: MoviesActions.PushRandomDiscover(movie: self.previousMovie!))
                        self.previousMovie = nil
                }
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            GeometryReader { reader in
                self.filterView.position(x: reader.frame(in: .global).midX,
                                    y: 20)
            }
            zonesButtons
            ForEach(movies) {id in
                if self.movies.reversed().firstIndex(of: id) == 0 {
                    DraggableCover(movieId: id,
                                   gestureViewState: self.$draggedViewState,
                                   endGestureHandler: { handler in
                                    self.doneGesture(handler: handler)
                    })
                } else {
                    DiscoverCoverImage(imageLoader: ImageLoader(poster: self.store.state.moviesState.movies[id]!.poster_path,
                                                                size: .small))
                        .padding(.bottom, Length(self.movies.reversed().firstIndex(of: id)! * 8) - self.dragResistance())
                        .opacity(Double(self.movies.firstIndex(of: id)!) * 0.05 + self.opacityResistance())
                        .animation(.spring())
                }
            }
            }
            .onAppear {
                self.fetchRandomMovies()
        }
    }
}

#if DEBUG
struct DiscoverView_Previews : PreviewProvider {
    static var previews: some View {
        DiscoverView().environmentObject(store)
    }
}
#endif
