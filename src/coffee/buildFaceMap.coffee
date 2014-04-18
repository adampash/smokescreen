class Faces
  constructor: (faces, @scale) ->
    if faces.length?
      @allFaces = @flatten faces
    else
      @allFaces = faces || []
    @calculateAvgFace()

    @facesByFrames = faces

  sortByCertainty: (faces) ->
    faces.sort (a, b) ->
      b.certainty - a.certainty
    faces


  groupFaces: (frames, faces) ->
    if !frames?
      @removeAnomolies()
    frames = frames || @reconstruct()
    faces = faces || []
    frameNumber = frameNumber || 0

    thisFace = new Face()
    faces.push thisFace

    # add the first face available in the array of frames
    firstFace = false
    i = 0
    until firstFace || i > frames.length
      if frames[i]? and frames[i].length
        firstFace = frames[i][0]
        frames[i].splice(0, 1)
      else
        thisFace.frames.push undefined
        i++

    thisFace.frames.push firstFace

    if !@empty(frames)
      thisFace.findRelatives(frames)

    # check if frames still has faces in it
    # if it does, tail recurse this method
    if @empty(frames)
      faces = @verifyFrameNumbers(faces, frames.length)
      faces = @removeProbableFalse(faces)
      # faces = @applyScale(@scale)
      @faceMap = faces
      faces
    else
      @groupFaces(frames, faces)

  applyScale: (scale) ->
    for face in @faceMap
      face.applyScale(scale)
    @faceMap

  removeProbableFalse: (faces) ->
    newFaces = []
    for face in faces
      console.log face.probability()
      if face.probability() > 0.18
        newFaces.push face
      else
        console.log 'removing ', face
    newFaces

  verifyFrameNumbers: (faces, numFrames) ->
    console.log 'all faces should have ' + numFrames + ' frames'
    fixedFaces = faces.map (face) ->
      if face.frames.length < numFrames
        until face.frames.length == numFrames
          face.frames.push undefined
      else if face.frames.length > numFrames
        face.frames.splice(numFrames, -1)
      face
    fixedFaces

  empty: (arrayOfArrays) ->
    i = 0
    empty = true
    console.log 'checking for empty'
    while empty and i < arrayOfArrays.length
      empty = false if arrayOfArrays[i].length > 0
      i++
    empty

  prepareForCanvas: (faces) ->
    faces = faces or @faceMap
    frames = []
    for face in faces
      for frame, index in face.frames
        frames[index] = [] unless frames[index]?
        frames[index].push frame if frame?
    frames

  fillInBlanks: ->
    for face in @faceMap
      face.fillInBlanks(3)
    @faceMap

  removeAnomolies: ->
    goodFaces = []
    newNumFaces = 0
    for face, index in @allFaces
      if !face.frame
        # face size is within x% of avg face size
        if Math.abs(1 - face.width*face.height / @avgFace) < 0.7
          goodFaces.push face
          newNumFaces++
      else
        goodFaces.push face

    console.log 'started with ' + @allFaces.length + ' and ending with ' + goodFaces.length
    @allFaces = goodFaces
    @numFaces = newNumFaces


  flatten: (faces) ->
    newFaces = []
    @numFaces = 0
    faces.map (facesArray, index) =>
      newFaces.push
        frame: true
        num: index
      facesArray.map (face) =>
        @numFaces++
        newFaces.push face
    newFaces

  reconstruct: ->
    console.log 'there are ' + @facesByFrames.length + ' frames and ' + @numFaces + ' faces total which adds up to ' + @allFaces.length
    facesInFrames = []
    for face, index in @allFaces
      if face.frame
        i = 1
        facesInFrames.push []
        while typeof @allFaces[index + i] is "object" and @allFaces[index + i].x?
          facesInFrames[facesInFrames.length-1].push @allFaces[index + i]
          i++
    facesInFrames

  calculateAvgFace: ->
    totalFaceArea = @allFaces.reduce((accumulator, face) ->
      if face.width?
        accumulator += face.width * face.height
      else
        accumulator
    , 0)
    @avgFace = totalFaceArea / @numFaces


class Face
  constructor: () ->
    @frames = []
    @started = null


  getAverageFace: ->
    return @averageFace if @averageFace?
    allX = 0
    allY = 0
    allWidth = 0
    allHeight = 0
    for frame in @frames
      allX += frame.x
      allY += frame.y
      allWidth += frame.width
      allHeight += frame.height

    length = @frames.length
    @averageFace =
      x: allX/length
      y: allY/length
      width: allWidth / length
      height: allHeight / length

  applyScale: (scale) ->
    for frame in @frames
      for key of frame
        frame[key] = Math.round(frame[key] * scale)
    @

  probability: ->
    @certainty = 1 - @emptyFrames() / @frames.length

  emptyFrames: ->
    numEmpty = 0
    for frame in @frames
      numEmpty++ if frame is undefined or frame is false

    numEmpty

  padFrames: (padding) ->
    newFrames = []
    for frame in @frames
      newFrames.push frame
      for num in [padding..0]
        newFrames.push undefined

    @frames = newFrames


  fillInBlanks: (padding) ->
    if padding?
      @padFrames(padding)
    i = 0
    for frame, index in @frames
      if frame is undefined
        @fillIn(index)

        i++
    console.log 'we had ' + i + ' frames that needed filling in'
    @fillInEyesAndMouth()

  fillIn: (index) ->
    if index is 0
      # find first match and fill in with it
      match = false
      i = 1
      until match
        match = @frames[index+i] unless @frames[index+i] is undefined
        i++
      @frames[index] = match

    else if index is @frames.length - 1
      @frames[index] = @frames[index-1]
      #only go backward
    else
      # go in both directions
      lastFrame = @frames[index-1]
      match = false
      i = 1
      until match or index+i >= @frames.length
        unless @frames[index+i] is undefined
          match = @frames[index+i] 
        else
          i++
      if match
        @fillBetween(index-1, index+i)
        # @frames[index] = match
      else
        @frames[index] = lastFrame

  fillBetween: (index1, index2) ->
    numFrames = index2 - index1
    firstFrame = @frames[index1]
    lastFrame = @frames[index2]

    xDiff = firstFrame.x - lastFrame.x
    yDiff = firstFrame.y - lastFrame.y
    widthDiff = firstFrame.width - lastFrame.width

    applyDiff =
      x: Math.round xDiff / numFrames
      y: Math.round yDiff / numFrames
      width: Math.round widthDiff / numFrames

    i = index1+1
    until i == index2
      @frames[i] =
        x: @frames[i-1].x - applyDiff.x
        y: @frames[i-1].y - applyDiff.y
        width: @frames[i-1].width - applyDiff.width
        height: @frames[i-1].height - applyDiff.width
      i++


  findRelatives: (frames) ->
    # add the first face available in the array of frames
    nextFrame = false
    until nextFrame || @frames.length > frames.length
      if frames[@frames.length]? and frames[@frames.length].length
        nextFrame = frames[@frames.length]
      else
        @frames.push undefined

    closestFaces = @findClosestFaceIn(nextFrame) if nextFrame

    bestMatch = @returnBestMatch(closestFaces)
    console.log "bestMatch is", bestMatch
    if bestMatch
      @frames.push bestMatch
    else
      @frames.push undefined

    if @frames.length < frames.length
      @findRelatives(frames)
    else
      @

  returnBestMatch: (faces) ->
    match = false

    if faces? and faces.length > 0
      face = @getLatestFace()

      i = 0
      until match or i > faces.length
        if faces[i]?
          testFace = faces[i]
          if Math.abs(1 - face.width / testFace.width) < 0.6 and 
                              @distance(face, testFace) < face.width * 0.6
            faces.splice(i, 1)
            match = testFace
        i++
    return match

  getLatestFace: ->
    i = 1
    face = false
    until face || i > @frames.length
      face = @frames[@frames.length-i]
      i++

    face

  fillInEyesAndMouth: ->
    for frame in @frames
      frame.eyebar =
        x: Math.round(frame.x + frame.width/10)
        width: Math.round(frame.width/10 * 8)
        y: Math.round(frame.y + frame.height / 3.7)
        height: Math.round(frame.height / 4)
      frame.mouth =
        x: Math.round(frame.x + frame.width/4)
        width: Math.round(frame.width/2)
        y: Math.round(frame.y + (frame.height/5*3.2))
        height: Math.round(frame.height/2)
      frame.mouth.center =
        x: Math.round frame.mouth.x + frame.mouth.width/2
        y: Math.round frame.mouth.y + frame.mouth.height/2
    @frames

  findClosestFaceIn: (frame) ->
    face = @getLatestFace()
    sorted = frame.sort (a, b) =>
      @distance(a, face) - @distance(b, face)

    sorted

  distance: (obj1, obj2) ->
    Math.sqrt(Math.pow((obj1.x - obj2.x), 2) + Math.pow((obj1.y - obj2.y), 2))

  pulse: (ctx, index, amount, type) ->
    mouth = @frames[index].mouth

    ctx.fillStyle = 'rgba(255, 255, 255, 1.0)'
    ctx.beginPath()
    pulseAmount = mouth.width/3 * amount * 1.5
    ctx.arc(mouth.center.x, mouth.center.y, pulseAmount, 0, 2 * Math.PI, false)

    # alpha = ((255 - audioIntensity * 255) + 100) / 200
    # log alpha

    # log type
    ctx.globalCompositeOperation = 'source-over'
    if type is 1
      ctx.fillStyle = 'white'
    else if type is 4
      ctx.fillStyle = 'black'
    else if type is 2
      ctx.fillStyle = 'black'
    else
      ctx.globalCompositeOperation = 'destination-out'
      ctx.fillStyle = 'black'

    ctx.fill()
    ctx.globalCompositeOperation = 'source-over'

  drawFace: (ctx, index, type) ->
    face = @frames[index]

    if type is 1
      ctx.fillStyle = 'black'
      ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
      ctx.fillStyle = 'white'
    else if type is 4
      ctx.fillStyle = 'black'
    else if type is 2
      ctx.fillStyle = 'black'
    else if type is 3
      ctx.globalCompositeOperation = 'destination-out'
      ctx.fillStyle = 'black'
      # ctx.fillStyle = 'rgba(5, 0, 0, 1.0)'
    ctx.fillRect(face.eyebar.x, face.eyebar.y, face.eyebar.width, face.eyebar.height)

    mouthQuarterX = face.mouth.width/4
    mouthQuarterY = face.mouth.height/4

    ctx.beginPath()
    ctx.moveTo(face.mouth.x, face.mouth.y + mouthQuarterY)
    ctx.lineTo(face.mouth.x + mouthQuarterX*3, face.mouth.y+face.mouth.height)
    ctx.lineTo(face.mouth.x + face.mouth.width, face.mouth.y+mouthQuarterY*3)
    ctx.lineTo(face.mouth.x + mouthQuarterX, face.mouth.y)
    ctx.fill()
    ctx.moveTo(face.mouth.x + mouthQuarterX*3, face.mouth.y)
    ctx.lineTo(face.mouth.x, face.mouth.y+mouthQuarterY*3)
    ctx.lineTo(face.mouth.x+mouthQuarterX, face.mouth.y+face.mouth.height)
    ctx.lineTo(face.mouth.x+face.mouth.width, face.mouth.y+mouthQuarterY)
    ctx.fill()

    ctx.globalCompositeOperation = 'source-over'


  isBegun: ->
    return @started if @started?
    if @frames.length > 0
      for frame in @frames
        if frame? and frame
          @started = true
          return @started

      console.log 'false'
      return false

    else
      return false
