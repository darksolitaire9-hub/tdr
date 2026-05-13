import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'collision_service.g.dart';

const double _cellSize = 300.0;
const double _repulsionRadius = 220.0; // Distance at which stickers start pushing each other
const double _repulsionForce = 0.8; // How strongly they push

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

@riverpod
class CollisionDisplacements extends _$CollisionDisplacements {
  @override
  Map<String, Offset> build() => {};

  void calculatePush(String draggingId, Offset dragPos, Map<String, Offset> allPositions, SpatialHashGrid grid) {
    final newDisplacements = <String, Offset>{};
    final potentialColliders = grid.getPotentialColliders(dragPos.dx, dragPos.dy);

    for (final otherId in potentialColliders) {
      if (otherId == draggingId) continue;

      final otherPos = allPositions[otherId];
      if (otherPos == null) continue;

      final dx = otherPos.dx - dragPos.dx;
      final dy = otherPos.dy - dragPos.dy;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance < _repulsionRadius && distance > 0) {
        // Calculate repulsion vector (inverse square-ish)
        final pushStrength = (_repulsionRadius - distance) / _repulsionRadius;
        final pushX = (dx / distance) * pushStrength * _repulsionRadius * _repulsionForce;
        final pushY = (dy / distance) * pushStrength * _repulsionRadius * _repulsionForce;
        
        newDisplacements[otherId] = Offset(pushX, pushY);
      }
    }

    state = newDisplacements;
  }

  void clear() {
    state = {};
  }
}
