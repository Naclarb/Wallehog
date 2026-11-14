// Native controls remain available when JavaScript is disabled.
const film = document.getElementById('product-film');
const playButton = document.querySelector('.play-film');
const status = document.getElementById('film-status');
if (film && playButton && status) {
  // Keep the poster clear; native controls remain the no-JS fallback.
  film.controls = false;
  film.tabIndex = -1;
  playButton.hidden = false;
  playButton.addEventListener('click', async () => {
    try {
      film.controls = true;
      film.tabIndex = 0;
      await film.play();
      film.focus({ preventScroll: true });
    } catch {
      status.textContent = status.dataset.error;
    }
  });
  film.addEventListener('playing', () => {
    playButton.hidden = true;
    status.textContent = status.dataset.playing;
  });
  film.addEventListener('pause', () => {
    if (!film.ended) status.textContent = status.dataset.paused;
  });
  film.addEventListener('ended', () => {
    playButton.hidden = false;
    status.textContent = status.dataset.ended;
  });
  film.addEventListener('error', () => {
    playButton.hidden = false;
    status.textContent = status.dataset.error;
  });
}
