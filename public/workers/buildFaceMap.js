window.Faces = (function() {
  function Faces(faces) {
    if (typeof faces[0] === Array) {
      this.faces = this.flatten(faces);
    } else {
      this.faces = faces || [];
    }
  }

  Faces.prototype.flatten = function(faces) {
    var newFaces;
    newFaces = [];
    faces.map(function(facesArray) {
      return facesArray.map(function(face) {
        return newFaces.push(face);
      });
    });
    return newFaces;
  };

  Faces.prototype.calculateAvgFace = function() {
    return this.averageFace = this.faces.reduce(function(face) {
      return face.width * face.height;
    }, 0) / this.faces.length;
  };

  return Faces;

})();

window.Face = (function() {
  function Face(x, y, area) {
    this.x = x;
    this.y = y;
    this.area = area;
    this.avg = {
      x: this.x,
      y: this.y,
      area: this.area
    };
    this.locations = [];
    this.locations.push({
      x: this.x,
      y: this.y,
      area: this.area
    });
    this.certainty = 0;
  }

  Face.prototype.newPosition = function(x, y, area) {
    this.x = x;
    this.y = y;
    this.area = area;
    return this.locations.push({
      x: this.x,
      y: this.y,
      area: this.area
    });
  };

  Face.prototype.averageArea = function() {
    var avgArea;
    avgArea = this.locations.reduce(function(a, b, c, d) {
      return a + b.area;
    }, 0) / this.locations.length;
    return avgArea;
  };

  Face.prototype.standardDeviation = function() {
    var avg, distances, variance;
    avg = this.averageArea();
    distances = this.locations.map(function(obj, index) {
      return Math.pow(avg - obj.area, 2);
    });
    variance = distances.reduce(function(a, b) {
      return a + b;
    }, 0) / distances.length;
    return Math.sqrt(variance);
  };

  Face.prototype.calculateCertainty = function(maxLocations) {};

  Face.certainty = Face.locations.length / maxLocations;

  return Face;

})();

//# sourceMappingURL=buildFaceMap.js.map
