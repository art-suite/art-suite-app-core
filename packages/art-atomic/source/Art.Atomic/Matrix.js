// Generated by CoffeeScript 1.12.7

/*

With the exception of the setter methods, this is a pure-functional class.
 */


/*
Experiment: Instead of storing the matrix as 6 members, use a Float32Array:

  Bonus: if we order the 6 elements correctly, we can just pass the Float32Array directly to Webgl uniformMatrix3fv
  Result:
    FF is about 2x as fast with this implementation, but Chrome is about 10x slower (see below)
    Sticking with Members implementation for now.

On my Macbook pro Retina (2.6 GHz Intel Core i7)

Chrome 29.0.1547.57 (members)
  Matrix.translate 14,716,649/s
  matrix().translate 8,052,404/s
  transform point 3,922,725/s
  invert 12,733,472/s
  mul 16,146,097/s

Chrome 29.0.1547.57 (float32Array)
  Matrix.translate 926,402/s
  matrix().translate 463,791/s
  transform point 3,684,177/s
  invert 978,248/s
  mul 992,078/s

FF 23.0.1 (members)
  Matrix.translate 1,281,078/s
  matrix().translate 534,542/s
  transform point 768,224/s
  invert 1,374,788/s
  mul 1,413,206/s

FF 23.0.1 (float32Array)
  Matrix.translate 2,126,281/s
  matrix().translate 1,013,548/s
  transform point 832,604/s
  invert 2,524,903/s
  mul 2,669,331/s

NOTE! the order of the fields in the float32array for Webgl uniformMatrix3fv should be:
  @values[0] = @sx
  @values[1] = @shy
  @values[2] = @tx
  @values[3] = @shx
  @values[4] = @sy
  @values[5] = @ty
 */

(function() {
  var AtomicBase, Matrix, Point, Rectangle, ceil, compact, defineModule, float32Eq, float32Eq0, floor, formattedInspect, inspect, isNumber, isPoint, log, max, min, point, rect, ref, simplifyNum, sqrt,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  AtomicBase = require("./Base");

  Point = require("./Point");

  Rectangle = require("./Rectangle");

  point = Point.point, isPoint = Point.isPoint;

  rect = Rectangle.rect;

  ceil = Math.ceil, floor = Math.floor, sqrt = Math.sqrt, min = Math.min, max = Math.max;

  ref = require('art-standard-lib'), float32Eq0 = ref.float32Eq0, formattedInspect = ref.formattedInspect, inspect = ref.inspect, simplifyNum = ref.simplifyNum, float32Eq = ref.float32Eq, compact = ref.compact, log = ref.log, isNumber = ref.isNumber, defineModule = ref.defineModule;

  defineModule(module, Matrix = (function(superClass) {
    var cleanInspect, identityMatrix, intermediatResultMatrix, isMatrix, matrix, transform1D;

    extend(Matrix, superClass);

    function Matrix() {
      return Matrix.__super__.constructor.apply(this, arguments);
    }

    Matrix.defineAtomicClass({
      fieldNames: "sx sy shx shy tx ty"
    });

    Matrix.isMatrix = isMatrix = function(v) {
      return (v != null ? v.constructor : void 0) === Matrix;
    };

    Matrix.matrix = matrix = function(a, b, c, d, e, f) {
      if (isMatrix(a)) {
        return a;
      } else if (a === null || a === void 0) {
        return identityMatrix;
      } else {
        return new Matrix(a, b, c, d, e, f);
      }
    };

    Matrix._cleanInspect = cleanInspect = function(pointName, s) {
      var out, r;
      out = pointName ? (r = new RegExp("([0-9])" + pointName, "g"), s.replace(r, "$1 * " + pointName).replace(/-1 \* /g, "-").replace(/\ \+ -/g, " - ").replace(/0\./g, ".")) : s.replace(/-1([A-Za-z]+)/g, "-$1").replace(/\ \+ -/g, " - ").replace(/0\./g, ".");
      return out;
    };

    Matrix.translate = function(a, b) {
      var x, y;
      if (isNumber(b)) {
        throw new Error("Matrix.translate no longer accepts two numbers. Use translateXY");
      }
      if (isNumber(a)) {
        x = y = a;
      } else {
        x = a.x, y = a.y;
      }
      return Matrix.translateXY(x, y);
    };

    Matrix.translateXY = function(x, y) {
      if (x === 0 && y === 0) {
        return identityMatrix;
      } else {
        return new Matrix(1, 1, 0, 0, x, y);
      }
    };

    Matrix.scale = function(a, b) {
      var x, y;
      if (isNumber(b)) {
        throw new Error("Matrix.scale no longer accepts two numbers. Use translateXY");
      }
      if (isNumber(a)) {
        x = y = a;
      } else {
        x = a.x, y = a.y;
      }
      return Matrix.scaleXY(x, y);
    };

    Matrix.scaleXY = function(sx, sy) {
      if (sx === 1 && sy === 1) {
        return identityMatrix;
      } else {
        return new Matrix(sx, sy, 0, 0, 0, 0);
      }
    };

    Matrix.rotate = function(radians) {
      var cr, sr;
      cr = Math.cos(radians);
      sr = Math.sin(radians);
      if (cr === 1 && sr === 0) {
        return identityMatrix;
      } else {
        return new Matrix(cr, cr, -sr, sr, 0, 0);
      }
    };


    /*
    Matrix.multitouch
      Solves:
        Given two points, moved in space
        Generate a transformation matrix m
        where:
          a2 == m.transform a1
          and
          b2 == m.transform b1
          and m.exactScale.aspectRatio == 1
     */

    Matrix.multitouch = function(a1, a2, b1, b2) {
      var angle, c1x, c1y, c2x, c2y, m, scale, v1, v1m, v2, v2m;
      c1x = (b1.x + a1.x) / 2;
      c1y = (b1.y + a1.y) / 2;
      c2x = (b2.x + a2.x) / 2;
      c2y = (b2.y + a2.y) / 2;
      v1 = b1.sub(a1);
      v2 = b2.sub(a2);
      v1m = v1.magnitude;
      v2m = v2.magnitude;
      m = Matrix.translateXY(-c1x, -c1y);
      if (!float32Eq0(v1m) && !float32Eq0(v2m)) {
        angle = v2.angle - v1.angle;
        scale = v2m / v1m;
        if (!float32Eq0(angle)) {
          m = m.rotate(angle);
        }
        if (!float32Eq(scale, 1)) {
          m = m.scale(scale);
        }
      }
      return m.translateXY(c2x, c2y);
    };

    Matrix.multitouchParts = function(a1, a2, b1, b2) {
      var v1, v2;
      v1 = b1.sub(a1);
      v2 = b2.sub(a2);
      return {
        rotate: v2.angle - v1.angle,
        scale: v2.magnitude / v1.magnitude,
        translate: point((b2.x + a2.x) / 2 - (b1.x + a1.x) / 2, (b2.y + a2.y) / 2 - (b1.y + a1.y) / 2)
      };
    };

    Matrix.prototype.initDefaults = function() {
      this.sx = this.sy = 1;
      this.shy = this.shx = 0;
      this.tx = this.ty = 0;
      this._exactScale = this._exactScaler = null;
      return this;
    };

    Matrix.prototype._init = function(a, b, c, d, e, f) {
      this.initDefaults();
      if (a == null) {
        return;
      }
      if (isPoint(a)) {
        return this._initFromPoint(a);
      } else if (isMatrix(a)) {
        return this._initFromMatrix(a);
      } else {
        this.sx = a - 0;
        if (b != null) {
          this.sy = b - 0;
        }
        if (c != null) {
          this.shx = c - 0;
        }
        if (d != null) {
          this.shy = d - 0;
        }
        if (e != null) {
          this.tx = e - 0;
        }
        if (f != null) {
          return this.ty = f - 0;
        }
      }
    };

    Matrix.prototype.getScale = function() {
      return this.getS();
    };

    Matrix.getter({
      t: function() {
        return point(this.tx, this.ty);
      },
      s: function() {
        return point(this.sx, this.sy);
      },
      sh: function() {
        return point(this.shx, this.shy);
      },
      xsv: function() {
        return point(this.sx, this.shx);
      },
      ysv: function() {
        return point(this.sy, this.shy);
      },
      xsvMagnitude: function() {
        return sqrt(this.sx * this.sx + this.shx * this.shx);
      },
      ysvMagnitude: function() {
        return sqrt(this.sy * this.sy + this.shy * this.shy);
      },
      exactScale: function() {
        return this._exactScale || (this._exactScale = point(this.xsv.magnitude, this.ysv.magnitude));
      },
      exactScaler: function() {
        return this._exactScaler || (this._exactScaler = (this.getXsvMagnitude() + this.getYsvMagnitude()) / 2);
      },
      inv: function() {
        return this.invert();
      },
      inverted: function() {
        return this.invert();
      },
      locationX: function() {
        return this.tx;
      },
      locationY: function() {
        return this.ty;
      },
      scaleX: function() {
        return this.sx;
      },
      scaleY: function() {
        return this.sy;
      },
      location: function() {
        return point(this.tx, this.ty);
      },
      rounded: function() {
        return this.getWithRoundedTranslation();
      },
      withRoundedTranslation: function() {
        if (this.translationIsIntegral) {
          return this;
        } else {
          return new Matrix(this.sx, this.sy, this.shx, this.shy, Math.round(this.tx), Math.round(this.ty));
        }
      },
      angle: function() {
        var p1, p2;
        p1 = this.transform(Point.point0);
        p2 = this.transform(new Point(0, 1));
        return (p2.sub(p1)).angle - Math.PI * .5;
      },
      float32Array: function() {
        return this.fillFloat32Array(new Float32Array(9));
      },
      isIdentity: function() {
        return float32Eq(this.sx, 1) && float32Eq(this.sy, 1) && float32Eq0(this.shx) && float32Eq0(this.shy) && float32Eq0(this.tx) && float32Eq0(this.ty);
      },
      isTranslateOnly: function() {
        return float32Eq(this.sx, 1) && float32Eq(this.sy, 1) && float32Eq0(this.shx) && float32Eq0(this.shy);
      },
      translationIsIntegral: function() {
        return float32Eq(this.tx, Math.round(this.tx)) && float32Eq(this.ty, Math.round(this.ty));
      },
      isIntegerTranslateOnly: function() {
        return this.isTranslateOnly && float32Eq(this.tx, this.tx | 0) && float32Eq(this.ty, this.ty | 0);
      },
      isTranslateAndScaleOnly: function() {
        return float32Eq0(this.shx) && float32Eq0(this.shy);
      },
      hasSkew: function() {
        return !this.getIsTranslateAndScaleOnly();
      },
      isTranslateAndPositiveScaleOnly: function() {
        return this.sx > 0 && this.sy > 0 && float32Eq(this.shx, 0) && float32Eq(this.shy, 0);
      }
    });

    Matrix.prototype.fillFloat32Array = function(a) {
      a[0] = this.sx;
      a[1] = this.shx;
      a[2] = this.tx;
      a[3] = this.shy;
      a[4] = this.sy;
      a[5] = this.ty;
      return a;
    };

    Matrix.prototype.simplify = function() {
      return new Matrix(simplifyNum(this.sx), simplifyNum(this.sy), simplifyNum(this.shx), simplifyNum(this.shy), simplifyNum(this.tx), simplifyNum(this.ty));
    };

    Matrix.prototype.withAngle = function(a) {
      return this.rotate(a - this.angle);
    };

    Matrix.prototype.withScale = function(a, b) {
      var x, y;
      if (isNumber(a)) {
        x = a;
        y = b != null ? b : x;
      } else {
        x = a.x, y = a.y;
      }
      return this.scale(x / this.sx, y / this.sy);
    };

    Matrix.prototype.withLocation = function(a, b) {
      var x, y;
      if (isNumber(a)) {
        x = a;
        y = b != null ? b : x;
      } else {
        x = a.x, y = a.y;
      }
      if (x === this.tx && y === this.ty) {
        return this;
      } else {
        return new Matrix(this.sx, this.sy, this.shx, this.shy, x, y);
      }
    };

    Matrix.prototype.withLocationXY = function(x, y) {
      if (x === this.tx && y === this.ty) {
        return this;
      } else {
        return new Matrix(this.sx, this.sy, this.shx, this.shy, x, y);
      }
    };


    /*
    IN:
      amount: point or number
      into: t/f
     */

    Matrix.prototype.translate = function(amount, into) {
      var x, y;
      if (isNumber(amount)) {
        x = y = amount;
      } else {
        x = amount.x, y = amount.y;
      }
      if (isNumber(into)) {
        throw new Error("Illegal second input: number (" + into + "). Use translateXY.");
      }
      return this.translateXY(x, y, into);
    };

    Matrix.prototype.translateXY = function(x, y, into) {
      return this._into(into, this.sx, this.sy, this.shx, this.shy, this.tx + x, this.ty + y);
    };

    Matrix.prototype.rotate = function(radians, into) {
      var cr, sr;
      cr = Math.cos(radians);
      sr = Math.sin(radians);
      return this._into(into, this.sx * cr - this.shy * sr, this.shx * sr + this.sy * cr, this.shx * cr - this.sy * sr, this.sx * sr + this.shy * cr, this.tx * cr - this.ty * sr, this.tx * sr + this.ty * cr);
    };

    Matrix.prototype.scale = function(a, into) {
      var x, y;
      if (isNumber(into)) {
        throw new Error("Matrix.scale no longer accepts two numbers. Use translateXY");
      }
      if (isNumber(a)) {
        x = y = a;
      } else {
        x = a.x, y = a.y;
      }
      return this.scaleXY(x, y, into);
    };

    Matrix.prototype.scaleXY = function(x, y, into) {
      return this._into(into, this.sx * x, this.sy * y, this.shx * x, this.shy * y, this.tx * x, this.ty * y);
    };

    Matrix.getter({
      determinantReciprocal: function() {
        return 1.0 / (this.sx * this.sy - this.shy * this.shx);
      }
    });

    Matrix.prototype.invert = function(into) {
      var d;
      d = this.getDeterminantReciprocal();
      return this._into(into, d * this.sy, d * this.sx, d * -this.shx, d * -this.shy, d * (-this.tx * this.sy + this.ty * this.shx), d * (this.tx * this.shy - this.ty * this.sx));
    };

    Matrix.prototype.invertAndMul = function(m, into) {
      var d, shx, shy, sx, sy, tx, ty;
      d = this.getDeterminantReciprocal();
      sx = d * this.sy;
      sy = d * this.sx;
      shx = d * -this.shx;
      shy = d * -this.shy;
      tx = d * (-this.tx * this.sy + this.ty * this.shx);
      ty = d * (this.tx * this.shy - this.ty * this.sx);
      return this._into(into, sx * m.sx + shy * m.shx, shx * m.shy + sy * m.sy, shx * m.sx + sy * m.shx, sx * m.shy + shy * m.sy, tx * m.sx + ty * m.shx + m.tx, tx * m.shy + ty * m.sy + m.ty);
    };

    Matrix.prototype.mul = function(m, into) {
      if (isNumber(m)) {
        return this._into(into, this.sx * m, this.sy * m, this.shx * m, this.shy * m, this.tx * m, this.ty * m);
      } else {
        return this._into(into, this.sx * m.sx + this.shy * m.shx, this.shx * m.shy + this.sy * m.sy, this.shx * m.sx + this.sy * m.shx, this.sx * m.shy + this.shy * m.sy, this.tx * m.sx + this.ty * m.shx + m.tx, this.tx * m.shy + this.ty * m.sy + m.ty);
      }
    };

    Matrix.prototype.div = function(m, into) {
      var multipler;
      multipler = isNumber(m) ? 1 / m : m.invert(intermediatResultMatrix);
      return this.mul(multipler, into);
    };

    Matrix.prototype.inspectX = function(pointName, nullForZeroString) {
      var pn;
      pn = pointName;
      pointName = pointName ? pointName + "." : "";
      if (!(this.sx || this.shx || this.tx)) {
        return (!nullForZeroString ? "0" : void 0);
      }
      return cleanInspect(pn, compact([this.sx === 1 ? pointName + "x" : this.sx ? "" + this.sx + pointName + "x" : void 0, this.shx === 1 ? pointName + "y" : this.shx ? "" + this.shx + pointName + "y" : void 0, this.tx ? "" + this.tx : void 0]).join(" + "));
    };

    Matrix.prototype.inspectY = function(pointName, nullForZeroString) {
      var pn;
      pn = pointName;
      pointName = pointName ? pointName + "." : "";
      if (!(this.sy || this.shy || this.ty)) {
        return (!nullForZeroString ? "0" : void 0);
      }
      return cleanInspect(pn, compact([this.sy === 1 ? pointName + "y" : this.sy ? "" + this.sy + pointName + "y" : void 0, this.shy === 1 ? pointName + "x" : this.shy ? "" + this.shy + pointName + "x" : void 0, this.ty ? "" + this.ty : void 0]).join(" + "));
    };

    Matrix.prototype.inspectBoth = function(pointName) {
      return "(" + (this.inspectX(pointName)) + ", " + (this.inspectY(pointName)) + ")";
    };

    Matrix.transform1D = transform1D = function(x, y, sx, shx, tx) {
      return x * sx + y * shx + tx;
    };


    /*
    IN: a: Point or any object where .x and .y are numbers
    IN: a: x (number; required), b: y (number, default: x)
     */

    Matrix.prototype.transform = function(a, b) {
      var x, y;
      if (isNumber(a)) {
        log.error("DEPRICATED: matrix.transform(x, y) - use matrix.transformXY");
        x = a;
        y = b != null ? b : x;
      } else {
        x = a.x, y = a.y;
      }
      return this.transformXY(x, y);
    };

    Matrix.prototype.transformX = function(x, y) {
      return transform1D(x, y, this.sx, this.shx, this.tx);
    };

    Matrix.prototype.transformY = function(x, y) {
      return transform1D(y, x, this.sy, this.shy, this.ty);
    };

    Matrix.prototype.transformXY = function(x, y) {
      return new Point(this.transformX(x, y), this.transformY(x, y));
    };

    Matrix.prototype.inverseTransform = function(a, b) {
      var d, shx, shy, sx, sy, tx, ty, x, y;
      if (isNumber(a)) {
        x = a;
        y = b != null ? b : x;
      } else {
        x = a.x, y = a.y;
      }
      d = this.getDeterminantReciprocal();
      sx = d * this.sy;
      sy = d * this.sx;
      shx = d * -this.shx;
      shy = d * -this.shy;
      tx = d * (-this.tx * this.sy + this.ty * this.shx);
      ty = d * (this.tx * this.shy - this.ty * this.sx);
      return new Point(transform1D(x, y, sx, shx, tx), transform1D(y, x, sy, shy, ty));
    };

    Matrix.prototype.transformVector = function(a, b) {
      var dx, dy;
      switch ((a != null) && a.constructor) {
        case false:
          dx = dy = 0;
          break;
        case Point:
          dx = a.x;
          dy = a.y;
          break;
        default:
          dx = a;
          dy = b;
      }
      return new Point(dx * this.sx + dy * this.shx, dy * this.sy + dx * this.shy);
    };

    Matrix.prototype.transformDifference = function(v1, v2) {
      var dx, dy;
      dx = v1.x - v2.x;
      dy = v1.y - v2.y;
      return new Point(dx * this.sx + dy * this.shx, dy * this.sy + dx * this.shy);
    };

    Matrix.prototype.transformBoundingRect = function(r, roundOut, into) {
      var bottom, h, left, right, top, w, x, x1, x2, x3, x4, y, y1, y2, y3, y4;
      r = rect(r);
      if (r.infinite) {
        x = r.x, y = r.y, w = r.w, h = r.h;
      } else if (this.isTranslateAndScaleOnly) {
        x = r.x * this.sx + this.tx;
        y = r.y * this.sy + this.ty;
        w = r.w * this.sx;
        h = r.h * this.sy;
        if (w < 0) {
          x += w;
          w = -w;
        }
        if (h < 0) {
          y += h;
          h = -h;
        }
      } else {
        top = r.top, left = r.left, right = r.right, bottom = r.bottom;
        x1 = transform1D(left, top, this.sx, this.shx, this.tx);
        y1 = transform1D(top, left, this.sy, this.shy, this.ty);
        x2 = transform1D(right, top, this.sx, this.shx, this.tx);
        y2 = transform1D(top, right, this.sy, this.shy, this.ty);
        x3 = transform1D(right, bottom, this.sx, this.shx, this.tx);
        y3 = transform1D(bottom, right, this.sy, this.shy, this.ty);
        x4 = transform1D(left, bottom, this.sx, this.shx, this.tx);
        y4 = transform1D(bottom, left, this.sy, this.shy, this.ty);
        x = min(x1, x2, x3, x4);
        w = max(x1, x2, x3, x4) - x;
        y = min(y1, y2, y3, y4);
        h = max(y1, y2, y3, y4) - y;
      }
      if (roundOut) {
        right = ceil(x + w);
        bottom = ceil(y + h);
        x = floor(x);
        y = floor(y);
        w = right - x;
        h = bottom - y;
      }
      if (into) {
        return into._setAll(x, y, w, h);
      } else {
        return new Rectangle(x, y, w, h);
      }
    };

    Matrix.identityMatrix = identityMatrix = new Matrix;

    Matrix.matrix0 = new Matrix(0, 0, 0, 0, 0, 0);

    intermediatResultMatrix = new Matrix;

    Matrix.prototype._initFromMatrix = function(m) {
      this.sx = m.sx;
      this.sy = m.sy;
      this.shx = m.shx;
      this.shy = m.shy;
      this.tx = m.tx;
      this.ty = m.ty;
      return this;
    };

    Matrix.prototype._initFromPoint = function(p) {
      this.tx = p.x;
      this.ty = p.y;
      return this;
    };

    return Matrix;

  })(AtomicBase));

}).call(this);

//# sourceMappingURL=Matrix.js.map
