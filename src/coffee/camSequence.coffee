$ ->
  duration = 2
  window.camSequence = new Sequence
      type: 'sequence'
      src: 'webcam'
      aspect: 16/9
      duration: duration
      onStart: ->
        @recordCam(duration)

  camSequence.drawAnimation = (context, elapsed) ->
    $('body').append '<div class="cover"></div>'

  camSequence.ended = ->
    @callback() if @callback?
    @cleanup()
    @video.cleanup()
    setTimeout ->
      $('.cover').remove()
    , 500

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
        window.allFrames = recorder.capturedFrames.slice(0)
        @doProcessing(recorder.capturedFrames, recorder.fps)


    fps = 30
    recorder.record seconds, fps,
      complete: complete

    recorder

  camSequence.doProcessing = (frames, fps) ->
    frames = frames.slice(0)
    window.processor = new Processor frames, null, fps
    processor.blackandwhite()
