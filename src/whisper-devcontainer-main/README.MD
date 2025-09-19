# Whisper Devcontainer
This is a [Visual Studio Code](https://code.visualstudio.com/) [Dev Container](https://code.visualstudio.com/docs/devcontainers/containers) for the openai's [Whisper](https://github.com/openai/whisper) Speech Recognition Model for ease of use and devlopment.

The main file is taken from the example on Whisper's repo and sample audio is taken from online using ffmpeg

ffmpeg converting video to audio script ->
```console
ffmpeg -i https://test.com/test.m3u8 -map 0:0 -vn -b:a 320k audio.mp3
```

## Links

+ [Visual Studio Code](https://code.visualstudio.com/)
+ [Docker](https://www.docker.com/)
+ [Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
+ [Whisper](https://github.com/openai/whisper)