// LoadingState.swift
// ShoreWatch

enum LoadingState: Equatable {
    case idle
    case locating
    case fetchingBuoy
    case assessing
    case ready
    case failed(String)
}
