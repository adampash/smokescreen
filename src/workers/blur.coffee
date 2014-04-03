blur = (frame, rate) ->
  rate = rate || 1
  width = frame.width
  height = frame.height
  data = frame.data

  for num in [rate...0]
    for pixel, index in data by 4
      imageWidth = 4 * width
      iSumOpacity = iSumRed = iSumGreen = iSumBlue = 0
      iCnt = 0

      # data of close pixels (from all 8 surrounding pixels)
      aCloseData = [
          index - imageWidth - 4, index - imageWidth, index - imageWidth + 4, # top pixels
          index - 4, index + 4, # middle pixels
          index + imageWidth - 4, index + imageWidth, index + imageWidth + 4 # bottom pixels
      ]

      # calculating Sum value of all close pixels
      for closeData, index2 in aCloseData
        if (aCloseData[index2] >= 0 && aCloseData[index2] <= data.length - 3)
          iSumOpacity += data[aCloseData[index2]]
          iSumRed += data[aCloseData[index2] + 1]
          iSumGreen += data[aCloseData[index2] + 2]
          iSumBlue += data[aCloseData[index2] + 3]
          iCnt += 1

      # apply average values
      data[index] = (iSumOpacity / iCnt)
      data[index+1] = (iSumRed / iCnt)
      data[index+2] = (iSumGreen / iCnt)
      data[index+3] = (iSumBlue / iCnt)

  data

self.addEventListener('message', (e) ->
  @frames = e.data
  @newFrames = []

  for frame, index in @frames
    frame.data = blur(frame, 1)

    @newFrames.push frame

  self.postMessage @newFrames


, false)



