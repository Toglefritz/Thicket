/// Thicket Agent Server
///
/// Entrypoint for the event-driven Thicket agent. Initializes Genkit with the registered world model tools, then
/// starts a Shelf HTTP server with endpoints for event processing and project registration.
library;

import 'dart:convert';
import 'dart:io';

import 'package:genkit/genkit.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/src/event_processor.dart';
import '../lib/src/genkit_setup.dart';
import '../lib/src/registration_handler.dart';

void main(List<String> args) async {
  final Genkit ai = initializeGenkit();

  final Router router = Router()
    ..post('/projects', handleProjectRegistration)
    ..post('/events', (Request request) async {
      final String payloadString = await request.readAsString();
      final Map<String, dynamic> body =
          jsonDecode(payloadString) as Map<String, dynamic>;

      final String? source = body['source'] as String?;
      final String? eventType = body['eventType'] as String?;
      final String? thicketProjectId = body['thicketProjectId'] as String?;
      final Map<String, dynamic> payload =
          body['payload'] as Map<String, dynamic>? ?? <String, dynamic>{};

      if (source == null || eventType == null || thicketProjectId == null) {
        return Response.badRequest(
            body:
                'Missing required parameters: source, eventType, thicketProjectId');
      }

      final String apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        return Response.internalServerError(
            body: 'GEMINI_API_KEY environment variable is not set');
      }

      try {
        final String summary = await processEvent(
          ai: ai,
          source: source,
          eventType: eventType,
          thicketProjectId: thicketProjectId,
          payload: payload,
        );

        return Response.ok(
          jsonEncode(
            <String, dynamic>{'status': 'success', 'summary': summary},
          ),
          headers: <String, String>{'content-type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });

  final String portStr = Platform.environment['PORT'] ?? '8080';
  final int port = int.tryParse(portStr) ?? 8080;

  final HttpServer server =
      await io.serve(router.call, InternetAddress.anyIPv4, port);

  print('Thicket Agent listening on port ${server.port}');
}
