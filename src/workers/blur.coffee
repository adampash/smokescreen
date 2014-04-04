importScripts('/workers/blurMethods.js')

self.addEventListener('message', (e) ->
  @frames = e.data
  @newFrames = []

  for frame, index in @frames
    frame.data = blur(frame, 1)

    @newFrames.push frame

  self.postMessage @newFrames


, false)



