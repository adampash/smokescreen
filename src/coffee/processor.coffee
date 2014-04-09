class window.Processor
  constructor: (@frames, @faces, @options) ->
    @newFrames = []
    @playFrames = []

  zoomOnFace: (face) ->
    centerFace = face.frames[6]
    # TODO face.averageFace
    crop = new Cropper
      width: player.displayWidth
      height: player.displayHeight
    frames = @frames.map (frame) ->
      crop.zoomToFit(centerFace, frame)
    @addSequence frames

  blackandwhite: (options) ->
    options = options || {}
    newFrames = []
    worker = new Worker('/workers/bnw.js')

    worker.addEventListener('message', (e) =>
      newFrames.push e.data[0]
      if newFrames.length == @frames.length
        log 'time to add sequence to player'
        log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'

        @playFrames = newFrames
        @addSequence()
      else
        worker.postMessage [@frames[newFrames.length]]
    , false)

    @startedAt = new Date().getTime()
    # for frame, index in @frames
    worker.postMessage [@frames[0]]


  drawFaceRects: (@faces, @scale) ->
    newFrames = []
    @worker = new Worker('/workers/drawFaceRect.js')

    @worker.addEventListener('message', (e) =>
      newFrames.push e.data[0]
      if newFrames.length == @frames.length
        log 'time to add sequence to player'
        log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'

        @addSequence(newFrames)
      else
        @sendFrame newFrames.length, scale
    , false)

    @startedAt = new Date().getTime()
    # @newFaces = []
    @newFaces = @faces

    @sendFrame 0, scale

  sendFrame: (index, scale) ->
    frame = @frames[index]
    params =
      frames: [frame]
      frameNumber: index
      faces: @newFaces[index]
      scale: scale || 3
      spacer: Math.round(window.spacer)
    @worker.postMessage params

  saturate: (percent) ->
    newFrames = []
    worker = new Worker('/workers/saturate.js')

    worker.addEventListener('message', (e) =>
      newFrames.push e.data[0]
      if newFrames.length == @frames.length
        log 'time to add sequence to player'
        log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'

        @playFrames = newFrames
        @addSequence()
    , false)

    @startedAt = new Date().getTime()
    for frame in @frames
      worker.postMessage [frame]

  blur: (rate) ->
    newFrames = []
    worker = new Worker('/workers/blur.js')

    worker.addEventListener('message', (e) =>
      newFrames.push e.data[0]
      if newFrames.length == @frames.length
        log 'time to add sequence to player'
        log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'

        @playFrames = newFrames
        @addSequence()
    , false)

    @startedAt = new Date().getTime()
    for frame in @frames
      worker.postMessage [frame]

  addSequence: (frames) ->
    frames = frames || @playFrames
    sequence = new Sequence
        type: 'sequence'
        aspect: 16/9
        duration: 3
        src: 'CanvasPlayer'
        frames: frames
    sequence.ended = ->
      @callback() if @callback?
      @cleanup()
      @video.cleanup()
    player.addTrack sequence
    log 'added track'
    # player.addTrack new VideoTrack
    #   src: '/assets/videos/ocean.mp4'
    #   aspect: 16/9
