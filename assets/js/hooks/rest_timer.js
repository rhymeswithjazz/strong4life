// Rest Timer Hook - handles audio and vibration notifications
const RestTimer = {
  mounted() {
    // Listen for timer completion event from server
    this.handleEvent("rest_timer_complete", () => {
      this.playNotification()
    })
  },

  playNotification() {
    // Play audio beep
    this.playAudioBeep()

    // Vibrate on mobile devices
    this.vibratePhone()
  },

  playAudioBeep() {
    // Create audio context for beep sound
    const audioContext = new (window.AudioContext || window.webkitAudioContext)()

    // Create oscillator (tone generator)
    const oscillator = audioContext.createOscillator()
    const gainNode = audioContext.createGain()

    // Connect nodes
    oscillator.connect(gainNode)
    gainNode.connect(audioContext.destination)

    // Configure beep sound - 800Hz tone, pleasant and attention-grabbing
    oscillator.frequency.value = 800
    oscillator.type = 'sine'

    // Volume envelope - start at 0.3, fade out
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime)
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5)

    // Play for 500ms
    oscillator.start(audioContext.currentTime)
    oscillator.stop(audioContext.currentTime + 0.5)
  },

  vibratePhone() {
    // Check if vibration API is supported (mobile devices)
    if ('vibrate' in navigator) {
      // Vibrate pattern: vibrate 200ms, pause 100ms, vibrate 200ms
      navigator.vibrate([200, 100, 200])
    }
  }
}

export default RestTimer
