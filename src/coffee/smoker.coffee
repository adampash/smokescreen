class Smoker
  constructor: (@canvas, @context, @player) ->
    @frames = []
    @smallFrames = []
    @bnwFrames = []
    @segments = {}
    @xFrames = []
    @xFrames2 = []
    @xFrames3 = []


  setBNW: (frames) ->
    @bnwFrames = frames.slice(0)
    @segments.xFrames =
      frames: @bnwFrames
      loop: true
      addition: (ctx, index) =>
        @pulseMouths(ctx, index, 1)
      start: =>
        new soundAnalyzer(@player).playSound()
    if @faces? #and @xFrames.length is 0
      # log 'bnw setup zooms'
      @setupZooms()
      # @processXFrames(null, null, 1)

  setFrames: (frames, fps) ->
    @frames = frames.slice(0)
    @width = @frames[0].width
    @height = @frames[0].height
    @segments.raw =
      frames: @frames
      # preprocess: @cbrFilter
    @fps = fps

  setSmall: (frames) ->
    @smallFrames = frames.slice(0)

  findFaces: ->
    converter = new Converter(@smallFrames[0].width)
    converter.runWorker(@smallFrames, (faces, faceCollection) =>
      @faceCollection = faceCollection
      @faces = @faceCollection.sortByCertainty(faces)
      @faceCollection.applyScale(@frames[0].width/@smallFrames[0].width)
      @faceCollection.fillInBlanks(3)
      @smallFrames = []
      @frames = []
      converter = null
      @player.recorder = null
      @player.smallRecorder = null
      log 'got all the faces', @faces
      if @bnwFrames.length > 0 #and @xFrames.length is 0
        # @processXFrames(null, null, 1)
        # log 'findFaces setup zooms'
        @setupZooms()
      # @segments.rawRects =
      #   frames: @frames
      #   addition: (ctx, index) =>
      #     @drawFaces(ctx, index)
    )


  processXFrames: (inProcess, index, type) ->
    inProcess = inProcess or @bnwFrames.slice(0)
    index = index or 0
    frame = inProcess.shift()
    @context.putImageData(frame, 0, 0)
    @drawFaces @context, index, type
    if type is 1
      @xFrames.push @context.getImageData 0, 0, @canvas.width, @canvas.height
    else if type is 2
      @xFrames2.push @context.getImageData 0, 0, @canvas.width, @canvas.height
    else
      @xFrames3.push @context.getImageData 0, 0, @canvas.width, @canvas.height

    if inProcess.length > 0
      setTimeout =>
        log index
        index++
        @processXFrames(inProcess, index, type)
      , 50
    else
      log 'done with processXFrames ' + type
      # if type is 1
      #   @segments.xFrames =
      #     frames: @xFrames
      #     loop: true
      #     addition: (ctx, index) =>
      #       @pulseMouths(ctx, index, 1)
      #     # postprocess: @pulseBlack
      #     # preprocess: @pulseBlack
      #   # @setupZooms()
      #   @processXFrames(null, null, 2)

      # else if type is 2
      if type is 2
        @segments.xFrames2 =
          frames: @xFrames2
          loop: true
          addition: (ctx, index) =>
            @pulseMouths(ctx, index, 2)
          # postprocess: @pulseBlack
          # preprocess: @pulseBlack
        @processXFrames(null, null, 3)
        # @setupZooms()
      else
        @segments.xFrames3 =
          frames: @xFrames3
          loop: true
          addition: (ctx, index) =>
            @pulseMouths(ctx, index, 3)
          # postprocess: @pulseBlack
          # preprocess: @pulseBlack


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
        index = 0
        # until frames.length is 260
        #   frames.push frames[index]
        #   index++
        #   if index > frames.length - 1
        #     index = 0
        @segments.firstFace =
          frames: frames
          # loop: true
          # addition: @pulseMouths
          # preprocess: @alphaInOut
          addition: @fadeInOut
          # complete: =>
          #   @segments.firstFace = null
        @getSecondFace(zoomFaces)
      )
    else
      log 'no faces to zoom on'

  zoomOnFace: (face, complete) ->
    return if !face.frames? or face.frames.length < 7
    log 'zoomonface'

    frames = @bnwFrames

    # centerFace = face.frames[6]
    centerFace = face.getAverageFace()
    # TODO face.averageFace
    crop = new Cropper
      width: @width
      height: @height
    crop.queue(centerFace, frames)
    crop.start (frames) =>
      console.log 'done running cropper'
      complete(frames)
      crop = null
      frames = null

  getSecondFace: (zoomFaces) ->
    @zoomOnFace(zoomFaces[1], (frames) =>
      log 'got second face'
      @segments.secondFace =
        frames: frames
        addition: @fadeInOut
        # complete: =>
        #   @segments.secondFace = null
        #   setTimeout =>
        #     log 'second face done, now process xFrames3'
        #     @processXFrames(null, null, 3)
        #   , 500
      # @getThirdFace(zoomFaces)
      @processXFrames(null, null, 2)
    )

  getThirdFace: (zoomFaces) ->
    @zoomOnFace(zoomFaces[2], (frames) =>
      @segments.thirdFace =
        frames: frames
        # addition: @fadeInOut
        preprocess: @cbrFilter

      @processXFrames(null, null, 1)
      # @getAlphaFace()
    )

  getAlphaFace: ->
    log 'get alpha face'
    face = @faces[0].frames[8]
    # frame = @bnwFrames.slice(8, 9)[0]
    frame = @frames.slice(8, 9)[0]

    crop = new Cropper
      width: @width
      height: @height

    @alphaFace = crop.zoomToFit(face, frame, true)
    @alphaFrames = []
    for i in [0..190]
      @alphaFrames.push @alphaFace
    @segments.alphaFace =
      frames: @alphaFrames
      # preprocess: @cbrFilter
      # addition: @drawAlphaFace

  drawFaces: (ctx, index, type) ->
    if type is 1
      @activeFaces = @faces.slice(0, 1)
    if type is 2
      @activeFaces = @faces.slice(0, 3)
    if type is 3
      @activeFaces = @faces
    if @activeFaces.length > 0
      for face in @activeFaces
        face.drawFace ctx, index, type

  pulseBlack: (frame) =>
    idata = frame.data
    trans = Math.floor (255 - audioIntensity * 255) + 100

    for pixel, index in idata by 4
      r = idata[index]
      g = idata[index+1]
      # b = idata[index+2]

      # total = r + g + b
      # debugger
      # if r is 5 and g is 0
      if r is 5 and g is 0
        # c = trans * 0.5
        # idata[index] = c
        # idata[index+1] = c
        # idata[index+2] = c
        idata[index+3] = 0
        # debugger

    frame.data = idata
    frame

  cbrFilter: (frame) ->
    # inProcess = inProcess or @frames.slice(0)
    # index = index or 0
    # frame = inProcess.shift()
    process.cbrFilter frame

  fadeInOut: (ctx, index) ->
    # totalFrames = totalFrames or 90
    if index < 30
      alpha = 1 - index/30
      ctx.fillStyle = 'rgba(0, 0, 0,' + alpha + ')'
    else if index > 30
      alpha = index%30/30
      ctx.fillStyle = 'rgba(0, 0, 0,' + alpha + ')'

    ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)

  alphaInOut: (frame, index) ->
    if index < 45
      alpha = 255 * (1 - index/45)
    else if index > 45
      alpha = 255 * (index%45/45)

    log index
    log alpha
    alpha = Math.floor alpha

    idata = frame.data
    for pixel, index in idata
      idata[index+3] = alpha

    frame.data = idata
    frame

  pulseMouths: (ctx, index, type) =>
    @type = type
    if @faces.length > 0
      if type is 1
        face = @faces[0]
        faces = [face]
        if @stopIn?
          type = 4
          @type = type
          @stopIn--
          log 'stopIn', @stopIn
          if @stopIn % 2 is 0
            ctx.fillStyle = 'rgba(0, 0, 0, 0.8)'
            ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
          else
            ctx.fillStyle = 'rgba(0, 0, 0, 0.6)'
            ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
          if @stopIn < 1
            log 'stop for real ' + type
            @stopIn = null
            @player.cPlayer.stop = true
        else
          ctx.fillStyle = 'black'
          ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
        face.drawFace(ctx, index, type)
      else if type is 2
        faces = @faces.slice(0, 3)
        # if @stopIn?
        #   @stopIn--
        #   if @stopIn < 1
        #     log 'stop for real ' + type
        #     @stopIn = null
        #     @player.cPlayer.stop = true
      else
        faces = @faces
      for face in faces
        face.pulse ctx, index, audioIntensity, type

  drawAlphaFace: (ctx, index) =>
    frame =
      width: ctx.canvas.width
      height: ctx.canvas.height

    # face =
    #   eyebar:
    #     x: frame.width / 2.5
    #     y: frame.height / 2.3
    #     width: frame.width / 4.5
    #     height: frame.height / 8



    # # ctx.globalCompositeOperation = 'destination-out'
    # ctx.fillStyle = 'black'

    # ctx.fillRect(face.eyebar.x, face.eyebar.y, face.eyebar.width, face.eyebar.height)
