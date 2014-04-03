var blur;

blur = function(frame, rate) {
  var aCloseData, closeData, data, height, iCnt, iSumBlue, iSumGreen, iSumOpacity, iSumRed, imageWidth, index, index2, num, pixel, width, _i, _j, _k, _len, _len1;
  rate = rate || 1;
  width = frame.width;
  height = frame.height;
  data = frame.data;
  for (num = _i = rate; rate <= 0 ? _i < 0 : _i > 0; num = rate <= 0 ? ++_i : --_i) {
    for (index = _j = 0, _len = data.length; _j < _len; index = _j += 4) {
      pixel = data[index];
      imageWidth = 4 * width;
      iSumOpacity = iSumRed = iSumGreen = iSumBlue = 0;
      iCnt = 0;
      aCloseData = [index - imageWidth - 4, index - imageWidth, index - imageWidth + 4, index - 4, index + 4, index + imageWidth - 4, index + imageWidth, index + imageWidth + 4];
      for (index2 = _k = 0, _len1 = aCloseData.length; _k < _len1; index2 = ++_k) {
        closeData = aCloseData[index2];
        if (aCloseData[index2] >= 0 && aCloseData[index2] <= data.length - 3) {
          iSumOpacity += data[aCloseData[index2]];
          iSumRed += data[aCloseData[index2] + 1];
          iSumGreen += data[aCloseData[index2] + 2];
          iSumBlue += data[aCloseData[index2] + 3];
          iCnt += 1;
        }
      }
      data[index] = iSumOpacity / iCnt;
      data[index + 1] = iSumRed / iCnt;
      data[index + 2] = iSumGreen / iCnt;
      data[index + 3] = iSumBlue / iCnt;
    }
  }
  return data;
};

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
