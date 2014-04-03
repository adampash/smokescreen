self.addEventListener('message', (e) ->
  @frames = e.data
  @newFrames = []

  for frame, index in @frames
    imageData = frame.data

    for pixel, index in imageData by 4
      r = imageData[index]
      g = imageData[index + 1]
      b = imageData[index + 2]

      if r < 255/2
        imageData[index] = r
      else
        imageData[index] = (r + 255) / 2
      if g < 255/2
        imageData[index+1] = g
      else
        imageData[index+1] = (g + 255) / 2
      if b < 255/2
        imageData[index+2] = b
      else
        imageData[index+2] = (b + 255) / 2

    frame.data = imageData

    @newFrames.push frame

  self.postMessage @newFrames


, false)


