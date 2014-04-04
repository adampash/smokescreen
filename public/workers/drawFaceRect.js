importScripts('/workers/blurMethods.js');

self.addEventListener('message', function(e) {
  var column, eyebar, face, faces, frame, height, imageData, index, key, mouth, pixel, row, spacer, width, _i, _j, _k, _l, _len, _m, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
  this.frames = e.data.frames;
  this.frameNumber = e.data.frameNumber;
  this.scale = e.data.scale;
  spacer = e.data.spacer || 0;
  if (e.data.faces != null) {
    faces = JSON.parse(e.data.faces);
  }
  this.newFrames = [];
  _ref = this.frames;
  for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
    frame = _ref[index];
    console.log(frame.width);
    console.log(frame.height);
    width = frame.width * 4;
    height = frame.height;
    imageData = frame.data;
    if (faces != null) {
      face = faces[0];
    }
    if (face != null) {
      for (key in face) {
        face[key] = Math.round(face[key] * scale);
      }
      if (spacer != null) {
        face.y += spacer;
      }
      console.log(JSON.stringify(face));
      eyebar = {
        x: face.x,
        width: face.width,
        y: Math.round(face.y + face.height / 4),
        height: Math.round(face.height / 4)
      };
      for (row = _j = _ref1 = eyebar.y, _ref2 = eyebar.y + eyebar.height; _ref1 <= _ref2 ? _j <= _ref2 : _j >= _ref2; row = _ref1 <= _ref2 ? ++_j : --_j) {
        for (column = _k = _ref3 = eyebar.x * 4, _ref4 = (eyebar.x + eyebar.width) * 4; _ref3 <= _ref4 ? _k <= _ref4 : _k >= _ref4; column = _ref3 <= _ref4 ? ++_k : --_k) {
          pixel = (row * width) + column;
          imageData[pixel] = 0;
        }
      }
      mouth = {
        x: Math.round(face.x + face.width / 4),
        width: Math.round(face.width / 2),
        y: Math.round(face.y + (face.height / 4 * 3)),
        height: Math.round(face.height / 4)
      };
      for (row = _l = _ref5 = mouth.y, _ref6 = mouth.y + mouth.height; _ref5 <= _ref6 ? _l <= _ref6 : _l >= _ref6; row = _ref5 <= _ref6 ? ++_l : --_l) {
        for (column = _m = _ref7 = mouth.x * 4, _ref8 = (mouth.x + mouth.width) * 4; _ref7 <= _ref8 ? _m <= _ref8 : _m >= _ref8; column = _ref7 <= _ref8 ? ++_m : --_m) {
          pixel = (row * width) + column;
          imageData[pixel] = 0;
        }
      }
    }
    frame.data = imageData;
    this.newFrames.push(frame);
  }
  return self.postMessage(this.newFrames);
}, false);

//# sourceMappingURL=drawFaceRect.js.map
