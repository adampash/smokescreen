class window.Processor
  constructor: (@frames, @faces, @options) ->
    @newFrames = []
    @playFrames = []

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
    , false)

    @startedAt = new Date().getTime()
    for frame, index in @frames
      worker.postMessage [frame]

    # if options.overwrite
    #   @frames = newFrames


  drawFaceRects: (@faces, @scale) ->
    newFrames = []
    worker = new Worker('/workers/drawFaceRect.js')

    worker.addEventListener('message', (e) =>
      newFrames.push e.data[0]
      if newFrames.length == @frames.length
        log 'time to add sequence to player'
        log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'

        @playFrames = newFrames
        @addSequence()
    , false)

    @startedAt = new Date().getTime()
    @newFaces = []
    for face in @faces
      @newFaces.push face
      @newFaces.push face
      @newFaces.push face
      @newFaces.push face
    for frame, index in @frames
      params =
        frames: [frame]
        frameNumber: index
        faces: @newFaces[index]
        scale: scale || 3
        spacer: Math.round(window.spacer)
      worker.postMessage params

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

  addSequence: ->
    sequence = new Sequence
        type: 'sequence'
        aspect: 16/9
        duration: 3
        src: 'CanvasPlayer'
        frames: @playFrames
    sequence.ended = ->
      @callback() if @callback?
      @cleanup()
      @video.cleanup()
    player.addTrack sequence
    log 'added track'
    # player.addTrack new VideoTrack
    #   src: '/assets/videos/ocean.mp4'
    #   aspect: 16/9
