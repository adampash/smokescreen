importScripts('/workers/blurMethods.js');

self.addEventListener('message', function(e) {
  var frame, index, _i, _len, _ref;
  this.frames = e.data;
  this.newFrames = [];
  _ref = this.frames;
  for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
    frame = _ref[index];
    frame.data = blur(frame, 1);
    this.newFrames.push(frame);
  }
  return self.postMessage(this.newFrames);
}, false);

//# sourceMappingURL=blur.js.map
