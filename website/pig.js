// Presentation only: one short hop, with the App's 420ms response cadence.
const heroPig = document.querySelector('.pig-touch');
if (heroPig) {
  const image = heroPig.parentElement.querySelector('img');
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  let hop;
  heroPig.hidden = false;
  heroPig.addEventListener('click', () => {
    hop?.cancel();
    if (reducedMotion.matches || !image.animate) return;
    const frames = Array.from({ length: 21 }, (_, index) => ({
      transform: `translateY(${-10 * Math.sin(Math.PI * index / 20)}px)`,
    }));
    hop = image.animate(frames, { duration: 420, easing: 'linear' });
  });
  reducedMotion.addEventListener('change', () => hop?.cancel());
}
