---
title: Documentation Standards - Philosophy & Language Guidelines
description: Philosophy, universal requirements, language-specific doc standards (Dart/Flutter and TypeScript/Node.js), and structural requirements.
tags:
  - documentation
  - dart
  - flutter
  - typescript
  - nodejs
---

# Documentation Standards - Philosophy & Language Guidelines

## Philosophy

Documentation is not optional. It is a critical component of code quality and project sustainability. Every piece of code must be thoroughly documented with the assumption that another developer will need to understand, maintain, and extend the work.

**Core Principle**: Code without proper documentation is incomplete code.

## Universal Documentation Requirements

### Mandatory Documentation for ALL Code Entities

Every single code entity across the entire project must include documentation:

- **Classes and Interfaces**: Purpose, usage patterns, and relationships
- **Functions and Methods**: Parameters, return values, side effects, and examples
- **Fields and Properties**: Purpose, expected values, and constraints
- **Enums and Constants**: Meaning and usage context
- **Type Definitions**: Structure and intended use cases
- **Configuration Objects**: All properties and their effects
- **API Endpoints**: Request/response formats and behavior
- **Database Schemas**: Table purposes and field meanings
- **Environment Variables**: Purpose and expected values

## Language-Specific Documentation Standards

### Dart/Flutter Documentation

Use Dartdoc format with triple slashes (`///`) for all public and private entities:

```dart
/// Manages the lifecycle and state of household applications.
/// 
/// This controller handles application creation, modification, deployment,
/// and monitoring. It serves as the primary interface between the UI and
/// the backend orchestration services.
class ApplicationController extends ChangeNotifier {
  /// The API service used for backend communication.
  /// 
  /// This service handles all HTTP requests to the orchestrator backend
  /// and manages authentication, retries, and error handling.
  final ApiService _apiService;

  /// WebSocket service for receiving real-time progress updates.
  /// 
  /// Automatically reconnects on connection loss and buffers messages
  /// during temporary disconnections.
  final WebSocketService _webSocketService;

  /// List of all applications currently managed by this controller.
  /// 
  /// Applications are sorted by creation date (newest first) and
  /// automatically updated when backend state changes.
  List<Application> _applications = [];

  /// Whether the controller is currently loading data from the backend.
  /// 
  /// Used by UI components to show loading indicators and prevent
  /// duplicate requests during ongoing operations.
  bool _isLoading = false;

  /// Current error message, if any operation has failed.
  /// 
  /// Null when no error is present. Automatically cleared when
  /// a successful operation completes.
  String? _error;

  /// Creates a new application controller with required services.
  /// 
  /// Both [apiService] and [webSocketService] must be properly initialized
  /// before passing to this constructor.
  /// 
  /// Throws [ArgumentError] if either service is null.
  ApplicationController(this._apiService, this._webSocketService) {
    ArgumentError.checkNotNull(_apiService, 'apiService');
    ArgumentError.checkNotNull(_webSocketService, 'webSocketService');
    _initializeWebSocketListeners();
  }

  /// Returns an immutable view of all applications.
  /// 
  /// Applications are automatically sorted by creation date with
  /// the most recently created applications first.
  List<Application> get applications => List.unmodifiable(_applications);

  /// Whether the controller is currently performing a loading operation.
  /// 
  /// UI components should show loading indicators when this is true
  /// and disable user interactions that could conflict with ongoing operations.
  bool get isLoading => _isLoading;

  /// Current error message from the most recent failed operation.
  /// 
  /// Returns null when no error is present. Error messages are
  /// user-friendly and suitable for display in the UI.
  String? get error => _error;

  /// Creates a new application based on the user's natural language request.
  /// 
  /// This method processes the [userRequest] through the conversation system,
  /// generates a specification, and initiates the development process.
  /// 
  /// Returns a [Future<Application>] that completes when the application
  /// is successfully queued for development.
  Future<Application> createApplication(
    String userRequest, {
    String? conversationId,
  }) async {
    // Implementation details...
  }

  /// Initializes WebSocket listeners for real-time updates.
  /// 
  /// Sets up handlers for progress updates, status changes, and error
  /// notifications. Automatically attempts reconnection on connection loss.
  void _initializeWebSocketListeners() {
    // Implementation details...
  }
}
```

### TypeScript/Node.js Documentation

Use JSDoc format for all TypeScript code:

```typescript
/**
 * Orchestrates the development and deployment of user-requested applications.
 * 
 * This service manages the complete lifecycle from user request to deployed
 * application, including specification generation, Kiro integration, and
 * container deployment.
 */
export class ApplicationOrchestrator {
  /**
   * API client for communicating with external services.
   * 
   * Handles authentication, rate limiting, and retry logic for all
   * external API calls including Kiro development sessions.
   */
  private readonly apiClient: ApiClient;

  /**
   * Service for managing Amazon Kiro development sessions.
   * 
   * Provides headless development capabilities with progress monitoring
   * and artifact collection.
   */
  private readonly kiroService: KiroService;

  /**
   * In-memory cache of active development jobs.
   * 
   * Maps job IDs to their current status and progress information.
   * Automatically cleaned up when jobs complete or fail.
   */
  private readonly activeJobs = new Map<string, DevelopmentJob>();

  /**
   * Creates a new application orchestrator with required dependencies.
   * 
   * @param apiClient - Configured API client for external service communication
   * @param kiroService - Service for managing Kiro development sessions
   * @throws {Error} If either dependency is null or undefined
   */
  constructor(apiClient: ApiClient, kiroService: KiroService) {
    if (!apiClient) {
      throw new Error('apiClient is required');
    }
    if (!kiroService) {
      throw new Error('kiroService is required');
    }
    
    this.apiClient = apiClient;
    this.kiroService = kiroService;
  }

  /**
   * Creates a new application from a user's natural language request.
   * 
   * This method handles the complete workflow:
   * 1. Parses and validates the user request
   * 2. Generates a technical specification
   * 3. Creates a development job in Kiro
   * 4. Monitors progress and collects artifacts
   * 5. Deploys the completed application
   * 
   * @param request - The user's application request
   * @param options - Optional configuration for the creation process
   * @returns Promise that resolves to the created application metadata
   * 
   * @throws {ValidationError} When the user request is invalid or incomplete
   * @throws {QuotaExceededError} When the user has reached their application limit
   * @throws {ServiceUnavailableError} When required services are unavailable
   * ```
   */
  async createApplication(
    request: ApplicationRequest,
    options: CreateApplicationOptions = {}
  ): Promise<Application> {
    // Implementation details...
  }
}

/**
 * Configuration options for application creation.
 * 
 * These options control various aspects of the development and deployment
 * process, allowing customization based on user preferences or system constraints.
 */
export interface CreateApplicationOptions {
  /**
   * Priority level for the development job.
   * 
   * Higher priority jobs are processed first when multiple requests
   * are queued. Default is 'normal'.
   * 
   * @default 'normal'
   */
  priority?: 'low' | 'normal' | 'high';

  /**
   * Maximum time to wait for application completion in milliseconds.
   * 
   * Jobs that exceed this timeout are automatically cancelled and
   * marked as failed. Default is 30 minutes.
   * 
   * @default 1800000
   */
  timeoutMs?: number;

  /**
   * Whether to enable debug logging for this application creation.
   * 
   * When enabled, detailed logs are collected and stored for
   * troubleshooting purposes. Default is false.
   * 
   * @default false
   */
  enableDebugLogging?: boolean;
}
```

## Documentation Structure Requirements

### File-Level Documentation

Every source file must begin with a comprehensive header:

```dart
/// Application Controller Module
/// 
/// This module contains the primary controller for managing household applications
/// within the Flutter dashboard. It handles the complete application lifecycle
/// from creation through deployment and monitoring.
```

### Complex Algorithm Documentation

For any non-trivial logic, provide detailed explanations:

```dart
/// Calculates the optimal grid layout for application tiles.
/// 
/// This algorithm balances several competing factors:
/// 1. Minimum tile width for readability (200px)
/// 2. Maximum screen utilization
/// 3. Consistent spacing between tiles
/// 4. Responsive behavior across screen sizes
/// 
/// The calculation works as follows:
/// 1. Subtract fixed margins from available width
/// 2. Calculate maximum possible columns based on minimum tile width
/// 3. Account for spacing between tiles in the calculation
/// 4. Ensure at least one column is always shown
/// 5. Apply breakpoint-based constraints for better UX
int calculateOptimalColumns(double availableWidth, double tileSpacing) {
  const double minTileWidth = 200.0;
  const double marginWidth = 32.0; // 16px on each side
  
  // Step 1: Calculate usable width after margins
  final usableWidth = availableWidth - marginWidth;
  
  // Step 2: Calculate theoretical maximum columns
  // Formula: (usableWidth + spacing) / (minTileWidth + spacing)
  // The +spacing accounts for the fact that we need spacing after each tile
  // except the last one, but this simplifies the calculation
  final theoreticalColumns = (usableWidth + tileSpacing) / (minTileWidth + tileSpacing);
  
  // Step 3: Apply practical constraints
  final maxColumns = theoreticalColumns.floor();
  final constrainedColumns = math.max(1, maxColumns);
  
  // Step 4: Apply responsive breakpoints for better UX
  if (availableWidth < 600) return math.min(constrainedColumns, 2);
  if (availableWidth < 1200) return math.min(constrainedColumns, 3);
  return math.min(constrainedColumns, 4); // Maximum 4 columns for readability
}
```
