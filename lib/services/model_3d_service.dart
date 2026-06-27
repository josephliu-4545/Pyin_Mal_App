import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;

/// Service to generate and manage 3D models for product viewing
class Model3DService {
  static const String hoodiemodelFileName = 'w_star_wear_p1.glb';

  /// Generate a procedural 3D hoodie model as GLB file or data URL
  static Future<String?> generateHoodie3DModel() async {
    try {
      print('🎨 Generating 3D hoodie model...');

      // Generate GLB mesh
      print('   Generating mesh...');
      final glbData = _generateHoodieGLB();
      print('   Generated GLB data: ${glbData.lengthInBytes} bytes');

      // Try to use file storage (native platforms)
      try {
        print('   Attempting file storage...');
        final dir = await getApplicationDocumentsDirectory();
        print('   App docs dir: ${dir.path}');

        final modelsDir = Directory('${dir.path}/models');

        if (!await modelsDir.exists()) {
          print('   Creating models directory...');
          await modelsDir.create(recursive: true);
        }

        final modelFile = File('${modelsDir.path}/$hoodiemodelFileName');

        if (await modelFile.exists()) {
          print('✓ 3D model already exists at: ${modelFile.path}');
          return modelFile.path;
        }

        print('   Writing to file...');
        await modelFile.writeAsBytes(glbData);

        if (await modelFile.exists()) {
          final fileSize = await modelFile.length();
          print('✅ 3D hoodie model generated successfully');
          print('   Path: ${modelFile.path}');
          print('   Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
          return modelFile.path;
        }
      } catch (fileError) {
        print('⚠️  File storage unavailable (likely web platform): $fileError');
        print('   Falling back to data URL...');

        // Fallback: Use data URL for web
        try {
          final base64Data = base64Encode(glbData);
          final dataUrl = 'data:model/gltf-binary;base64,$base64Data';
          print('✅ 3D hoodie model generated successfully (web/data URL)');
          print('   Data URL size: ${(glbData.lengthInBytes / 1024).toStringAsFixed(2)} KB');
          return dataUrl;
        } catch (dataUrlError) {
          print('❌ Error creating data URL: $dataUrlError');
          return null;
        }
      }
    } catch (e) {
      print('❌ Error generating 3D model: $e');
      print('   Stack trace: ${e.toString()}');
      return null;
    }
  }

  /// Generate GLB (Binary glTF) file with hoodie geometry
  static Uint8List _generateHoodieGLB() {
    // Create hoodie mesh geometry
    final vertices = _generateHoodieMesh();
    final indices = _generateHoodieIndices(vertices);

    // Create binary data
    final vertexData = _floatArrayToBytes(vertices);
    const vertexByteOffset = 0;

    final indexData = _uint32ArrayToBytes(indices);
    final indexByteOffset = vertexData.lengthInBytes;

    final binaryData = BytesBuilder();
    binaryData.add(vertexData);
    binaryData.add(indexData);

    // Create JSON structure
    final json = _createGLTFJSON(
      vertexCount: vertices.length ~/ 3,
      indexCount: indices.length,
      vertexByteOffset: vertexByteOffset,
      vertexByteSize: vertexData.lengthInBytes,
      indexByteOffset: indexByteOffset,
      indexByteSize: indexData.lengthInBytes,
    );

    // Encode JSON to bytes
    final jsonBytes = _stringToUtf8Bytes(json);

    // Pad JSON to 4-byte boundary
    final jsonPadding = 4 - (jsonBytes.length % 4);
    final paddedJsonBytes = BytesBuilder();
    paddedJsonBytes.add(jsonBytes);
    for (int i = 0; i < jsonPadding && jsonPadding < 4; i++) {
      paddedJsonBytes.addByte(0x20); // Space character for padding
    }

    // Create GLB file
    return _createGLBFile(paddedJsonBytes.toBytes(), binaryData.toBytes());
  }

  /// Generate hoodie mesh vertices (x, y, z coordinates)
  static Float32List _generateHoodieMesh() {
    final vertices = <double>[];

    // Body (Cylinder)
    const bodyHeight = 2.0;
    const bodyRadius = 0.4;
    const bodySegments = 24;
    const bodyHeightSegments = 12;

    for (int h = 0; h <= bodyHeightSegments; h++) {
      final heightPercent = h / bodyHeightSegments;
      final y = heightPercent * bodyHeight - bodyHeight / 2;

      for (int s = 0; s < bodySegments; s++) {
        final angle = (s / bodySegments) * 2 * math.pi;
        final x = bodyRadius * math.cos(angle);
        final z = bodyRadius * math.sin(angle);

        vertices.addAll([x, y, z]);
      }
    }

    final bodyVertexCount = (bodyHeightSegments + 1) * bodySegments;

    // Hood (Hemisphere)
    const hoodRadius = 0.35;
    const hoodSegments = 16;
    const hoodHeightSegments = 8;

    for (int h = 0; h <= hoodHeightSegments; h++) {
      final heightAngle = (h / hoodHeightSegments) * (math.pi / 3);

      for (int s = 0; s < hoodSegments; s++) {
        final angle = (s / hoodSegments) * 2 * math.pi;

        final x = hoodRadius * math.sin(heightAngle) * math.cos(angle);
        final z = hoodRadius * math.sin(heightAngle) * math.sin(angle);
        final y = bodyHeight / 2 - 0.1 + hoodRadius * (1 - math.cos(heightAngle));

        vertices.addAll([x, y, z]);
      }
    }

    // Left Arm (Cylinder)
    const armRadius = 0.12;
    const armLength = 0.8;
    const armSegments = 12;
    const armHeightSegments = 6;

    for (int h = 0; h <= armHeightSegments; h++) {
      final length = (h / armHeightSegments) * armLength;

      for (int s = 0; s < armSegments; s++) {
        final angle = (s / armSegments) * 2 * math.pi;

        final x = -bodyRadius - 0.05 - length;
        final y = bodyHeight / 4 + armRadius * math.cos(angle);
        final z = armRadius * math.sin(angle);

        vertices.addAll([x, y, z]);
      }
    }

    // Right Arm (Cylinder)
    for (int h = 0; h <= armHeightSegments; h++) {
      final length = (h / armHeightSegments) * armLength;

      for (int s = 0; s < armSegments; s++) {
        final angle = (s / armSegments) * 2 * math.pi;

        final x = bodyRadius + 0.05 + length;
        final y = bodyHeight / 4 + armRadius * math.cos(angle);
        final z = armRadius * math.sin(angle);

        vertices.addAll([x, y, z]);
      }
    }

    return Float32List.fromList(vertices);
  }

  /// Generate indices for mesh faces
  static Uint32List _generateHoodieIndices(Float32List vertices) {
    final indices = <int>[];

    const bodySegments = 24;
    const bodyHeightSegments = 12;
    const hoodSegments = 16;
    const hoodHeightSegments = 8;
    const armSegments = 12;
    const armHeightSegments = 6;

    int vertexOffset = 0;

    // Body faces
    for (int h = 0; h < bodyHeightSegments; h++) {
      for (int s = 0; s < bodySegments; s++) {
        final s_next = (s + 1) % bodySegments;

        final v0 = vertexOffset + h * bodySegments + s;
        final v1 = vertexOffset + h * bodySegments + s_next;
        final v2 = vertexOffset + (h + 1) * bodySegments + s;
        final v3 = vertexOffset + (h + 1) * bodySegments + s_next;

        indices.addAll([v0, v1, v2]);
        indices.addAll([v1, v3, v2]);
      }
    }

    vertexOffset += (bodyHeightSegments + 1) * bodySegments;

    // Hood faces
    for (int h = 0; h < hoodHeightSegments; h++) {
      for (int s = 0; s < hoodSegments; s++) {
        final s_next = (s + 1) % hoodSegments;

        final v0 = vertexOffset + h * hoodSegments + s;
        final v1 = vertexOffset + h * hoodSegments + s_next;
        final v2 = vertexOffset + (h + 1) * hoodSegments + s;
        final v3 = vertexOffset + (h + 1) * hoodSegments + s_next;

        indices.addAll([v0, v1, v2]);
        indices.addAll([v1, v3, v2]);
      }
    }

    vertexOffset += (hoodHeightSegments + 1) * hoodSegments;

    // Arm faces (left and right, same pattern)
    for (int arm = 0; arm < 2; arm++) {
      for (int h = 0; h < armHeightSegments; h++) {
        for (int s = 0; s < armSegments; s++) {
          final s_next = (s + 1) % armSegments;

          final v0 = vertexOffset + h * armSegments + s;
          final v1 = vertexOffset + h * armSegments + s_next;
          final v2 = vertexOffset + (h + 1) * armSegments + s;
          final v3 = vertexOffset + (h + 1) * armSegments + s_next;

          indices.addAll([v0, v1, v2]);
          indices.addAll([v1, v3, v2]);
        }
      }
      vertexOffset += (armHeightSegments + 1) * armSegments;
    }

    return Uint32List.fromList(indices);
  }

  /// Create glTF JSON structure
  static String _createGLTFJSON({
    required int vertexCount,
    required int indexCount,
    required int vertexByteOffset,
    required int vertexByteSize,
    required int indexByteOffset,
    required int indexByteSize,
  }) {
    return '''{
  "asset": {
    "generator": "PyinMal 3D Model Generator",
    "version": "2.0"
  },
  "scene": 0,
  "scenes": [
    {
      "nodes": [0]
    }
  ],
  "nodes": [
    {
      "mesh": 0,
      "name": "Hoodie"
    }
  ],
  "meshes": [
    {
      "primitives": [
        {
          "attributes": {
            "POSITION": 0
          },
          "indices": 1,
          "material": 0
        }
      ],
      "name": "Hoodie_Mesh"
    }
  ],
  "materials": [
    {
      "doubleSided": true,
      "name": "HoodieMaterial",
      "pbrMetallicRoughness": {
        "baseColorFactor": [0.2, 0.2, 0.2, 1.0],
        "metallicFactor": 0.0,
        "roughnessFactor": 0.8
      }
    }
  ],
  "accessors": [
    {
      "bufferView": 0,
      "componentType": 5126,
      "count": $vertexCount,
      "max": [1.0, 1.0, 1.0],
      "min": [-1.0, -1.0, -1.0],
      "type": "VEC3"
    },
    {
      "bufferView": 1,
      "componentType": 5125,
      "count": $indexCount,
      "type": "SCALAR"
    }
  ],
  "bufferViews": [
    {
      "buffer": 0,
      "byteLength": $vertexByteSize,
      "byteOffset": $vertexByteOffset,
      "target": 34962
    },
    {
      "buffer": 0,
      "byteLength": $indexByteSize,
      "byteOffset": $indexByteOffset,
      "target": 34963
    }
  ],
  "buffers": [
    {
      "byteLength": ${vertexByteSize + indexByteSize}
    }
  ]
}''';
  }

  /// Create GLB file (Binary glTF)
  static Uint8List _createGLBFile(
      Uint8List jsonBytes, Uint8List binaryData) {
    final glb = BytesBuilder();

    // GLB Header
    glb.addByte(0x67); // 'g'
    glb.addByte(0x6C); // 'l'
    glb.addByte(0x54); // 'T'
    glb.addByte(0x46); // 'F'

    // Version (2)
    glb.addByte(0x02);
    glb.addByte(0x00);
    glb.addByte(0x00);
    glb.addByte(0x00);

    // Total file size (will update later)
    const headerSize = 12;
    const chunkHeaderSize = 8;
    final fileSize = headerSize +
        chunkHeaderSize +
        jsonBytes.length +
        chunkHeaderSize +
        binaryData.length;

    glb.add(_uint32ToBytes(fileSize));

    // JSON chunk header
    glb.add(_uint32ToBytes(jsonBytes.length));
    glb.add(_uint32ToBytes(0x4E4F534A)); // "JSON"

    // JSON chunk data
    glb.add(jsonBytes);

    // Binary chunk header
    glb.add(_uint32ToBytes(binaryData.length));
    glb.add(_uint32ToBytes(0x004E4942)); // "BIN\0"

    // Binary chunk data
    glb.add(binaryData);

    return glb.toBytes();
  }

  // Helper functions
  static Uint8List _floatArrayToBytes(Float32List data) {
    return data.buffer.asUint8List(
        data.offsetInBytes, data.lengthInBytes);
  }

  static Uint8List _uint32ArrayToBytes(Uint32List data) {
    return data.buffer.asUint8List(
        data.offsetInBytes, data.lengthInBytes);
  }

  static Uint8List _stringToUtf8Bytes(String str) {
    return Uint8List.fromList(str.codeUnits);
  }

  static Uint8List _uint32ToBytes(int value) {
    final bytes = Uint8List(4);
    bytes[0] = value & 0xFF;
    bytes[1] = (value >> 8) & 0xFF;
    bytes[2] = (value >> 16) & 0xFF;
    bytes[3] = (value >> 24) & 0xFF;
    return bytes;
  }
}
