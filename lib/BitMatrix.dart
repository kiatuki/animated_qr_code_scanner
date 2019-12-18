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

// Ported from com.google.zxing.common.BitMatrix

/// <p>Represents a 2D matrix of bits. In function arguments below, and throughout the common
/// module, x is the column position, and y is the row position. The ordering is always x, y.
/// The origin is at the top-left.</p>
///
/// <p>Internally the bits are represented in a 1-D array of 32-bit ints. However, each row begins
/// with a new int. This is done intentionally so that we can copy out a row into a BitArray very
/// efficiently.</p>
///
/// <p>The ordering of bits is row-major. Within each int, the least significant bits are used first,
/// meaning they represent lower x values. This is compatible with BitArray's implementation.</p>
///
/// @author Sean Owen
/// @author dswitkin@google.com (Daniel Switkin)
class BitMatrix {
  /// Creates an empty square {@code BitMatrix}.
  ///
  /// @param dimension height and width
  BitMatrix({
    this.width,
    this.height,
  }){clear();}

  BitMatrix.fromString(String string):
    width = string.indexOf('\n'),
    height = '\n'.allMatches(string).length
  {
    clear();
    for(int i=0,j=0;i<string.length;i++)
    {
      if(string[i]=='1'){
        final int x = j%width;
        final int y = j~/width;
        set(x,y);
        j++;
      }
      else if(string[i]=='0'){
        j++;
      }
    }
  }
  
  final int width;
  final int height;
  List<bool> bits;


  /// <p>Gets the requested bit, where true means black.</p>
  ///
  /// @param x The horizontal component (i.e. which column)
  /// @param y The vertical component (i.e. which row)
  /// @return value of given bit in matrix
  bool get(int x, int y) => bits[y * width + x];

  /// <p>Sets the given bit to true.</p>
  ///
  /// @param x The horizontal component (i.e. which column)
  /// @param y The vertical component (i.e. which row)
  void set(int x, int y) => bits[y * width + x] = true;


  /// <p>Sets the given bit to false.</p>
  ///
  /// @param x The horizontal component (i.e. which column)
  /// @param y The vertical component (i.e. which row)
  void unset(int x, int y) => bits[y * width + x] = false;

  /// <p>Flips the given bit.</p>
  ///
  /// @param x The horizontal component (i.e. which column)
  /// @param y The vertical component (i.e. which row)
  void flip(int x, int y) => bits[y * width + x] = !bits[y * width + x];

  /// Clears all bits (sets to false).
  void clear() => bits = [for(int i=0;i<width*height;i++) false];

}