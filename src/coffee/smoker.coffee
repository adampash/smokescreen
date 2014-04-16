class window.Smoker
  constructor: (@canvas, @context) ->
    @frames = []
    @smallFrames = []
    @bnwFrames = []
    @segments = {}
    @xFrames = []


  setBNW: (frames) ->
    @bnwFrames = frames.slice(0)
    if @faces? and @xFrames.length is 0
      @processXFrames()

  setFrames: (frames, fps) ->
    @frames = frames.slice(0)
    @width = @frames[0].width
    @height = @frames[0].height
    @segments.raw =
      frames: @frames
    @fps = fps

  setSmall: (frames) ->
    @smallFrames = frames.slice(0)

  findFaces: ->
    window.converter = new Converter(@smallFrames[0].width)
    converter.runWorker(@smallFrames, (faces, faceCollection) =>
      @faces = faces
      @faceCollection = faceCollection
      @faceCollection.applyScale(@frames[0].width/@smallFrames[0].width)
      @faceCollection.fillInBlanks(3)
      log 'got all the faces', @faces
      if @bnwFrames.length > 0 and @xFrames.length is 0
        @processXFrames()
      # @segments.rawRects =
      #   frames: @frames
      #   addition: (ctx, index) =>
      #     @drawFaces(ctx, index)
    )


  processXFrames: (inProcess, index) ->
    inProcess = inProcess or @bnwFrames.slice(0)
    index = index or 0
    frame = inProcess.shift()
    @context.putImageData(frame, 0, 0)
    @drawFaces @context, index
    @xFrames.push @context.getImageData 0, 0, @canvas.width, @canvas.height

    if inProcess.length > 0
      setTimeout =>
        index++
        @processXFrames(inProcess, index)
      , 50
    else
      log 'done with processXFrames'
      @segments.xFrames =
        frames: @xFrames
        addition: @pulseMouths
        # postprocess: @pulseBlack
        preprocess: @pulseBlack

      log 'set up zooms'
      @setupZooms()


  setupZooms: ->
    if @faces.length > 0
      zoomFaces = []
      # TODO @faceCollection.threeBestFaces()
      for i in [0..2]
        if i < @faces.length
          zoomFaces[i] = @faces[i]
        else
          zoomFaces[i] = @faces[0]
      @zoomOnFace(zoomFaces[0], (frames) =>
        log 'zoom ready'
        @segments.firstFace =
          frames: frames
          # addition: @pulseMouths
          # preprocess: @pulseBlack
          addition: @fadeInOut
          start: ->
            new soundAnalyzer().playSound()
        @getSecondFace(zoomFaces)
      )
    else
      log 'no faces to zoom on'

  zoomOnFace: (face, complete) ->
    return if !face.frames? or face.frames.length < 7

    frames = @bnwFrames.slice(0)

    centerFace = face.frames[6]
    # TODO face.averageFace
    crop = new Cropper
      width: @width
      height: @height
    crop.queue(centerFace, frames)
    crop.start (frames) =>
      console.log 'done running cropper'
      complete(frames)

  getSecondFace: (zoomFaces) ->
    @zoomOnFace(zoomFaces[1], (frames) =>
      @segments.secondFace =
        frames: frames
        addition: @fadeInOut
      @getThirdFace(zoomFaces)
    )

  getThirdFace: (zoomFaces) ->
    @zoomOnFace(zoomFaces[2], (frames) =>
      @segments.thirdFace =
        frames: frames
        addition: @fadeInOut

      @getAlphaFace()
    )

  getAlphaFace: ->
    log 'get alpha face'
    face = @faces[0].frames[8]
    frame = @bnwFrames.slice(8, 9)[0]

    crop = new Cropper
      width: @width
      height: @height

    @alphaFace = crop.zoomToFit(face, frame, true)
    @alphaFrames = []
    for i in [0..30]
      @alphaFrames.push @alphaFace
    @segments.alphaFace =
      frames: @alphaFrames
      addition: @drawAlphaFace

  drawFaces: (ctx, index) ->
    if @faces.length > 0
      for face in @faces
        face.drawFace ctx, index

  pulseBlack: (frame) =>
    log 'pulse black'
    idata = frame.data
    trans = Math.floor (255 - audioIntensity * 255) + 100
    # trans = 150 - trans
    # trans = Math.floor trans/60 * 255
    # log trans

    for pixel, index in idata by 4
      r = idata[index]
      g = idata[index+1]
      # b = idata[index+2]

      # total = r + g + b
      # debugger
      if r is 5 and g is 0
        # c = trans * 0.5
        # idata[index] = c
        # idata[index+1] = c
        # idata[index+2] = c
        idata[index+3] = 0
        # debugger

    frame.data = idata
    frame

  fadeInOut: (ctx, index) ->
    # totalFrames = totalFrames or 90
    if index < 45
      alpha = 1 - index/45
      ctx.fillStyle = 'rgba(0, 0, 0,' + alpha + ')'
      ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
    else if index > 45
      alpha = index%45/45
      ctx.fillStyle = 'rgba(0, 0, 0,' + alpha + ')'
      ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)

  pulseMouths: (ctx, index) =>
    if @faces.length > 0
      for face in @faces
        face.pulse ctx, index, audioIntensity

  drawAlphaFace: (ctx, index) =>
    frame =
      width: ctx.canvas.width
      height: ctx.canvas.height

    face =
      eyebar:
        x: frame.width / 3
        y: frame.height / 3
        width: frame.width / 3
        height: frame.height / 12



    # ctx.globalCompositeOperation = 'destination-out'
    ctx.fillStyle = 'black'

    ctx.fillRect(face.eyebar.x, face.eyebar.y, face.eyebar.width, face.eyebar.height)
