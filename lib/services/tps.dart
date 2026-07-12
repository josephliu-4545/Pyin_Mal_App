import 'dart:math' as math;
import 'dart:ui' show Offset;

// ─────────────────────────────────────────────────────────────────────────────
// ThinPlateSpline
//
// A 2D → 2D thin-plate-spline warp. Given a set of SOURCE control points and
// where each one should MOVE TO (destination), it produces a smooth mapping
// that (a) sends every source point exactly onto its destination and
// (b) bends the space between them as smoothly as possible.
//
// This is the classic image-based virtual try-on warp: the source points are
// the garment's anchor pixels (neck / shoulders / elbows / hips inside the PNG)
// and the destinations are the live body landmarks from pose detection. Sample
// a grid of pixels through [transform] to get a warped mesh you can hand to
// Canvas.drawVertices.
//
// Math:
//   kernel U(r) = r² · ln(r)
//   Solve  L · [w ; a] = [v ; 0]
//     where L = [[K, P], [Pᵀ, 0]],  K_ij = U(‖Pi − Pj‖),  P_i = [1, xi, yi]
//   Then   f(p) = a0 + a1·x + a2·y + Σ w_i · U(‖p − Pi‖)
//   solved independently for the x- and y-outputs.
//
// Control-point count is tiny (5–9), so rebuilding the spline every frame is
// cheap.
// ─────────────────────────────────────────────────────────────────────────────
class ThinPlateSpline {
  final List<Offset> _src;
  final List<double> _xCoef; // length n + 3
  final List<double> _yCoef;

  ThinPlateSpline._(this._src, this._xCoef, this._yCoef);

  /// Builds a spline mapping each [src] point onto the matching [dst] point.
  /// [src] and [dst] must be the same length and >= 3 (non-collinear) points.
  factory ThinPlateSpline(List<Offset> src, List<Offset> dst) {
    assert(src.length == dst.length);
    final n = src.length;
    final size = n + 3;

    // L matrix
    final L = List.generate(size, (_) => List<double>.filled(size, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        L[i][j] = _kernel((src[i] - src[j]).distance);
      }
      L[i][n] = 1.0;
      L[i][n + 1] = src[i].dx;
      L[i][n + 2] = src[i].dy;
      L[n][i] = 1.0;
      L[n + 1][i] = src[i].dx;
      L[n + 2][i] = src[i].dy;
    }

    // Right-hand sides (destination x and y; last 3 rows are 0)
    final bx = List<double>.filled(size, 0.0);
    final by = List<double>.filled(size, 0.0);
    for (int i = 0; i < n; i++) {
      bx[i] = dst[i].dx;
      by[i] = dst[i].dy;
    }

    return ThinPlateSpline._(
      List<Offset>.from(src),
      _solve(L, bx),
      _solve(L, by),
    );
  }

  static double _kernel(double r) {
    if (r <= 1e-9) return 0.0;
    return r * r * math.log(r);
  }

  /// Maps a point from source space to destination space.
  Offset transform(Offset p) {
    final n = _src.length;
    double x = _xCoef[n] + _xCoef[n + 1] * p.dx + _xCoef[n + 2] * p.dy;
    double y = _yCoef[n] + _yCoef[n + 1] * p.dx + _yCoef[n + 2] * p.dy;
    for (int i = 0; i < n; i++) {
      final u = _kernel((p - _src[i]).distance);
      x += _xCoef[i] * u;
      y += _yCoef[i] * u;
    }
    return Offset(x, y);
  }

  // ── Linear solver ──────────────────────────────────────────────────────────
  // Gaussian elimination with partial pivoting. Operates on copies so the
  // caller's matrix is untouched. Returns the solution vector for A·z = b.
  static List<double> _solve(List<List<double>> a, List<double> b) {
    final n = b.length;
    final m = List.generate(n, (i) => List<double>.from(a[i]));
    final x = List<double>.from(b);

    for (int col = 0; col < n; col++) {
      // Partial pivot: find the largest-magnitude entry in this column.
      int piv = col;
      double best = m[col][col].abs();
      for (int r = col + 1; r < n; r++) {
        final v = m[r][col].abs();
        if (v > best) {
          best = v;
          piv = r;
        }
      }
      if (piv != col) {
        final tmpRow = m[piv];
        m[piv] = m[col];
        m[col] = tmpRow;
        final tmpB = x[piv];
        x[piv] = x[col];
        x[col] = tmpB;
      }

      final diag = m[col][col];
      if (diag.abs() < 1e-12) continue; // near-singular; skip (degenerate input)

      for (int r = col + 1; r < n; r++) {
        final f = m[r][col] / diag;
        if (f == 0) continue;
        for (int c = col; c < n; c++) {
          m[r][c] -= f * m[col][c];
        }
        x[r] -= f * x[col];
      }
    }

    // Back-substitution
    for (int r = n - 1; r >= 0; r--) {
      double s = x[r];
      for (int c = r + 1; c < n; c++) {
        s -= m[r][c] * x[c];
      }
      final diag = m[r][r];
      x[r] = diag.abs() < 1e-12 ? 0.0 : s / diag;
    }
    return x;
  }
}
