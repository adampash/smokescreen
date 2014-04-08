class window.Faces
  constructor: (faces) ->
    if faces.length?
      @allFaces = @flatten faces
    else
      @allFaces = faces || []
    @calculateAvgFace()

    @facesByFrames = faces

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
      faces
    else
      @groupFaces(frames, faces)

  empty: (arrayOfArrays) ->
    i = 0
    empty = true
    while empty and i < arrayOfArrays.length
      empty = false if arrayOfArrays[i].length > 0
      i++
    empty

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
    until nextFrame || @frames.length > frames.length
      if frames[@frames.length].length
        nextFrame = frames[@frames.length]
      else
        @frames.push undefined

    closestFaces = @findClosestFaceIn(nextFrame)

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
