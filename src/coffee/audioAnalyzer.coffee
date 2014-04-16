class window.soundAnalyzer
  constructor: ->
    @all = 0
    @counter = 0
    @low = 1000
    @high = 4000
  playSound: (soundURL) ->
    # http://stackoverflow.com/questions/10105063/how-to-play-a-notification-sound-on-websites 
    @shouldAnalyze = true
    soundURL = soundURL or "/assets/audio/awobmolg.m4a"
    console.log('playing sound: ' + soundURL)
    $('body').append '<audio id="poem" autoplay="autoplay"><source src="' + soundURL + '" type="audio/mpeg" /><embed hidden="true" autostart="true" loop="false" src="' + soundURL + '" /></audio>'

    audioContext = new (window.AudioContext||window.webkitAudioContext)()

    @audioElement = document.getElementById("poem")

    @analyzer = audioContext.createAnalyser()
    @analyzer.fftSize = 64
    @frequencyData = new Uint8Array(@analyzer.frequencyBinCount)

    @audioElement.addEventListener("canplay", =>
      source = audioContext.createMediaElementSource(@audioElement)
      console.log 'can play'
      source.connect(@analyzer)
      @analyzer.connect(audioContext.destination)
    )

    @audioElement.addEventListener('ended', =>
      @shouldAnalyze = false
      log 'average level: ' + @all/@counter
      log('audio ended')
    , false)
    # audioElement.addEventListener('canplaythrough', voiceLoaded, false)
    @audioElement.addEventListener('playing', @analyze, false)

    $intensity = $("#intensity")

  analyze: =>
    @analyzer.getByteFrequencyData(@frequencyData)
    magnitude = 0
    for frequency in @frequencyData
      magnitude += frequency
    # i = 0
    # while i < @frequencyData.length
    #   magnitude += @frequencyData[i]
    #   i++

    @high = Math.max @high, magnitude
    @low = Math.min @low, magnitude
    @all += magnitude
    @counter++

    window.audioIntensity = (magnitude/@high)
    # console.log audioIntensity
    # opacity = 0.8 - (magnitude/frequencyData.length)/40
    # $intensity.css("opacity": opacity)

    setTimeout(@analyze, 33) if @shouldAnalyze

  
