#!/usr/bin/env python3
"""
Generate 3D Hoodie Model from 2D Texture Image
Creates a procedural 3D hoodie mesh with texture mapping
Exports to GLB format for Flutter integration
"""

import numpy as np
import os
from pathlib import Path

# Try to import required libraries
try:
    import trimesh
    from PIL import Image
except ImportError:
    print("❌ Required libraries not found. Install with:")
    print("   pip install trimesh pillow numpy")
    exit(1)


def create_hoodie_mesh():
    """
    Create a procedural 3D hoodie mesh
    Basic shapes: cylinder body, spherical hood, cylinder arms
    """
    vertices = []
    faces = []
    uv_coords = []

    # Parameters
    body_height = 2.0
    body_radius = 0.4
    arm_radius = 0.15
    arm_length = 0.8
    hood_radius = 0.35

    vertex_offset = 0

    # === CREATE BODY (Cylinder) ===
    segments = 32
    height_segments = 16

    for h in range(height_segments + 1):
        height = (h / height_segments) * body_height
        for s in range(segments):
            angle = (s / segments) * 2 * np.pi
            x = body_radius * np.cos(angle)
            z = body_radius * np.sin(angle)
            y = height - body_height / 2
            vertices.append([x, y, z])

            # UV coordinates: wrap around body
            u = s / segments
            v = h / height_segments
            uv_coords.append([u, v * 0.6])  # Body takes 60% of texture height

    # Create body faces
    for h in range(height_segments):
        for s in range(segments):
            s_next = (s + 1) % segments

            # Two triangles per quad
            v0 = vertex_offset + h * segments + s
            v1 = vertex_offset + h * segments + s_next
            v2 = vertex_offset + (h + 1) * segments + s
            v3 = vertex_offset + (h + 1) * segments + s_next

            faces.append([v0, v1, v2])
            faces.append([v1, v3, v2])

    vertex_offset = len(vertices)

    # === CREATE HOOD (Partial Sphere) ===
    hood_segments = 16
    hood_height_segments = 12

    for h in range(hood_height_segments + 1):
        for s in range(hood_segments):
            angle = (s / hood_segments) * 2 * np.pi
            height_angle = (h / hood_height_segments) * (np.pi / 3)  # Partial sphere

            x = hood_radius * np.sin(height_angle) * np.cos(angle)
            z = hood_radius * np.sin(height_angle) * np.sin(angle)
            y = body_height / 2 - 0.1 + hood_radius * (1 - np.cos(height_angle))

            vertices.append([x, y, z])

            # UV coordinates: hood texture
            u = s / hood_segments
            v = 0.6 + (h / hood_height_segments) * 0.4  # Hood takes 40% from 60-100%
            uv_coords.append([u, v])

    # Create hood faces
    for h in range(hood_height_segments):
        for s in range(hood_segments):
            s_next = (s + 1) % hood_segments

            v0 = vertex_offset + h * hood_segments + s
            v1 = vertex_offset + h * hood_segments + s_next
            v2 = vertex_offset + (h + 1) * hood_segments + s
            v3 = vertex_offset + (h + 1) * hood_segments + s_next

            faces.append([v0, v1, v2])
            faces.append([v1, v3, v2])

    vertex_offset = len(vertices)

    # === CREATE LEFT ARM ===
    arm_segments = 16
    arm_height_segments = 8

    for h in range(arm_height_segments + 1):
        for s in range(arm_segments):
            angle = (s / arm_segments) * 2 * np.pi
            length = (h / arm_height_segments) * arm_length

            # Left arm (negative X)
            x = -body_radius - 0.05 - length
            y = body_height / 4 + arm_radius * np.cos(angle)
            z = arm_radius * np.sin(angle)

            vertices.append([x, y, z])

            # UV coordinates - split between left and right arms
            u = length / arm_length * 0.25  # Left arm: 0-25%
            v = s / arm_segments
            uv_coords.append([u, v])

    # Create left arm faces
    for h in range(arm_height_segments):
        for s in range(arm_segments):
            s_next = (s + 1) % arm_segments

            v0 = vertex_offset + h * arm_segments + s
            v1 = vertex_offset + h * arm_segments + s_next
            v2 = vertex_offset + (h + 1) * arm_segments + s
            v3 = vertex_offset + (h + 1) * arm_segments + s_next

            faces.append([v0, v1, v2])
            faces.append([v1, v3, v2])

    vertex_offset = len(vertices)

    # === CREATE RIGHT ARM ===
    for h in range(arm_height_segments + 1):
        for s in range(arm_segments):
            angle = (s / arm_segments) * 2 * np.pi
            length = (h / arm_height_segments) * arm_length

            # Right arm (positive X)
            x = body_radius + 0.05 + length
            y = body_height / 4 + arm_radius * np.cos(angle)
            z = arm_radius * np.sin(angle)

            vertices.append([x, y, z])

            # UV coordinates - right arm: 25-50%
            u = 0.25 + (length / arm_length * 0.25)
            v = s / arm_segments
            uv_coords.append([u, v])

    # Create right arm faces
    for h in range(arm_height_segments):
        for s in range(arm_segments):
            s_next = (s + 1) % arm_segments

            v0 = vertex_offset + h * arm_segments + s
            v1 = vertex_offset + h * arm_segments + s_next
            v2 = vertex_offset + (h + 1) * arm_segments + s
            v3 = vertex_offset + (h + 1) * arm_segments + s_next

            faces.append([v0, v1, v2])
            faces.append([v1, v3, v2])

    # Convert to numpy arrays
    vertices = np.array(vertices, dtype=np.float64)
    faces = np.array(faces, dtype=np.uint32)
    uv_coords = np.array(uv_coords, dtype=np.float32)

    # Create trimesh object
    mesh = trimesh.Trimesh(vertices=vertices, faces=faces)

    # Store UV coordinates as visual attribute
    mesh.visual.uv = uv_coords

    return mesh


def apply_texture(mesh, texture_path):
    """
    Apply texture image to the mesh
    """
    if not os.path.exists(texture_path):
        print(f"⚠️  Warning: Texture file not found at {texture_path}")
        print("   Creating white placeholder texture...")
        # Create placeholder white texture
        img = Image.new('RGB', (1024, 1024), color='white')
    else:
        print(f"✓ Loading texture from: {texture_path}")
        img = Image.open(texture_path)

        # Resize to standard size if needed
        if img.size != (1024, 1024):
            print(f"  Resizing texture to 1024x1024...")
            img = img.resize((1024, 1024), Image.Resampling.LANCZOS)

    # Apply as simple material
    # Note: GLB will use basic material; texture is embedded
    mesh.visual.image = img

    return mesh


def generate_model(output_path='assets/models/hoodie.glb'):
    """
    Main function: Generate 3D hoodie model and export to GLB
    """
    print("\n" + "="*60)
    print("🎨 3D HOODIE MODEL GENERATOR")
    print("="*60 + "\n")

    # Create output directory if needed
    output_dir = os.path.dirname(output_path)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"✓ Created directory: {output_dir}")

    # Step 1: Create mesh
    print("📐 Creating 3D hoodie mesh...")
    mesh = create_hoodie_mesh()
    print(f"   Vertices: {len(mesh.vertices)}")
    print(f"   Faces: {len(mesh.faces)}")

    # Step 2: Apply texture
    print("\n🖼️  Applying texture...")
    texture_path = 'assets/images/hoodie_texture.png'
    mesh = apply_texture(mesh, texture_path)

    # Step 3: Fix normals (important for proper lighting)
    print("\n✨ Computing normals...")
    mesh.fix_normals()

    # Step 4: Export to GLB
    print(f"\n💾 Exporting to GLB format...")
    print(f"   Output: {output_path}")

    # Export with texture embedded
    mesh.export(output_path, file_type='glb')

    # Verify file
    if os.path.exists(output_path):
        file_size = os.path.getsize(output_path)
        print(f"\n✅ SUCCESS!")
        print(f"   File size: {file_size / 1024 / 1024:.2f} MB")
        print(f"   Ready for integration! 🚀")
        return True
    else:
        print(f"\n❌ ERROR: File was not created")
        return False


if __name__ == '__main__':
    success = generate_model()

    if success:
        print("\n" + "="*60)
        print("Next steps:")
        print("  1. Update pubspec.yaml with model asset")
        print("  2. Run: flutter pub get")
        print("  3. Add model_viewer package")
        print("  4. Update product_detail_screen.dart")
        print("="*60 + "\n")
