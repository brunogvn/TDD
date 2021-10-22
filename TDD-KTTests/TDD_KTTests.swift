//
//  TDD_KTTests.swift
//  TDD-KTTests
//
//  Created by Tulio de Oliveira Parreiras on 22/10/21.
//

import XCTest
@testable import TDD_KT

/*
 - Abriu o app, carrega um progress e baixa um feed
    - Exibe progress
    - Baixa um feed
        - Esconde o progress
    - Exibe feed baixado
    - Exibe um erro
 - Ao fazer pull na tela, atualiza o feed
    - Exibe progress
    - Atualiza o feed
 */

protocol FeedLoader {
    func loadFeed(completion: @escaping () -> Void)
}

final class TableViewModel: TableControllerDelegate {
    init(loader: FeedLoader, tableView: TableView) {
        self.loader = loader
        self.tableView = tableView
    }
    
    var loader: FeedLoader
    var tableView: TableView
    
    func didRequestLoadFeed() {
        tableView.showProgress(isLoading: true)
        loader.loadFeed {
            self.tableView.loadFeed([])
            self.tableView.showProgress(isLoading: false)
        }
    }
    
}

protocol TableControllerDelegate {
    func didRequestLoadFeed()
}

protocol TableView {
    func loadFeed(_ feed: [Any])
    
    func showProgress(isLoading: Bool)
}

final class TableController: UITableViewController, TableView {
    
    var delegate: TableControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        refreshAction()
    }
    
    func showProgress(isLoading: Bool) {
        isLoading ? refreshControl?.beginRefreshing() : refreshControl?.endRefreshing()
    }
    
    @objc
    func refreshAction() {
        requestFeed()
    }
    
    func requestFeed() {
        delegate?.didRequestLoadFeed()
    }
    
    func loadFeed(_ feed: [Any]) {
        
    }

}

class TDD_KTTests: XCTestCase {

    func test_viewDidLoad_showProgress() {
        // Given
        let (sut, _) = makeSUT()
        // When
        sut.loadViewIfNeeded()
        // Then
        XCTAssertTrue(sut.isShowingProgress)
    }
    
    func test_loadFeedAction_requestFeedFromLoader() {
        // Given
        let (sut, loader) = makeSUT()
        // When
        sut.loadViewIfNeeded()
        // Then
        XCTAssertNotNil(loader.feedRequests)
    }
    
    func test_loadFeedResult_dismissProgress() {
        // Given
        let (sut, loader) = makeSUT()
        // When
        sut.loadViewIfNeeded()
        loader.completeLoadFeed()
        
        XCTAssertFalse(sut.isShowingProgress)
    }
    
    func test_feedReload_showProgress() {
        // Given
        let (sut, loader) = makeSUT()
        // When
        sut.loadViewIfNeeded()
        loader.completeLoadFeed()
        sut.requestRefresh()
        
        XCTAssertTrue(sut.isShowingProgress)
        
    }
    
    func test_feedReload_downloadFeedFromLoader() {
        // Given
        let (sut, loader) = makeSUT()
        // When
        sut.loadViewIfNeeded()
        loader.completeLoadFeed()
        sut.requestRefresh()
        
        XCTAssertEqual(loader.feedRequests.count, 2)
    }
    
    func test_progressFinish_afterLoadFeed() {
        // Given
        let (sut, loader) = makeSUT()
        // When
        sut.loadViewIfNeeded()
        loader.completeLoadFeed()
        sut.requestRefresh()
        loader.completeLoadFeed()
        
        XCTAssertFalse(sut.isShowingProgress)
    }
    
    func makeSUT() -> (sut: TableController, loader: FeedLoaderMock) {
        let sut = TableController()
        let loader = FeedLoaderMock()
        let viewModel = TableViewModel(loader: loader, tableView: sut)
        sut.delegate = viewModel
        return (sut, loader)
    }

    final class FeedLoaderMock: FeedLoader {
        var feedRequests: [(() -> Void)] = []
        
        func loadFeed(completion: @escaping () -> Void) {
            feedRequests.append(completion)
        }
        
        func completeLoadFeed(index: Int = 0) {
            feedRequests[index]()
        }
    }
    
}

extension TableController {
    var isShowingProgress: Bool {
        refreshControl?.isRefreshing ?? false
    }
    
    func requestRefresh() {
        refreshControl?.sendActions(for: .valueChanged)
    }
}
