(function() {
  var constraints, errorCallback, successCallback,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $(function() {
    window.dev = true;
    window.log = function(args) {
      if (dev) {
        return console.log.apply(console, arguments);
      }
    };
    if (dev) {
      return $('body').append($('<script src="//localhost:35729/livereload.js"></script>'));
    }
  });

  $(function() {
    return window.Player = (function() {
      function Player(tracks) {
        this.tracks = tracks;
        this.setupVideoListeners = __bind(this.setupVideoListeners, this);
        this.drawVideo = __bind(this.drawVideo, this);
        this.drawSequence = __bind(this.drawSequence, this);
        this.currentTrack = 0;
        this.videoPlaying = false;
        this.setDimensions();
      }

      Player.prototype.createCanvas = function() {
        var canvas;
        canvas = document.createElement('canvas');
        return canvas;
      };

      Player.prototype.createContext = function(canvas) {
        var context;
        return context = canvas.getContext('2d');
      };

      Player.prototype.setDimensions = function(canvas) {
        this.displayWidth = $(document).width();
        return this.displayHeight = $(document).height();
      };

      Player.prototype.play = function() {
        log('play');
        if (this.currentTrack < this.tracks.length) {
          return this.queue(this.tracks[this.currentTrack]);
        }
      };

      Player.prototype.nextTrack = function() {
        this.currentTrack++;
        return this.play();
      };

      Player.prototype.queue = function(track) {
        log('queue', track);
        return track.play(this, (function(_this) {
          return function() {
            log('callback');
            return _this.nextTrack();
          };
        })(this));
      };

      Player.prototype.playVideo = function(track) {
        log('playVideo');
        this.video = document.createElement('video');
        this.video.src = track.src;
        this.setupVideoListeners(this.video, track);
        this.videoPlaying = true;
        this.video.play();
        return this.drawVideo(track);
      };

      Player.prototype.playSequence = function(track) {
        log('playSequence');
        this.sequenceStart = new Date();
        if (track.src != null) {
          if (track.src === 'webcam') {
            log('get webcam');
            track.src = webcam.src;
            return this.playVideo(track);
          } else {
            return this.playVideo(track);
          }
        } else {
          return this.drawSequence(track);
        }
      };

      Player.prototype.drawSequence = function(track) {
        var elapsed;
        elapsed = (new Date() - this.sequenceStart) / 1000;
        track.play.call(this, this.aniContext, elapsed);
        if (elapsed < track.duration) {
          return requestAnimationFrame((function(_this) {
            return function() {
              return _this.drawSequence(track);
            };
          })(this));
        } else {
          log('end sequence');
          track.ended.call(this, this.aniContext, this.aniCanvas);
          return this.nextTrack();
        }
      };

      Player.prototype.drawVideo = function(track) {
        var height, spacer;
        height = this.displayWidth / track.aspect;
        spacer = (this.displayHeight - height) / 2;
        this.videoContext.drawImage(this.video, 0, spacer, this.displayWidth, height);
        if (this.videoPlaying) {
          return requestAnimationFrame((function(_this) {
            return function() {
              return _this.drawVideo(track);
            };
          })(this));
        }
      };

      Player.prototype.setupVideoListeners = function(video, track) {
        video.addEventListener('ended', (function(_this) {
          return function(event) {
            if (_this.video === event.srcElement) {
              return _this.videoEnded();
            }
          };
        })(this));
        if (track.type === 'sequence') {
          return video.addEventListener('playing', (function(_this) {
            return function() {
              return _this.drawSequence(track);
            };
          })(this));
        }
      };

      Player.prototype.videoEnded = function() {
        log('ended');
        this.videoPlaying = false;
        return this.nextTrack();
      };

      return Player;

    })();
  });

  $(function() {
    return window.Sequence = (function() {
      function Sequence(options) {
        this.drawSequence = __bind(this.drawSequence, this);
        this.type = 'sequence';
        this.src = options.src;
        this.aspect = options.aspect;
        this.duration = options.duration;
        this.canvas = this.createCanvas();
        this.canvas.id = new Date().getTime();
        this.context = this.createContext(this.canvas);
        this.videoPlaying = false;
      }

      Sequence.prototype.play = function(player, callback) {
        log('playSequence');
        this.player = player;
        this.callback = callback;
        this.canvas.width = this.player.displayWidth;
        this.canvas.height = this.player.displayHeight;
        if (this.src != null) {
          if (this.src === 'webcam') {
            log('get webcam');
            return this.src = webcam.src;
          } else {
            this.video = new VideoTrack({
              src: this.src,
              aspect: this.aspect
            });
            return this.video.play(this.player, null, {
              onplaystart: (function(_this) {
                return function() {
                  return _this.startSequence();
                };
              })(this)
            });
          }
        } else {
          return this.startSequence();
        }
      };

      Sequence.prototype.startSequence = function() {
        $('body').append(this.canvas);
        this.sequenceStart = new Date();
        return this.drawSequence();
      };

      Sequence.prototype.drawSequence = function() {
        var elapsed;
        elapsed = (new Date() - this.sequenceStart) / 1000;
        this.drawAnimation(this, elapsed);
        if (elapsed < this.duration) {
          return requestAnimationFrame((function(_this) {
            return function() {
              return _this.drawSequence();
            };
          })(this));
        } else {
          log('end sequence');
          return this.ended();
        }
      };

      Sequence.prototype.drawAnimation = function() {};

      Sequence.prototype.cleanup = function() {
        setTimeout((function(_this) {
          return function() {
            return $(_this.canvas).remove();
          };
        })(this), 300);
        return this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
      };

      Sequence.prototype.createCanvas = function() {
        var canvas;
        canvas = document.createElement('canvas');
        return canvas;
      };

      Sequence.prototype.createContext = function(canvas) {
        var context;
        return context = canvas.getContext('2d');
      };

      return Sequence;

    })();
  });

  $(function() {
    window.testSequence = new Sequence({
      type: 'sequence',
      src: '/assets/videos/short.mov',
      aspect: 16 / 9,
      duration: 5
    });
    testSequence.drawAnimation = function(context, elapsed) {
      var x, y;
      log('draw');
      x = elapsed * 100;
      y = elapsed * 100;
      this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.context.fillStyle = 'rgba(0, 100, 0, 0.4)';
      this.context.fillOpacity = 0.1;
      return this.context.fillRect(x, y, 400, 400);
    };
    return testSequence.ended = function() {
      if (this.callback != null) {
        this.callback();
      }
      return this.cleanup();
    };
  });

  $(function() {
    return window.VideoTrack = (function() {
      function VideoTrack(options) {
        this.setupVideoListeners = __bind(this.setupVideoListeners, this);
        this.drawVideo = __bind(this.drawVideo, this);
        this.type = 'video';
        this.src = options.src;
        this.aspect = options.aspect;
        this.canvas = this.createCanvas();
        this.canvas.id = new Date().getTime();
        this.context = this.createContext(this.canvas);
        this.videoPlaying = false;
      }

      VideoTrack.prototype.play = function(player, callback, options) {
        log('playVideo');
        this.player = player;
        this.callback = callback;
        if (options) {
          if (options.onplaystart != null) {
            this.onplaystart = options.onplaystart;
          }
        }
        $('body').append(this.canvas);
        this.canvas.width = this.player.displayWidth;
        this.canvas.height = this.player.displayHeight;
        this.video = document.createElement('video');
        this.video.src = this.src;
        this.setupVideoListeners(this.video);
        return this.video.play();
      };

      VideoTrack.prototype.drawVideo = function() {
        var height, spacer;
        height = this.player.displayWidth / this.aspect;
        spacer = (this.player.displayHeight - height) / 2;
        this.context.drawImage(this.video, 0, spacer, this.player.displayWidth, height);
        if (this.videoPlaying) {
          return requestAnimationFrame((function(_this) {
            return function() {
              return _this.drawVideo();
            };
          })(this));
        }
      };

      VideoTrack.prototype.setupVideoListeners = function(video) {
        video.addEventListener('playing', (function(_this) {
          return function(event) {
            if (_this.onplaystart != null) {
              _this.onplaystart();
            }
            _this.videoPlaying = true;
            return _this.drawVideo();
          };
        })(this));
        return video.addEventListener('ended', (function(_this) {
          return function(event) {
            if (_this.video === event.srcElement) {
              _this.videoPlaying = false;
              setTimeout(function() {
                return $(_this.canvas).remove();
              }, 300);
              if (_this.callback != null) {
                return _this.callback();
              }
            }
          };
        })(this));
      };

      VideoTrack.prototype.createCanvas = function() {
        var canvas;
        canvas = document.createElement('canvas');
        return canvas;
      };

      VideoTrack.prototype.createContext = function(canvas) {
        var context;
        return context = canvas.getContext('2d');
      };

      return VideoTrack;

    })();
  });

  window.CamSequence = {
    type: 'sequence',
    src: 'webcam',
    aspect: 16 / 9,
    duration: 5,
    videoEffect: function() {
      var b, data, g, i, idata, r, _results;
      backContext.drawImage(webcam, 0, 0);
      idata = backContext.getImageData(0, 0, canvas.width, canvas.height);
      data = idata.data;
      i = 0;
      _results = [];
      while (i < data.length) {
        r = data[i];
        g = data[i + 1];
        b = data[i + 2];
        _results.push(i += 4);
      }
      return _results;
    },
    play: function(context, elapsed) {
      var x, y;
      x = elapsed * 100;
      y = elapsed * 100;
      context.clearRect(0, 0, this.aniCanvas.width, this.aniCanvas.height);
      context.fillStyle = 'rgba(0, 100, 0, 0.4)';
      context.fillOpacity = 0.1;
      return context.fillRect(x, y, 400, 400);
    },
    ended: function(context, canvas) {
      return context.clearRect(0, 0, canvas.width, canvas.height);
    }
  };

  navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;

  constraints = {
    audio: false,
    video: {
      mandatory: {
        minWidth: 1280,
        minHeight: 720
      }
    }
  };

  successCallback = function(stream) {
    window.webcam = stream;
    if (window.URL) {
      return webcam.src = window.URL.createObjectURL(stream);
    } else {
      return webcam.src = stream;
    }
  };

  errorCallback = function(error) {
    return log("navigator.getUserMedia error: ", error);
  };

  navigator.getUserMedia(constraints, successCallback, errorCallback);

  $(function() {
    window.player = new Player([
      new VideoTrack({
        src: '/assets/videos/short.mov',
        aspect: 16 / 9
      }), testSequence, new VideoTrack({
        src: '/assets/videos/ocean.mp4',
        aspect: 16 / 9
      }), CamSequence
    ]);
    $(window).resize(function() {
      return player.setDimensions();
    });
    return player.play();
  });

}).call(this);

//# sourceMappingURL=app.js.map
