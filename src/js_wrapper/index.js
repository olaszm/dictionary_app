
export const tryPlayAudio = (elementId, cb) => {
    const audioEl = document.getElementById(elementId)
    if (!audioEl) {
        cb()
        return
    }

    audioEl.play()
    audioEl.addEventListener("ended", () => {
        cb()
    })
}

export const tryPause = (elementId, cb) => {
    const audioEl = document.getElementById(elementId)
    if (!audioEl) {
        cb()
        return
    }

    audioEl.pause()
    audioEl.addEventListener("pause", () => {
        audioEl.currentTime = 0
        cb()
    })
}
