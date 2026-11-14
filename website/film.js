// Native controls remain available when JavaScript is disabled.
const film = document.getElementById('product-film');
const playButton = document.querySelector('.play-film');
const status = document.getElementById('film-status');
if (film && playButton && status) {
  playButton.hidden = false;
  playButton.addEventListener('click', async () => {
    try {
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
