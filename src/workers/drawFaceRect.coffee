importScripts('/workers/blurMethods.js')

self.addEventListener('message', (e) ->
  @frames = e.data.frames
  @frameNumber = e.data.frameNumber
  @scale = e.data.scale
  spacer = e.data.spacer || 0

  if e.data.faces?
    faces = JSON.parse e.data.faces

  @newFrames = []

  for frame, index in @frames
    console.log frame.width
    console.log frame.height
    width = frame.width * 4
    height = frame.height
    imageData = frame.data

    if faces?
      face = faces[0]

    if face?
      for key of face
        face[key] = Math.round(face[key] * scale)

      face.y += spacer if spacer?
      console.log JSON.stringify face
      eyebar =
        x: face.x
        width: face.width
        y: Math.round(face.y + face.height / 4)
        height: Math.round(face.height / 4)

      # for row in [face.y..face.y+face.height]
      #   for column in [(face.x*4)..(face.x+face.width)*4]
      for row in [eyebar.y..eyebar.y+eyebar.height]
        for column in [(eyebar.x*4)..(eyebar.x+eyebar.width)*4]
          pixel = (row * width) + column
          # imageData = blurPixel(pixel, imageData, width)
          imageData[pixel] = 0

      mouth =
        x: Math.round(face.x + face.width/4)
        width: Math.round(face.width/2)
        y: Math.round(face.y + (face.height/4*3))
        height: Math.round(face.height/4)

      for row in [mouth.y..mouth.y+mouth.height]
        for column in [(mouth.x*4)..(mouth.x+mouth.width)*4]
          pixel = (row * width) + column
          # imageData = blurPixel(pixel, imageData, width)
          imageData[pixel] = 0
      # for pixel, index in imageData by 4
      #   row = Math.floor(index/width)
      #   column = index % width

      #   if face?
      #     point =
      #       x: row
      #       y: column

      #     a =
      #       x: face.x * scale
      #       y: (face.y + height) * scale
      #     b =
      #       x: (face.x + face.width) * scale
      #       y: face.y * scale

      #     # if index > width * 2 and index < width * 2 + 30
      #     #   console.log "point"
      #     #   console.log JSON.stringify point

      #     if isInsideSquare a,b,point
      #       # console.log "we have a winner"
      #       imageData[index] = 255
      #       imageData[index + 1] = 255
      #       imageData[index + 2] = 255


    frame.data = imageData

    @newFrames.push frame

  self.postMessage @newFrames


, false)
