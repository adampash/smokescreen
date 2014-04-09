$ ->
  duration = 3
  window.camSequence = new Sequence
      type: 'sequence'
      src: 'webcam'
      aspect: 16/9
      duration: duration
      onStart: ->
        @recordCam(duration)

  camSequence.drawAnimation = (context, elapsed) ->

  camSequence.ended = ->
    @callback() if @callback?
    @cleanup()
    @video.cleanup()

  camSequence.recordCam = (seconds) ->
    window.recorder = @record(@video.canvas, seconds, false)
    window.littleRecorder = @record(@video.littleCanvas, seconds, true)

  camSequence.record = (canvas, seconds, convert) ->
    recorder = new Recorder canvas

    if convert
      complete = =>
        window.converter = new Converter recorder.canvas,
                            recorder.capturedFrames,
                            recorder.fps,
                            null,
                            converted: ->
        converter.runWorker()
    else
      complete = =>
        @doProcessing(recorder.capturedFrames, recorder.fps)


    fps = 30
    recorder.record seconds, fps,
      complete: complete

    recorder

  camSequence.doProcessing = (frames, fps) ->
    window.processor = new Processor frames, null, fps
    processor.blackandwhite(overwrite: true)
    # processor.saturate()
    # processor.blur()
