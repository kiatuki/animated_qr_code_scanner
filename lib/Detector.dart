/*
 * Copyright 2007 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';

import 'BitMatrix.dart';
import 'PerspectiveTransform.dart';

// Ported from com.google.zxing.qrcode.detector

/// <p>Encapsulates logic that can detect a QR Code in an image, even if the QR Code
/// is rotated or skewed, or partially obscured.</p>
/// 
/// @author Sean Owen
class Detector {

  BitMatrix bitMatrix;

  int computedDimension;

  PerspectiveTransform createTransform(Offset topLeft,
                                       Offset topRight,
                                       Offset bottomLeft,
                                       Offset alignmentPattern,) {
    computedDimension = computeDimension(topLeft, topRight, bottomLeft, calculateModuleSize(topLeft, topRight, bottomLeft));
    final double dimMinusThree = computedDimension - 3.5;
    double bottomRightX;
    double bottomRightY;
    double sourceBottomRightX;
    double sourceBottomRightY;
    if (alignmentPattern != null) {
      bottomRightX = alignmentPattern.dx;
      bottomRightY = alignmentPattern.dy;
      sourceBottomRightX = dimMinusThree - 3.0;
      sourceBottomRightY = sourceBottomRightX;
    } else {
      // Don't have an alignment pattern, just make up the bottom-right point
      bottomRightX = (topRight.dx - topLeft.dx) + bottomLeft.dx;
      bottomRightY = (topRight.dy - topLeft.dy) + bottomLeft.dy;
      sourceBottomRightX = dimMinusThree;
      sourceBottomRightY = dimMinusThree;
    }

    return PerspectiveTransform.quadrilateralToQuadrilateral(
        3.5,
        3.5,
        dimMinusThree,
        3.5,
        sourceBottomRightX,
        sourceBottomRightY,
        3.5,
        dimMinusThree,
        topLeft.dx,
        topLeft.dy,
        topRight.dx,
        topRight.dy,
        bottomRightX,
        bottomRightY,
        bottomLeft.dx,
        bottomLeft.dy);
  }

    PerspectiveTransform createTransformCorners(Offset topLeft,
                                       Offset topRight,
                                       Offset bottomLeft,
                                       Offset alignmentPattern,) {
    computedDimension = computeDimension(topLeft, topRight, bottomLeft, calculateModuleSize(topLeft, topRight, bottomLeft));
    double bottomRightX;
    double bottomRightY;
    double sourceBottomRightX;
    double sourceBottomRightY;
    if (alignmentPattern != null) {
      bottomRightX = alignmentPattern.dx;
      bottomRightY = alignmentPattern.dy;
      sourceBottomRightX = computedDimension - 3.0;
      sourceBottomRightY = sourceBottomRightX;
    } else {
      // Don't have an alignment pattern, just make up the bottom-right point
      bottomRightX = (topRight.dx - topLeft.dx) + bottomLeft.dx;
      bottomRightY = (topRight.dy - topLeft.dy) + bottomLeft.dy;
      sourceBottomRightX = computedDimension.toDouble();
      sourceBottomRightY = computedDimension.toDouble();
    }

    return PerspectiveTransform.quadrilateralToQuadrilateral(
        0,
        0,
        computedDimension.toDouble(),
        0,
        sourceBottomRightX,
        sourceBottomRightY,
        0,
        computedDimension.toDouble(),
        topLeft.dx,
        topLeft.dy,
        topRight.dx,
        topRight.dy,
        bottomRightX,
        bottomRightY,
        bottomLeft.dx,
        bottomLeft.dy);
  }

  PerspectiveTransform createInverseTransform(Offset topLeft,
                                       Offset topRight,
                                       Offset bottomLeft,
                                       Offset alignmentPattern,) {
    computedDimension = computeDimension(topLeft, topRight, bottomLeft, calculateModuleSize(topLeft, topRight, bottomLeft));
    final double dimMinusThree = computedDimension - 3.5;
    double bottomRightX;
    double bottomRightY;
    double sourceBottomRightX;
    double sourceBottomRightY;
    if (alignmentPattern != null) {
      bottomRightX = alignmentPattern.dx;
      bottomRightY = alignmentPattern.dy;
      sourceBottomRightX = dimMinusThree - 3.0;
      sourceBottomRightY = sourceBottomRightX;
    } else {
      // Don't have an alignment pattern, just make up the bottom-right point
      bottomRightX = (topRight.dx - topLeft.dx) + bottomLeft.dx;
      bottomRightY = (topRight.dy - topLeft.dy) + bottomLeft.dy;
      sourceBottomRightX = dimMinusThree;
      sourceBottomRightY = dimMinusThree;
    }

    return PerspectiveTransform.quadrilateralToQuadrilateral(
        topLeft.dx,
        topLeft.dy,
        topRight.dx,
        topRight.dy,
        bottomRightX,
        bottomRightY,
        bottomLeft.dx,
        bottomLeft.dy,
        3.5,
        3.5,
        dimMinusThree,
        3.5,
        sourceBottomRightX,
        sourceBottomRightY,
        3.5,
        dimMinusThree);
  }

  /// <p>Computes the dimension (number of modules on a size) of the QR Code based on the position
  /// of the finder patterns and estimated module size.</p>
  int computeDimension(Offset topLeft,
                                      Offset topRight,
                                      Offset bottomLeft,
                                      double moduleSize) {
    final int tltrCentersDimension = (topLeft - topRight).distance ~/ moduleSize;
    final int tlblCentersDimension = (topLeft - bottomLeft).distance ~/ moduleSize;
    int dimension = ((tltrCentersDimension + tlblCentersDimension) ~/ 2) + 7;
    switch (dimension % 4) { // mod 4
      case 0:
        dimension++;
        break;
        // 1? do nothing
      case 2:
        dimension--;
        break;
      case 3:
        //throw NotFoundException.getNotFoundInstance();
        break;
    }
    return dimension;
  }

  /// <p>Computes an average estimated module size based on estimated derived from the positions
  /// of the three finder patterns.</p>
  ///
  /// @param topLeft detected top-left finder pattern center
  /// @param topRight detected top-right finder pattern center
  /// @param bottomLeft detected bottom-left finder pattern center
  /// @return estimated module size
  double calculateModuleSize(Offset topLeft,
                             Offset topRight,
                             Offset bottomLeft) {
    // Take the average
    return (calculateModuleSizeOneWay(topLeft, topRight) +
        calculateModuleSizeOneWay(topLeft, bottomLeft)) / 2.0;
  }

  /// <p>Estimates module size based on two finder patterns -- it uses
  /// {@link #sizeOfBlackWhiteBlackRunBothWays(int, int, int, int)} to figure the
  /// width of each, measuring along the axis between their centers.</p>
  double calculateModuleSizeOneWay(Offset pattern, Offset otherPattern) {
    final double moduleSizeEst1 = sizeOfBlackWhiteBlackRunBothWays( pattern.dx.toInt(),
        pattern.dy.toInt(),
        otherPattern.dx.toInt(),
        otherPattern.dy.toInt());
    final double moduleSizeEst2 = sizeOfBlackWhiteBlackRunBothWays(otherPattern.dx.toInt(),
        otherPattern.dy.toInt(),
        pattern.dx.toInt(),
        pattern.dy.toInt());
    if (moduleSizeEst1 == double.nan) {
      return moduleSizeEst2 / 7.0;
    }
    if (moduleSizeEst2 == double.nan) {
      return moduleSizeEst1 / 7.0;
    }
    // Average them, and divide by 7 since we've counted the width of 3 black modules,
    // and 1 white and 1 black module on either side. Ergo, divide sum by 14.
    return (moduleSizeEst1 + moduleSizeEst2) / 14.0;
  }

  /// See {@link #sizeOfBlackWhiteBlackRun(int, int, int, int)}; computes the total width of
  /// a finder pattern by looking for a black-white-black run from the center in the direction
  /// of another point (another finder pattern center), and in the opposite direction too.
  double sizeOfBlackWhiteBlackRunBothWays(int fromX, int fromY, int toX, int toY) {

    double result = sizeOfBlackWhiteBlackRun(fromX, fromY, toX, toY);

    // Now count other way -- don't run off image though of course
    double scale = 1.0;
    int otherToX = fromX - (toX - fromX);
    if (otherToX < 0) {
      scale = fromX / (fromX - otherToX).toDouble();
      otherToX = 0;
    } else if (otherToX >= bitMatrix.width) {
      scale = (bitMatrix.width - 1 - fromX) / (otherToX - fromX).toDouble();
      otherToX = bitMatrix.width - 1;
    }
    int otherToY = (fromY - (toY - fromY) * scale).toInt();

    scale = 1.0;
    if (otherToY < 0) {
      scale = fromY / (fromY - otherToY).toDouble();
      otherToY = 0;
    } else if (otherToY >= bitMatrix.height) {
      scale = (bitMatrix.height - 1 - fromY) / (otherToY - fromY).toDouble();
      otherToY = bitMatrix.height - 1;
    }
    otherToX = (fromX + (otherToX - fromX) * scale).toInt();

    result += sizeOfBlackWhiteBlackRun(fromX, fromY, otherToX, otherToY);

    // Middle pixel is double-counted this way; subtract 1
    return result - 1.0;
  }

  /// <p>This method traces a line from a point in the image, in the direction towards another point.
  /// It begins in a black region, and keeps going until it finds white, then black, then white again.
  /// It reports the distance from the start to this point.</p>
  ///
  /// <p>This is used when figuring out how wide a finder pattern is, when the finder pattern
  /// may be skewed or rotated.</p>
  double sizeOfBlackWhiteBlackRun(int fromX, int fromY, int toX, int toY) {
    // Mild variant of Bresenham's algorithm;
    // see http://en.wikipedia.org/wiki/Bresenham's_line_algorithm
    final bool steep = (toY - fromY).abs() > (toX - fromX).abs();
    if (steep) {
      int temp = fromX;
      fromX = fromY;
      fromY = temp;
      temp = toX;
      toX = toY;
      toY = temp;
    }

    final int dx = (toX - fromX).abs();
    final int dy = (toY - fromY).abs();
    int error = -dx ~/ 2;
    final int xstep = fromX < toX ? 1 : -1;
    final int ystep = fromY < toY ? 1 : -1;

    // In black pixels, looking for white, first or second time.
    int state = 0;
    // Loop up until x == toX, but not beyond
    final int xLimit = toX + xstep;
    for (int x = fromX, y = fromY; x != xLimit; x += xstep) {
      final int realX = steep ? y : x;
      final int realY = steep ? x : y;

      // Does current pixel mean we have moved white to black or vice versa?
      // Scanning black in state 0,2 and white in state 1, so if we find the wrong
      // color, advance to next state or end if we are in state 2 already
      if ((state == 1) == bitMatrix.get(realX, realY)) {
        if (state == 2) {
          return (Offset(x.toDouble(), y.toDouble())- Offset(fromX.toDouble(), fromY.toDouble())).distance;
        }
        state++;
      }

      error += dy;
      if (error > 0) {
        if (y == toY) {
          break;
        }
        y += ystep;
        error -= dx;
      }
    }
    // Found black-white-black; give the benefit of the doubt that the next pixel outside the image
    // is "white" so this last point at (toX+xStep,toY) is the right ending. This is really a
    // small approximation; (toX+xStep,toY+yStep) might be really correct. Ignore this.
    if (state == 2) {
      return (Offset((toX + xstep).toDouble(), toY.toDouble()) - Offset(fromX.toDouble(), fromY.toDouble())).distance;
    }
    // else we didn't find even black-white-black; no estimate is really possible
    return double.nan;
  }

}