---
title: Documentation Standards
description: Detailed documentation requirements for all code entities. Covers Dart, TypeScript, SQL, and testing documentation with detailed examples and enforcement checklists.
tags:
  - documentation
  - dart
  - typescript
  - sql
  - api
  - testing
---


# Documentation Standards

## Philosophy

Documentation is not optional. It is a critical component of code quality and project sustainability. Every piece of must be thoroughly documented with the assumption that another developer will need to understand, maintain, and extend the work.

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

## API Documentation Standards

### REST Endpoint Documentation

```typescript
/**
 * Creates a new household application based on user requirements.
 * 
 * This endpoint processes natural language requests and initiates the
 * application development workflow through the Kiro integration.
 * 
 * @route POST /api/applications
 * @access Private - Requires valid user authentication
 * @rateLimit 10 requests per minute per user
 * 
 * @param {ApplicationCreateRequest} body - Application creation request
 * @param {string} body.description - Natural language description of desired app
 * @param {string} body.userId - ID of the requesting user
 * @param {string} [body.conversationId] - Optional conversation context ID
 * @param {'low'|'normal'|'high'} [body.priority='normal'] - Development priority
 * 
 * @returns {Promise<ApplicationCreateResponse>} Created application metadata
 * @returns {string} returns.id - Unique application identifier
 * @returns {string} returns.title - Generated application title
 * @returns {string} returns.description - Processed application description
 * @returns {'requested'|'developing'|'ready'|'failed'} returns.status - Current status
 * @returns {string} returns.createdAt - ISO timestamp of creation
 * @returns {DevelopmentProgress} returns.progress - Initial progress information
 * 
 * @throws {400} ValidationError - Invalid or incomplete request data
 * @throws {401} AuthenticationError - Missing or invalid authentication
 * @throws {403} QuotaExceededError - User has reached application limit
 * @throws {429} RateLimitError - Too many requests from user
 * @throws {500} InternalServerError - Unexpected server error
 * 
 * @example
 * ```typescript
 * // Request
 * POST /api/applications
 * Content-Type: application/json
 * Authorization: Bearer <token>
 * 
 * {
 *   "description": "I need a family chore tracker with weekly rotation",
 *   "userId": "user_123",
 *   "priority": "normal"
 * }
 * 
 * // Response (201 Created)
 * {
 *   "id": "app_456",
 *   "title": "Family Chore Tracker",
 *   "description": "A household chore management system with weekly rotation scheduling",
 *   "status": "requested",
 *   "createdAt": "2025-01-10T14:30:00Z",
 *   "progress": {
 *     "percentage": 0,
 *     "currentPhase": "Analyzing Requirements",
 *     "estimatedCompletion": "2025-01-10T15:00:00Z"
 *   }
 * }
 * ```
 */
export async function createApplication(req: Request, res: Response): Promise<void> {
  // Implementation...
}
```

## Database Schema Documentation

```sql
-- Applications table stores metadata for all user-created applications
-- This is the primary table for application management and tracking
CREATE TABLE applications (
    -- Primary key: Unique identifier for each application
    -- Format: UUID v4 for global uniqueness across distributed systems
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- User-facing application title generated from the description
    -- Max length chosen to fit comfortably in UI tiles (50 chars)
    -- NOT NULL ensures every application has a displayable name
    title VARCHAR(50) NOT NULL,
    
    -- Detailed description of the application's purpose and functionality
    -- Supports markdown formatting for rich text display in UI
    -- Length limit prevents abuse while allowing detailed descriptions
    description TEXT NOT NULL CHECK (length(description) <= 2000),
    
    -- Current status in the application lifecycle
    -- Enum values correspond to UI states and workflow stages
    status application_status NOT NULL DEFAULT 'requested',
    
    -- ID of the user who created this application
    -- Foreign key to users table with cascade delete for data cleanup
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Timestamp when the application was first requested
    -- Used for sorting and analytics, immutable after creation
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Timestamp of the last status or metadata update
    -- Automatically updated by triggers on any row modification
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- JSON blob containing development progress information
    -- Includes percentage, current phase, milestones, and logs
    -- Nullable because progress doesn't exist until development starts
    progress JSONB,
    
    -- JSON blob containing deployment configuration
    -- Includes container settings, port mappings, and health checks
    -- Nullable because deployment config is generated during development
    deployment_config JSONB,
    
    -- Path to the application's source code and artifacts
    -- Relative to the configured app capsules directory
    -- Format: "app-capsules/{app_id}/"
    capsule_path VARCHAR(255),
    
    -- Resource limits and quotas for the deployed application
    -- JSON structure with CPU, memory, disk, and network limits
    -- Used by container manager for resource enforcement
    resource_limits JSONB DEFAULT '{"cpu": "0.5", "memory": "512Mi", "disk": "1Gi"}'::jsonb
);

-- Index for efficient user-based queries (dashboard loading)
-- Covers the most common query pattern: fetch all apps for a user
CREATE INDEX idx_applications_user_id_created_at 
ON applications(user_id, created_at DESC);

-- Index for status-based queries (monitoring and cleanup jobs)
-- Supports efficient filtering by status for background processes
CREATE INDEX idx_applications_status 
ON applications(status) 
WHERE status IN ('developing', 'failed');

-- Trigger to automatically update the updated_at timestamp
-- Ensures accurate tracking of when records are modified
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$ language 'plpgsql';

CREATE TRIGGER update_applications_updated_at 
    BEFORE UPDATE ON applications 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
```

## Error Documentation Standards

All error types must be thoroughly documented:

```dart
/// Base class for all application-related errors in the system.
/// 
/// This hierarchy provides structured error handling with consistent
/// error codes, user-friendly messages, and debugging information.
/// All errors include context for logging and user feedback.
abstract class ApplicationError implements Exception {
  /// Human-readable error message suitable for display to users.
  /// 
  /// This message should be clear, actionable, and free of technical jargon.
  /// It should guide users toward resolution when possible.
  final String message;
  
  /// Unique error code for programmatic error handling.
  /// 
  /// Format: "APP_CATEGORY_SPECIFIC" (e.g., "APP_VALIDATION_MISSING_TITLE")
  /// Used by error tracking systems and automated recovery logic.
  final String code;
  
  /// Optional underlying cause of this error.
  /// 
  /// When this error wraps another exception, the original exception
  /// is preserved here for debugging and logging purposes.
  final Object? cause;
  
  /// Additional context information for debugging.
  /// 
  /// May include request IDs, user IDs, timestamps, or other relevant
  /// data that helps with troubleshooting and error analysis.
  final Map<String, dynamic> context;

  /// Creates a new application error with required information.
  const ApplicationError(
    this.message,
    this.code, {
    this.cause,
    this.context = const {},
  });

  @override
  String toString() => 'ApplicationError($code): $message';
}

/// Error thrown when user input fails validation requirements.
/// 
/// This error indicates that the user's request cannot be processed
/// due to missing, invalid, or malformed input data. The error message
/// should guide the user toward providing correct input.
/// 
/// Common scenarios:
/// * Missing required fields in application requests
/// * Invalid format for user input (e.g., malformed email)
/// * Input that violates business rules or constraints
/// 
/// Recovery: User should correct the input and retry the operation.
class ValidationError extends ApplicationError {
  /// The specific field or input that failed validation.
  /// 
  /// Used by UI components to highlight problematic fields
  /// and provide targeted error feedback to users.
  final String? field;
  
  /// The value that failed validation.
  /// 
  /// Included for debugging purposes but should not be displayed
  /// to users as it may contain sensitive information.
  final dynamic invalidValue;

  /// Creates a validation error for a specific field and value.
  const ValidationError(
    String message, {
    this.field,
    this.invalidValue,
    Map<String, dynamic> context = const {},
  }) : super(
    message,
    'APP_VALIDATION_FAILED',
    context: context,
  );

  /// Creates a validation error for a missing required field.
  factory ValidationError.missingField(String field) {
    return ValidationError(
      'The $field field is required but was not provided.',
      field: field,
      context: {'errorType': 'missing_field'},
    );
  }

  /// Creates a validation error for an invalid field format.
  factory ValidationError.invalidFormat(
    String field,
    String expectedFormat,
    dynamic actualValue,
  ) {
    return ValidationError(
      'The $field field must be in $expectedFormat format.',
      field: field,
      invalidValue: actualValue,
      context: {
        'errorType': 'invalid_format',
        'expectedFormat': expectedFormat,
      },
    );
  }
}
```

## Testing Documentation Standards

All tests must include comprehensive documentation:

```dart
/// Test suite for ApplicationController functionality.
/// 
/// This test suite covers all public methods and edge cases for the
/// ApplicationController class, ensuring reliable behavior across
/// different scenarios and error conditions.
/// 
/// Test Categories:
/// * Initialization and dependency injection
/// * Application creation workflow
/// * Real-time progress updates
/// * Error handling and recovery
/// * State management and UI binding
/// 
/// Mock Dependencies:
/// * MockApiService - Simulates backend API responses
/// * MockWebSocketService - Simulates real-time updates
/// * MockNotificationService - Captures notification calls
void main() {
  group('ApplicationController', () {
    late ApplicationController controller;
    late MockApiService mockApiService;
    late MockWebSocketService mockWebSocketService;
    late MockNotificationService mockNotificationService;

    /// Set up test dependencies and controller instance.
    /// 
    /// Creates fresh mock instances for each test to ensure isolation
    /// and prevent test interference. All mocks are configured with
    /// default successful responses unless overridden in specific tests.
    setUp(() {
      mockApiService = MockApiService();
      mockWebSocketService = MockWebSocketService();
      mockNotificationService = MockNotificationService();
      
      // Configure default successful responses
      when(mockApiService.getApplications())
          .thenAnswer((_) async => Right([]));
      when(mockWebSocketService.connect())
          .thenAnswer((_) async => {});
      
      controller = ApplicationController(
        mockApiService,
        mockWebSocketService,
        mockNotificationService,
      );
    });

    /// Clean up resources after each test.
    /// 
    /// Ensures proper disposal of controllers and clears any
    /// lingering state that could affect subsequent tests.
    tearDown(() {
      controller.dispose();
    });

    group('initialization', () {
      /// Verifies that the controller properly validates required dependencies.
      /// 
      /// This test ensures that the controller fails fast with clear error
      /// messages when required services are not provided, preventing
      /// runtime errors later in the application lifecycle.
      test('should throw ArgumentError when apiService is null', () {
        expect(
          () => ApplicationController(
            null, // Invalid null service
            mockWebSocketService,
            mockNotificationService,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      /// Verifies that WebSocket listeners are properly initialized.
      /// 
      /// This test confirms that the controller sets up real-time update
      /// handlers during initialization, ensuring that progress updates
      /// and status changes are received from the backend.
      test('should initialize WebSocket listeners on creation', () async {
        // Verify that WebSocket connection was attempted
        verify(mockWebSocketService.connect()).called(1);
        
        // Verify that progress update handler was registered
        verify(mockWebSocketService.onProgressUpdate(any)).called(1);
        
        // Verify that status change handler was registered
        verify(mockWebSocketService.onStatusChange(any)).called(1);
      });
    });

    group('createApplication', () {
      /// Tests successful application creation with valid user input.
      /// 
      /// This test verifies the complete happy path workflow:
      /// 1. User request is validated and processed
      /// 2. Backend API is called with correct parameters
      /// 3. Application is added to the local state
      /// 4. UI listeners are notified of the change
      /// 5. Success notification is displayed to user
      test('should create application successfully with valid request', () async {
        // Arrange: Set up successful API response
        final expectedApp = Application(
          id: 'app_123',
          title: 'Test Application',
          description: 'A test application for unit testing',
          status: ApplicationStatus.requested,
          createdAt: DateTime.now(),
        );
        
        when(mockApiService.createApplication(any))
            .thenAnswer((_) async => Right(expectedApp));

        // Act: Create application with valid request
        final result = await controller.createApplication(
          'I need a test application for my household',
        );

        // Assert: Verify successful creation and state updates
        expect(result, equals(expectedApp));
        expect(controller.applications, contains(expectedApp));
        expect(controller.isLoading, false);
        expect(controller.error, null);
        
        // Verify API was called with correct parameters
        verify(mockApiService.createApplication(
          argThat(predicate<ApplicationRequest>((req) =>
            req.description == 'I need a test application for my household'
          )),
        )).called(1);
        
        // Verify success notification was shown
        verify(mockNotificationService.showSuccess(
          'Application "Test Application" created successfully',
        )).called(1);
      });

      /// Tests error handling when backend API fails.
      /// 
      /// This test ensures that network errors and backend failures
      /// are properly handled without crashing the application:
      /// 1. API failure is caught and wrapped in appropriate error type
      /// 2. Error state is updated for UI display
      /// 3. Loading state is properly cleared
      /// 4. User is notified of the failure with actionable message
      test('should handle API errors gracefully', () async {
        // Arrange: Configure API to return error
        final apiError = NetworkError('Backend service unavailable');
        when(mockApiService.createApplication(any))
            .thenAnswer((_) async => Left(apiError));

        // Act: Attempt to create application
        expect(
          () => controller.createApplication('Test request'),
          throwsA(isA<NetworkError>()),
        );

        // Assert: Verify error state is properly set
        expect(controller.isLoading, false);
        expect(controller.error, 'Backend service unavailable');
        expect(controller.applications, isEmpty);
        
        // Verify error notification was shown
        verify(mockNotificationService.showError(
          'Failed to create application: Backend service unavailable',
        )).called(1);
      });
    });
  });
}
```

## Anti-Patterns and Unacceptable Comment Formats

### Avoid Decorative Section Comments

Do not use decorative section comments such as:

```dart
// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
```

These comments add visual noise, increase file length, and do not provide any navigation benefits.

When a section marker is useful for organizing a file, use a `MARK:` comment instead:

```dart
// MARK: Constants
```

Many IDEs recognize `MARK:` comments and expose them in the file outline or navigation menu, making it easier to jump between logical sections of a file. Keep `MARK:` comments concise and use them only to identify meaningful, high-level sections of a file.


## Enforcement and Quality Assurance

### Documentation Review Checklist

Before any code is considered complete, verify:

- [ ] Every class has a comprehensive doc comment with purpose and usage
- [ ] Every public method has parameter and return value documentation
- [ ] Every field/property has a clear description of its purpose
- [ ] Complex algorithms include step-by-step explanations
- [ ] Error conditions and exceptions are documented
- [ ] Examples are provided for non-trivial usage patterns
- [ ] Dependencies and relationships are clearly explained
- [ ] Performance characteristics are noted where relevant
- [ ] Thread safety and concurrency considerations are documented
- [ ] Deprecation notices include migration guidance

### Documentation Quality Standards

Documentation must be:

1. **Accurate**: Reflects the actual behavior of the code
2. **Complete**: Covers all public interfaces and important private methods
3. **Clear**: Written in plain language accessible to other developers
4. **Consistent**: Follows established patterns and terminology
5. **Maintainable**: Updated whenever code changes
6. **Actionable**: Provides concrete guidance for usage and troubleshooting

### Conclusion

Remember: **Undocumented code is incomplete code.** All code must include appropriate documentation that enables future developers to understand, maintain, and extend the system effectively.
