import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'collision_service.g.dart';

const double _cellSize = 300.0;
const double _snapRadius = 24.0; // Distance to trigger magnetic snap

class SpatialHashGrid {
  final Map<String, List<String>> _cells = {};

  String _getKey(double x, double y) {
    final int cx = (x / _cellSize).floor();
    final int cy = (y / _cellSize).floor();
    return '${cx}_$cy';
  }

  void insert(String id, double x, double y) {
    final key = _getKey(x, y);
    _cells.putIfAbsent(key, () => []).add(id);
  }

  void remove(String id, double x, double y) {
    final key = _getKey(x, y);
    _cells[key]?.remove(id);
    if (_cells[key]?.isEmpty ?? false) {
      _cells.remove(key);
    }
  }

  void clear() {
    _cells.clear();
  }

  List<String> getPotentialColliders(double x, double y) {
    final int cx = (x / _cellSize).floor();
    final int cy = (y / _cellSize).floor();
    final Set<String> result = {};

    // Check current and 8 surrounding cells
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final key = '${cx + dx}_${cy + dy}';
        final list = _cells[key];
        if (list != null) {
          result.addAll(list);
        }
      }
    }
    return result.toList();
  }
}

@Riverpod(keepAlive: true)
class SpatialGrid extends _$SpatialGrid {
  final SpatialHashGrid _grid = SpatialHashGrid();

  @override
  SpatialHashGrid build() => _grid;

  void rebuild(Map<String, Offset> positions) {
    _grid.clear();
    positions.forEach((id, pos) {
      _grid.insert(id, pos.dx, pos.dy);
    });
  }
}

class SnapState {
  final Offset offset;
  final bool isSnapped;
  const SnapState(this.offset, this.isSnapped);
}

@riverpod
class SnapDisplacement extends _$SnapDisplacement {
  @override
  SnapState build() => const SnapState(Offset.zero, false);

  void calculateSnap(String draggingId, Offset dragPos, Map<String, Offset> allPositions, SpatialHashGrid grid) {
    final potentialColliders = grid.getPotentialColliders(dragPos.dx, dragPos.dy);

    double minDx = _snapRadius;
    double minDy = _snapRadius;
    double snapX = 0;
    double snapY = 0;
    bool snapped = false;

    for (final otherId in potentialColliders) {
      if (otherId == draggingId) continue;

      final otherPos = allPositions[otherId];
      if (otherPos == null) continue;

      final dx = otherPos.dx - dragPos.dx;
      final dy = otherPos.dy - dragPos.dy;

      // Axial snapping (align X or Y independently, just like smart guides)
      if (dx.abs() < minDx) {
        minDx = dx.abs();
        snapX = dx;
        snapped = true;
      }
      
      if (dy.abs() < minDy) {
        minDy = dy.abs();
        snapY = dy;
        snapped = true;
      }
    }

    if (snapped) {
      state = SnapState(Offset(snapX, snapY), true);
    } else {
      state = const SnapState(Offset.zero, false);
    }
  }

  void clear() {
    state = const SnapState(Offset.zero, false);
  }
}
