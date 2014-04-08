class window.Faces
  constructor: (faces) ->
    if faces.length?
      @allFaces = @flatten faces
    else
      @allFaces = faces || []
    @calculateAvgFace()

    @facesByFrames = faces

  groupFaces2: (frames, faces) ->
    # if !frames?
    #   @removeAnomolies()
    frames = frames || @reconstruct()
    faces = faces || []
    frameNumber = frameNumber || 0

    thisFace = new Face()
    faces.push thisFace
    console.log faces

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
    console.log 'we have our first face', thisFace

    thisFace.findRelatives(frames)

    # check if frames still has faces in it
    # if it does, tail recurse this method
    if @empty(frames)
      console.log 'i guess it is empty', frames
      faces
    else
      console.log 'find a new face!'
      @groupFaces2(frames, faces)

  empty: (arrayOfArrays) ->
    i = 0
    empty = true
    while empty || i < arrayOfArrays.length
      console.log arrayOfArrays[i].length
      empty = false if arrayOfArrays[i].length > 0
      i++
    empty

  groupFaces: (frames, faces, thisFace, frameNumber, started, currentFace) ->
    if !frames?
      @removeAnomolies()
    frames = frames || @reconstruct()
    faces = faces || []
    frameNumber = frameNumber || 0
    unless thisFace?
      thisFace = new Face()
      faces.push thisFace

    # does a frame exist with this frame number?
    unless frames[frameNumber]?
      # start over with thisFace = null if there are still faces in the frames array
      # TODO need to implement above
      # other wise return all faces
      console.log 'done', faces
      return faces

    # otherwise, this frame is that frameNumber
    thisFrame = frames[frameNumber]

    # does this frame have a face in it?
    if !currentFace?
      if thisFrame[0]?
        currentFace = thisFrame[0]
        thisFrame.splice(0, 1)
      else
        currentFace = undefined

    # add currentFace to thisFace unless it's already initialized
    if !thisFace.isBegun()
      console.log 'push currentFace', currentFace
      thisFace.frames.push currentFace

    # if we have a defined currentFace
    if currentFace?
      # find closestMatch in closest following frame
      closestFace = false
      until closestFace || frameNumber > frames.length
        if frames[frameNumber+1]?
          nextFrame = frames[frameNumber+1]
          if nextFrame.length
            closestFace = @findClosestFaceIn(nextFrame, face)
          else
            console.log 'push undefined', 'undefined'
            thisFace.frames.push undefined
            frameNumber++
        else
          return faces

      console.log currentFace
      # if it's a close enough match, connect these faces
      if Math.abs(1 - currentFace.width / closestFace.width) < 0.6 and 
         @distance(currentFace, closestFace) < currentFace.width * 0.6
          console.log 'push closestFace', closestFace
          thisFace.frames.push closestFace
          for face, index in nextFrame
            if face is closestFace
              console.log 'we have a match at ', index, face
              nextFrame.splice(index, 1)

          console.log "it's a match"
          @groupFaces(frames, faces, thisFace, frameNumber+1, true, closestFace)

    # if not, push an empty face iteration
    else
      console.log 'push empty'
      thisFace.frames[frameNumber + 1] = undefined


    if frameNumber < frames.length
      @groupFaces(frames, faces, thisFace, frameNumber+1, true)

    # make this a recursive method; 
    # frames decrease when no faces left
    # faces are removed from frames when associated with an existing face
    # an object builds all the diff faces recursively from within
    #
    # tail recurse with face 1 in frame 1 all the way to the end
    # all those associated faces should now be removed
    # then tail recurse with face 2 in frame 1 all the way to the end
    # when frame 1 is empty remove frame 1 and tail recurse with face 1 frame 2. etc

    # if frames.length > 1 and frames[frameNumber].length
    #   debugger
    #   frame = frames[frameNumber]
    #   face = frame[0]
    #   if !thisFace.isBegun()
    #     thisFace.frames.push face

    #   closestFace = false
    #   i = 1
    #   until closestFace
    #     nextFrame = frames[frameNumber+i]
    #     if nextFrame.length
    #       closestFace = @findClosestFaceIn(nextFrame, face)
    #     else
    #       thisFace.frames.push undefined
    #     i++


    #   # if it's a close enough match, connect these faces
    #   if Math.abs(1 - face.width / closestFace.width) < 0.6 and 
    #      @distance(face, closestFace) < face.width * 0.6
    #       thisFace.frames[frameNumber + 1] = closestFace
    #       console.log "it's a match"
    #       debugger
    #       frame.shift()
    #       debugger
    #       @groupFaces(frames, faces, thisFace, frameNumber+1, true)

    #   # if not, push an empty face iteration
    #   else
    #     thisFace[frameNumber + 1] = undefined

    # else if frames[1]? and frames[1].length is 0
    #   frames.splice(1,1)
    #   faces
    #   # @groupFaces(frames, faces, thisFace, frameNumber+1, true)
    #   # console.log 1, faces

    # else
    #   # get rid of this frame
    #   # frames.shift()

    #   # add an empty version of this face
    #   if frameNumber is 0 or frames[0]? and frames[0].length is 0
    #     thisFace.frames.push undefined

    #   #recurse
    #   console.log "frames.length: ", frames.length
    #   console.log "frameNumber: ", frameNumber
    #   if frames.length > 0 || frameNumber == frames.length
    #     if thisFace.isBegun()
    #       @groupFaces(frames, faces, thisFace, frameNumber, true)
    #       # console.log 0, faces
    #     else
    #       @groupFaces(frames, faces, thisFace, frameNumber+1, true)
    #       # console.log 2, faces
    #   else
    #     console.log 'done; here are the faces'
    #     faces

  distance: (obj1, obj2) ->
    Math.sqrt(Math.pow((obj1.x - obj2.x), 2) + Math.pow((obj1.y - obj2.y), 2))

  findClosestFaceIn: (faces, newFace) ->
    sorted = faces.sort (a, b) =>
      @distance(a, newFace) - @distance(b, newFace)

    sorted[0]

  removeAnomolies: ->
    goodFaces = []
    newNumFaces = 0
    for face, index in @allFaces
      if !face.frame
        if Math.abs(1 - face.width*face.height / @avgFace) < 0.5
          goodFaces.push face
          newNumFaces++
      else
        goodFaces.push face
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


class window.Face
  constructor: () ->
    @frames = []
    @started = null

  findRelatives: (frames) ->
    # add the first face available in the array of frames
    nextFrame = false
    # console.log frames
    until nextFrame || @frames.length > frames.length
      if frames[@frames.length].length
        nextFrame = frames[@frames.length]
      else
        @frames.push undefined

    console.log 'we have our next frame', nextFrame
    closestFaces = @findClosestFaceIn(nextFrame)
    console.log 'sorted possible matches are', closestFaces

    bestMatch = @returnBestMatch(closestFaces)
    console.log "bestMatch is", bestMatch
    if bestMatch
      @frames.push bestMatch
    else
      @frames.push undefined

    if @frames.length != frames.length
      @findRelatives(frames)
    else
      @

  returnBestMatch: (faces) ->
    face = @getLatestFace()

    match = false

    i = 0
    until match or i > faces.length
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
    until face || i < 0
      face = @frames[@frames.length-i]
      i++
    face


  findClosestFaceIn: (frame) ->
    face = @getLatestFace()
    sorted = frame.sort (a, b) =>
      @distance(a, face) - @distance(b, face)

    sorted

  distance: (obj1, obj2) ->
    Math.sqrt(Math.pow((obj1.x - obj2.x), 2) + Math.pow((obj1.y - obj2.y), 2))


  isBegun: ->
    return @started if @started?
    if @frames.length > 0
      for frame in @frames
        if frame?
          @started = true
          return @started

      false

    else
      false


# class window.Face
#   constructor: (@x, @y, @area) ->
#     @avg =
#       x: @x
#       y: @y
#       area: @area
#     @locations = []
#     @locations.push(
#       x: @x
#       y: @y
#       area: @area
#     )
#     @certainty = 0
# 
#   newPosition: (@x, @y, @area) ->
#     @locations.push
#       x: @x
#       y: @y
#       area: @area
# 
# 
#   averageArea: ->
#     avgArea = (@locations.reduce((a, b, c, d) ->
#       a + b.area
#     , 0) / @locations.length)
#     avgArea
# 
#   standardDeviation: ->
#     avg = @averageArea()
#     distances = @locations.map (obj, index) ->
#       Math.pow(avg - obj.area, 2)
#     variance = distances.reduce((a, b) ->
#       a + b
#     , 0) / distances.length
#     Math.sqrt(variance)
# 
#   calculateCertainty: (maxLocations) ->
#     @certainty = @locations.length / maxLocations
# 
# 
# # function findFaces() {
# #   window.faceCollection = new Faces();
# #   faceCoords.forEach(function(obj, index) {
# #     obj.forEach(function(face, index) {
# #       if (faceCollection.faces.length == 0) {
# #         faceCollection.faces.push(new Face(face.x, face.y, face.width * face.height));
# #       }
# #       if (faceCollection.faces.length > 0) {
# #         possibleMatch = closestFace(faceCollection.faces, face);
# #         if (distance(possibleMatch, face) < Math.sqrt(possibleMatch.area) / 5) {
# #           if (possibleMatch.area - (face.width * face.height) < possibleMatch.standardDeviation()) {
# #             possibleMatch.newPosition(face.x, face.y, face.width * face.height);
# #           }
# #         }
# #           else {
# #             faceCollection.faces.push(new Face(face.x, face.y, face.width * face.height));
# #           }
# #       }
# #     });
# #   });
# #   faceCollection.calculateCertainties();
# # }
