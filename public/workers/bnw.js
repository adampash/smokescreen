self.addEventListener('message', function(e) {
  var b, brightness, frame, g, imageData, index, pixel, r, _i, _j, _len, _len1, _ref;
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
      brightness = (r + g + b) / 3;
      imageData[index] = brightness;
      imageData[index + 1] = brightness;
      imageData[index + 2] = brightness;
    }
    frame.data = imageData;
    this.newFrames.push(frame);
  }
  return self.postMessage(this.newFrames);
}, false);

//# sourceMappingURL=bnw.js.map
