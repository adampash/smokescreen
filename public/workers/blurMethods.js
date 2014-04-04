var blur, blurPixel;

blurPixel = function(index, data, width) {
  var aCloseData, closeData, iCnt, iSumBlue, iSumGreen, iSumOpacity, iSumRed, imageWidth, index2, _i, _len;
  imageWidth = 4 * width;
  iSumOpacity = iSumRed = iSumGreen = iSumBlue = 0;
  iCnt = 0;
  aCloseData = [index - imageWidth - 4, index - imageWidth, index - imageWidth + 4, index - 4, index + 4, index + imageWidth - 4, index + imageWidth, index + imageWidth + 4];
  for (index2 = _i = 0, _len = aCloseData.length; _i < _len; index2 = ++_i) {
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
  return data;
};

blur = function(frame, rate) {
  var data, height, index, num, pixel, width, _i, _j, _len;
  rate = rate || 1;
  width = frame.width;
  height = frame.height;
  data = frame.data;
  for (num = _i = rate; rate <= 0 ? _i < 0 : _i > 0; num = rate <= 0 ? ++_i : --_i) {
    for (index = _j = 0, _len = data.length; _j < _len; index = _j += 4) {
      pixel = data[index];
      blurPixel(index, data, width);
    }
  }
  return data;
};

//# sourceMappingURL=blurMethods.js.map
