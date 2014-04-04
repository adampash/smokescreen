self.addEventListener('message', (e) ->
  @frames = e.data
  @newFrames = []

  for frame, index in @frames
    imageData = frame.data

    for pixel, index in imageData by 4
      r = imageData[index]
      g = imageData[index+1]
      b = imageData[index+2]

      brightness = (r + g + b)/3

      imageData[index] = brightness
      imageData[index+1] = brightness
      imageData[index+2] = brightness

    frame.data = imageData

    @newFrames.push frame

  self.postMessage @newFrames


, false)



