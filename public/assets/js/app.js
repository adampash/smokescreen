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
        this.currentTrack = 0;
        this.videoPlaying = false;
        this.setDimensions();
      }

      Player.prototype.setDimensions = function(canvas) {
        this.displayWidth = $(document).width();
        this.displayHeight = $(document).height();
        return this.tracks[this.currentTrack].setDimensions();
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
            return _this.nextTrack();
          };
        })(this));
      };

      return Player;

    })();
  });

  $(function() {
    return window.Sequence = (function() {
      function Sequence(options) {
        this.drawSequence = __bind(this.drawSequence, this);
        this.setDimensions = __bind(this.setDimensions, this);
        var _this;
        this.type = 'sequence';
        this.src = options.src;
        this.aspect = options.aspect;
        this.duration = options.duration;
        if (options.onStart != null) {
          this.onStart = options.onStart;
        }
        this.canvas = this.createCanvas();
        this.canvas.id = new Date().getTime();
        this.context = this.createContext(this.canvas);
        this.canvases = [];
        this.canvases.push(this.canvas);
        $('body').append(this.canvas);
        this.playing = false;
        _this = this;
        $(window).resize((function(_this) {
          return function() {
            if (_this.playing) {
              return _this.setDimensions();
            }
          };
        })(this));
      }

      Sequence.prototype.setDimensions = function() {
        if (this.player != null) {
          this.canvases.map(function(canvas) {
            canvas.width = this.player.displayWidth;
            return canvas.height = this.player.displayHeight;
          });
          if (this.video) {
            return this.video.setDimensions();
          }
        }
      };

      Sequence.prototype.play = function(player, callback) {
        log('playSequence');
        this.playing = true;
        this.player = player;
        this.callback = callback;
        this.setDimensions();
        if (this.src != null) {
          if (this.src === 'webcam') {
            log('get webcam');
            this.src = webcam.src;
            this.video = new VideoTrack({
              src: this.src,
              aspect: this.aspect,
              littleCanvas: true
            });
            this.video.play(this.player);
            this.startSequence();
            return this.canvases.push(this.video);
          } else if (this.src === 'CanvasPlayer') {
            this.video = new CanvasPlayer(this.canvas, window.recorder.capturedFrames, window.recorder.fps);
            return this.video.play({
              player: this.player
            });
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
        this.sequenceStart = new Date();
        this.drawSequence();
        if (this.onStart != null) {
          return this.onStart();
        }
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
        if (options.littleCanvas != null) {
          this.littleCanvas = this.createCanvas();
          this.littleCanvas.width = 480;
          this.littleCanvas.height = 320;
          this.littleContext = this.createContext(this.littleCanvas);
        }
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
        $('body').prepend(this.canvas);
        this.setDimensions();
        this.video = document.createElement('video');
        this.video.src = this.src;
        this.setupVideoListeners(this.video);
        return this.video.play();
      };

      VideoTrack.prototype.setDimensions = function() {
        if (this.player != null) {
          this.canvas.width = this.player.displayWidth;
          return this.canvas.height = this.player.displayHeight;
        }
      };

      VideoTrack.prototype.drawVideo = function() {
        var height, spacer;
        height = this.player.displayWidth / this.aspect;
        spacer = (this.player.displayHeight - height) / 2;
        this.context.drawImage(this.video, 0, spacer, this.player.displayWidth, height);
        if (this.littleCanvas != null) {
          this.littleContext.drawImage(this.video, 0, 0, this.littleCanvas.width, this.littleCanvas.height);
        }
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
              _this.cleanup();
              if (_this.callback != null) {
                return _this.callback();
              }
            }
          };
        })(this));
      };

      VideoTrack.prototype.cleanup = function() {
        return setTimeout((function(_this) {
          return function() {
            return $(_this.canvas).remove();
          };
        })(this), 300);
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

  $(function() {
    var duration;
    duration = 1;
    window.camSequence = new Sequence({
      type: 'sequence',
      src: 'webcam',
      aspect: 16 / 9,
      duration: duration,
      onStart: function() {
        return this.recordCam(duration);
      }
    });
    camSequence.drawAnimation = function(context, elapsed) {
      var x, y;
      x = elapsed * 100;
      y = elapsed * 100;
      this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.context.fillStyle = 'rgba(0, 100, 0, 0.4)';
      this.context.fillOpacity = 0.1;
      return this.context.fillRect(x, y, 400, 400);
    };
    camSequence.ended = function() {
      if (this.callback != null) {
        this.callback();
      }
      this.cleanup();
      return this.video.cleanup();
    };
    camSequence.recordCam = function(seconds) {
      window.recorder = this.record(this.video.canvas, seconds);
      return window.littleRecorder = this.record(this.video.littleCanvas, seconds, true);
    };
    return camSequence.record = function(canvas, seconds, convert) {
      var complete, recorder;
      recorder = new Recorder(canvas);
      if (convert) {
        complete = (function(_this) {
          return function() {
            log('recording complete');
            window.converter = new Converter(recorder.canvas, recorder.capturedFrames, recorder.fps, null, {
              converted: function() {
                return log('converted');
              }
            });
            return converter.convertAndUpload();
          };
        })(this);
      } else {
        complete = null;
      }
      recorder.record(seconds, 40, {
        complete: complete
      });
      return recorder;
    };
  });

  window.CanvasPlayer = (function() {
    function CanvasPlayer(canvas, frames, fps) {
      this.canvas = canvas;
      this.frames = frames;
      this.fps = fps;
      this.options = {};
      this.paused = false;
      this.context = this.canvas.getContext('2d');
      this.index = 0;
      this.fps = this.fps || 30;
      this.loopStyle = 'beginning';
      this.increment = true;
      this.startFrame = 1;
      this.endFrame = this.frames.length - 1;
    }

    CanvasPlayer.prototype.reset = function() {
      this.frames = [];
      this.options = {};
      this.paused = false;
      this.index = 0;
      this.fps = this.fps || 30;
      this.loopStyle = 'beginning';
      this.increment = true;
      return this.startFrame = 0;
    };

    CanvasPlayer.prototype.setDimensions = function() {
      if (this.player != null) {
        this.canvas.width = this.player.displayWidth;
        return this.canvas.height = this.player.displayHeight;
      }
    };

    CanvasPlayer.prototype.play = function(options) {
      if (options.player != null) {
        this.player = options.player;
      }
      this.timeout = 1 / this.fps * 1000;
      if (!this.paused) {
        this.options = options || this.options;
        if (this.endFrame > this.index) {
          if (this.index <= this.startFrame) {
            this.index = this.startFrame;
            this.increment = true;
          }
          if (this.increment) {
            this.index++;
          } else {
            this.index--;
          }
        } else {
          if (this.loopStyle === 'beginning') {
            this.index = this.startFrame;
          } else {
            this.index = this.endFrame - 1;
            this.increment = false;
          }
        }
        this.paintFrame(this.index);
      }
      return setTimeout((function(_this) {
        return function() {
          return _this.play(options);
        };
      })(this), this.timeout);
    };

    CanvasPlayer.prototype.pause = function() {
      return this.paused = !this.paused;
    };

    CanvasPlayer.prototype.paintFrame = function(index) {
      var frame;
      if (index >= this.frames.length || index < 0) {
        return false;
      }
      this.index = index || this.index;
      frame = this.frames[this.index];
      this.context.putImageData(frame, 0, 0);
      if (this.options.progress) {
        return this.options.progress();
      }
    };

    return CanvasPlayer;

  })();

  window.Converter = (function() {
    function Converter(canvas, frames, fps, player, options) {
      this.canvas = canvas;
      this.frames = frames;
      this.fps = fps;
      this.player = player;
      this.options = options || {};
      this.convertCanvas = document.createElement('canvas');
      this.convertCanvas.width = this.canvas.width;
      this.convertCanvas.height = this.canvas.height;
      this.convertContext = this.convertCanvas.getContext('2d');
      this.files = [];
      this.uploadedFiles = [];
      this.formdata = new FormData();
      this.fps = this.fps || 10;
      this.save = false;
      this.uploadedSprite;
      this.gifFinished = options.gifFinished;
    }

    Converter.prototype.reset = function() {
      this.files = [];
      this.uploadedFiles = [];
      this.formdata = new FormData();
      this.fps = this.fps || 10;
      this.uploadedSprite = null;
      return this.save = false;
    };

    Converter.prototype.convertAndUpload = function() {
      var file;
      if (this.convertingFrames == null) {
        this.convertingFrames = this.frames;
        this.startedAt = new Date().getTime();
      }
      if (this.convertingFrames.length > 0) {
        file = this.convertFrame(this.convertingFrames.shift());
        return this.postImage(file, {
          success: (function(_this) {
            return function(response) {
              window.faces.push(response);
              return _this.convertAndUpload();
            };
          })(this)
        });
      } else {
        log('All done converting and uploading frames');
        log("Total time took: " + (new Date().getTime() - this.startedAt) / 1000 + 'secs');
        return alert('DONE');
      }
    };

    Converter.prototype.convert = function() {
      var frame, _i, _len, _ref;
      this.files = [];
      _ref = this.frames;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        frame = _ref[_i];
        this.files.push(this.convertFrame(frame));
      }
      if (this.options.converted != null) {
        return this.options.converted();
      }
    };

    Converter.prototype.convertFrame = function(frame) {
      var dataURL;
      this.convertContext.putImageData(frame, 0, 0);
      dataURL = this.convertCanvas.toDataURL();
      return this.convertDataURL(dataURL);
    };

    Converter.prototype.convertDataURL = function(dataURL, type) {
      var array, bb, blobBin, e, file, i;
      type = type || "image/png";
      blobBin = atob(dataURL.split(',')[1]);
      array = [];
      i = 0;
      while (i < blobBin.length) {
        array.push(blobBin.charCodeAt(i));
        i++;
      }
      try {
        return file = new Blob([new Uint8Array(array)], {
          type: type
        });
      } catch (_error) {
        e = _error;
        window.BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder || window.MSBlobBuilder;
        if (e.name === 'TypeError' && window.BlobBuilder) {
          bb = new BlobBuilder();
          bb.append([array.buffer]);
          file = bb.getBlob("image/png");
        } else if (e.name === "InvalidStateError") {
          file = new Blob([array.buffer], {
            type: "image/png"
          });
        }
        return file;
      }
    };

    Converter.prototype.totalFileSize = function() {
      return this.files.reduce(function(acc, file) {
        return acc += file.size;
      }, 0);
    };

    Converter.prototype.framesInFinalGif = function(loopStyle) {
      if (loopStyle === 'ping-pong') {
        return (this.frames.length * 2) - 2;
      } else {
        return this.frames.length;
      }
    };

    Converter.prototype.postImage = function(file, options) {
      var formdata;
      options = options || {};
      formdata = new FormData();
      formdata.append("upload", file);
      return $.ajax({
        url: "http://localhost:3000/",
        type: "POST",
        data: formdata,
        processData: false,
        contentType: false,
        xhrFields: {
          withCredentials: false
        },
        xhr: function() {
          var req;
          req = $.ajaxSettings.xhr();
          if (req) {
            if (options.progress) {
              req.upload.addEventListener('progress', function(event) {
                if (event.lengthComputable) {
                  return options.progress(event);
                }
              }, false);
            }
          }
          return req;
        }
      }).done((function(_this) {
        return function(response) {
          if (options.success) {
            return options.success(response);
          }
        };
      })(this)).always(function() {
        if (options.complete) {
          return options.complete();
        }
      }).fail(function() {
        if (options.error) {
          return options.error();
        }
      });
    };

    Converter.prototype.postPNGs = function(options) {
      var file, index, _i, _len, _ref;
      _ref = this.files;
      for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
        file = _ref[index];
        this.formdata.append("upload[" + index + "]", file);
      }
      return $.ajax({
        url: "http://localhost:3000/",
        type: "POST",
        data: this.formdata,
        processData: false,
        contentType: 'text/plain',
        xhrFields: {
          withCredentials: false
        },
        xhr: function() {
          var req;
          req = $.ajaxSettings.xhr();
          if (req) {
            if (options && options.progress) {
              req.upload.addEventListener('progress', function(event) {
                if (event.lengthComputable) {
                  return options.progress(event);
                }
              }, false);
            }
          }
          return req;
        }
      }).done((function(_this) {
        return function(response) {
          if (options && options.success) {
            return options.success(response);
          }
        };
      })(this)).always(function() {
        console.log(new Date().getTime() / 1000);
        if (options && options.complete) {
          return options.complete();
        }
      }).fail(function() {
        if (options && options.error) {
          return options.error();
        }
      });
    };

    Converter.prototype.upload = function(loopStyle, options) {
      var file, i, _i, _len, _ref;
      loopStyle = loopStyle || false;
      _ref = this.files;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        file = _ref[i];
        this.appendToForm(i, file);
      }
      this.formdata.append("ping", loopStyle === 'ping-pong');
      this.formdata.append("fps", this.fps);
      this.formdata.append("authenticity_token", AUTH_TOKEN);
      if (options && options.description) {
        this.formdata.append("description", options.description);
      }
      return $.ajax({
        url: "/gifs",
        type: "POST",
        data: this.formdata,
        processData: false,
        contentType: false,
        xhr: function() {
          var req;
          req = $.ajaxSettings.xhr();
          if (req) {
            if (options && options.progress) {
              req.upload.addEventListener('progress', function(event) {
                if (event.lengthComputable) {
                  return options.progress(event);
                }
              }, false);
            }
          }
          return req;
        }
      }).done(function(response) {
        if (options && options.success) {
          return options.success(response);
        }
      }).always(function() {
        if (options && options.complete) {
          return options.complete();
        }
      }).fail(function() {
        if (options && options.error) {
          return options.error();
        }
      });
    };

    Converter.prototype.uploadToS3 = function(fileBlobs, options) {
      var $uploadForm, fd, file, index, key, postURL, _i, _len, _results;
      fileBlobs = fileBlobs || this.files;
      $uploadForm = $('#png-uploader');
      _results = [];
      for (index = _i = 0, _len = fileBlobs.length; _i < _len; index = ++_i) {
        file = fileBlobs[index];
        key = $uploadForm.data("key").replace('{index}', index).replace('{timestamp}', new Date().getTime()).replace('{unique_id}', Math.random().toString(36).substr(2, 16)).replace('{extension}', 'png');
        fd = new FormData();
        fd.append('utf8', '✓');
        fd.append('key', key);
        fd.append('acl', $uploadForm.find('#acl').val());
        fd.append('AWSAccessKeyId', $uploadForm.find('#AWSAccessKeyId').val());
        fd.append('policy', $uploadForm.find('#policy').val());
        fd.append('signature', $uploadForm.find('#signature').val());
        fd.append('success_action_status', "201");
        fd.append('X-Requested-With', "xhr");
        fd.append('Content-Type', "image/png");
        fd.append("file", file);
        postURL = $uploadForm.attr('action');
        _results.push($.ajax({
          url: postURL,
          type: "POST",
          data: fd,
          processData: false,
          contentType: false
        }).done((function(_this) {
          return function(response) {
            var pngURL;
            pngURL = $(response).find('Location').text();
            _this.uploadedFiles.push(pngURL);
            if (options && options.success) {
              return options.success(response);
            }
          };
        })(this)).always(function() {
          if (options && options.complete) {
            return options.complete();
          }
        }).fail(function() {
          if (options && options.error) {
            return options.error();
          }
        }));
      }
      return _results;
    };

    Converter.prototype.appendToForm = function(index, file) {
      return this.formdata.append("upload[" + index + "]", file);
    };

    return Converter;

  })();

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
    window.playbackCamSequence = new Sequence({
      type: 'sequence',
      aspect: 16 / 9,
      duration: 3,
      src: 'CanvasPlayer'
    });
    camSequence.drawAnimation = function(context, elapsed) {
      return this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
    };
    return camSequence.ended = function() {
      if (this.callback != null) {
        this.callback();
      }
      this.cleanup();
      return this.video.cleanup();
    };
  });

  window.Recorder = (function() {
    function Recorder(canvas) {
      this.canvas = canvas;
      this.captureFrames = __bind(this.captureFrames, this);
      this.capturedFrames = [];
      this.context = this.canvas.getContext('2d');
      this.width = this.canvas.width;
      this.height = this.canvas.height;
    }

    Recorder.prototype.reset = function() {
      return this.capturedFrames = [];
    };

    Recorder.prototype.record = function(seconds, fps, options) {
      var frames;
      this.fps = fps;
      this.options = options;
      this.options = this.options || {};
      this.fps = this.fps || 30;
      seconds = seconds || 3;
      this.totalFrames = frames = seconds * this.fps;
      return this.captureFrames(frames);
    };

    Recorder.prototype.captureFrames = function(frames) {
      this.options = this.options || {};
      if (frames > 0) {
        this.capturedFrames.push(this.context.getImageData(0, 0, this.width, this.height));
        frames--;
        setTimeout((function(_this) {
          return function() {
            return _this.captureFrames(frames);
          };
        })(this), 1000 / this.fps);
        if (this.options.progress) {
          return this.options.progress((this.totalFrames - frames) / this.totalFrames, this.capturedFrames[this.capturedFrames.length - 1]);
        }
      } else {
        if (this.options.complete) {
          return this.options.complete();
        }
      }
    };

    return Recorder;

  })();

  $(function() {
    window.faces = [];
    window.player = new Player([
      camSequence, new VideoTrack({
        src: '/assets/videos/short.mov',
        aspect: 16 / 9
      }), testSequence, new VideoTrack({
        src: '/assets/videos/ocean.mp4',
        aspect: 16 / 9
      })
    ]);
    $(window).resize(function() {
      return player.setDimensions();
    });
    return $(window).on('click', function() {
      $('h1').remove();
      return player.play();
    });
  });

}).call(this);

//# sourceMappingURL=app.js.map
