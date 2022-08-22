# Samples

This folder contains several sample applications that demonstrate different kinds of usage for the **AsyncStateMachine**:

- TaskTracker: A fully functional task tracking application
	- UI: SwiftUI
	- Tech: CoreData
	- Features: Loads, adds, removes tasks in a CoreData database
	- Specific aspects: State machine and side effects are tested in complete isolation, State is mapped to a ViewState for UI rendering
- SearchApis: A search screen that query a REST API
	- UI: SwiftUI
	- Tech: URLSession
	- Features: Queries a rest API
	- Specific aspects: Search field is debounced, pull to refresh triggers a reload, requests are cancelled on new searches