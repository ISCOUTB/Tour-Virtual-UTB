(function () {
  'use strict';
  const mapa = document.querySelector('model-viewer');
  let norte = 137.382;
  let inclinada = false;
  let quieto = false;
  let ultimaCamara = 0;
  function avisar(datos) { TourMapa3d.postMessage(JSON.stringify(datos)); }
  function encuadrar(x, z, radio, theta, instantaneo) {
    mapa.interpolationDecay = quieto || instantaneo ? 0 : 100;
    mapa.cameraTarget = `${x}m 0m ${z}m`;
    mapa.cameraOrbit = `${theta}rad ${inclinada ? 52 : 0.1}deg ${Math.max(70, Math.min(2600, radio))}m`;
    if (quieto || instantaneo) mapa.jumpCameraToGoal();
  }
  window.tour3d = {
    configurar(config) {
      norte = config.norte;
      quieto = config.quieto;
      mapa.setAttribute('alt', config.descripcion);
      mapa.style.setProperty('--color-pin', config.color);
      mapa.style.setProperty('--texto-pin', config.texto);
      mapa.style.setProperty('--visitado', config.visitado);
      mapa.style.setProperty('--tam-texto', `${14 * config.escalaTexto}px`);
      mapa.querySelectorAll('[data-tour-poi]').forEach(p => p.remove());
      config.pois.forEach(p => {
        const boton = document.createElement('button');
        boton.slot = `hotspot-${p.id}`;
        boton.className = 'poi' + (p.numero ? ' parada' : ' lugar') + (p.visitado ? ' visitado' : '');
        boton.setAttribute('data-position', `${p.x}m 22m ${p.z}m`);
        boton.setAttribute('data-normal', '0m 1m 0m');
        boton.setAttribute('aria-label', p.etiqueta);
        boton.title = p.nombre;
        boton.dataset.tourPoi = p.id;
        boton.textContent = p.numero ? String(p.numero) : '';
        boton.addEventListener('click', e => { e.stopPropagation(); avisar({tipo: 'poi', id: p.id}); });
        mapa.appendChild(boton);
      });
      window.tour3d.visibilidad();
    },
    vista(activa, x, z, radio, sinMovimiento, instantaneo) {
      inclinada = activa;
      quieto = sinMovimiento;
      encuadrar(x, z, radio, norte * Math.PI / 180, instantaneo);
    },
    centrar(x, z) {
      const o = mapa.getCameraOrbit();
      encuadrar(x, z, Math.min(o.radius, 430), o.theta, false);
    },
    zoom(factor) {
      const o = mapa.getCameraOrbit(), c = mapa.getCameraTarget();
      encuadrar(c.x, c.z, o.radius / factor, o.theta, false);
    },
    girar(grados) {
      const o = mapa.getCameraOrbit(), c = mapa.getCameraTarget();
      encuadrar(c.x, c.z, o.radius, o.theta + grados * Math.PI / 180, false);
    },
    todo() { encuadrar(138, -154, 1100, norte * Math.PI / 180, false); },
    visibilidad() {
      const cerca = mapa.getCameraOrbit().radius < 620;
      mapa.querySelectorAll('.lugar').forEach(p => { p.hidden = !cerca; });
    }
  };
  mapa.addEventListener('load', () => requestAnimationFrame(() => requestAnimationFrame(() => avisar({tipo: 'listo'}))), {once: true});
  mapa.addEventListener('error', () => avisar({tipo: 'error'}));
  mapa.addEventListener('camera-change', () => {
    window.tour3d.visibilidad();
    if (performance.now() - ultimaCamara < 160) return;
    ultimaCamara = performance.now();
    const o = mapa.getCameraOrbit(), c = mapa.getCameraTarget();
    avisar({tipo: 'camara', x: c.x, z: c.z, radio: o.radius});
  });
})();
