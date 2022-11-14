    let peer;
    let room;
    let remoteAudioMap = {};
    let localStream;
    let audioContext;
    let audioDestination;
    let audioSource;
    let audioGainNode;
    let audioAnalyser;
    let audioDataArray;
    let mypeerid;

    for(var c of document.cookie.split(';')){ //一つ一つ取り出して
        var cArray = c.split('='); //さらに=で分割して配列に
        console.log(cArray);
        if( cArray[0].trim() == 'mypeerid'){ // 取り出したいkeyと合致したら
            mypeerid = cArray[1];
            console.log(mypeerid);  // [key,value]
        }
    }

    function setupLocalAudio(onSetupLocalAudio, onAnalyseVoiceLoop) {
        console.log('index: setupLocalAudio: E');
        try {
            navigator.mediaDevices.getUserMedia({audio: true})
            .then(function(stream) {
              console.log('index: setupLocalAudio: on enabled.');
              audioContext = new (window.AudioContext || window.webkitAudioContext)();
              audioSource = audioContext.createMediaStreamSource(stream);
              // audioGainNode = audioContext.createGain();
              audioAnalyser = audioContext.createAnalyser();
              audioDestination = audioContext.createMediaStreamDestination();

              //audioSource.connect(audioGainNode);
              //audioGainNode.connect(audioDestination);
              //audioGainNode.gain.setValueAtTime(0.5, audioContext.currentTime);
              audioAnalyser.fftSize = 2048;
              audioSource.connect(audioAnalyser);
              audioAnalyser.connect(audioDestination);
              var bufferLength = audioAnalyser.frequencyBinCount;
              audioDataArray = new Uint8Array(bufferLength);

              localStream = audioDestination.stream;
              onSetupLocalAudio(true, '');
              setInterval(function() {analyseVoiceLooper(onAnalyseVoiceLoop)}, 300);
            })
            .catch(function(err) {
              console.log('index: setupLocalAudio: on error.');
              onSetupLocalAudio(false, err.message);
            });
        } catch(err) {
            onSetupLocalAudio(false, err.message);
        }
        console.log('index: setupLocalAudio: X');
    }

    function setEnabledMic(enabled) {
      console.log('index: setEnabledMic: E');
      if (localStream !== 'undefined') {
        console.log(localStream.getAudioTracks());
        localStream.getAudioTracks()[0].enabled = enabled;
      }
      console.log('index: setEnabledMic: X');
    }

    function analyseVoiceLooper(onAnalyseVoiceLoop) {
      // console.log('index: analyseVoiceLooper: E');
      audioAnalyser.getByteTimeDomainData(audioDataArray);
      let minValue = audioDataArray.reduce((min, p) => p < min ? p : min);
      let maxValue = audioDataArray.reduce((max, p) => p > max ? p : max);
      let diffValue = maxValue - minValue;
      // console.log(diffValue);
      onAnalyseVoiceLoop(diffValue);
      // console.log('index: analyseVoiceLooper: X');
    }

    function newPeer(key, debug, onOpenCallback, onErrorCallback) {
      console.log('index: newPeer: E');
      /*
      if (mypeerid !== 'undefined') {
        console.log(`index: newPeer by ${mypeerid}`);
        peer = new Peer(mypeerid, {key: key, debug: debug});
      } else {
        console.log(`index: newPeer no mypeerid`);
        peer = new Peer({key: key, debug: debug});
      }
      */
      peer = new Peer({key: key, debug: debug});
      peer.once('open', id => {
        document.cookie = `mypeerid=${id}; max-age=36000`;
        onOpenCallback(id);
      });
      peer.on("error", (error) => {
        console.log(`${error.type}: ${error.message}`);
        onErrorCallback(`${error.type}: ${error.message}`);
      });
      console.log('index: newPeer: X');
      return;
    }

    function joinRoom(roomId, mode,
                      onOpenCallback,
                      onPeerJoinCallback,
                      onStreamCallback,
                      onDataCallback,
                      onPeerLeave,
                      onClose,
                      onError) {
      console.log('index: joinRoom: E');
      if (localStream === 'undefined') {
        room = peer.joinRoom(roomId, {mode: mode,});
      } else {
        room = peer.joinRoom(roomId, {mode: mode, stream: localStream,});
      }

      room.once('open', () => {
        onOpenCallback();
      });

      room.on('peerJoin', peerId => {
        console.log('index: peerJoin: E');
        onPeerJoinCallback(peerId);
        console.log('index: peerJoin: X');
      });

      room.on('stream', async stream => {
        onStreamCallback();
        const remoteAudio = new Audio();
        remoteAudio.srcObject = stream;
        remoteAudioMap[stream.peerId] = remoteAudio;
        await remoteAudio.play().catch(console.error);
      });

      room.on('data', ({ data, src }) => {
        console.log(`index: data: E: peerId: ${src}`);
        // console.log(data);
        onDataCallback(data, src);
        console.log('index: data: X');
      });

      room.on('peerLeave', peerId => {
        console.log(`index: peerLeave: E: peerId: ${peerId}`);
        if (typeof remoteAudioMap[peerId] !== 'undefined') {
          console.log(`index: peerLeave: : stop remote audio.`);
          const remoteAudio = remoteAudioMap[peerId];
          remoteAudio.srcObject.getTracks().forEach(track => track.stop());
          remoteAudio.srcObject = null;
        }
        onPeerLeave(peerId);
        console.log('index: peerLeave: X');
      });

      // for closing(leaving) myself
      room.once('close', () => {
        console.log('index: close: E');
        for (let key in remoteAudioMap) {
          const remoteAudio = remoteAudioMap[key];
          remoteAudio.srcObject.getTracks().forEach(track => track.stop());
          remoteAudio.srcObject = null;
        }
        onClose();
        console.log('index: close: X');
      });
      console.log('index: joinRoom: X');
    }

    function sendData(data) {
      console.log('index: sendData: E');
      room.send(data);
      console.log('index: sendData: X');
    }

    function leaveRoom() {
      room.close();
    }
