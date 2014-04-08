importScripts('/workers/blurMethods.js');

self.addEventListener('message', function(e) {
  var column, eyebar, face, faces, frame, height, imageData, index, key, mouth, percent, pixel, row, spacer, width, xFactor, yFactor, _i, _j, _k, _l, _len, _len1, _m, _n, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
  this.frames = e.data.frames;
  this.frameNumber = e.data.frameNumber;
  this.scale = e.data.scale;
  spacer = e.data.spacer || 0;
  if (e.data.faces != null) {
    faces = e.data.faces;
  }
  this.newFrames = [];
  _ref = this.frames;
  for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
    frame = _ref[index];
    width = frame.width * 4;
    height = frame.height;
    imageData = frame.data;
    if (faces != null) {
      face = faces[0];
      for (_j = 0, _len1 = faces.length; _j < _len1; _j++) {
        face = faces[_j];
        for (key in face) {
          face[key] = Math.round(face[key] * scale);
        }
        if (spacer != null) {
          face.y += spacer;
        }
        eyebar = {
          x: Math.round(face.x + face.width / 10),
          width: Math.round(face.width / 10 * 8),
          y: Math.round(face.y + face.height / 4),
          height: Math.round(face.height / 4)
        };
        index = 0;
        for (row = _k = _ref1 = eyebar.y, _ref2 = eyebar.y + eyebar.height; _ref1 <= _ref2 ? _k <= _ref2 : _k >= _ref2; row = _ref1 <= _ref2 ? ++_k : --_k) {
          yFactor = Math.round(Math.abs(eyebar.height / 2 - (row - eyebar.y)) / eyebar.height * 255);
          for (column = _l = _ref3 = eyebar.x * 4, _ref4 = (eyebar.x + eyebar.width) * 4; _l <= _ref4; column = _l += 4) {
            percent = Math.abs((eyebar.width / 2 - (column / 4 % eyebar.width)) / eyebar.width);
            xFactor = Math.round(percent * 255);
            if (percent > 1 && index < 10) {
              console.log(percent);
              index++;
            }
            pixel = (row * width) + column;
            imageData[pixel + 3] = 0;
          }
        }
        mouth = {
          x: Math.round(face.x + face.width / 4),
          width: Math.round(face.width / 2),
          y: Math.round(face.y + (face.height / 5 * 3.5)),
          height: Math.round(face.height / 4)
        };
        for (row = _m = _ref5 = mouth.y, _ref6 = mouth.y + mouth.height; _ref5 <= _ref6 ? _m <= _ref6 : _m >= _ref6; row = _ref5 <= _ref6 ? ++_m : --_m) {
          for (column = _n = _ref7 = mouth.x * 4, _ref8 = (mouth.x + mouth.width) * 4; _n <= _ref8; column = _n += 4) {
            pixel = (row * width) + column;
            imageData[pixel + 3] = 0;
          }
        }
      }
    }
    frame.data = imageData;
    this.newFrames.push(frame);
  }
  return self.postMessage(this.newFrames);
}, false);

//# sourceMappingURL=drawFaceRect.js.map
