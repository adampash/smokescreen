self.addEventListener('message', function(e) {
  var b, frame, g, imageData, index, pixel, r, _i, _j, _len, _len1, _ref;
  this.frames = e.data;
  this.newFrames = [];
  _ref = this.frames;
  for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
    frame = _ref[index];
    imageData = frame.data;
    for (index = _j = 0, _len1 = imageData.length; _j < _len1; index = _j += 4) {
      pixel = imageData[index];
      r = imageData[index];
      g = imageData[index + 1];
      b = imageData[index + 2];
      if (r < 255 / 2) {
        imageData[index] = r;
      } else {
        imageData[index] = (r + 255) / 2;
      }
      if (g < 255 / 2) {
        imageData[index + 1] = g;
      } else {
        imageData[index + 1] = (g + 255) / 2;
      }
      if (b < 255 / 2) {
        imageData[index + 2] = b;
      } else {
        imageData[index + 2] = (b + 255) / 2;
      }
    }
    frame.data = imageData;
    this.newFrames.push(frame);
  }
  return self.postMessage(this.newFrames);
}, false);

//# sourceMappingURL=saturate.js.map
