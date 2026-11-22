(function () {
  'use strict';
  const mapa = document.querySelector('model-viewer');

  // Inclinación de la cámara, en grados desde la vertical.
  const CENITAL = 0.1;
  const INCLINADA = 55;
  const RADIO_MIN = 60;
  const RADIO_MAX = 1500;
  // Desde este radio los lugares que no son parada se pueden tocar; antes
  // son puntos mudos, como en el plano 2D. Con el campus entero en
  // pantalla, veinte objetivos de 48 px se pisaban.
  const RADIO_LUGARES = 430;
  // Desde este radio los lugares muestran su nombre.
  const RADIO_NOMBRES = 240;
  // La punta del pin está 18 px por debajo del centro de su caja de 56×60.
  const PUNTA = 18;
  const SVG = 'http://www.w3.org/2000/svg';
  // Desplazamientos que se prueban para una parada que pisa a otra, del más
  // barato al más caro: subir alarga el tallo y se lee como «está aquí
  // debajo»; apartarse de lado cuesta más, y bajar más aún.
  const CANDIDATOS = (() => {
    const lista = [];
    for (const dx of [0, -20, 20, -40, 40, -64, 64]) {
      for (const dy of [0, -20, -40, -60, -80, -100, 24, 48]) {
        lista.push([dx, dy, Math.abs(dx) * 1.6 + (dy < 0 ? -dy : dy * 2.5)]);
      }
    }
    return lista.sort((a, b) => a[2] - b[2]).map(([dx, dy]) => [dx, dy]);
  })();

  let norte = 137.382;
  let quieto = false;
  let seleccion = null;
  let caja = null;
  let vuelo = 0;
  let ultimoAviso = 0;
  let avisoTardio = null;
  let repartoPendiente = false;
  const alturas = new Map();
  // Zonas tapadas por los controles de Flutter: ahí no van nombres.
  let reservadas = [];

  const avisar = datos => TourMapa3d.postMessage(JSON.stringify(datos));
  const rad = g => g * Math.PI / 180;
  const limitar = (v, a, b) => Math.max(a, Math.min(b, v));
  const mezclar = (a, b, k) => a + (b - a) * k;
  const vaiven = t => t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

  // model-viewer aplica el campo de visión según la proporción de la vista:
  // en retrato el vertical ronda 39° aunque el atributo diga 25°. Dart habla
  // en metros visibles y aquí se convierten con el campo real.
  const fovVertical = () => rad(mapa.getFieldOfView());
  const radioPara = alto => alto / (2 * Math.tan(fovVertical() / 2));
  const altoDe = radio => 2 * radio * Math.tan(fovVertical() / 2);

  function actual() {
    const o = mapa.getCameraOrbit(), c = mapa.getCameraTarget();
    return {theta: o.theta, phi: o.phi, radio: o.radius, x: c.x, y: c.y, z: c.z};
  }

  /**
   * Lleva la cámara a [e] sin la interpolación propia de model-viewer.
   *
   * model-viewer aplica las propiedades en su siguiente ciclo, y al cambiar
   * el objetivo recalcula la órbita para no mover la cámara. Asignando las
   * dos a la vez, ese recálculo pisaba la órbita pedida y la cámara seguía
   * deslizándose sola: cada vuelo arrancaba a medio camino y los giros se
   * desviaban hasta 15°. Por eso van en ciclos separados y el salto al final.
   */
  async function aplicar(e) {
    const objetivo = `${e.x}m ${e.y}m ${e.z}m`;
    if (mapa.cameraTarget !== objetivo) {
      mapa.cameraTarget = objetivo;
      await mapa.updateComplete;
    }
    mapa.cameraOrbit = `${e.theta}rad ${e.phi}rad ${e.radio}m`;
    await mapa.updateComplete;
    mapa.jumpCameraToGoal();
  }

  /** El objetivo de la cámara no sale del campus: arrastrar no lo pierde. */
  function acotar(x, z) {
    if (!caja) return {x, z};
    return {x: limitar(x, caja.x0, caja.x1), z: limitar(z, caja.z0, caja.z1)};
  }

  /** Vuelo con aceleración y frenado. Lo interrumpe cualquier gesto. */
  function volar(destino, ms) {
    const id = ++vuelo;
    const fin = {
      ...destino,
      ...acotar(destino.x, destino.z),
      y: 0,
      radio: limitar(destino.radio, RADIO_MIN, RADIO_MAX),
    };
    const origen = actual();
    // El giro va por el camino corto.
    let giro = (fin.theta - origen.theta) % (2 * Math.PI);
    if (giro > Math.PI) giro -= 2 * Math.PI;
    if (giro < -Math.PI) giro += 2 * Math.PI;
    if (quieto || !ms) {
      aplicar({...fin, theta: origen.theta + giro});
      return;
    }
    const inicio = performance.now();
    const paso = ahora => {
      if (id !== vuelo) return;
      const t = Math.min(1, (ahora - inicio) / ms);
      const k = vaiven(t);
      aplicar({
        theta: origen.theta + giro * k,
        phi: mezclar(origen.phi, fin.phi, k),
        // La distancia cambia en proporción, no en metros: acercarse de
        // 1000 a 100 m no se come el vuelo en el primer tramo.
        radio: origen.radio * Math.pow(fin.radio / origen.radio, k),
        x: mezclar(origen.x, fin.x, k),
        y: mezclar(origen.y, fin.y, k),
        z: mezclar(origen.z, fin.z, k),
      });
      if (t < 1) requestAnimationFrame(paso);
    };
    requestAnimationFrame(paso);
  }

  function inclinacion() { return mapa.getCameraOrbit().phi; }

  // ----------------------------------------------------------- Ambiente

  /**
   * Entorno de luz dibujado aquí mismo, sin archivos ni red.
   *
   * El entorno por defecto de model-viewer ilumina igual desde todos lados:
   * techos y fachadas salían del mismo tono y la maqueta se veía plana. Un
   * cielo claro, un suelo más oscuro, un sol y un lado opuesto más frío
   * separan las caras de cada edificio.
   */
  function entorno() {
    const w = 512, h = 256;
    const lienzo = document.createElement('canvas');
    lienzo.width = w;
    lienzo.height = h;
    const g = lienzo.getContext('2d');
    const cielo = g.createLinearGradient(0, 0, 0, h / 2);
    cielo.addColorStop(0, '#c9d9ec');
    cielo.addColorStop(1, '#f4f1ea');
    g.fillStyle = cielo;
    g.fillRect(0, 0, w, h / 2);
    const suelo = g.createLinearGradient(0, h / 2, 0, h);
    suelo.addColorStop(0, '#cfc9bc');
    suelo.addColorStop(1, '#8f8a80');
    g.fillStyle = suelo;
    g.fillRect(0, h / 2, w, h / 2);
    const mancha = (x, y, radio, centro, borde) => {
      for (const dx of [-w, 0, w]) {
        const r = g.createRadialGradient(x + dx, y, 0, x + dx, y, radio);
        r.addColorStop(0, centro);
        r.addColorStop(1, borde);
        g.fillStyle = r;
        g.fillRect(0, 0, w, h);
      }
    };
    const sol = 200 / 360 * w;
    mancha((sol + w / 2) % w, h / 2, 170, 'rgba(120,135,160,.55)', 'rgba(120,135,160,0)');
    mancha(sol, h / 2 - 40 / 90 * h / 2, 140, 'rgba(255,252,242,1)', 'rgba(255,245,225,0)');
    return lienzo.toDataURL('image/png');
  }
  try {
    // model-viewer avisa en consola de que el PNG no trae «gain map» HDR y
    // lo usa como imagen normal, que es lo que se quiere.
    mapa.environmentImage = entorno();
    mapa.toneMapping = 'neutral';
  } catch (_) {
    // Sin canvas queda la luz por defecto: se ve más plana, nada más.
  }

  // ---------------------------------------------------------------- Pines

  function pin(p) {
    const svg = document.createElementNS(SVG, 'svg');
    svg.setAttribute('viewBox', '0 0 56 60');
    svg.setAttribute('aria-hidden', 'true');
    svg.classList.add('figura');
    const id = `grad-${p.id}`;
    svg.innerHTML =
      `<defs><linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1">` +
      '<stop offset="0" class="claro"/><stop offset="1" class="pleno"/></linearGradient></defs>' +
      // Círculo de 17 en (28, 23) con la punta en (28, 48): la misma
      // figura que pinta el plano 2D, para que el fundido no la cambie.
      `<path d="M28 48 L21.13 38.55 A17 17 0 1 1 34.87 38.55 Z" fill="url(#${id})" ` +
      'stroke="#fff" stroke-width="2.5" stroke-linejoin="round"/>' +
      '<path class="marca" d="M23.2 23.4l3.2 3.2 6.6-6.6" fill="none" stroke="#fff" ' +
      'stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>';
    return svg;
  }

  function crearBoton(p) {
    const boton = document.createElement('button');
    boton.slot = `hotspot-${p.numero ? 'parada' : 'lugar'}-${p.id}`;
    boton.type = 'button';
    boton.className = 'poi ' + (p.numero ? 'parada' : 'lugar') + (p.visitado ? ' visitado' : '');
    boton.setAttribute('data-position', `${p.x}m ${alturas.get(p.id) ?? 0}m ${p.z}m`);
    boton.setAttribute('data-normal', '0m 1m 0m');
    boton.setAttribute('aria-label', p.etiqueta);
    boton.dataset.tourPoi = p.id;
    boton.dataset.x = p.x;
    boton.dataset.z = p.z;
    if (p.numero) {
      boton.append(pin(p));
      const pulso = document.createElement('span');
      pulso.className = 'pulso';
      const cifra = document.createElement('span');
      cifra.className = 'cifra';
      cifra.textContent = String(p.numero);
      const tallo = document.createElement('span');
      tallo.className = 'tallo';
      const ancla = document.createElement('span');
      ancla.className = 'ancla';
      boton.prepend(tallo, ancla, pulso);
      boton.append(cifra);
    } else {
      const punto = document.createElement('span');
      punto.className = 'punto';
      if (p.icono) {
        const icono = document.createElement('img');
        icono.src = p.icono;
        icono.alt = '';
        punto.append(icono);
      }
      boton.append(punto);
    }
    const nombre = document.createElement('span');
    nombre.className = 'nombre';
    nombre.setAttribute('aria-hidden', 'true');
    nombre.textContent = p.nombre;
    boton.append(nombre);
    boton.addEventListener('click', e => {
      e.stopPropagation();
      avisar({tipo: 'poi', id: p.id});
    });
    return boton;
  }

  /** Altura del techo bajo cada lugar, para clavar el pin encima. */
  function medirAlturas() {
    // Solo con la cámara cenital: el rayo baja en vertical y toca el techo,
    // no la fachada de otro edificio.
    if (inclinacion() > rad(3)) return;
    let cambio = false;
    mapa.querySelectorAll('[data-tour-poi]').forEach(boton => {
      const id = Number(boton.dataset.tourPoi);
      if (alturas.has(id)) return;
      const punto = mapa.queryHotspot(boton.slot)?.canvasPosition;
      if (!punto || punto.x < 0 || punto.y < 0 ||
          punto.x > mapa.clientWidth || punto.y > mapa.clientHeight) return;
      const golpe = mapa.positionAndNormalFromPoint(punto.x, punto.y);
      if (!golpe || !isFinite(golpe.position.y)) return;
      const y = limitar(golpe.position.y, 0, 40);
      alturas.set(id, y);
      mapa.updateHotspot({
        name: boton.slot,
        position: `${boton.dataset.x}m ${y}m ${boton.dataset.z}m`,
      });
      cambio = true;
    });
    if (cambio) programarReparto();
  }

  /**
   * model-viewer apila los pines por profundidad: un lugar cercano tapaba
   * una parada lejana. Las paradas van siempre encima, y la elegida encima
   * de todas.
   */
  const capas = document.createElement('style');
  function ordenarCapas() {
    // model-viewer se registra después de este script (su módulo es
    // diferido): el shadow root aparece más tarde, no al arrancar.
    if (mapa.shadowRoot && capas.parentNode !== mapa.shadowRoot) mapa.shadowRoot.append(capas);
    capas.textContent =
      '.annotation-wrapper:has(slot[name^="hotspot-parada-"]) { z-index: 1000 !important; }' +
      (seleccion == null ? '' :
        `.annotation-wrapper:has(slot[name="hotspot-parada-${Number(seleccion)}"]) { z-index: 1001 !important; }`);
  }

  function seSolapan(a, b, margen) {
    return a.x0 < b.x1 + margen && b.x0 < a.x1 + margen &&
      a.y0 < b.y1 + margen && b.y0 < a.y1 + margen;
  }

  /**
   * Coloca pines y nombres sin que se pisen. Las paradas que caen encima de
   * otra suben (o se apartan) y dejan un tallo hasta su punto real; nunca
   * se mueve un lugar que está fuera del encuadre.
   */
  function repartir() {
    // El ResizeObserver avisa antes de que model-viewer se registre.
    if (!mapa.loaded) return;
    const ancho = mapa.clientWidth, alto = mapa.clientHeight;
    const radio = mapa.getCameraOrbit().radius;
    const ocupadas = [];

    const paradas = [...mapa.querySelectorAll('.parada')];
    // La elegida se coloca primero: es la que se está mirando.
    paradas.sort((a, b) => (b.dataset.tourPoi == seleccion) - (a.dataset.tourPoi == seleccion));
    for (const boton of paradas) {
      const punto = mapa.queryHotspot(boton.slot)?.canvasPosition;
      if (!punto) continue;
      let dx = 0, dy = 0;
      const w = 56, h = 60;
      const cajaPin = (cx, cy) => ({x0: cx - w / 2, x1: cx + w / 2, y0: cy - h / 2 - PUNTA, y1: cy + h / 2 - PUNTA});
      if (punto.x >= 0 && punto.x <= ancho && punto.y >= 0 && punto.y <= alto) {
        for (const [cx, cy] of CANDIDATOS) {
          const c = cajaPin(punto.x + cx, punto.y + cy);
          // En su sitio puede asomar por el borde; apartada, tiene que caber.
          if ((cx || cy) && (c.x0 < 4 || c.x1 > ancho - 4 || c.y0 < 4 || c.y1 > alto - 4)) continue;
          if (ocupadas.some(o => seSolapan(c, o, 0))) continue;
          dx = cx;
          dy = cy;
          break;
        }
        ocupadas.push(cajaPin(punto.x + dx, punto.y + dy));
      }
      boton.style.transform = `translate(${dx}px, ${dy - PUNTA}px)`;
      const largo = Math.hypot(dx, dy);
      boton.style.setProperty('--tallo', `${largo}px`);
      boton.style.setProperty('--tallo-angulo', `${Math.atan2(-dy, -dx)}rad`);
      boton.style.setProperty('--ancla-x', `${-dx}px`);
      boton.style.setProperty('--ancla-y', `${-dy}px`);
      boton.classList.toggle('desplazada', largo > 0);
      // El nombre de la elegida no se sale por los lados: se corre hacia
      // dentro sobre su pin.
      const nombre = boton.querySelector('.nombre');
      let corrimiento = 0;
      if (boton.classList.contains('elegida') && nombre.offsetWidth) {
        const centro = punto.x + dx, mitad = nombre.offsetWidth / 2;
        if (centro - mitad < 8) corrimiento = 8 - (centro - mitad);
        else if (centro + mitad > ancho - 8) corrimiento = ancho - 8 - (centro + mitad);
      }
      boton.style.setProperty('--nombre-x', `${corrimiento}px`);
      let abajo = false;
      if (boton.classList.contains('elegida') && nombre.offsetWidth) {
        const x = punto.x + dx + corrimiento, y = punto.y + dy - PUNTA - h / 2;
        const arriba = {x0: x - nombre.offsetWidth / 2, x1: x + nombre.offsetWidth / 2,
          y0: y - 6 - nombre.offsetHeight, y1: y - 6};
        abajo = arriba.y0 < 4 || reservadas.some(o => seSolapan(arriba, o, 0));
      }
      boton.classList.toggle('nombre-abajo', abajo);
    }

    const cerca = radio < RADIO_LUGARES;
    const conNombres = radio < RADIO_NOMBRES;
    const lugares = [...mapa.querySelectorAll('.lugar')];
    // Primero los que están más cerca del centro de la vista.
    const centro = {x: ancho / 2, y: alto / 2};
    const conPunto = lugares.map(b => [b, mapa.queryHotspot(b.slot)?.canvasPosition]);
    conPunto.sort((a, b) => (a[1] ? Math.hypot(a[1].x - centro.x, a[1].y - centro.y) : 1e9) -
      (b[1] ? Math.hypot(b[1].x - centro.x, b[1].y - centro.y) : 1e9));
    for (const [boton, punto] of conPunto) {
      boton.classList.toggle('lejos', !cerca);
      boton.tabIndex = cerca ? 0 : -1;
      if (cerca) boton.removeAttribute('aria-hidden'); else boton.setAttribute('aria-hidden', 'true');
      let nombre = false;
      if (conNombres && punto) {
        const etiqueta = boton.querySelector('.nombre');
        const w = etiqueta.offsetWidth, h = etiqueta.offsetHeight;
        const c = {x0: punto.x - w / 2, x1: punto.x + w / 2, y0: punto.y + 15, y1: punto.y + 15 + h};
        const punto2 = {x0: punto.x - 13, x1: punto.x + 13, y0: punto.y - 13, y1: punto.y + 13};
        nombre = c.x0 > 2 && c.x1 < ancho - 2 && c.y1 < alto - 2 &&
          !ocupadas.some(o => seSolapan(c, o, 3)) &&
          !reservadas.some(o => seSolapan(c, o, 0));
        if (nombre) ocupadas.push(c);
        ocupadas.push(punto2);
      }
      boton.classList.toggle('con-nombre', nombre);
    }
  }

  function programarReparto() {
    if (repartoPendiente) return;
    repartoPendiente = true;
    requestAnimationFrame(() => { repartoPendiente = false; repartir(); });
  }

  // --------------------------------------------------------------- Fondo

  /** Cielo tenue hacia el horizonte; en cenital el fondo es la tierra. */
  function pintarFondo() {
    const k = limitar((inclinacion() - rad(10)) / rad(40), 0, 1);
    document.body.style.setProperty('--cielo', k.toFixed(3));
  }

  // ------------------------------------------------------------- Avisos

  function avisarCamara() {
    const ahora = performance.now();
    clearTimeout(avisoTardio);
    // Se avisa como mucho cada 160 ms, pero el último movimiento siempre
    // llega: es el encuadre al que vuelve el plano 2D.
    if (ahora - ultimoAviso < 160) {
      avisoTardio = setTimeout(avisarCamara, 170);
      return;
    }
    ultimoAviso = ahora;
    const o = mapa.getCameraOrbit(), c = mapa.getCameraTarget();
    let rumbo = (o.theta * 180 / Math.PI - norte) % 360;
    if (rumbo < 0) rumbo += 360;
    avisar({tipo: 'camara', x: c.x, z: c.z, alto: altoDe(o.radius), rumbo});
  }

  // ---------------------------------------------------------------- API

  window.tour3d = {
    configurar(config) {
      norte = config.norte;
      quieto = config.quieto;
      seleccion = config.seleccion ?? seleccion;
      document.body.classList.toggle('quieto', quieto);
      document.body.classList.toggle('contraste', !!config.contraste);
      mapa.setAttribute('alt', config.descripcion);
      const estilo = document.body.style;
      estilo.setProperty('--color-pin', config.color);
      estilo.setProperty('--color-pin-claro', config.colorClaro);
      estilo.setProperty('--visitado', config.visitado);
      estilo.setProperty('--visitado-claro', config.visitadoClaro);
      estilo.setProperty('--tam-texto', `${13 * config.escalaTexto}px`);
      mapa.querySelectorAll('[data-tour-poi]').forEach(p => p.remove());
      // Las paradas van primero: el lector de pantalla las recorre antes.
      const orden = [...config.pois].sort((a, b) => (b.numero ? 1 : 0) - (a.numero ? 1 : 0));
      orden.forEach(p => mapa.appendChild(crearBoton(p)));
      window.tour3d.seleccionar(seleccion);
      requestAnimationFrame(() => requestAnimationFrame(medirAlturas));
      programarReparto();
    },
    /** [alto]: metros del modelo que caben en vertical. */
    vista(inclinada, x, z, alto, sinMovimiento, instantaneo, ms) {
      quieto = sinMovimiento;
      document.body.classList.toggle('quieto', quieto);
      volar({
        theta: rad(norte),
        phi: rad(inclinada ? INCLINADA : CENITAL),
        radio: radioPara(alto),
        x, z,
      }, instantaneo ? 0 : ms);
    },
    centrar(x, z) {
      const e = actual();
      volar({...e, x, z, radio: Math.min(e.radio, 420)}, 700);
    },
    seleccionar(id) {
      seleccion = id;
      mapa.querySelectorAll('.parada').forEach(b => {
        b.classList.toggle('elegida', id != null && b.dataset.tourPoi == id);
      });
      ordenarCapas();
      programarReparto();
    },
    reservar(zonas) {
      reservadas = zonas.map(([x0, y0, x1, y1]) => ({x0, y0, x1, y1}));
      programarReparto();
    },
    zoom(factor) {
      const e = actual();
      volar({...e, radio: e.radio / factor}, 380);
    },
    girar(grados) {
      const e = actual();
      volar({...e, theta: e.theta + rad(grados)}, 480);
    },
    norte() {
      const e = actual();
      volar({...e, theta: rad(norte)}, 480);
    },
    todo() {
      if (!caja) return;
      // El campus entero cabe a lo ancho, que en retrato es lo que limita.
      const fovH = 2 * Math.atan(Math.tan(fovVertical() / 2) * mapa.clientWidth / mapa.clientHeight);
      const diagonal = Math.hypot(caja.x1 - caja.x0, caja.z1 - caja.z0);
      volar({
        theta: rad(norte),
        phi: inclinacion() > rad(3) ? rad(INCLINADA) : rad(CENITAL),
        radio: 0.42 * diagonal / Math.tan(fovH / 2),
        x: (caja.x0 + caja.x1) / 2,
        z: (caja.z0 + caja.z1) / 2,
      }, 700);
    },
  };

  mapa.addEventListener('load', () => {
    const c = mapa.getBoundingBoxCenter(), d = mapa.getDimensions();
    caja = {x0: c.x - d.x / 2, x1: c.x + d.x / 2, z0: c.z - d.z / 2, z1: c.z + d.z / 2};
    ordenarCapas();
    requestAnimationFrame(() => requestAnimationFrame(() => avisar({tipo: 'listo'})));
  }, {once: true});
  mapa.addEventListener('error', () => avisar({tipo: 'error'}));
  mapa.addEventListener('camera-change', e => {
    if (e.detail && e.detail.source === 'user-interaction') {
      vuelo++;
      const e = actual();
      const dentro = acotar(e.x, e.z);
      // Un tope firme en el borde del campus, sin girar la vista.
      if (dentro.x !== e.x || dentro.z !== e.z) aplicar({...e, ...dentro, y: limitar(e.y, 0, 15)});
    }
    pintarFondo();
    programarReparto();
    avisarCamara();
  });
  new ResizeObserver(programarReparto).observe(mapa);
})();
