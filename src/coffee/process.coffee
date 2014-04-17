window.process =
  cbrFilter: (frame) ->
    idata = frame.data

    for pixel, index in idata by 4
      r = idata[index]
      g = idata[index+1]
      b = idata[index+2]

      y  = 0.299 * r + 0.587 * g + 0.114 * b
      cB = 128 + (-0.169 * r + 0.331 * g + 0.5 * b)
      cR = 128 + (0.5 * r - 0.419 * g - 0.081 * b)

      if cR > 80 && cR > 127 && cB > 137 && cB < 165 && y > 26 && y < 226
      # if r > 100
       idata[index]   = 255
       idata[index+1] = 255
       idata[index+2] = 255
       if audioIntensity?
         alpha = ((255 - audioIntensity * 255) + 100) / 200
       else
         window.audioIntensity = 0
       idata[index+3] = alpha
      else
       idata[index+3] = 0

    frame.data = idata
    frame
